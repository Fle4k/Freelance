//
//  LiquidGlassUI.swift
//  Freelance
//
//  Created by Shahin on 28.10.25.
//
//  This file showcases the native iOS 18+ .glassEffect() API
//  for creating authentic liquid glass UI elements.
//  
//  Key Features:
//  - Default glass effect with .glassEffect()
//  - Tinted glass with .glassEffect(.regular.tint(Color.opacity))
//  - Interactive effects with .interactive()
//  - Works best with subtle gradient backgrounds
//  
//  Note: This is a demo/reference view. Use Xcode Preview to see examples.

import SwiftUI

struct LiquidGlassUI: View {
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background image to showcase the glass effect
            Image("fle4k_create_a_background_wall_for_a_towerdefence_game_in_viv_c6e19b3d-3d62-4820-a054-40f9d9086328_0")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .opacity(colorScheme == .dark ? 0.4 : 0.3)
                .ignoresSafeArea()
            
            // Gradient overlay to enhance the glass effect
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.2),
                    Color.purple.opacity(0.2),
                    Color.pink.opacity(0.2)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Text("liquid glass showcase")
                        .font(.custom("Major Mono Display Regular", size: 24))
                        .padding(.top, 40)
                    
                    // MARK: - Default Glass Effect
                    VStack(alignment: .leading, spacing: 16) {
                        Text("default glass")
                            .font(.custom("Major Mono Display Regular", size: 14))
                            .foregroundStyle(.secondary)
                        
                        Button("tap me") {
                            print("Default glass button tapped")
                        }
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .padding()
                        .glassEffect()
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Tinted Glass Effects
                    VStack(alignment: .leading, spacing: 16) {
                        Text("tinted glass")
                            .font(.custom("Major Mono Display Regular", size: 14))
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 12) {
                            Button("blue") {
                                print("Blue button tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .padding()
                            .glassEffect(.regular.tint(.blue.opacity(0.6)))
                            
                            Button("purple") {
                                print("Purple button tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .padding()
                            .glassEffect(.regular.tint(.purple.opacity(0.6)))
                            
                            Button("pink") {
                                print("Pink button tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .padding()
                            .glassEffect(.regular.tint(.pink.opacity(0.6)))
                        }
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Interactive Glass Effect
                    VStack(alignment: .leading, spacing: 16) {
                        Text("interactive glass")
                            .font(.custom("Major Mono Display Regular", size: 14))
                            .foregroundStyle(.secondary)
                        
                        Button("press me") {
                            isPressed.toggle()
                        }
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .padding()
                        .glassEffect(.regular.tint(.orange.opacity(0.5)).interactive())
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Card with Glass Effect
                    VStack(alignment: .leading, spacing: 16) {
                        Text("glass cards")
                            .font(.custom("Major Mono Display Regular", size: 14))
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("time tracked")
                                .font(.custom("Major Mono Display Regular", size: 16))
                            Text("04:37:39")
                                .font(.custom("Major Mono Display Regular", size: 24))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .glassEffect(.regular.tint(.white.opacity(0.1)))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Different Glass Strengths
                    VStack(alignment: .leading, spacing: 16) {
                        Text("glass strength")
                            .font(.custom("Major Mono Display Regular", size: 14))
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 12) {
                            Button("ultra thin") {
                                print("Ultra thin tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect(.regular.tint(.white.opacity(0.05)))
                            
                            Button("regular") {
                                print("Regular tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect()
                            
                            Button("thick") {
                                print("Thick tapped")
                            }
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .glassEffect(.regular.tint(.white.opacity(0.3)))
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

#Preview {
    LiquidGlassUI()
}
