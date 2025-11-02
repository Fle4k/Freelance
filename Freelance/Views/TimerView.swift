//
//  TimerView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct ProgressCapsule: View {
    let progress: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        Capsule()
            .trim(from: 0, to: progress)
            .stroke(Color.primary, lineWidth: 2)
            .frame(width: width, height: height)
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
    @State private var isTapped = false
    @Environment(\.colorScheme) var colorScheme
    
    private let longPressDuration: Double = 0.8
    private let progressDelay: Double = 0.2
    
    var body: some View {
        ZStack {
            // Background matching statistics view
            Color.clear
                .themedBackground()
                .ignoresSafeArea()
            
            // White particles (always visible, behavior changes based on running state)
            TimerParticleView(isActive: timeTracker.isRunning)
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Timer Display - pill style centered with tap and long press
                VStack(spacing: 8) {                        
                    Text(timeTracker.formattedElapsedTime)
                        .font(.custom("Major Mono Display Regular", size: 48))
                        .foregroundColor(timeTracker.isRunning ? .primary : .secondary)
                        .monospacedDigit()
                        .animation(.easeInOut(duration: 0.2), value: timeTracker.isRunning)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, themeManager.spacing.xLarge)
                .padding(.vertical, 32)
                .themedSectionBackground()
                .opacity(timeTracker.isRunning ? 1.0 : 0.6)
                .overlay(
                    Group {
                        if isLongPressing && longPressProgress > 0 {
                            ProgressCapsule(
                                progress: longPressProgress,
                                width: UIScreen.main.bounds.width - (themeManager.spacing.contentHorizontal * 2),
                                height: 112
                            )
                        }
                    }
                )
                .padding(.horizontal, themeManager.spacing.contentHorizontal)
                .scaleEffect(isTapped ? 0.95 : 1.0)
                .opacity(isTapped ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isTapped)
                .contentShape(Capsule())
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if longPressTimer == nil {
                                isTapped = true
                                startLongPress()
                            }
                        }
                        .onEnded { _ in
                            // Delay the tap animation reset slightly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isTapped = false
                            }
                            
                            // Check if it was a tap (not long press)
                            if !isLongPressing && longPressProgress < 0.1 {
                                if timeTracker.isRunning {
                                    timeTracker.pauseTimer()
                                } else {
                                    timeTracker.startTimer()
                                }
                            }
                            
                            endLongPress()
                        }
                )
                
                Spacer()
            }
            
            // Floating menu button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingStatistics = true
                    }) {
                        ZStack {
                            Color.clear
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                    .modifier(GlassButtonModifier(
                        isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                        size: 64
                    ))
                    .contentShape(Circle())
                    .padding(.trailing, themeManager.spacing.medium)
                    .padding(.bottom, themeManager.spacing.medium)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
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
