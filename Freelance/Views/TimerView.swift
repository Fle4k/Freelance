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
            .stroke(Color.primary.opacity(0.6), lineWidth: 2)
            .rotationEffect(.degrees(-90))
            .frame(width: size, height: size)
    }
}

struct TimerView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @State private var showingStatistics = false
    @State private var showingResetAlert = false
    @State private var longPressProgress: Double = 0.0
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?
    
    private let longPressDuration: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Timer Display
                    Text(timeTracker.formattedElapsedTime)
                        .font(.custom("Major Mono Display Regular", size: min(geometry.size.width * 0.12, 64)))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                    
                    // Record/Pause Button
                    ZStack {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 120, height: 120)
                        
                        // Progress circle overlay
                        if isLongPressing {
                            ProgressCircle(progress: longPressProgress, size: 120)
                        }
                        
                        Image(systemName: timeTracker.isRunning ? "square" : "play")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary)
                            .contentTransition(.symbolEffect(.replace.offUp))
                            .animation(.easeInOut(duration: 0.3), value: timeTracker.isRunning)
                    }
                    .scaleEffect(timeTracker.isRunning ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: timeTracker.isRunning)
                    .simultaneousGesture(
                        TapGesture()
                            .onEnded { _ in
                                if !isLongPressing {
                                    if timeTracker.isRunning {
                                        timeTracker.pauseTimer()
                                    } else {
                                        timeTracker.startTimer()
                                    }
                                }
                            }
                    )
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
                    .padding(.bottom, 80)
                    
                    // Menu Button (centered below record button)
                    Button(action: {
                        showingStatistics = true
                    }) {
                        Image(systemName: "circle")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.primary)
                            .symbolEffect(.disappear, isActive: showingStatistics)
                            .frame(width: 80, height: 80)
                            .background(Color.clear)
                    }
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 60)
                }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            timeTracker.updateElapsedTime()
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsOverviewView()
        }
        .onDisappear {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
        .alert("reset timer", isPresented: $showingResetAlert) {
            Button("cancel", role: .cancel) { }
            Button("store and reset") {
                timeTracker.recordTimer()
                timeTracker.startTimer()
            }
        } message: {
            Text("Store time and start a new session?")
        }
    }
    
    private func startLongPress() {
        longPressProgress = 0.0
        
        // Create a placeholder timer to mark that pressing has started
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
            // After delay, start the actual progress timer if still pressing
            self.isLongPressing = true
            
            // Track the start time for dynamic progress calculation
            let startTime = Date()
            
            self.longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
                let elapsed = Date().timeIntervalSince(startTime)
                let normalizedTime = min(elapsed / self.longPressDuration, 1.0)
                
                // Quadratic ease-in function: starts slow, accelerates toward end
                // f(x) = x^2 where x is normalized time (0 to 1)
                self.longPressProgress = normalizedTime * normalizedTime
                
                if normalizedTime >= 1.0 {
                    timer.invalidate()
                    self.longPressTimer = nil
                    
                    // Haptic feedback when circle completes
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    
                    // Show reset alert
                    self.showingResetAlert = true
                    
                    // Reset progress state
                    self.isLongPressing = false
                    self.longPressProgress = 0.0
                }
            }
        }
    }
    
    private func endLongPress() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        isLongPressing = false
        longPressProgress = 0.0
    }
}


#Preview {
    TimerView()
}
