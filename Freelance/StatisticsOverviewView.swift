//
//  StatisticsOverviewView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct StatisticsOverviewView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingDailyStats = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("STATISTICS")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Statistics Content
                VStack(spacing: 30) {
                    // Time periods
                    VStack(spacing: 20) {
                        Button(action: { showingDailyStats = true }) {
                            StatisticRow(
                                title: "TODAY",
                                value: timeTracker.formattedTotalTime(for: .today),
                                unit: ""
                            )
                        }
                        .foregroundColor(.primary)
                        
                        StatisticRow(
                            title: "THIS WEEK",
                            value: String(format: "%.0f", timeTracker.getTotalHours(for: .thisWeek)),
                            unit: "H"
                        )
                        
                        StatisticRow(
                            title: "LAST WEEK",
                            value: String(format: "%.0f", timeTracker.getTotalHours(for: .lastWeek)),
                            unit: "H"
                        )
                    }
                    
                    Divider()
                        .padding(.horizontal, 40)
                    
                    // Settings Header
                    Text("SETTINGS")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.bottom, 20)
                    
                    // Settings Content (inline)
                    VStack(spacing: 20) {
                        // Dead Man Switch
                        VStack(spacing: 8) {
                            HStack {
                                Text("CHECK IN EVERY")
                                    .font(.custom("EkMukta-ExtraLight", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    settings.deadManSwitchEnabled.toggle()
                                }) {
                                    Text("\(Int(settings.deadManSwitchInterval))MIN")
                                        .font(.custom("EkMukta-ExtraLight", size: 17))
                                        .foregroundColor(settings.deadManSwitchEnabled ? .primary : .secondary)
                                        .overlay(
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(settings.deadManSwitchEnabled ? .primary : .secondary),
                                            alignment: .bottom
                                        )
                                }
                            }
                        }
                        
                        // Motion Detection
                        VStack(spacing: 8) {
                            HStack {
                                Text("ASK WHEN I")
                                    .font(.custom("EkMukta-ExtraLight", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    settings.askWhenMoving.toggle()
                                }) {
                                    Text(settings.askWhenMoving ? "MOVE" : "DON'T MOVE")
                                        .font(.custom("EkMukta-ExtraLight", size: 17))
                                        .foregroundColor(.primary)
                                        .overlay(
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(.primary),
                                            alignment: .bottom
                                        )
                                }
                            }
                            
                            HStack {
                                Text("LONGER THAN")
                                    .font(.custom("EkMukta-ExtraLight", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    settings.motionDetectionEnabled.toggle()
                                }) {
                                    Text("\(Int(settings.motionThreshold))MIN")
                                        .font(.custom("EkMukta-ExtraLight", size: 17))
                                        .foregroundColor(settings.motionDetectionEnabled ? .primary : .secondary)
                                        .overlay(
                                            Rectangle()
                                                .frame(height: 1)
                                                .foregroundColor(settings.motionDetectionEnabled ? .primary : .secondary),
                                            alignment: .bottom
                                        )
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, 40)
                        
                        // Salary Setting
                        HStack {
                            Text("SALARY")
                                .font(.custom("EkMukta-ExtraLight", size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            TextField("80 €/H", value: $settings.hourlyRate, format: .number)
                                .font(.custom("EkMukta-ExtraLight", size: 17))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .overlay(
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundColor(.primary),
                                    alignment: .bottom
                                )
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingDailyStats) {
            DailyStatisticsView()
        }
        .onDisappear {
            settings.saveSettings()
        }
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                                                    .font(.custom("EkMukta-ExtraLight", size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                                                        .font(.custom("EkMukta-ExtraLight", size: 17))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.custom("EkMukta-ExtraLight", size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    StatisticsOverviewView()
}
