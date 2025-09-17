//
//  SettingsView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeadManSwitchPicker = false
    @State private var showingMotionThresholdPicker = false
    @State private var showingSalaryInput = false
    @State private var showingWeekStartsPicker = false
    @State private var customDeadManValue = ""
    @State private var customMotionValue = ""
    @State private var salaryInputValue = ""
    @State private var selectedDeadManInterval = 0
    @State private var selectedMotionThreshold = 5
    @State private var selectedWeekStarts = 2
    @FocusState private var isCustomDeadManFocused: Bool
    
    private func requestNotificationPermissionAndEnable(interval: Double) {
        settings.requestNotificationPermission { granted in
            if granted {
                DispatchQueue.main.async {
                    settings.deadManSwitchInterval = interval
                    settings.deadManSwitchEnabled = true
                    settings.saveSettings()
                    TimeTracker.shared.restartDeadManSwitch()
                }
            }
        }
    }
    
    private func getNextNotificationTime() -> String {
        // Calculate next clock-aligned time (same logic as in TimeTracker)
        let calendar = Calendar.current
        let now = Date()
        let currentMinute = calendar.component(.minute, from: now)
        let currentSecond = calendar.component(.second, from: now)
        let intervalMinutes = Int(settings.deadManSwitchInterval)
        
        let minutesSinceLastBoundary = currentMinute % intervalMinutes
        var nextMinute: Int
        
        if minutesSinceLastBoundary == 0 && currentSecond == 0 {
            nextMinute = currentMinute + intervalMinutes
        } else {
            nextMinute = currentMinute - minutesSinceLastBoundary + intervalMinutes
        }
        
        var nextHour = calendar.component(.hour, from: now)
        if nextMinute >= 60 {
            nextHour += nextMinute / 60
            nextMinute = nextMinute % 60
        }
        
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = nextHour
        dateComponents.minute = nextMinute
        dateComponents.second = 0
        
        if let nextTime = calendar.date(from: dateComponents) {
            let formatter = DateFormatter()
            formatter.dateFormat = settings.timeFormat()
            return formatter.string(from: nextTime)
        }
        
        return "unknown"
    }
    
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
        NavigationView {
            VStack(spacing: 40) {
                    // Salary Setting (first)
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
                    
                    // Dead Man Switch
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("check in every")
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                selectedDeadManInterval = settings.deadManSwitchEnabled ? Int(settings.deadManSwitchInterval) : 0
                                showingDeadManSwitchPicker = true
                            }) {
                                Text(settings.deadManSwitchEnabled ? "\(Int(settings.deadManSwitchInterval))min" : "none")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if settings.deadManSwitchEnabled && TimeTracker.shared.isRunning {
                            Text("next: \(getNextNotificationTime())")
                                .font(.custom("Major Mono Display Regular", size: 12))
                                .foregroundColor(.secondary)
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
                                        selectedMotionThreshold = Int(settings.motionThreshold)
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
                    
                    // Time format
                    HStack {
                        Text("time format")
                            .font(.custom("Major Mono Display Regular", size: 17))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            settings.use24HourFormat.toggle()
                        }) {
                            Text(settings.use24HourFormat ? "24h" : "am/pm")
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Week starts on
                    HStack {
                        Text("weekday starts")
                            .font(.custom("Major Mono Display Regular", size: 17))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            selectedWeekStarts = settings.weekStartsOn
                            showingWeekStartsPicker = true
                        }) {
                            Text(weekdayName)
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.primary)
                        }
                    }
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .background(Color(.systemBackground))
            .blur(radius: (showingDeadManSwitchPicker || showingMotionThresholdPicker || showingWeekStartsPicker || showingSalaryInput) ? 3 : 0)
            .animation(.easeInOut(duration: 0.2), value: showingDeadManSwitchPicker || showingMotionThresholdPicker || showingWeekStartsPicker || showingSalaryInput)
            .navigationTitle("settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            settings.saveSettings()
            TimeTracker.shared.restartDeadManSwitch()
        }
        .sheet(isPresented: $showingDeadManSwitchPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("check in every")
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Picker("interval", selection: $selectedDeadManInterval) {
                            Text("none").tag(0)
                            Text("5min").tag(5)
                            Text("10min").tag(10)
                            Text("30min").tag(30)
                            Text("custom").tag(-1)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 200)
                        .onChange(of: selectedDeadManInterval) { oldValue, newValue in
                            if newValue == -1 {
                                // Always preload with current setting when custom is selected
                                if settings.deadManSwitchEnabled {
                                    customDeadManValue = String(Int(settings.deadManSwitchInterval))
                                } else {
                                    customDeadManValue = ""
                                }
                            }
                        }
                        
                        if selectedDeadManInterval == -1 {
                            FocusableTextField(
                                text: $customDeadManValue,
                                placeholder: "minutes",
                                font: UIFont(name: "Major Mono Display Regular", size: 18) ?? UIFont.systemFont(ofSize: 18),
                                shouldFocus: true
                            )
                            .frame(height: 40)
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingDeadManSwitchPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            if selectedDeadManInterval == 0 {
                                settings.deadManSwitchEnabled = false
                                TimeTracker.shared.restartDeadManSwitch()
                            } else if selectedDeadManInterval == -1 {
                                if let value = Double(customDeadManValue) {
                                    requestNotificationPermissionAndEnable(interval: value)
                                }
                            } else {
                                requestNotificationPermissionAndEnable(interval: Double(selectedDeadManInterval))
                            }
                            showingDeadManSwitchPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingMotionThresholdPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("longer than")
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Picker("Threshold", selection: $selectedMotionThreshold) {
                            Text("5min").tag(5)
                            Text("10min").tag(10)
                            Text("30min").tag(30)
                            Text("custom").tag(-1)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 200)
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingMotionThresholdPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            if selectedMotionThreshold == -1 {
                                // Handle custom motion value
                            } else {
                                settings.motionThreshold = Double(selectedMotionThreshold)
                                settings.motionDetectionEnabled = true
                            }
                            showingMotionThresholdPicker = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingWeekStartsPicker) {
            NavigationView {
                VStack(spacing: 20) {
                    Text("weekday starts")
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.secondary)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Picker("Weekday", selection: $selectedWeekStarts) {
                            Text("monday").tag(2)
                            Text("tuesday").tag(3)
                            Text("wednesday").tag(4)
                            Text("thursday").tag(5)
                            Text("friday").tag(6)
                            Text("saturday").tag(7)
                            Text("sunday").tag(1)
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 200)
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingWeekStartsPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            settings.weekStartsOn = selectedWeekStarts
                            showingWeekStartsPicker = false
                        }
                    }
                }
            }
        }
        .alert("salary", isPresented: $showingSalaryInput) {
            TextField("Hourly rate", text: $salaryInputValue)
                .keyboardType(.numberPad)
            Button("Cancel", role: .cancel) { }
            Button("Save") {
                if let value = Double(salaryInputValue) {
                    settings.hourlyRate = value
                }
            }
        }
    }
}
