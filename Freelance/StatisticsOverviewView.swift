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

enum DetailViewType {
    case today, thisWeek, thisMonth
}

struct StatisticsOverviewView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var selectedDetailView: DetailViewType?
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
                    
                if selectedDetailView == nil {
                    // Overview Page
                    VStack(spacing: 30) {
                        // Today Card
                        Button(action: {
                            selectedDetailView = .today
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
                            selectedDetailView = .thisWeek
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
                            selectedDetailView = .thisMonth
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
                } else {
                    // Detail View
                    VStack(spacing: 0) {
                        HStack {
                            Button("back") {
                                selectedDetailView = nil
                            }
                            .font(.custom("Major Mono Display Regular", size: 17))
                            .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                        
                        // Match the spacing from overview to align headers
                        VStack(spacing: 30) {
                            switch selectedDetailView {
                            case .today:
                                TodayDetailView()
                            case .thisWeek:
                                WeekDetailView()
                            case .thisMonth:
                                MonthDetailView()
                            case .none:
                                EmptyView()
                            }
                        }
                        .padding(.vertical, 20) // Same padding as overview cards
                        
                        Spacer()
                    }
                }
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

// Detail Views
struct TodayDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    
    var todayEntries: [TimeEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        var entries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= today && entry.startDate < tomorrow && entry.endDate != nil
        }
        
        // Include current session if it started today
        if let currentStart = timeTracker.currentSessionStart,
           currentStart >= today && currentStart < tomorrow {
            let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
            entries.append(currentEntry)
        }
        
        return entries.sorted { $0.startDate > $1.startDate }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        return formatDuration(from: duration)
    }
    
    private func formatDuration(from duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm%02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header matching overview style
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
            
            // Time entries with smaller font
            VStack(spacing: 15) {
                ForEach(todayEntries) { entry in
                    HStack {
                        if let endDate = entry.endDate {
                            Text("\(timeFormatter.string(from: entry.startDate))-\(timeFormatter.string(from: endDate))")
                                .font(.custom("Major Mono Display Regular", size: 15))
                                .foregroundColor(.primary)
                        } else {
                            ActiveTimerView(startDate: entry.startDate, timeFormatter: timeFormatter)
                        }
                        
                        Spacer()
                        
                        if entry.isActive {
                            Text(formatDuration(from: entry.startDate, to: Date()))
                                .font(.custom("Major Mono Display Regular", size: 15))
                                .foregroundColor(.primary)
                        } else {
                            Text(formatDuration(from: entry.duration))
                                .font(.custom("Major Mono Display Regular", size: 15))
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                if todayEntries.isEmpty {
                    HStack {
                        Spacer()
                        
                        Text("-")
                            .font(.custom("Major Mono Display Regular", size: 15))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(.horizontal, 40)
    }
}

struct ActiveTimerView: View {
    let startDate: Date
    let timeFormatter: DateFormatter
    @State private var currentTime = Date()
    
    var body: some View {
        Text("\(timeFormatter.string(from: startDate))-\(timeFormatter.string(from: currentTime))")
            .font(.custom("Major Mono Display Regular", size: 15))
            .foregroundColor(.primary)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                currentTime = Date()
            }
    }
}

struct WeekDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    
    private var weekEntries: [(Date, [TimeEntry])] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get start of week based on user setting
        var startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        if settings.weekStartsOn != calendar.firstWeekday {
            let difference = settings.weekStartsOn - calendar.firstWeekday
            startOfWeek = calendar.date(byAdding: .day, value: difference, to: startOfWeek) ?? startOfWeek
        }
        
        var entries: [(Date, [TimeEntry])] = []
        
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let dayStart = calendar.startOfDay(for: dayDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayDate
                
                let dayEntries = timeTracker.timeEntries.filter { entry in
                    entry.startDate >= dayStart && entry.startDate < dayEnd
                }
                
                if !dayEntries.isEmpty {
                    entries.append((dayDate, dayEntries))
                }
            }
        }
        
        // Sort by newest day first
        return entries.sorted { $0.0 > $1.0 }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        return formatDuration(from: duration)
    }
    
    private func formatDuration(from duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm%02ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var body: some View {
        VStack(spacing: 30) {
            // Header matching overview style
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
            
            // Week entries with smaller font
            VStack(spacing: 15) {
                ForEach(weekEntries, id: \.0) { dayEntry in
                    HStack {
                        Text(formatDate(dayEntry.0))
                            .font(.custom("Major Mono Display Regular", size: 15))
                            .foregroundColor(.primary)
        
        Spacer()
                        
                        Text(formatDayDuration(for: dayEntry.0))
                            .font(.custom("Major Mono Display Regular", size: 15))
                                .foregroundColor(.primary)
                    }
                }
                        
                if weekEntries.isEmpty {
                    Text("no time tracked this week")
                        .font(.custom("Major Mono Display Regular", size: 15))
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 40)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTimeRange(_ start: Date, _ end: Date?) -> String {
        let startTime = timeFormatter.string(from: start)
        if let end = end {
            let endTime = timeFormatter.string(from: end)
            return "\(startTime)-\(endTime)"
        }
        return startTime
    }
    
    private func formatDayDuration(for date: Date) -> String {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        var dayEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
        // Include current session if it started on this day
        if let currentStart = timeTracker.currentSessionStart,
           currentStart >= dayStart && currentStart < dayEnd {
            let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
            dayEntries.append(currentEntry)
        }
        
        let totalDuration = dayEntries.reduce(0) { total, entry in
            if entry.isActive {
                return total + Date().timeIntervalSince(entry.startDate)
            } else {
                return total + entry.duration
            }
        }
        
        return formatDuration(from: totalDuration)
    }
}

struct MonthDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    
    var body: some View {
        VStack(spacing: 30) {
            // Header matching overview style
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
            
            // Calendar only
            CalendarView(period: .thisMonth)
                .frame(height: 300)
        }
        .padding(.horizontal, 40)
    }
}


struct CalendarView: View {
    let period: StatisticsPeriod
    @ObservedObject private var timeTracker = TimeTracker.shared
    
    var body: some View {
        VStack(spacing: 13) {
            // Days of week header
            HStack {
                ForEach(["su", "mo", "tu", "we", "th", "fr", "sa"], id: \.self) { day in
                    Text(day)
                        .font(.custom("Major Mono Display Regular", size: 15))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 9) {
                ForEach(getCalendarDays(), id: \.self) { day in
                    CalendarDayView(
                        day: day,
                        hasTimeEntry: hasTimeEntry(for: day),
                        isToday: isToday(day)
                    )
                }
            }
            .padding(.bottom, 10)
        }
    }
    
    private func getCalendarDays() -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return Array(1...31)
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 31
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        var days: [Int] = []
        
        // Add empty days for proper alignment
        for _ in 1..<firstWeekday {
            days.append(0) // 0 represents empty day
        }
        
        // Add actual days
        for day in 1...daysInMonth {
            days.append(day)
        }
        
        return days
    }
    
    private func hasTimeEntry(for day: Int) -> Bool {
        guard day > 0 else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
              let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else {
            return false
        }
        
        let dayStart = calendar.startOfDay(for: dayDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayDate
        
        return timeTracker.timeEntries.contains { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
    }
    
    private func isToday(_ day: Int) -> Bool {
        guard day > 0 else { return false }
        let today = Calendar.current.component(.day, from: Date())
        return day == today
    }
}

struct CalendarDayView: View {
    let day: Int
    let hasTimeEntry: Bool
    let isToday: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if day > 0 {
                    Text("\(day)")
                        .font(.custom("Major Mono Display Regular", size: 18))
                    .foregroundColor(textColor)
                        .frame(width: 35, height: 35)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            } else {
                // Empty day
                Text("")
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return colorScheme == .dark ? .white : .black
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isToday {
            return colorScheme == .dark ? .black : .white
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return colorScheme == .dark ? .white : .black
        } else if hasTimeEntry {
            return .secondary
        } else {
            return .clear
        }
    }
}

#Preview {
    StatisticsOverviewView()
}