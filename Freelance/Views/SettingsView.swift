//
//  SettingsView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingMotionThresholdPicker = false
    @State private var showingSalaryInput = false
    @State private var showingWeekStartsPicker = false
    @State private var customMotionValue = ""
    @State private var salaryInputValue = ""
    @State private var selectedMotionThreshold = 5
    @State private var selectedWeekStarts = 2
    @FocusState private var isCustomMotionFocused: Bool
    
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
            .blur(radius: (showingMotionThresholdPicker || showingWeekStartsPicker || showingSalaryInput) ? 3 : 0)
            .animation(.easeInOut(duration: 0.2), value: showingMotionThresholdPicker || showingWeekStartsPicker || showingSalaryInput)
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
                        
                        if selectedMotionThreshold == -1 {
                            FocusableTextField(
                                text: $customMotionValue,
                                placeholder: "minutes",
                                font: UIFont(name: "Major Mono Display Regular", size: 18) ?? UIFont.systemFont(ofSize: 18),
                                shouldFocus: isCustomMotionFocused
                            )
                            .frame(height: 40)
                            .padding(.horizontal, 40)
                            .onAppear {
                                // Preload with current setting when custom field appears
                                customMotionValue = String(Int(settings.motionThreshold))
                                // Set focus immediately
                                isCustomMotionFocused = true
                            }
                        }
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            isCustomMotionFocused = false
                            showingMotionThresholdPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            if selectedMotionThreshold == -1 {
                                // Handle custom motion value
                                if let value = Double(customMotionValue) {
                                    settings.motionThreshold = value
                                    settings.motionDetectionEnabled = true
                                }
                            } else {
                                settings.motionThreshold = Double(selectedMotionThreshold)
                                settings.motionDetectionEnabled = true
                            }
                            isCustomMotionFocused = false
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
