//
//  StarfieldView.swift
//  Freelance
//
//  Created by Shahin on 12.09.25.
//

import SwiftUI

struct StarfieldView: View {
    let isActive: Bool
    @StateObject private var particleSystem = StarfieldParticleSystem()
    
    var body: some View {
        Canvas { context, size in
            guard (isActive || particleSystem.isFadingOut) && !particleSystem.particles.isEmpty else { return }
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            for particle in particleSystem.particles {
                let depth = CGFloat(1.0 - particle.z)
                let scale = depth * CGFloat(particle.size) + 0.5
                let x = centerX + CGFloat(particle.x) * depth * 0.5
                let y = centerY + CGFloat(particle.y) * depth * 0.5
                
                // Better fade calculation with fade out
                let baseAlpha = min(depth * CGFloat(particle.alpha) * 1.5, 1.0)
                let fadeOutAlpha = 1.0 - CGFloat(particle.fadeOutProgress)
                let alpha = baseAlpha * fadeOutAlpha
                
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

final class StarfieldParticleSystem: ObservableObject {
    @Published var particles: [StarParticle] = []
    @Published var isFadingOut = false
    private var timer: Timer?
    private var isRunning = false
    
    func start() {
        // Don't start if already running
        guard !isRunning else { return }
        
        // Stop any existing timer and reset state
        timer?.invalidate()
        timer = nil
        
        isRunning = true
        isFadingOut = false
        particles = (0..<200).map { _ in StarParticle.random() }
        
        // Higher framerate for smoother animation
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.updateParticles()
        }
    }
    
    func stop() {
        // Don't start fade out if already fading out or not running
        guard !isFadingOut && isRunning else { return }
        
        // Stop any existing timer first
        timer?.invalidate()
        timer = nil
        
        isRunning = false
        isFadingOut = true
        
        // Start fade out animation for all particles
        for i in particles.indices {
            particles[i].fadeOutProgress = 0.0
        }
        
        // Continue updating particles during fade out
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            self.updateParticlesFadeOut()
        }
    }
    
    private func updateParticles() {
        for i in particles.indices {
            // Smooth movement at 60fps - reduced speed to maintain same visual speed
            particles[i].z -= particles[i].speed * 0.0033
            
            // Start fading out when particle gets close to the front
            if particles[i].z <= 0.1 {
                particles[i].fadeOutProgress += 0.013  // Adjusted for 60fps (~1.25 seconds)
                
                // Only replace particle when fully faded out
                if particles[i].fadeOutProgress >= 1.0 {
                    particles[i] = StarParticle.random()
                }
            }
        }
    }
    
    private func updateParticlesFadeOut() {
        var allFadedOut = true
        
        for i in particles.indices {
            // Continue moving particles during fade out
            particles[i].z -= particles[i].speed * 0.0033
            
            // Fade out all particles at the same rate as individual particles
            particles[i].fadeOutProgress += 0.013  // Adjusted for 60fps (~1.25 seconds)
            
            if particles[i].fadeOutProgress < 1.0 {
                allFadedOut = false
            }
        }
        
        // When all particles are fully faded out, stop the timer and clear particles
        if allFadedOut {
            timer?.invalidate()
            timer = nil
            particles.removeAll()
            isFadingOut = false
            isRunning = false  // Reset running state
        }
    }
}

struct StarParticle {
    var x: Float
    var y: Float
    var z: Float
    var speed: Float
    var size: Float
    var alpha: Float
    var fadeOutProgress: Float = 0.0  // 0.0 = fully visible, 1.0 = fully faded
    
    static func random() -> StarParticle {
        StarParticle(
            x: Float.random(in: -800...800),
            y: Float.random(in: -1000...1000),
            z: Float.random(in: 0.85...1.0),        // Closer starting point
            speed: Float.random(in: 0.2...0.6),     // Moderate speeds
            size: Float.random(in: 1.5...4.0),      // Bigger particles
            alpha: Float.random(in: 0.8...1.0),     // High visibility
            fadeOutProgress: 0.0                     // Start fully visible
        )
    }
}

#Preview {
    StarfieldView(isActive: true)
        .background(.black)
}
