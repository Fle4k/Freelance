//
//  StatisticsOverviewView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

extension StatisticsPeriod {
    var displayName: String {
        switch self {
        case .today: return "today"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        case .thisMonth: return "this month"
        case .total: return "total"
        }
    }
}

struct StatisticsOverviewView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingTodayDetail = false
    @State private var showingWeekDetail = false
    @State private var showingMonthDetail = false
    @State private var showingDeadManSwitchPicker = false
    @State private var showingMotionThresholdPicker = false
    @State private var showingSalaryInput = false
    @State private var showingCustomDeadManInput = false
    @State private var showingCustomMotionInput = false
    @State private var showingWeekStartsPicker = false
    @State private var customDeadManValue = ""
    @State private var customMotionValue = ""
    @State private var salaryInputValue = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer(minLength: 30)
                    
                // Overview Page
                VStack(spacing: 30) {
                    // Today Card
                    Button(action: {
                        showingTodayDetail = true
                    }) {
                        VStack(spacing: 10) {
                            Text("today")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                            Text(timeTracker.formattedTimeHMS(for: .today))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .today)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // This Week Card
                    Button(action: {
                        showingWeekDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this week")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                            Text(timeTracker.formattedTimeHMS(for: .thisWeek))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisWeek)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // This Month Card
                    Button(action: {
                        showingMonthDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this month")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                            Text(timeTracker.formattedTimeHMS(for: .thisMonth))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisMonth)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Settings section - always at bottom
                SettingsSection(
                    settings: settings,
                    showingDeadManSwitchPicker: $showingDeadManSwitchPicker,
                    showingMotionThresholdPicker: $showingMotionThresholdPicker,
                    showingSalaryInput: $showingSalaryInput,
                    showingCustomDeadManInput: $showingCustomDeadManInput,
                    showingCustomMotionInput: $showingCustomMotionInput,
                    showingWeekStartsPicker: $showingWeekStartsPicker,
                    customDeadManValue: $customDeadManValue,
                    customMotionValue: $customMotionValue,
                    salaryInputValue: $salaryInputValue
                )
            }
            .background(Color(.systemBackground))
        }
        .onDisappear {
            settings.saveSettings()
        }
        .confirmationDialog("check in every", isPresented: $showingDeadManSwitchPicker, titleVisibility: .visible) {
            Button("5min") {
                settings.deadManSwitchInterval = 5
                settings.deadManSwitchEnabled = true
            }
            Button("10min") {
                settings.deadManSwitchInterval = 10
                settings.deadManSwitchEnabled = true
            }
            Button("30min") {
                settings.deadManSwitchInterval = 30
                settings.deadManSwitchEnabled = true
            }
            Button("custom") {
                customDeadManValue = String(Int(settings.deadManSwitchInterval))
                showingCustomDeadManInput = true
            }
            Button("cancel", role: .cancel) { }
        }
        .confirmationDialog("longer than", isPresented: $showingMotionThresholdPicker, titleVisibility: .visible) {
            Button("5min") {
                settings.motionThreshold = 5
                settings.motionDetectionEnabled = true
            }
            Button("10min") {
                settings.motionThreshold = 10
                settings.motionDetectionEnabled = true
            }
            Button("30min") {
                settings.motionThreshold = 30
                settings.motionDetectionEnabled = true
            }
            Button("custom") {
                customMotionValue = String(Int(settings.motionThreshold))
                showingCustomMotionInput = true
            }
            Button("cancel", role: .cancel) { }
        }
        .confirmationDialog("weekday starts", isPresented: $showingWeekStartsPicker, titleVisibility: .visible) {
            Button("monday") {
                settings.weekStartsOn = 2
            }
            Button("tuesday") {
                settings.weekStartsOn = 3
            }
            Button("wednesday") {
                settings.weekStartsOn = 4
            }
            Button("thursday") {
                settings.weekStartsOn = 5
            }
            Button("friday") {
                settings.weekStartsOn = 6
            }
            Button("saturday") {
                settings.weekStartsOn = 7
            }
            Button("sunday") {
                settings.weekStartsOn = 1
            }
            Button("cancel", role: .cancel) { }
        }
        .alert("salary", isPresented: $showingSalaryInput) {
            TextField("hourly rate", text: $salaryInputValue)
                .keyboardType(.numberPad)
            Button("cancel", role: .cancel) { }
            Button("save") {
                if let value = Double(salaryInputValue) {
                    settings.hourlyRate = value
                }
            }
        }
        .alert("check in every", isPresented: $showingCustomDeadManInput) {
            TextField("minutes", text: $customDeadManValue)
                .keyboardType(.numberPad)
            Button("cancel", role: .cancel) { }
            Button("save") {
                if let value = Double(customDeadManValue) {
                    settings.deadManSwitchInterval = value
                    settings.deadManSwitchEnabled = true
                }
            }
        }
        .alert("longer than", isPresented: $showingCustomMotionInput) {
            TextField("minutes", text: $customMotionValue)
                .keyboardType(.numberPad)
            Button("cancel", role: .cancel) { }
            Button("save") {
                if let value = Double(customMotionValue) {
                    settings.motionThreshold = value
                    settings.motionDetectionEnabled = true
                }
            }
        }
        .sheet(isPresented: $showingTodayDetail) {
            TodayDetailView()
        }
        .sheet(isPresented: $showingWeekDetail) {
            WeekDetailView()
        }
        .sheet(isPresented: $showingMonthDetail) {
            MonthDetailView()
        }
    }
}

struct SettingsSection: View {
    @ObservedObject var settings: AppSettings
    @Binding var showingDeadManSwitchPicker: Bool
    @Binding var showingMotionThresholdPicker: Bool
    @Binding var showingSalaryInput: Bool
    @Binding var showingCustomDeadManInput: Bool
    @Binding var showingCustomMotionInput: Bool
    @Binding var showingWeekStartsPicker: Bool
    @Binding var customDeadManValue: String
    @Binding var customMotionValue: String
    @Binding var salaryInputValue: String
    
    private var weekdayName: String {
        switch settings.weekStartsOn {
        case 1: return "sunday"
        case 2: return "monday"
        case 3: return "tuesday"
        case 4: return "wednesday"
        case 5: return "thursday"
        case 6: return "friday"
        case 7: return "saturday"
        default: return "monday"
        }
    }
    
    var body: some View {
                    VStack(spacing: 20) {
                        Divider()
                            .padding(.horizontal, 40)
                        
                        Text("settings")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        VStack(spacing: 20) {
                // Week starts on
                HStack {
                    Text("weekday starts")
                        .font(.custom("Major Mono Display Regular", size: 17))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        showingWeekStartsPicker = true
                    }) {
                        Text(weekdayName)
                            .font(.custom("Major Mono Display Regular", size: 17))
                            .foregroundColor(.primary)
                    }
                }
                
                            // Dead Man Switch
                            HStack {
                                Text("check in every")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    showingDeadManSwitchPicker = true
                                }) {
                                    Text("\(Int(settings.deadManSwitchInterval))min")
                                        .font(.custom("Major Mono Display Regular", size: 17))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Motion Detection
                            Button(action: {
                                settings.motionDetectionEnabled.toggle()
                            }) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("ask when i")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if settings.motionDetectionEnabled {
                                            Button(action: {
                                                settings.askWhenMoving.toggle()
                                            }) {
                                                Text(settings.askWhenMoving ? "move" : "don't move")
                                                    .font(.custom("Major Mono Display Regular", size: 17))
                                                    .foregroundColor(.primary)
                                            }
                                        } else {
                                            Text(settings.askWhenMoving ? "move" : "don't move")
                                                .font(.custom("Major Mono Display Regular", size: 17))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("longer than")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                        
                                        if settings.motionDetectionEnabled {
                                            Button(action: {
                                                showingMotionThresholdPicker = true
                                            }) {
                                                Text("\(Int(settings.motionThreshold))min")
                                                    .font(.custom("Major Mono Display Regular", size: 17))
                                                    .foregroundColor(.primary)
                                            }
                                        } else {
                                            Text("\(Int(settings.motionThreshold))min")
                                                .font(.custom("Major Mono Display Regular", size: 17))
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .opacity(settings.motionDetectionEnabled ? 1.0 : 0.3)
                            
                            // Salary Setting
                            HStack {
                                Text("salary")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Button(action: {
                                    salaryInputValue = String(format: "%.0f", settings.hourlyRate)
                                    showingSalaryInput = true
                                }) {
                                    HStack(spacing: 0) {
                                        Text(String(format: "%.0f", settings.hourlyRate))
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                        
                                Text("/€")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
}

#Preview {
    StatisticsOverviewView()
}