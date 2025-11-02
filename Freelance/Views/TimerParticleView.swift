//
//  TimerParticleView.swift
//  Freelance
//
//  Created by AI Assistant on 18.09.25.
//

import SwiftUI

struct TimerParticleView: View {
    let isActive: Bool
    @ObservedObject private var timeTracker = TimeTracker.shared
    @StateObject private var particleSystem = TimerParticleSystem()
    
    // Calculate total elapsed seconds across all sessions
    private var totalElapsedSeconds: Int {
        let totalTime = timeTracker.totalAccumulatedTime + (timeTracker.isRunning ? timeTracker.elapsedTime : 0)
        return Int(totalTime)
    }
    
    var body: some View {
        Canvas { context, size in
            guard !particleSystem.particles.isEmpty else { return }
            
            for particle in particleSystem.particles {
                // Calculate position based on screen size
                let x = CGFloat(particle.x) * size.width
                let y = CGFloat(particle.y) * size.height
                let scale = CGFloat(particle.size)
                let alpha = CGFloat(particle.alpha)
                
                let rect = CGRect(x: x - scale/2, y: y - scale/2, width: scale, height: scale)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onAppear {
            particleSystem.updateTimerState(
                isRunning: timeTracker.isRunning,
                totalElapsedSeconds: totalElapsedSeconds
            )
        }
        .onChange(of: timeTracker.isRunning) { _, isRunning in
            particleSystem.updateTimerState(
                isRunning: isRunning,
                totalElapsedSeconds: totalElapsedSeconds
            )
        }
        .onChange(of: totalElapsedSeconds) { _, seconds in
            particleSystem.updateTimerState(
                isRunning: timeTracker.isRunning,
                totalElapsedSeconds: seconds
            )
        }
    }
}

final class TimerParticleSystem: ObservableObject {
    @Published var particles: [TimerParticle] = []
    private var animationTimer: Timer?
    private var isRunning = false
    private var isPaused = false
    private var lastSeenSecond = -1
    private var lastElapsedSeconds = -1
    
    func updateTimerState(isRunning: Bool, totalElapsedSeconds: Int) {
        // Detect timer reset: total seconds went backwards significantly
        if totalElapsedSeconds < lastElapsedSeconds && (lastElapsedSeconds - totalElapsedSeconds) > 2 {
            particles.removeAll()
            lastSeenSecond = -1
            self.isPaused = false
            print("🔄 Timer reset detected - cleared all particles")
        }
        
        // Timer started fresh (from 0)
        if isRunning && !self.isRunning && !self.isPaused {
            startAnimation()
            self.isRunning = true
            self.isPaused = false
            print("▶️ Timer started fresh")
        }
        // Timer paused
        else if !isRunning && self.isRunning {
            self.isRunning = false
            self.isPaused = true
            print("⏸️ Timer paused at \(totalElapsedSeconds)s - \(particles.count) particles stay visible and bounce")
            // Keep animation running so particles continue to move and bounce
            startAnimation()
        }
        // Timer resumed from pause
        else if isRunning && self.isPaused {
            self.isRunning = true
            self.isPaused = false
            print("▶️ Timer resumed at \(totalElapsedSeconds)s - \(particles.count) particles wrap again")
            
            // Particles continue with their current direction (no velocity reset)
        }
        
        // Add particle for each new second (only when running)
        if isRunning {
            let currentSecond = totalElapsedSeconds % 60
            
            if totalElapsedSeconds != lastElapsedSeconds {
                // New second started
                if currentSecond == 0 && lastSeenSecond > 0 {
                    // Clear all particles at the start of a new minute
                    particles.removeAll()
                    lastSeenSecond = -1
                    print("🔄 New minute - cleared all particles")
                }
                
                if currentSecond != lastSeenSecond {
                    addParticle(forSecond: currentSecond + 1)
                    lastSeenSecond = currentSecond
                    
                    // At 57 seconds, start fading particles individually
                    if currentSecond >= 57 {
                        startFadingParticles(currentSecond: currentSecond)
                    }
                }
            }
        }
        
        lastElapsedSeconds = totalElapsedSeconds
    }
    
    private func startAnimation() {
        // Only start if not already running
        guard animationTimer == nil else { return }
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            
            // Keep animating as long as there are particles (even when paused)
            if self.particles.isEmpty && !self.isRunning {
                timer.invalidate()
                self.animationTimer = nil
            } else {
                self.updateParticles()
            }
        }
    }
    
    private func addParticle(forSecond second: Int) {
        guard second <= 60 else { return }
        
        let newParticle = TimerParticle.random(createdAtSecond: second)
        particles.append(newParticle)
        
        print("✨ Added particle #\(second), total: \(particles.count)")
    }
    
    private func startFadingParticles(currentSecond: Int) {
        // At 57s: All particles start fading independently
        // They should all be gone by the end of second 59
        
        for i in particles.indices {
            // Only start fading particles that haven't started fading yet
            if !particles[i].isFading {
                particles[i].isFading = true
                particles[i].fadeOutProgress = 0.0
                
                // Stagger fade durations based on particle age (older particles fade slower)
                // This creates an independent, staggered disappearance effect
                let particleAge = Float(particles[i].createdAtSecond)
                let fadeSpread = Float.random(in: 0.8...1.2) // Add some randomness
                
                // Map particle age (1-60) to fade duration (1.0-3.0 seconds)
                // Older particles (lower numbers) get longer fade times
                let baseFadeDuration = 3.0 - (particleAge / 60.0) * 2.0
                particles[i].fadeDuration = baseFadeDuration * fadeSpread
                
                print("🌫️ Particle #\(particles[i].createdAtSecond) starting fade (duration: \(String(format: "%.1f", particles[i].fadeDuration))s)")
            }
        }
    }
    
    private func updateParticles() {
        var indicesToRemove: [Int] = []
        
        for i in particles.indices {
            // Handle fading
            if particles[i].isFading {
                particles[i].fadeOutProgress += 1.0 / (60.0 * particles[i].fadeDuration)
                particles[i].alpha = max(0, particles[i].originalAlpha * (1.0 - particles[i].fadeOutProgress))
                
                if particles[i].fadeOutProgress >= 1.0 {
                    indicesToRemove.append(i)
                    continue
                }
            }
            
            // Gentle floating animation (35% speed when paused)
            let speedMultiplier: Float = isPaused ? 0.00056 : 0.0016
            particles[i].x += particles[i].velocityX * speedMultiplier
            particles[i].y += particles[i].velocityY * speedMultiplier
            
            // Keep constant size
            particles[i].size = particles[i].baseSize
            
            // Different edge behavior based on pause state
            if isPaused {
                // Bounce off edges when paused
                if particles[i].x <= 0.0 || particles[i].x >= 1.0 {
                    particles[i].velocityX *= -1
                    particles[i].x = max(0.0, min(1.0, particles[i].x))
                }
                if particles[i].y <= 0.0 || particles[i].y >= 1.0 {
                    particles[i].velocityY *= -1
                    particles[i].y = max(0.0, min(1.0, particles[i].y))
                }
            } else {
                // Wrap around edges when running (allow particles to leave screen)
                if particles[i].x < 0 { 
                    particles[i].x = 1.0 + particles[i].x  // Maintain overflow
                }
                if particles[i].x > 1 { 
                    particles[i].x = particles[i].x - 1.0  // Maintain overflow
                }
                if particles[i].y < 0 { 
                    particles[i].y = 1.0 + particles[i].y  // Maintain overflow
                }
                if particles[i].y > 1 { 
                    particles[i].y = particles[i].y - 1.0  // Maintain overflow
                }
            }
        }
        
        // Remove faded particles
        for index in indicesToRemove.reversed() {
            particles.remove(at: index)
        }
    }
    
    deinit {
        animationTimer?.invalidate()
    }
}

struct TimerParticle: Identifiable {
    let id = UUID()
    var x: Float
    var y: Float
    var size: Float
    var baseSize: Float
    var alpha: Float
    var originalAlpha: Float
    var velocityX: Float
    var velocityY: Float
    var originalVelocityX: Float
    var originalVelocityY: Float
    var createdAtSecond: Int
    var isFading: Bool = false
    var fadeOutProgress: Float = 0.0
    var fadeDuration: Float = 1.0
    
    static func random(createdAtSecond: Int) -> TimerParticle {
        let baseSize = Float.random(in: 2.0...6.0)
        let alpha = Float.random(in: 0.6...1.0)
        let velX = Float.random(in: -0.5...0.5)
        let velY = Float.random(in: -0.5...0.5)
        return TimerParticle(
            x: Float.random(in: 0.1...0.9),
            y: Float.random(in: 0.1...0.9),
            size: baseSize,
            baseSize: baseSize,
            alpha: alpha,
            originalAlpha: alpha,
            velocityX: velX,
            velocityY: velY,
            originalVelocityX: velX,
            originalVelocityY: velY,
            createdAtSecond: createdAtSecond
        )
    }
}

#Preview {
    TimerParticleView(isActive: true)
        .background(.black)
}
