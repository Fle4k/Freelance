//
//  MonthDetailView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct MonthDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var showingEditSheet = false
    @State private var selectedDay: Date?
    @State private var showingDayDetail = false
    @State private var precomputedDayData: (entries: [TimeEntry], totalTime: TimeInterval, earnings: Double, title: String)?
    
    private var monthEntries: [(Date, [TimeEntry])] {
        let calendar = Calendar.current
        
        guard !months.isEmpty && currentMonthIndex < months.count else { return [] }
        let currentMonth = months[currentMonthIndex]
        
        // Get start and end of current month
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        var entries: [(Date, [TimeEntry])] = []
        
        // Iterate through each day of the month
        var currentDate = monthInterval.start
        while currentDate < monthInterval.end {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? currentDate
            
            let dayEntries = timeTracker.timeEntries.filter { entry in
                entry.startDate >= dayStart && entry.startDate < dayEnd
            }
            
            // Include current session if it started on this day
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
        
        // Sort by newest day first
        return entries.sorted { $0.0 > $1.0 }
    }
    
    private func setupMonths() {
        let calendar = Calendar.current
        let now = Date()
        var monthsArray: [Date] = []
        
        // Add 3 previous months for testing (oldest first)
        for i in (1...3).reversed() {
            if let previousMonth = calendar.date(byAdding: .month, value: -i, to: now) {
                monthsArray.append(previousMonth)
            }
        }
        
        // Add current month last (rightmost card)
        monthsArray.append(now)
        
        months = monthsArray
        // Set currentMonthIndex to the last element (the current month)
        currentMonthIndex = months.count - 1
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
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
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
    
    private func precomputeDayData(for date: Date) {
        print("🔍 Precomputing data for date: \(date)")
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        print("📅 Day range: \(dayStart) to \(dayEnd)")
        print("📊 Total time entries: \(timeTracker.timeEntries.count)")
        
        // Debug: Print all time entries to see their dates
        for (index, entry) in timeTracker.timeEntries.enumerated() {
            print("📝 Entry \(index): \(entry.startDate) - \(entry.endDate?.description ?? "nil")")
        }
        
        // Compute day entries - include both completed and active entries
        var entries = timeTracker.timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
        
        print("📝 Filtered entries (all): \(entries.count)")
        
        // Separate completed entries
        let completedEntries = entries.filter { $0.endDate != nil }
        print("📝 Completed entries: \(completedEntries.count)")
        
        // Include current session if it started on this day
        if let currentStart = timeTracker.currentSessionStart,
           currentStart >= dayStart && currentStart < dayEnd {
            let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
            entries.append(currentEntry)
            print("⏰ Added current session entry")
        }
        
        let sortedEntries = entries.sorted { $0.startDate > $1.startDate }
        print("📝 Final sorted entries: \(sortedEntries.count)")
        
        // Compute total time
        let totalTime = sortedEntries.reduce(0) { total, entry in
            if entry.isActive {
                return total + Date().timeIntervalSince(entry.startDate)
            } else {
                return total + entry.duration
            }
        }
        
        // Compute earnings
        let earnings = totalTime / 3600 * settings.hourlyRate
        
        // Compute day title
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd.MM.yyyy"
        let title = formatter.string(from: date).lowercased()
        
        print("💰 Computed data - Entries: \(sortedEntries.count), Time: \(totalTime), Earnings: \(earnings), Title: \(title)")
        
        precomputedDayData = (sortedEntries, totalTime, earnings, title)
        print("✅ Precomputed data set: \(precomputedDayData != nil)")
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                VStack(spacing: 30) {
                    // Header with month navigation - interactive title button
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        showingEditSheet = true
                    }) {
                        VStack(spacing: 10) {
                            Text(months.isEmpty ? "this month" : getMonthTitle(for: months[currentMonthIndex]))
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                            ProportionalTimeDisplay(
                                timeString: formatTime(months.isEmpty ? 0 : getMonthTime(for: months[currentMonthIndex])),
                                digitFontSize: 20
                            )
                            
                            Text(String(format: "%.0f€", months.isEmpty ? 0 : getMonthEarnings(for: months[currentMonthIndex])))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Calendar with swipe navigation
                    Group {
                        if !months.isEmpty {
                            TabView(selection: $currentMonthIndex) {
                                ForEach(0..<months.count, id: \.self) { index in
                                    CalendarView(period: .thisMonth, monthDate: months[index]) { selectedDate in
                                        print("📱 Calendar day tapped: \(selectedDate)")
                                        precomputeDayData(for: selectedDate)
                                        selectedDay = selectedDate
                                        showingDayDetail = true
                                        print("📱 Sheet should show: \(showingDayDetail)")
                                    }
                                    .frame(height: 350)
                                    .padding(.top, 15)
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        guard !months.isEmpty else { return }
                                        
                                        // Check for vertical swipe down to dismiss
                                        if value.translation.height > 100 && abs(value.translation.width) < 100 {
                                            // Swipe down - dismiss sheet
                                            dismiss()
                                            return
                                        }
                                        
                                        // Check for horizontal swipes for month navigation
                                        if value.translation.width > 50 && currentMonthIndex > 0 {
                                            // Swipe right - go to older month
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentMonthIndex -= 1
                                            }
                                        } else if value.translation.width < -50 && currentMonthIndex < months.count - 1 {
                                            // Swipe left - go to newer month
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                currentMonthIndex += 1
                                            }
                                        }
                                    }
                            )
                        } else {
                            // Fallback calendar when months array is empty
                            CalendarView(period: .thisMonth, monthDate: Date()) { selectedDate in
                                print("📱 Fallback calendar day tapped: \(selectedDate)")
                                precomputeDayData(for: selectedDate)
                                selectedDay = selectedDate
                                showingDayDetail = true
                                print("📱 Fallback sheet should show: \(showingDayDetail)")
                            }
                            .frame(height: 350)
                            .padding(.top, 15)
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        // Check for vertical swipe down to dismiss
                                        if value.translation.height > 100 && abs(value.translation.width) < 100 {
                                            // Swipe down - dismiss sheet
                                            dismiss()
                                        }
                                    }
                            )
                        }
                    }
                    
                    // Days list with timer usage
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 15) {
                            ForEach(monthEntries, id: \.0) { dayEntry in
                                HStack {
                                    Text(formatDate(dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 15))
                                        .foregroundColor(.primary)
        
        Spacer()
                                    
                                    Text(formatDayDuration(for: dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 15))
                                            .foregroundColor(.primary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    print("📱 List item tapped: \(dayEntry.0)")
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    precomputeDayData(for: dayEntry.0)
                                    selectedDay = dayEntry.0
                                    showingDayDetail = true
                                    print("📱 List sheet should show: \(showingDayDetail)")
                                }
                            }
                                    
                            if monthEntries.isEmpty {
                                Text("no time tracked this month")
                                    .font(.custom("Major Mono Display Regular", size: 15))
                                    .foregroundColor(.secondary)
                                }
                            }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        // Check for vertical swipe down to dismiss
                        if value.translation.height > 100 && abs(value.translation.width) < 100 {
                            // Swipe down - dismiss sheet
                            dismiss()
                        }
                    }
            )
        }
            .onAppear {
                setupMonths()
            }
            .sheet(isPresented: $showingEditSheet) {
                EditTimeSheet(
                    period: .thisMonth,
                    currentTime: formatTime(months.isEmpty ? 0 : getMonthTime(for: months[currentMonthIndex])),
                    isPresented: $showingEditSheet,
                    customTitle: getCustomTitle(for: .thisMonth)
                )
            }
            .sheet(isPresented: $showingDayDetail) {
                if let selectedDay = selectedDay {
                    DayDetailView(selectedDate: selectedDay, precomputedData: precomputedDayData)
                        .onAppear {
                            print("📋 Sheet presenting for day: \(selectedDay)")
                            print("📋 Precomputed data: \(precomputedDayData != nil)")
                        }
                } else {
                    Text("No day selected")
                        .onAppear {
                            print("❌ No selected day for sheet")
                        }
                }
            }
            .onChange(of: showingDayDetail) { oldValue, isShowing in
                if isShowing {
                    print("📋 Sheet state changed to showing: \(isShowing)")
                    print("📋 Selected day: \(selectedDay?.description ?? "nil")")
                }
            }
        }
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

struct DayDetailView: View {
    let selectedDate: Date
    let precomputedData: (entries: [TimeEntry], totalTime: TimeInterval, earnings: Double, title: String)?
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingRemoveConfirmation = false
    @State private var showingDayEditSheet = false
    
    // Precomputed data for instant display
    @State private var dayEntries: [TimeEntry] = []
    @State private var dayTotalTime: TimeInterval = 0
    @State private var dayEarnings: Double = 0
    @State private var dayTitle: String = ""
    
    private func formatTime(_ date: Date) -> String {
        return AppSettings.shared.formatTime(date)
    }
    
    private func precomputeDayData() {
        print("🎯 DayDetailView precomputeDayData called")
        print("📦 Precomputed data available: \(precomputedData != nil)")
        
        if let data = precomputedData {
            print("✅ Using precomputed data - Entries: \(data.entries.count), Time: \(data.totalTime), Earnings: \(data.earnings), Title: \(data.title)")
            // Use precomputed data for instant display
            dayEntries = data.entries
            dayTotalTime = data.totalTime
            dayEarnings = data.earnings
            dayTitle = data.title
        } else {
            print("⚠️ No precomputed data, computing fallback")
            // Fallback to computing data (shouldn't happen with our optimization)
            let calendar = Calendar.current
            let dayStart = calendar.startOfDay(for: selectedDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Compute day entries
            var entries = timeTracker.timeEntries.filter { entry in
                entry.startDate >= dayStart && entry.startDate < dayEnd && entry.endDate != nil
            }
            
            // Include current session if it started on this day
            if let currentStart = timeTracker.currentSessionStart,
               currentStart >= dayStart && currentStart < dayEnd {
                let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
                entries.append(currentEntry)
            }
            
            dayEntries = entries.sorted { $0.startDate > $1.startDate }
            
            // Compute total time
            dayTotalTime = dayEntries.reduce(0) { total, entry in
                if entry.isActive {
                    return total + Date().timeIntervalSince(entry.startDate)
                } else {
                    return total + entry.duration
                }
            }
            
            // Compute earnings
            dayEarnings = dayTotalTime / 3600 * settings.hourlyRate
            
            // Compute day title
            let formatter = DateFormatter()
            formatter.dateFormat = "E dd.MM.yyyy"
            dayTitle = formatter.string(from: selectedDate).lowercased()
        }
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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                VStack(spacing: 30) {
                    // Header matching overview style - interactive title button
                    Button(action: {
                        // Add haptic feedback
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        showingEditSheet = true
                    }) {
                        VStack(spacing: 10) {
                            Text(dayTitle)
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                            
                            ProportionalTimeDisplay(
                                timeString: formatTime(dayTotalTime),
                                digitFontSize: 20
                            )
                            
                            Text(String(format: "%.0f€", Double(dayEarnings)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Time entries with smaller font
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 15) {
                            ForEach(dayEntries) { entry in
                                HStack {
                                    if let endDate = entry.endDate {
                                        Text("\(formatTime(entry.startDate))-\(formatTime(endDate))")
                                            .font(.custom("Major Mono Display Regular", size: 15))
                                            .foregroundColor(.primary)
                                    } else {
                                        ActiveTimerView(startDate: entry.startDate)
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
                            
                            if dayEntries.isEmpty {
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
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Action buttons section
                VStack(spacing: 8) {
                    Button(action: editDayTime) {
                        Text("edit")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: removeDayData) {
                        Text("remove")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                    }
                }
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            precomputeDayData()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTimeSheet(
                period: .today,
                currentTime: formatTime(dayTotalTime),
                isPresented: $showingEditSheet,
                customTitle: "edit \(dayTitle)"
            )
        }
        .confirmationDialog("remove day", isPresented: $showingRemoveConfirmation, titleVisibility: .visible) {
            Button("remove", role: .destructive) {
                confirmRemove()
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text("are you sure you want to remove all data for \(dayTitle)? this will permanently delete all time entries for this day.")
        }
        .sheet(isPresented: $showingDayEditSheet) {
            DayEditTimeSheet(
                selectedDate: selectedDate,
                currentTime: formatTime(dayTotalTime),
                isPresented: $showingDayEditSheet,
                customTitle: "edit \(dayTitle)"
            )
        }
    }
    
    private func editDayTime() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        showingDayEditSheet = true
    }
    
    private func removeDayData() {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        showingRemoveConfirmation = true
    }
    
    private func confirmRemove() {
        timeTracker.deleteDayData(for: selectedDate)
        dismiss()
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval.truncatingRemainder(dividingBy: 3600)) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct DayEditTimeSheet: View {
    let selectedDate: Date
    let currentTime: String
    @Binding var isPresented: Bool
    let customTitle: String?
    @State private var hoursText: String = ""
    @State private var minutesText: String = ""
    @State private var isHoursFocused: Bool = true
    @State private var originalHoursText: String = ""
    @State private var originalMinutesText: String = ""
    
    private var periodTitle: String {
        return customTitle ?? "edit day"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                VStack(spacing: 30) {
                    // Title matching overview style
                    Text(periodTitle)
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.primary)
                        .padding(.top, 20)
                    
                    // Show current total time
                    VStack(spacing: 10) {
                        Text("current total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        Text(currentTime)
                            .font(.custom("Major Mono Display Regular", size: 20))
                            .foregroundColor(.primary)
                    }
                    
                    // Hours and minutes input
                    VStack(spacing: 20) {
                        Text("new total")
                            .font(.custom("Major Mono Display Regular", size: 16))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            // Hours input
                            VStack(spacing: 5) {
                                Text("hours")
                                    .font(.custom("Major Mono Display Regular", size: 14))
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: $hoursText)
                                    .font(.custom("Major Mono Display Regular", size: 24))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                                    .background(
                                        Rectangle()
                                            .stroke(isHoursFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                            .background(Color(.systemBackground))
                                    )
                                    .onTapGesture {
                                        isHoursFocused = true
                                    }
                            }
                            
                            // Minutes input
                            VStack(spacing: 5) {
                                Text("minutes")
                                    .font(.custom("Major Mono Display Regular", size: 14))
                                    .foregroundColor(.secondary)
                                
                                TextField("0", text: $minutesText)
                                    .font(.custom("Major Mono Display Regular", size: 24))
                                    .keyboardType(.numberPad)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 80)
                                    .background(
                                        Rectangle()
                                            .stroke(!isHoursFocused ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                            .background(Color(.systemBackground))
                                    )
                                    .onTapGesture {
                                        isHoursFocused = false
                                    }
                            }
                        }
                    }
                    
                    // Buttons
                    VStack(spacing: 15) {
                        Button(action: saveChanges) {
                            Text("save")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: cancel) {
                            Text("cancel")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .onAppear {
            parseCurrentTime()
            originalHoursText = hoursText
            originalMinutesText = minutesText
        }
    }
    
    private func parseCurrentTime() {
        // Parse time from HH:MM:SS format
        let components = currentTime.split(separator: ":")
        if components.count >= 2 {
            hoursText = String(components[0])
            minutesText = String(components[1])
        }
    }
    
    private func saveChanges() {
        let hours = Int(hoursText) ?? 0
        let minutes = Int(minutesText) ?? 0
        let totalSeconds = TimeInterval(hours * 3600 + minutes * 60)
        
        TimeTracker.shared.editDayTime(for: selectedDate, newTime: totalSeconds)
        isPresented = false
    }
    
    private func cancel() {
        hoursText = originalHoursText
        minutesText = originalMinutesText
        isPresented = false
    }
}

#Preview {
    MonthDetailView()
}
