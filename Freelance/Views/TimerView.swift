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
    @State private var showingRecordConfirmation = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Timer Display
                    Text(timeTracker.formattedElapsedTime)
                        .font(.custom("CMU Typewriter Text Light", size: min(geometry.size.width * 0.12, 64)))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5)
                    
                    Spacer()
                    
                    // Hamburger Menu (centered above record button)
                    Button(action: {
                        showingStatistics = true
                    }) {
                        VStack(spacing: 3) {
                            Rectangle()
                                .fill(Color.primary)
                                .frame(width: 20, height: 2)
                            Rectangle()
                                .fill(Color.primary)
                                .frame(width: 20, height: 2)
                            Rectangle()
                                .fill(Color.primary)
                                .frame(width: 20, height: 2)
                        }
                    }
                    .padding(.bottom, 80)
                    
                    // Record/Pause Button
                    Button(action: {
                        if timeTracker.isRunning {
                            timeTracker.pauseTimer()
                        } else if timeTracker.currentSessionStart != nil {
                            // If paused, show options to continue or record
                            showingRecordConfirmation = true
                        } else {
                            timeTracker.startTimer()
                        }
                    }) {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Group {
                                    if timeTracker.isRunning {
                                        // Pause icon (two rectangles)
                                        HStack(spacing: 4) {
                                            Rectangle()
                                                .fill(Color.primary)
                                                .frame(width: 6, height: 20)
                                            Rectangle()
                                                .fill(Color.primary)
                                                .frame(width: 6, height: 20)
                                        }
                                    } else {
                                        // Play icon (triangle)
                                        Triangle()
                                            .fill(Color.primary)
                                            .frame(width: 16, height: 16)
                                            .offset(x: 2)
                                    }
                                }
                            )
                    }
                    .scaleEffect(timeTracker.isRunning ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: timeTracker.isRunning)
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
        .actionSheet(isPresented: $showingRecordConfirmation) {
            ActionSheet(
                title: Text("Timer Paused"),
                message: Text("What would you like to do?"),
                buttons: [
                    .default(Text("Continue")) {
                        timeTracker.startTimer()
                    },
                    .destructive(Text("Record & Reset")) {
                        timeTracker.recordTimer()
                    },
                    .cancel()
                ]
            )
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    TimerView()
}
