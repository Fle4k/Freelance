//
//  TimerParticleView.swift
//  Freelance
//
//  Created by AI Assistant on 18.09.25.
//

import SwiftUI

struct TimerParticleView: View {
    let isActive: Bool
    @StateObject private var particleSystem = TimerParticleSystem()
    
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
                context.fill(Path(ellipseIn: rect), with: .color(.primary.opacity(alpha)))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                particleSystem.start()
            } else {
                particleSystem.stop()
            }
        }
    }
}

final class TimerParticleSystem: ObservableObject {
    @Published var particles: [TimerParticle] = []
    private var timer: Timer?
    private var isRunning = false
    private var secondsElapsed = 0
    
    func start() {
        guard !isRunning else { return }
        
        timer?.invalidate()
        timer = nil
        
        isRunning = true
        secondsElapsed = 0
        particles.removeAll()
        
        // Timer that fires every second to add new particles
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.addParticle()
        }
        
        // Animation timer for smooth movement (60fps)
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { animationTimer in
            if !self.isRunning {
                animationTimer.invalidate()
                return
            }
            self.updateParticles()
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        
        // Start fade out animation for all particles
        for i in particles.indices {
            particles[i].fadeOutProgress = 0.0
        }
        
        // Continue animation until all particles fade out
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { fadeTimer in
            var allFadedOut = true
            
            for i in self.particles.indices {
                // Fade out particles
                self.particles[i].fadeOutProgress += 0.033  // ~0.5 seconds to fade
                self.particles[i].alpha = max(0, self.particles[i].alpha - 0.033)
                
                if self.particles[i].fadeOutProgress < 1.0 {
                    allFadedOut = false
                }
            }
            
            if allFadedOut {
                fadeTimer.invalidate()
                self.particles.removeAll()
            }
        }
    }
    
    private func addParticle() {
        guard isRunning else { return }
        
        secondsElapsed += 1
        
        // After 59 seconds, start fading out all particles
        if secondsElapsed >= 60 {
            // Reset the counter and fade out all particles
            secondsElapsed = 0
            fadeOutAllParticles()
            return
        }
        
        // Add a new particle
        let newParticle = TimerParticle.random()
        particles.append(newParticle)
        
        print("Added particle #\(secondsElapsed), total particles: \(particles.count)")
    }
    
    private func fadeOutAllParticles() {
        print("60 seconds reached - fading out all \(particles.count) particles")
        
        // Start fade out animation for all particles
        for i in particles.indices {
            particles[i].fadeOutProgress = 0.0
        }
        
        // Continue animation until all particles fade out
        Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { fadeTimer in
            var allFadedOut = true
            
            for i in self.particles.indices {
                // Fade out particles faster (0.5 seconds total)
                self.particles[i].fadeOutProgress += 0.033
                self.particles[i].alpha = max(0, self.particles[i].alpha - 0.033)
                
                if self.particles[i].fadeOutProgress < 1.0 {
                    allFadedOut = false
                }
            }
            
            if allFadedOut {
                fadeTimer.invalidate()
                self.particles.removeAll()
                print("All particles faded out and removed")
            }
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            // Gentle floating animation
            particles[i].x += particles[i].velocityX * 0.0016 // Slow horizontal drift
            particles[i].y += particles[i].velocityY * 0.0016 // Slow vertical drift
            
            // Keep constant size (no pulsing)
            particles[i].size = particles[i].baseSize
            
            // Wrap around screen edges
            if particles[i].x < 0 { particles[i].x = 1.0 }
            if particles[i].x > 1 { particles[i].x = 0.0 }
            if particles[i].y < 0 { particles[i].y = 1.0 }
            if particles[i].y > 1 { particles[i].y = 0.0 }
        }
    }
}

struct TimerParticle {
    var x: Float
    var y: Float
    var size: Float
    var baseSize: Float
    var alpha: Float
    var velocityX: Float
    var velocityY: Float
    var pulseTime: Float
    var fadeOutProgress: Float = 0.0
    
    static func random() -> TimerParticle {
        let baseSize = Float.random(in: 2.0...6.0)
        return TimerParticle(
            x: Float.random(in: 0.1...0.9),
            y: Float.random(in: 0.1...0.9),
            size: baseSize,
            baseSize: baseSize,
            alpha: Float.random(in: 0.6...1.0),
            velocityX: Float.random(in: -0.5...0.5),
            velocityY: Float.random(in: -0.5...0.5),
            pulseTime: Float.random(in: 0...Float.pi * 2),
            fadeOutProgress: 0.0
        )
    }
}

#Preview {
    TimerParticleView(isActive: true)
        .background(.black)
}
