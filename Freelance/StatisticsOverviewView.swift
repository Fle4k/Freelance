//
//  StatisticsOverviewView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI
import UIKit

struct FocusableTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let font: UIFont
    let shouldFocus: Bool
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = font
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        
        if shouldFocus && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                
                // If there's existing text, select it all for easy replacement
                if !text.isEmpty {
                    uiView.selectAll(nil)
                } else {
                    // Center the cursor by setting an empty selection
                    uiView.selectedTextRange = uiView.textRange(from: uiView.beginningOfDocument, to: uiView.beginningOfDocument)
                }
            }
        } else if !shouldFocus && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            parent.text = newText
            return true
        }
    }
}

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
    @State private var selectedDeadManInterval = 0
    @State private var selectedMotionThreshold = 5
    @State private var selectedWeekStarts = 2
    // Unified edit state
    @State private var showingEditSheet = false
    @State private var editingPeriod: StatisticsPeriod = .today
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
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        editingPeriod = period
        showingEditSheet = true
    }
    
    private func resetTime(for period: StatisticsPeriod) {
        resettingPeriod = period
        showingResetConfirmation = true
    }
    
    private func getCustomTitle(for period: StatisticsPeriod) -> String? {
        let formatter = DateFormatter()
        
        switch period {
        case .today:
            formatter.dateFormat = "EEEE"
            return "edit \(formatter.string(from: Date()).lowercased())"
        case .thisWeek:
            formatter.dateFormat = "MMMM"
            return "edit \(formatter.string(from: Date()).lowercased())"
        case .thisMonth:
            formatter.dateFormat = "MMMM"
            return "edit \(formatter.string(from: Date()).lowercased())"
        default:
            return "edit time"
        }
    }
    
    // MARK: - Card Views
    private var todayCard: some View {
                    Button(action: {
                        showingTodayDetail = true
                    }) {
                        VStack(spacing: 10) {
                            Text("today")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                ProportionalTimeDisplay(
                    timeString: timeTracker.formattedTimeHMS(for: .today),
                    digitFontSize: 20
                )
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .today)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
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
                    }
                    
    private var weekCard: some View {
                    Button(action: {
                        showingWeekDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this week")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                ProportionalTimeDisplay(
                    timeString: timeTracker.formattedTimeHMS(for: .thisWeek),
                    digitFontSize: 20
                )
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisWeek)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
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
                    }
                    
    private var monthCard: some View {
                    Button(action: {
                        showingMonthDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this month")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                ProportionalTimeDisplay(
                    timeString: timeTracker.formattedTimeHMS(for: .thisMonth),
                    digitFontSize: 20
                )
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisMonth)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
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
    
    // MARK: - View Modifiers
    private var mainView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Overview Page
                    VStack(spacing: 20) {
                    todayCard
                    
                    weekCard
                    
                    monthCard
                    }
                    .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Settings section
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
                            selectedWeekStarts = settings.weekStartsOn
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
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        }
    
    
    private func confirmReset() {
        TimeTracker.shared.resetTime(for: resettingPeriod)
        showingResetConfirmation = false
    }
    
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
        mainView
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
                                // Preload with current setting if it's a custom value (not 5, 10, or 30)
                                let currentInterval = Int(settings.deadManSwitchInterval)
                                if settings.deadManSwitchEnabled && ![5, 10, 30].contains(currentInterval) {
                                    customDeadManValue = String(currentInterval)
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
                .presentationDetents([.fraction(0.45)])
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
                            TextField("minutes", text: $customMotionValue)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.numberPad)
                                .padding(.horizontal, 40)
                        }
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
                                    if let value = Double(customMotionValue) {
                                        settings.motionThreshold = value
                                        settings.motionDetectionEnabled = true
                                    }
                                } else {
                                    settings.motionThreshold = Double(selectedMotionThreshold)
                                    settings.motionDetectionEnabled = true
                                }
                                showingMotionThresholdPicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.45)])
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
                .presentationDetents([.fraction(0.45)])
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
        .sheet(isPresented: $showingEditSheet) {
            EditTimeSheet(
                period: editingPeriod,
                currentTime: timeTracker.formattedTimeHMS(for: editingPeriod),
                isPresented: $showingEditSheet,
                customTitle: getCustomTitle(for: editingPeriod)
            )
        }
    }
}



#Preview {
    StatisticsOverviewView()
}