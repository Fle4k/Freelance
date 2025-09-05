//
//  TimerView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @State private var showingStatistics = false
    @State private var showingResetAlert = false
    
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
                    
                    // Menu Button (centered above record button)
                    Button(action: {
                        showingStatistics = true
                    }) {
                        Image(systemName: "circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.primary)
                            .symbolEffect(.disappear, isActive: showingStatistics)
                    }
                    .padding(.bottom, 80)
                    
                    // Record/Pause Button
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: timeTracker.isRunning ? "square" : "play.fill")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.primary)
                                .contentTransition(.symbolEffect(.replace))
                                .animation(.easeInOut(duration: 0.3), value: timeTracker.isRunning)
                        )
                        .scaleEffect(timeTracker.isRunning ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: timeTracker.isRunning)
                        .simultaneousGesture(
                            TapGesture()
                                .onEnded { _ in
                                    if timeTracker.isRunning {
                                        timeTracker.pauseTimer()
                                    } else {
                                        timeTracker.startTimer()
                                    }
                                }
                        )
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 1.0)
                                .onEnded { _ in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    showingResetAlert = true
                                }
                        )
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
}


#Preview {
    TimerView()
}
