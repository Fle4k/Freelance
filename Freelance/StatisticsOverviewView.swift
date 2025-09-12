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
    @State private var showingDailyStats = false
    @State private var selectedPeriod: StatisticsPeriod = .today
    @State private var currentIndex: Int = 0
    @State private var showingDeadManSwitchPicker = false
    @State private var showingMotionThresholdPicker = false
    @State private var showingSalaryInput = false
    @State private var showingCustomDeadManInput = false
    @State private var showingCustomMotionInput = false
    @State private var customDeadManValue = ""
    @State private var customMotionValue = ""
    @State private var salaryInputValue = ""
    @Environment(\.dismiss) private var dismiss
    
    private let periods: [StatisticsPeriod] = [.today, .thisWeek, .thisMonth]
    
    init() {
        // Load persisted selected period
        if let savedPeriodRaw = UserDefaults.standard.object(forKey: "selectedPeriod") as? String {
            switch savedPeriodRaw {
            case "today": 
                _selectedPeriod = State(initialValue: .today)
                _currentIndex = State(initialValue: 0)
            case "thisWeek": 
                _selectedPeriod = State(initialValue: .thisWeek)
                _currentIndex = State(initialValue: 1)
            case "thisMonth": 
                _selectedPeriod = State(initialValue: .thisMonth)
                _currentIndex = State(initialValue: 2)
            default: 
                _selectedPeriod = State(initialValue: .today)
                _currentIndex = State(initialValue: 0)
            }
        } else {
            _selectedPeriod = State(initialValue: .today)
            _currentIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 30)
                    
                    // Swipable carousel with cards
                    TabView(selection: $currentIndex) {
                        // Card 0: Today
                        VStack(spacing: 20) {
                            Text("today")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 10) {
                                Text(timeTracker.formattedTimeHMS(for: .today))
                                    .font(.custom("Major Mono Display Regular", size: 24))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: "%.0fe", timeTracker.getEarnings(for: .today)))
                                    .font(.custom("Major Mono Display Regular", size: 20))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer(minLength: 25)
                            
                            ChartView(period: .today)
                                .frame(height: 120)
                        }
                        .padding(.horizontal, 40)
                        .tag(0)
                        
                        // Card 1: This Week
                        VStack(spacing: 20) {
                            Text("this week")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 10) {
                                Text(timeTracker.formattedTimeHMS(for: .thisWeek))
                                    .font(.custom("Major Mono Display Regular", size: 24))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: "%.0fe", timeTracker.getEarnings(for: .thisWeek)))
                                    .font(.custom("Major Mono Display Regular", size: 20))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer(minLength: 25)
                            
                            ChartView(period: .thisWeek)
                                .frame(height: 120)
                        }
                        .padding(.horizontal, 40)
                        .tag(1)
                        
                        // Card 2: This Month
                        VStack(spacing: 20) {
                            Text("this month")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 10) {
                                Text(timeTracker.formattedTimeHMS(for: .thisMonth))
                                    .font(.custom("Major Mono Display Regular", size: 24))
                                    .foregroundColor(.primary)
                                
                                Text(String(format: "%.0fe", timeTracker.getEarnings(for: .thisMonth)))
                                    .font(.custom("Major Mono Display Regular", size: 20))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer(minLength: 25)
                            
                            CalendarView(period: .thisMonth)
                                .frame(height: 150)
                        }
                        .padding(.horizontal, 40)
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 350)
                    .onChange(of: currentIndex) {
                        // Update selectedPeriod based on card index
                        switch currentIndex {
                        case 0: selectedPeriod = .today
                        case 1: selectedPeriod = .thisWeek
                        case 2: selectedPeriod = .thisMonth
                        default: selectedPeriod = .today
                        }
                        saveSelectedPeriod()
                    }
                    
                    Spacer(minLength: 80)
                    
                    // Settings at the bottom
                    VStack(spacing: 20) {
                        Divider()
                            .padding(.horizontal, 40)
                        
                        Text("settings")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        VStack(spacing: 20) {
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
                                        
                                        Text("/e")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 40)
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
    
    private func saveSelectedPeriod() {
        let periodString: String
        switch selectedPeriod {
        case .today: periodString = "today"
        case .thisWeek: periodString = "thisWeek"
        case .thisMonth: periodString = "thisMonth"
        default: periodString = "today"
        }
        UserDefaults.standard.set(periodString, forKey: "selectedPeriod")
    }
}

struct ChartView: View {
    let period: StatisticsPeriod
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart title at top
            Text("chart for \(period.displayName)")
                .font(.custom("Major Mono Display Regular", size: 17))
                .foregroundColor(.primary)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Spacer()
            
            // Chart bars with day labels for week views
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<7) { index in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.primary.opacity(0.3))
                                .frame(width: 2, height: getBarHeight(for: index))
                            
                            if period == .thisWeek || period == .lastWeek {
                                Text(getDayLabel(for: index))
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                            }
                        }
                        
                        if index < 6 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
    
    private func getBarHeight(for index: Int) -> CGFloat {
        // Static heights for consistent display (no animation)
        let heights: [CGFloat] = [45, 25, 60, 30, 40, 55, 20]
        return heights[index]
    }
    
    private func getDayLabel(for index: Int) -> String {
        let labels = ["m", "d", "m", "d", "f", "s", "s"]
        return labels[index]
    }
}

struct StatisticRowWithEarnings: View {
    let title: String
    let time: String
    let earnings: Double
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Major Mono Display Regular", size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text("\(time)/\(String(format: "%.0f", earnings))e")
                .font(.custom("Major Mono Display Regular", size: 17))
                .foregroundColor(.primary)
        }
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
    
    var body: some View {
        VStack {
            if day > 0 {
                VStack(spacing: 2) {
                    Text("\(day)")
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.primary)
                        .frame(width: 35, height: 35)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(backgroundColor)
                        )
                    
                    // Underline for today
                    Rectangle()
                        .fill(.primary)
                        .frame(width: 20, height: isToday ? 1 : 0)
                        .opacity(isToday ? 1 : 0)
                }
            } else {
                // Empty day
                Text("")
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    private var backgroundColor: Color {
        if hasTimeEntry {
            return Color.gray.opacity(0.2) // Light grey for days with time entries
        } else {
            return Color.clear // Clear background as requested
        }
    }
    
}

#Preview {
    StatisticsOverviewView()
}
