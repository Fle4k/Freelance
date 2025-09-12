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
            guard isActive && !particleSystem.particles.isEmpty else { return }
            
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            for particle in particleSystem.particles {
                let depth = CGFloat(1.0 - particle.z)
                let scale = depth * CGFloat(particle.size) + 0.5
                let x = centerX + CGFloat(particle.x) * depth * 0.5
                let y = centerY + CGFloat(particle.y) * depth * 0.5
                
                // Better fade calculation
                let alpha = min(depth * CGFloat(particle.alpha) * 1.5, 1.0)
                
                let rect = CGRect(x: x - scale/2, y: y - scale/2, width: scale, height: scale)
                context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
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
    private var timer: Timer?
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        particles = (0..<200).map { _ in StarParticle.random() }
        
        // Back to 20fps but slower movement
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/20.0, repeats: true) { _ in
            self.updateParticles()
        }
    }
    
    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        particles.removeAll()
    }
    
    private func updateParticles() {
        for i in particles.indices {
            // Slower but not too slow
            particles[i].z -= particles[i].speed * 0.01
            
            if particles[i].z <= 0.0 {
                particles[i] = StarParticle.random()
            }
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
    
    static func random() -> StarParticle {
        StarParticle(
            x: Float.random(in: -800...800),
            y: Float.random(in: -1000...1000),
            z: Float.random(in: 0.85...1.0),        // Closer starting point
            speed: Float.random(in: 0.2...0.6),     // Moderate speeds
            size: Float.random(in: 1.5...4.0),      // Bigger particles
            alpha: Float.random(in: 0.8...1.0)      // High visibility
        )
    }
}

#Preview {
    StarfieldView(isActive: true)
        .background(.black)
}
