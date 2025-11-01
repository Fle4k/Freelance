//
//  UnifiedMonthView.swift
//  Freelance
//
//  Created by Shahin on 24.10.25.
//

import SwiftUI

struct UnifiedMonthView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var selectedDay: Date?
    @State private var showingEditSheet = false
    @State private var showingDayEditSheet = false
    @State private var showingRemoveConfirmation = false
    @State private var showingSettings = false
    @State private var expandedDay: Date?
    @State private var editingDay: Date?
    @State private var showEditAlert = false
    @State private var editTimeHours = 0
    @State private var editTimeMinutes = 0
    @State private var editEarnings = 0.0
    @State private var showConfirmation = false
    @State private var previousEntries: [Date: [TimeEntry]] = [:]
    
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
            
            let dayEntries = timeTracker.timeEntries.filter { entry in
                entry.startDate >= dayStart && entry.startDate < dayEnd
            }
            
            if let currentStart = timeTracker.currentSessionStart,
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
        
        let monthEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= monthInterval.start && entry.startDate < monthInterval.end
        }
        
        let totalTime = monthEntries.reduce(0) { $0 + $1.duration }
        return totalTime / 3600 * AppSettings.shared.hourlyRate
    }
    
    private func getMonthTime(for month: Date) -> TimeInterval {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return 0 }
        
        let monthEntries = timeTracker.timeEntries.filter { entry in
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
        
        var dayEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
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
        
        return formatTime(totalDuration)
    }
    
    private func getTodayEntry() -> Date? {
        let calendar = Calendar.current
        
        // Check if there's an entry for today in the current month
        return monthEntries.first { calendar.isDateInToday($0.0) }?.0
    }
    
    private func getSelectedDayInfo() -> (title: String, time: String, earnings: String)? {
        guard let day = selectedDay else { return nil }
        
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMMM yyyy"
        let title = formatter.string(from: day).lowercased()
        
        let dayStart = calendar.startOfDay(for: day)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? day
        
        var dayEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
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
        
        let time = formatTime(totalDuration)
        let earnings = String(format: "%.0f€", totalDuration / 3600 * settings.hourlyRate)
        
        return (title, time, earnings)
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
    
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                VStack(spacing: 10) {
                    // Top header with earnings and time - each in separate pill
                    if !months.isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            // Earnings

                            HStack {
                                Text("earnings")
                                    .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 :
                                                    24))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f€", getMonthEarnings(for: months[currentMonthIndex])))
                                    .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                                    .foregroundColor(.primary)
                            }

                            // Time
                            HStack {
                                Text("time")
                                    .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(formatTime(getMonthTime(for: months[currentMonthIndex])))
                                    .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, themeManager.spacing.contentHorizontal)
                        .padding(.top, themeManager.spacing.contentHorizontal)
                        .padding(.bottom, themeManager.spacing.xxLarge)
                    }
                    Spacer()
                    
                    // Month and Year - centered and closer together
                    if !months.isEmpty {
                        HStack(spacing: 8) {
                            Text(getFormattedMonth(for: months[currentMonthIndex]))
                                .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                                .foregroundColor(.primary)
                            
                            Text(getFormattedYear(for: months[currentMonthIndex]))
                                .font(.custom("Major Mono Display Regular", size: themeManager.currentTheme == .liquidGlass ? 20 : 24))
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, themeManager.spacing.small)
                    }
                    
                    // Calendar - with peeking adjacent months
                    if !months.isEmpty {
                        TabView(selection: $currentMonthIndex) {
                            ForEach(0..<months.count, id: \.self) { index in
                                CalendarView(period: .thisMonth, monthDate: months[index]) { selectedDate in
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    selectedDay = selectedDate
                                }
                                .padding(.horizontal, themeManager.spacing.large)
                                .padding(.vertical, themeManager.spacing.medium)
                                .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 290)
                        .padding(.bottom, themeManager.spacing.tiny)
                    }
                    
                    // Scrollable list of tracked days - now with responsive layout
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: themeManager.currentTheme == .liquidGlass ? themeManager.spacing.small : 0) {
                            ForEach(monthEntries, id: \.0) { dayEntry in
                                VStack(spacing: 0) {
                                    // Main day row
                                    HStack(spacing: 8) {
                                        // Date column - flexible
                                        Text(formatDate(dayEntry.0))
                                            .font(.custom("Major Mono Display Regular", size: 14))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                        
                                        Spacer()
                                        
                                        // Time column - fixed minimum width
                                        Text(formatDayDuration(for: dayEntry.0))
                                            .font(.custom("Major Mono Display Regular", size: 14))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(minWidth: 70, alignment: .trailing)
                                        
                                        // Earnings column - fixed minimum width
                                        Text(String(format: "%.0f€", formatDayEarnings(for: dayEntry.0)))
                                            .font(.custom("Major Mono Display Regular", size: 14))
                                            .foregroundColor(.primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)
                                            .frame(minWidth: 50, alignment: .trailing)
                                    }
                                    .padding(.vertical, themeManager.currentTheme == .liquidGlass ? themeManager.spacing.itemSpacing : 8)
                                    .padding(.horizontal, 16)
                                    .modifier(
                                        GlassListRowModifier(
                                            isLiquidGlass: themeManager.currentTheme == .liquidGlass
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
                                    .simultaneousGesture(
                                        LongPressGesture(minimumDuration: 0.5)
                                            .onEnded { _ in
                                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                                impactFeedback.impactOccurred()
                                                openEditAlert(for: dayEntry.0)
                                            }
                                    )
                                    
                                    // Expanded session details
                                    if expandedDay == dayEntry.0 {
                                        VStack(spacing: themeManager.currentTheme == .liquidGlass ? 4 : 2) {
                                            if timeTracker.isDayManuallyEdited(for: dayEntry.0) {
                                                // Show "data changed by user" centered
                                                Text("data changed by user")
                                                    .font(.custom("Major Mono Display Regular", size: 14))
                                                    .foregroundColor(.secondary)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding(.vertical, 4)
                                                    .padding(.horizontal, 16)
                                                
                                                // Show previous entries with strikethrough if available
                                                if let prevEntries = previousEntries[dayEntry.0] {
                                                    ForEach(prevEntries) { entry in
                                                        HStack(spacing: 8) {
                                                            // Time range column
                                                            Text(formatTimeRange(entry))
                                                                .font(.custom("Major Mono Display Regular", size: 14))
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .minimumScaleFactor(0.8)
                                                                .strikethrough()
                                                            
                                                            Spacer()
                                                            
                                                            // Session duration
                                                            Text(formatSessionDuration(entry))
                                                                .font(.custom("Major Mono Display Regular", size: 14))
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .minimumScaleFactor(0.8)
                                                                .strikethrough()
                                                            
                                                            // Session earnings
                                                            Text(String(format: "%.0f€", calculateSessionEarnings(entry)))
                                                                .font(.custom("Major Mono Display Regular", size: 14))
                                                                .foregroundColor(.secondary)
                                                                .lineLimit(1)
                                                                .minimumScaleFactor(0.8)
                                                                .frame(minWidth: 50, alignment: .trailing)
                                                                .strikethrough()
                                                        }
                                                        .padding(.vertical, 4)
                                                        .padding(.horizontal, 16)
                                                    }
                                                }
                                            } else {
                                                // Show individual time entries for normal tracked days
                                                ForEach(dayEntry.1) { entry in
                                                    HStack(spacing: 8) {
                                                        // Time range column
                                                        Text(formatTimeRange(entry))
                                                            .font(.custom("Major Mono Display Regular", size: 14))
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.8)
                                                        
                                                        Spacer()
                                                        
                                                        // Session duration
                                                        Text(formatSessionDuration(entry))
                                                            .font(.custom("Major Mono Display Regular", size: 14))
                                                            .foregroundColor(.secondary)
                                                            .lineLimit(1)
                                                            .minimumScaleFactor(0.8)
                                                        
                                                        // Session earnings
                                                        Text(String(format: "%.0f€", calculateSessionEarnings(entry)))
                                                            .font(.custom("Major Mono Display Regular", size: 14))
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
                            }
                            .padding(.horizontal, 16)
                            
                            if monthEntries.isEmpty {
                                Text("no time tracked this month")
                                    .font(.custom("Major Mono Display Regular", size: 12))
                                    .foregroundColor(.secondary)
                                    .padding(.top, themeManager.spacing.large)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
                .themedBackground()
                .blur(radius: (showingSettings || showingDayEditSheet || showEditAlert) ? 3 : 0)
                .animation(.easeInOut(duration: 0.2), value: showingSettings || showingDayEditSheet || showEditAlert)
                .gesture(
                    DragGesture(minimumDistance: 50)
                        .onEnded { value in
                            if value.translation.height > 100 && abs(value.translation.width) < 100 {
                                dismiss()
                            }
                        }
                )
                .ignoresSafeArea(edges: .top)
            }
            
            // Floating settings button in bottom right corner
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showingSettings = true
                    }) {
                        ZStack {
                            Color.clear
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                    .modifier(GlassButtonModifier(
                        isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                        size: 64
                    ))
                    .contentShape(Circle())
                    .padding(.trailing, themeManager.spacing.medium)
                    .padding(.bottom, themeManager.spacing.medium)
                }
            }
            .ignoresSafeArea(edges: .bottom)
            
            // Custom edit alert
            if showEditAlert {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showEditAlert = false
                    }
                
                VStack(spacing: 20) {
                    // Earnings display (read-only)
                    Text(String(format: "%.0f€", editEarnings))
                        .font(.custom("Major Mono Display Regular", size: 24))
                        .foregroundColor(.primary)
                    
                    // Time picker section
                    HStack {
                        Picker("Hours", selection: $editTimeHours) {
                            ForEach(0..<24) { hour in
                                Text("\(hour)h").tag(hour)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .onChange(of: editTimeHours) { _, _ in
                            updateEarningsFromTime()
                        }
                        
                        Picker("Minutes", selection: $editTimeMinutes) {
                            ForEach(0..<60) { minute in
                                Text("\(minute)m").tag(minute)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .onChange(of: editTimeMinutes) { _, _ in
                            updateEarningsFromTime()
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            showEditAlert = false
                        }) {
                            Text("cancel")
                                .font(.custom("Major Mono Display Regular", size: 14))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(8)
                        }
                        
                        Button(action: {
                            showConfirmation = true
                        }) {
                            Text("change")
                                .font(.custom("Major Mono Display Regular", size: 14))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(24)
                .frame(width: 300)
                .background(
                    themeManager.currentTheme == .liquidGlass ?
                    AnyView(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                    ) :
                    AnyView(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(UIColor.systemBackground))
                    )
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            setupMonths()
        }
        .sheet(isPresented: $showingDayEditSheet) {
            if let selectedDay = selectedDay,
               let dayInfo = getSelectedDayInfo() {
                DayEditTimeSheet(
                    selectedDate: selectedDay,
                    currentTime: dayInfo.time,
                    isPresented: $showingDayEditSheet,
                    customTitle: "edit \(formatDate(selectedDay).lowercased())"
                )
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .confirmationDialog("remove day", isPresented: $showingRemoveConfirmation, titleVisibility: .visible) {
            Button("remove", role: .destructive) {
                confirmRemove()
            }
            Button("cancel", role: .cancel) { }
        } message: {
            if let day = selectedDay {
                Text("are you sure you want to remove all data for \(formatDate(day).lowercased())? this will permanently delete all time entries for this day.")
            }
        }
        .confirmationDialog("do you really want to change the tracked time? all previous tracked data for this day will be overwritten.", isPresented: $showConfirmation, titleVisibility: .visible) {
            Button("confirm", role: .destructive) {
                confirmEdit()
            }
            Button("cancel", role: .cancel) { }
        }
    }
    
    private func formatDayEarnings(for date: Date) -> Double {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        var dayEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
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
        
        return totalDuration / 3600 * settings.hourlyRate
    }
    
    private func editDayTime() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        showingDayEditSheet = true
    }
    
    private func removeDayData() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        showingRemoveConfirmation = true
    }
    
    private func confirmRemove() {
        guard let day = selectedDay else { return }
        timeTracker.deleteDayData(for: day)
        selectedDay = nil
    }
    
    private func openEditAlert(for date: Date) {
        editingDay = date
        
        // Get current duration for the day
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        var dayEntries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
        if let currentStart = timeTracker.currentSessionStart,
           currentStart >= dayStart && currentStart < dayEnd {
            let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
            dayEntries.append(currentEntry)
        }
        
        // Store previous entries before editing (only if not already manually edited)
        if !timeTracker.isDayManuallyEdited(for: date) && !dayEntries.isEmpty {
            previousEntries[date] = dayEntries
        }
        
        let totalDuration = dayEntries.reduce(0) { total, entry in
            if entry.isActive {
                return total + Date().timeIntervalSince(entry.startDate)
            } else {
                return total + entry.duration
            }
        }
        
        // Set initial values
        let totalSeconds = Int(totalDuration)
        editTimeHours = totalSeconds / 3600
        editTimeMinutes = (totalSeconds % 3600) / 60
        editEarnings = totalDuration / 3600 * settings.hourlyRate
        
        showEditAlert = true
    }
    
    private func updateEarningsFromTime() {
        let totalSeconds = Double(editTimeHours * 3600 + editTimeMinutes * 60)
        editEarnings = totalSeconds / 3600 * settings.hourlyRate
    }
    
    private func confirmEdit() {
        guard let day = editingDay else { return }
        
        let totalSeconds = TimeInterval(editTimeHours * 3600 + editTimeMinutes * 60)
        timeTracker.editDayTime(for: day, newTime: totalSeconds)
        
        showEditAlert = false
        showConfirmation = false
        editingDay = nil
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    UnifiedMonthView()
}
