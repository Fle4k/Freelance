//
//  TimerView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct ProgressCircle: View {
    let progress: Double
    let size: CGFloat
    
    var body: some View {
        Circle()
            .trim(from: 0, to: progress)
            .stroke(Color.primary, lineWidth: 1)
            .rotationEffect(.degrees(-90)) // Start from top and go counter-clockwise
            .scaleEffect(x: -1, y: 1) // Flip horizontally for true counter-clockwise
            .frame(width: size, height: size)
    }
}

struct TimerView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingStatistics = false
    @State private var showingResetAlert = false
    @State private var longPressProgress: Double = 0.0
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?
    @Environment(\.colorScheme) var colorScheme
    
    private let longPressDuration: Double = 0.8
    private let progressDelay: Double = 0.2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full screen background - always visible
                if themeManager.useMaterialBackground {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(red: 0.2, green: 0.2, blue: 0.2), // Anthracite
                            Color.black
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                } else {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                }
                
                // White particles appear when timer is running (on top of background)
                if timeTracker.isRunning {
                    TimerParticleView(isActive: true)
                        .ignoresSafeArea()
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Timer Display
                    HStack {
                        Spacer()
                        Text(timeTracker.formattedElapsedTime)
                            .font(.custom("Major Mono Display Regular", size: min(geometry.size.width * 0.15, 64)))
                            .foregroundColor(themeManager.currentTheme == .liquidGlass ? .white : .primary)
                            .shadow(
                                color: themeManager.currentTheme == .liquidGlass ? Color.black.opacity(0.3) : Color.clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Glass Effect Container for both buttons
                    HStack {
                        Spacer()
                        GlassEffectContainer {
                            VStack(spacing: 40) {
                                // Record/Pause Button
                                Button(action: {
                                    if !isLongPressing {
                                        if timeTracker.isRunning {
                                            timeTracker.pauseTimer()
                                        } else {
                                            timeTracker.startTimer()
                                        }
                                    }
                                }) {
                                    ZStack {
                                        Color.clear
                                            .frame(width: 64, height: 64)
                                        
                                        if timeTracker.isRunning {
                                            Image(systemName: "stop.fill")
                                                .font(.system(size: 22, weight: .regular))
                                                .foregroundColor(.primary)
                                                .contentTransition(.symbolEffect(.replace.downUp))
                                                .animation(.easeInOut(duration: 0.3), value: timeTracker.isRunning)
                                        } else {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 24, weight: .regular))
                                                .foregroundColor(.primary)
                                                .contentTransition(.symbolEffect(.replace.downUp))
                                                .animation(.easeInOut(duration: 0.3), value: timeTracker.isRunning)
                                                .offset(x: 1.5) // Optical centering for play triangle
                                        }
                                    }
                                }
                                .modifier(GlassButtonModifier(
                                    isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                                    size: 64
                                ))
                                .scaleEffect(timeTracker.isRunning ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: timeTracker.isRunning)
                                .overlay(
                                    Group {
                                        if isLongPressing && longPressProgress > 0 {
                                            ProgressCircle(progress: longPressProgress, size: 100)
                                        }
                                    }
                                )
                                .contentShape(Circle())
                                .simultaneousGesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if longPressTimer == nil {
                                                startLongPress()
                                            }
                                        }
                                        .onEnded { _ in
                                            endLongPress()
                                        }
                                )
                                
                                // Menu Button
                                Button(action: {
                                    showingStatistics = true
                                }) {
                                    ZStack {
                                        Color.clear
                                            .frame(width: 64, height: 64)
                                        
                                        Image(systemName: "line.3.horizontal")
                                            .font(.system(size: 20, weight: .regular))
                                            .foregroundColor(.primary)
                                            .symbolEffect(.disappear, isActive: showingStatistics)
                                    }
                                }
                                .modifier(GlassButtonModifier(
                                    isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                                    size: 64
                                ))
                                .contentShape(Circle())
                            }
                        }
                        Spacer()
                    }
                    .padding(.bottom, 80)
                }
            }
        }
        .ignoresSafeArea()
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            timeTracker.updateElapsedTime()
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsOverviewView()
        }
        .alert("reset timer", isPresented: $showingResetAlert) {
            Button("cancel", role: .cancel) { }
            Button("store and reset") {
                timeTracker.recordTimer()
                timeTracker.startTimer()
            }
            Button("reset", role: .destructive) {
                timeTracker.resetTimer()
            }
        } message: {
            Text("store time and start a new session or reset without storing?")
        }
        .onDisappear {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
    }
    
    private func startLongPress() {
        longPressProgress = 0.0
        
        // Add delay before showing progress circle
        longPressTimer = Timer.scheduledTimer(withTimeInterval: progressDelay, repeats: false) { _ in
            // After delay, start the actual progress animation if still pressing
            self.isLongPressing = true
            self.animateProgress()
        }
    }
    
    private func animateProgress() {
        let startTime = Date()
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let normalizedTime = min(elapsed / self.longPressDuration, 1.0)
            
            // Quadratic easing: starts slow, accelerates towards end
            let easedProgress = normalizedTime * normalizedTime
            self.longPressProgress = easedProgress
            
            if normalizedTime >= 1.0 {
                timer.invalidate()
                self.longPressTimer = nil
                
                // Ensure visual completion at exactly 1.0
                self.longPressProgress = 1.0
                
                // Haptic feedback when circle completes
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Longer delay to ensure circle visually completes before alert
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Show reset alert
                    self.showingResetAlert = true
                    
                    // Reset progress state AFTER alert appears to prevent visual artifacts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.isLongPressing = false
                        self.longPressProgress = 0.0
                    }
                }
            }
        }
    }
    
    private func endLongPress() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        // Only reset if circle hasn't completed (progress < 1.0)
        // If completed, let the completion handler manage the reset
        if longPressProgress < 1.0 {
            isLongPressing = false
            longPressProgress = 0.0
        }
    }
}

#Preview {
    TimerView()
}
