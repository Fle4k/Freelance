//
//  ProjectDetailView.swift
//  Freelance
//
//  Created for individual project statistics
//

import SwiftUI

struct ProjectDetailView: View {
    let project: Project
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var selectedDay: Date?
    @State private var showingEditSheet = false
    @State private var showingDayEditSheet = false
    @State private var showingRemoveConfirmation = false
    @State private var expandedDay: Date?
    @State private var editingDay: Date?
    @State private var showEditAlert = false
    @State private var editTimeHours = 0
    @State private var editTimeMinutes = 0
    @State private var editEarnings = 0.0
    @State private var showConfirmation = false
    @State private var previousEntries: [Date: [TimeEntry]] = [:]
    
    // Filter time entries for this project
    private var projectTimeEntries: [TimeEntry] {
        project.timeEntries
    }
    
    private var monthEntries: [(Date, [TimeEntry])] {
        let calendar = Calendar.current
        
        guard !months.isEmpty && currentMonthIndex < months.count else { return [] }
        let currentMonth = months[currentMonthIndex]
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        var entries: [(Date, [TimeEntry])] = []
        
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            let dayEntries = projectTimeEntries.filter { entry in
                entry.startDate >= dayStart && entry.startDate < dayEnd
            }
            
            // Include current session if it's running for this project
            if let currentStart = project.currentSessionStart,
               project.isRunning,
               currentStart >= dayStart && currentStart < dayEnd {
                let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
                var allDayEntries = dayEntries
                allDayEntries.append(currentEntry)
                entries.append((currentDate, allDayEntries))
            } else if !dayEntries.isEmpty {
                entries.append((currentDate, dayEntries))
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return entries.sorted { $0.0 > $1.0 }
    }
    
    private func setupMonths() {
        let calendar = Calendar.current
        let now = Date()
        var monthsArray: [Date] = []
        
        for i in (1...3).reversed() {
            if let previousMonth = calendar.date(byAdding: .month, value: -i, to: now) {
                monthsArray.append(previousMonth)
            }
        }
        
        monthsArray.append(now)
        
        months = monthsArray
        currentMonthIndex = months.count - 1
        
        // Select today by default
        selectedDay = calendar.startOfDay(for: now)
    }
    
    private func getMonthTitle(for month: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: month).lowercased()
    }
    
    private func getMonthEarnings(for month: Date) -> Double {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return 0 }
        
        let monthEntries = projectTimeEntries.filter { entry in
            entry.startDate >= monthInterval.start && entry.startDate < monthInterval.end
        }
        
        let totalTime = monthEntries.reduce(0) { $0 + $1.duration }
        return totalTime / 3600 * AppSettings.shared.hourlyRate
    }
    
    private func getMonthTime(for month: Date) -> TimeInterval {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return 0 }
        
        let monthEntries = projectTimeEntries.filter { entry in
            entry.startDate >= monthInterval.start && entry.startDate < monthInterval.end
        }
        
        return monthEntries.reduce(0) { $0 + $1.duration }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let totalSeconds = Int(timeInterval)
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if days > 0 {
            return String(format: "%dd %02d:%02d:%02d", days, hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd.MM.yy"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatTimeRange(_ entry: TimeEntry) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = settings.use24HourFormat ? "HH:mm" : "h:mm a"
        
        let startTime = formatter.string(from: entry.startDate)
        let endTime: String
        
        if let endDate = entry.endDate {
            endTime = formatter.string(from: endDate)
        } else if entry.isActive {
            endTime = "now"
        } else {
            endTime = "---"
        }
        
        return "\(startTime) - \(endTime)".lowercased()
    }
    
    private func formatSessionDuration(_ entry: TimeEntry) -> String {
        let duration: TimeInterval
        if entry.isActive {
            duration = Date().timeIntervalSince(entry.startDate)
        } else {
            duration = entry.duration
        }
        
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
    
    private func calculateSessionEarnings(_ entry: TimeEntry) -> Double {
        let duration: TimeInterval
        if entry.isActive {
            duration = Date().timeIntervalSince(entry.startDate)
        } else {
            duration = entry.duration
        }
        return duration / 3600 * settings.hourlyRate
    }
    
    private func formatDayDuration(for date: Date) -> String {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        var dayEntries = projectTimeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
        if let currentStart = project.currentSessionStart,
           project.isRunning,
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
        
        return formatTime(totalDuration)
    }
    
    private func formatDayEarnings(for date: Date) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        var dayEntries = projectTimeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
        if let currentStart = project.currentSessionStart,
           project.isRunning,
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
        
        return totalDuration / 3600 * settings.hourlyRate
    }
    
    private func getFormattedMonth(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: date).lowercased()
    }
    
    private func getFormattedYear(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
    }
    
    private func isDayManuallyEdited(for date: Date) -> Bool {
        // For now, we'll use the same logic as TimeTracker
        // This could be enhanced to track manual edits per project
        return false
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Spacer(minLength: 0)
            // Top header with earnings and time (no project name, no extra spacing)
            if !months.isEmpty {
                VStack(spacing: 20) {
                    // Earnings
                    HStack {
                        Text("earnings")
                            .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                            .textCase(nil)
                            .foregroundColor(project.isRunning ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text(String(format: "%.0f\(settings.currency)", getMonthEarnings(for: months[currentMonthIndex])))
                            .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                            .textCase(nil)
                            .foregroundColor(project.isRunning ? .primary : .secondary)
                    }
                    
                    // Time
                    HStack {
                        Text("time")
                            .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                            .textCase(nil)
                            .foregroundColor(project.isRunning ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text(formatTime(getMonthTime(for: months[currentMonthIndex])))
                            .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                            .textCase(nil)
                            .foregroundColor(project.isRunning ? .primary : .secondary)
                    }
                }
                .padding(.horizontal, themeManager.spacing.contentHorizontal)
                .padding(.top, themeManager.spacing.large)
                .padding(.bottom, themeManager.spacing.xxLarge)
            }
            
            // Month and Year - centered and closer together
            if !months.isEmpty {
                HStack(spacing: 8) {
                    Text(getFormattedMonth(for: months[currentMonthIndex]))
                        .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                        .textCase(nil)
                        .foregroundColor(.primary)
                    
                    Text(getFormattedYear(for: months[currentMonthIndex]))
                        .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                        .textCase(nil)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, themeManager.spacing.small)
            }
            
            // Calendar - with peeking adjacent months
            if !months.isEmpty {
                TabView(selection: $currentMonthIndex) {
                    ForEach(0..<months.count, id: \.self) { index in
                        CalendarView(period: .thisMonth, monthDate: months[index], onDaySelected: { selectedDate in
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            selectedDay = selectedDate
                        }, timeEntries: projectTimeEntries)
                        .padding(.horizontal, themeManager.spacing.large)
                        .padding(.vertical, themeManager.spacing.medium)
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .scrollIndicators(.hidden)
                .frame(height: 290)
                .padding(.bottom, themeManager.spacing.tiny)
            }
            
            // Scrollable list of tracked days
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: themeManager.currentTheme == .liquidGlass ? themeManager.spacing.small : 0) {
                        ForEach(monthEntries, id: \.0) { dayEntry in
                            VStack(spacing: 0) {
                                // Main day row
                                HStack(spacing: 8) {
                                    let isTodayWithActiveTimer = Calendar.current.isDateInToday(dayEntry.0) && project.isRunning
                                    let textColor: Color = isTodayWithActiveTimer ? .white : .primary
                                    
                                    // Date column
                                    Text(formatDate(dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 14))
                                        .textCase(nil)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    
                                    Spacer()
                                    
                                    // Time column
                                    Text(formatDayDuration(for: dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 14))
                                        .textCase(nil)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(minWidth: 70, alignment: .trailing)
                                    
                                    // Earnings column
                                    Text(String(format: "%.0f\(settings.currency)", formatDayEarnings(for: dayEntry.0)))
                                        .font(.custom("Major Mono Display Regular", size: 14))
                                        .textCase(nil)
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                        .frame(minWidth: 50, alignment: .trailing)
                                }
                                .padding(.vertical, themeManager.currentTheme == .liquidGlass ? themeManager.spacing.itemSpacing : 8)
                                .padding(.horizontal, 16)
                                .modifier(
                                    GlassListRowModifier(
                                        isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                                        isHighlighted: Calendar.current.isDate(dayEntry.0, inSameDayAs: selectedDay ?? Date.distantPast) ||
                                                     (Calendar.current.isDateInToday(dayEntry.0) && project.isRunning)
                                    )
                                )
                                .contentShape(Rectangle())
                                .simultaneousGesture(
                                    TapGesture()
                                        .onEnded {
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                if expandedDay == dayEntry.0 {
                                                    expandedDay = nil
                                                } else {
                                                    expandedDay = dayEntry.0
                                                }
                                            }
                                        }
                                )
                                
                                // Expanded session details
                                if expandedDay == dayEntry.0 {
                                    VStack(spacing: themeManager.currentTheme == .liquidGlass ? 4 : 2) {
                                        if isDayManuallyEdited(for: dayEntry.0) {
                                            Text("data changed by user")
                                                .font(.custom("Major Mono Display Regular", size: 14))
                                                .textCase(nil)
                                                .foregroundColor(.secondary)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 16)
                                        } else {
                                            // Show individual time entries
                                            ForEach(dayEntry.1) { entry in
                                                HStack(spacing: 8) {
                                                    // Time range column
                                                    Text(formatTimeRange(entry))
                                                        .font(.custom("Major Mono Display Regular", size: 14))
                                                        .textCase(nil)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.8)
                                                    
                                                    Spacer()
                                                    
                                                    // Session duration
                                                    Text(formatSessionDuration(entry))
                                                        .font(.custom("Major Mono Display Regular", size: 14))
                                                        .textCase(nil)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.8)
                                                    
                                                    // Session earnings
                                                    Text(String(format: "%.0f\(settings.currency)", calculateSessionEarnings(entry)))
                                                        .font(.custom("Major Mono Display Regular", size: 14))
                                                        .textCase(nil)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                        .minimumScaleFactor(0.8)
                                                        .frame(minWidth: 50, alignment: .trailing)
                                                }
                                                .padding(.vertical, 4)
                                                .padding(.horizontal, 16)
                                            }
                                        }
                                    }
                                    .padding(.top, 4)
                                    .padding(.bottom, 4)
                                    .transition(.opacity.combined(with: .move(edge: .top)))
                                }
                            }
                            .id(dayEntry.0)
                        }
                        .padding(.horizontal, 16)
                        
                        if monthEntries.isEmpty {
                            Text("no time tracked this month")
                                .font(.custom("Major Mono Display Regular", size: 12))
                                .textCase(nil)
                                .foregroundColor(.secondary)
                                .padding(.top, themeManager.spacing.large)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .onChange(of: selectedDay) { _, newDay in
                    if let day = newDay {
                        withAnimation {
                            proxy.scrollTo(day, anchor: .top)
                        }
                    }
                }
            }
            
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .padding(.horizontal, themeManager.spacing.small)
        .padding(.vertical, themeManager.spacing.small)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 40))
        .onAppear {
            setupMonths()
        }
    }
}
