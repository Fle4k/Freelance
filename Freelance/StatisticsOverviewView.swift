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
    // Separate edit states for each period
    @State private var showingEditTodayPicker = false
    @State private var showingEditWeekPicker = false
    @State private var showingEditMonthPicker = false
    
    // Today edit state
    @State private var editingTodayHours = 0
    @State private var editingTodayMinutes = 0
    @State private var currentTodayTime = ""
    
    // Week edit state
    @State private var editingWeekHoursText = ""
    @State private var editingWeekMinutesText = ""
    @State private var currentWeekTime = ""
    
    // Month edit state
    @State private var editingMonthHoursText = ""
    @State private var editingMonthMinutesText = ""
    @State private var currentMonthTime = ""
    @State private var showingResetConfirmation = false
    @State private var resettingPeriod: StatisticsPeriod = .today
    @Environment(\.dismiss) private var dismiss
    
    private func requestNotificationPermissionAndEnable(interval: Double) {
        settings.requestNotificationPermission { granted in
            if granted {
                settings.deadManSwitchInterval = interval
                settings.deadManSwitchEnabled = true
                TimeTracker.shared.restartDeadManSwitch()
            }
        }
    }
    
    private func copyTime(for period: StatisticsPeriod) {
        TimeTracker.shared.copyTime(for: period)
    }
    
    private func editTime(for period: StatisticsPeriod) {
        print("🔧 editTime called for period: \(period)")
        
        // Hide all existing sheets first
        showingEditTodayPicker = false
        showingEditWeekPicker = false
        showingEditMonthPicker = false
        
        let currentTime = TimeTracker.shared.getTotalHours(for: period)
        let formattedTime = TimeTracker.shared.formattedTimeHMS(for: period)
        
        // Use DispatchQueue to ensure state is updated before showing sheet
        DispatchQueue.main.async {
            switch period {
            case .today:
                print("🔧 Showing today picker")
                let hours = Int(currentTime)
                let minutes = Int((currentTime - Double(hours)) * 60)
                self.editingTodayHours = hours
                self.editingTodayMinutes = minutes
                self.currentTodayTime = formattedTime
                self.showingEditTodayPicker = true
                
            case .thisWeek:
                print("🔧 Showing week picker")
                let hours = Int(currentTime)
                let minutes = Int((currentTime - Double(hours)) * 60)
                self.editingWeekHoursText = hours > 0 ? "\(hours)" : ""
                self.editingWeekMinutesText = minutes > 0 ? "\(minutes)" : ""
                self.currentWeekTime = formattedTime
                self.showingEditWeekPicker = true
                
            case .thisMonth:
                print("🔧 Showing month picker")
                let hours = Int(currentTime)
                let minutes = Int((currentTime - Double(hours)) * 60)
                self.editingMonthHoursText = hours > 0 ? "\(hours)" : ""
                self.editingMonthMinutesText = minutes > 0 ? "\(minutes)" : ""
                self.currentMonthTime = formattedTime
                self.showingEditMonthPicker = true
                
            default:
                break
            }
        }
    }
    
    private func resetTime(for period: StatisticsPeriod) {
        resettingPeriod = period
        showingResetConfirmation = true
    }
    
    private func confirmReset() {
        TimeTracker.shared.resetTime(for: resettingPeriod)
        showingResetConfirmation = false
    }
    
    private func saveEditedTodayTime() {
        let totalSeconds = TimeInterval(editingTodayHours * 3600 + editingTodayMinutes * 60)
        TimeTracker.shared.editTime(for: .today, newTime: totalSeconds)
        showingEditTodayPicker = false
    }
    
    private func saveEditedWeekTime() {
        let hours = Int(editingWeekHoursText) ?? 0
        let minutes = Int(editingWeekMinutesText) ?? 0
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        TimeTracker.shared.adjustTime(for: .thisWeek, newTime: totalSeconds)
        showingEditWeekPicker = false
    }
    
    private func saveEditedMonthTime() {
        let hours = Int(editingMonthHoursText) ?? 0
        let minutes = Int(editingMonthMinutesText) ?? 0
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        TimeTracker.shared.adjustTime(for: .thisMonth, newTime: totalSeconds)
        showingEditMonthPicker = false
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Overview Page
                VStack(spacing: 20) {
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
                        .frame(minHeight: 80) // Ensure minimum touch target
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .today)
                        }
                        Button("edit") {
                            editTime(for: .today)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .today)
                        }
                    }
                    
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
                        .frame(minHeight: 80) // Ensure minimum touch target
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .thisWeek)
                        }
                        Button("edit") {
                            editTime(for: .thisWeek)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .thisWeek)
                        }
                    }
                    
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
                        .frame(minHeight: 80) // Ensure minimum touch target
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .thisMonth)
                        }
                        Button("edit") {
                            editTime(for: .thisMonth)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .thisMonth)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Settings section - moved up
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
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .onDisappear {
            settings.saveSettings()
            TimeTracker.shared.restartDeadManSwitch()
        }
        .confirmationDialog("check in every", isPresented: $showingDeadManSwitchPicker, titleVisibility: .visible) {
            Button("none") {
                settings.deadManSwitchEnabled = false
                TimeTracker.shared.restartDeadManSwitch()
            }
            Button("5min") {
                requestNotificationPermissionAndEnable(interval: 5)
            }
            Button("10min") {
                requestNotificationPermissionAndEnable(interval: 10)
            }
            Button("30min") {
                requestNotificationPermissionAndEnable(interval: 30)
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
                    requestNotificationPermissionAndEnable(interval: value)
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
        .confirmationDialog("reset \(resettingPeriod.displayName)", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("reset", role: .destructive) {
                confirmReset()
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text("are you sure you want to reset \(resettingPeriod.displayName)? this will permanently delete all time data for this period.")
        }
        .sheet(isPresented: $showingEditTodayPicker) {
            NavigationView {
                VStack(spacing: 30) {
                    Text("edit today time")
                        .font(.custom("Major Mono Display Regular", size: 24))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Show current total time
                    VStack(spacing: 10) {
                        Text("current total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(currentTodayTime)
                            .font(.custom("Major Mono Display Regular", size: 20))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 10)
                    
                    // Wheel picker for today
                    VStack(spacing: 20) {
                        HStack {
                            Text("hours")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Picker("hours", selection: $editingTodayHours) {
                                ForEach(0..<24, id: \.self) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80)
                        }
                        
                        HStack {
                            Text("minutes")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Picker("minutes", selection: $editingTodayMinutes) {
                                ForEach(0..<60, id: \.self) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingEditTodayPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            saveEditedTodayTime()
                        }
                    }
                }
            }
        }
        // Week edit sheet
        .sheet(isPresented: $showingEditWeekPicker) {
            NavigationView {
                VStack(spacing: 30) {
                    Text("edit this week time")
                        .font(.custom("Major Mono Display Regular", size: 24))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Show current total time
                    VStack(spacing: 10) {
                        Text("current total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(currentWeekTime)
                            .font(.custom("Major Mono Display Regular", size: 20))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 10)
                    
                    // Text input for week
                    VStack(spacing: 0) {
                        HStack {
                            Text("hours")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SelectAllTextField(text: $editingWeekHoursText, shouldBecomeFirstResponder: true)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        
                        HStack {
                            Text("minutes")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SelectAllTextField(text: $editingWeekMinutesText)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingEditWeekPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            saveEditedWeekTime()
                        }
                    }
                }
            }
        }
        
        // Month edit sheet
        .sheet(isPresented: $showingEditMonthPicker) {
            NavigationView {
                VStack(spacing: 30) {
                    Text("edit this month time")
                        .font(.custom("Major Mono Display Regular", size: 24))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Show current total time
                    VStack(spacing: 10) {
                        Text("current total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(currentMonthTime)
                            .font(.custom("Major Mono Display Regular", size: 20))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 10)
                    
                    // Text input for month
                    VStack(spacing: 0) {
                        HStack {
                            Text("hours")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SelectAllTextField(text: $editingMonthHoursText, shouldBecomeFirstResponder: true)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        
                        HStack {
                            Text("minutes")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            SelectAllTextField(text: $editingMonthMinutesText)
                                .keyboardType(.numberPad)
                                .frame(width: 80)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("cancel") {
                            showingEditMonthPicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("save") {
                            saveEditedMonthTime()
                        }
                    }
                }
            }
        }
    }
}

struct SelectAllTextField: UIViewRepresentable {
    @Binding var text: String
    let shouldBecomeFirstResponder: Bool
    
    init(text: Binding<String>, shouldBecomeFirstResponder: Bool = false) {
        self._text = text
        self.shouldBecomeFirstResponder = shouldBecomeFirstResponder
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.textAlignment = .center
        textField.borderStyle = .none
        textField.backgroundColor = UIColor.clear
        
        // Apply custom font
        if let customFont = UIFont(name: "Major Mono Display Regular", size: 20) {
            textField.font = customFont
        }
        
        // Set text color to match SwiftUI primary color
        textField.textColor = UIColor.label
        
        // Set keyboard type to number pad
        textField.keyboardType = .numberPad
        
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        
        // Auto-focus if this is the hours field
        if shouldBecomeFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: SelectAllTextField

        init(_ parent: SelectAllTextField) {
            self.parent = parent
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Select all text when editing begins
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
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
    
    private func getNextNotificationTime() -> String {
        let calendar = Calendar.current
        let now = Date()
        let intervalMinutes = settings.deadManSwitchInterval
        
        // Calculate next clock-aligned time (same logic as in TimeTracker)
        let currentMinute = calendar.component(.minute, from: now)
        let minutesSinceLastBoundary = currentMinute % Int(intervalMinutes)
        
        var nextMinute: Int
        if minutesSinceLastBoundary == 0 {
            nextMinute = currentMinute + Int(intervalMinutes)
        } else {
            nextMinute = currentMinute - minutesSinceLastBoundary + Int(intervalMinutes)
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
            formatter.timeStyle = .short
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
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("check in every")
                                        .font(.custom("Major Mono Display Regular", size: 17))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
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
            .padding(.bottom, 10)
        }
    }
}

#Preview {
    StatisticsOverviewView()
}