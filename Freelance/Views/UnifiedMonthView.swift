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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var selectedDay: Date?
    @State private var showingEditSheet = false
    @State private var showingDayEditSheet = false
    @State private var showingRemoveConfirmation = false
    @State private var showingSettings = false
    
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
        let today = Date()
        
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
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 60)
                
                VStack(spacing: 25) {
                    // Month title and calendar
                    if !months.isEmpty {
                        VStack(spacing: 15) {
                            // Month title with time and earnings
                            VStack(spacing: 8) {
                                Text(getMonthTitle(for: months[currentMonthIndex]))
                                    .font(.custom("Major Mono Display Regular", size: 18))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
                                    Text(formatTime(getMonthTime(for: months[currentMonthIndex])))
                                        .font(.custom("Major Mono Display Regular", size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Text("/")
                                        .font(.custom("Major Mono Display Regular", size: 18))
                                        .foregroundColor(.primary)
                                    
                                    Text(String(format: "%.0f€", getMonthEarnings(for: months[currentMonthIndex])))
                                        .font(.custom("Major Mono Display Regular", size: 18))
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            // Calendar
                            TabView(selection: $currentMonthIndex) {
                                ForEach(0..<months.count, id: \.self) { index in
                                    CalendarView(period: .thisMonth, monthDate: months[index]) { selectedDate in
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        selectedDay = selectedDate
                                    }
                                    .frame(height: 280)
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 280)
                        }
                    }
                    
                    // Scrollable list of tracked days
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(monthEntries, id: \.0) { dayEntry in
                                let isSelected = selectedDay != nil && Calendar.current.isDate(dayEntry.0, inSameDayAs: selectedDay!)
                                
                                HStack(spacing: 8) {
                                    // Date column
                                    Text(formatDate(dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 12))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .lineLimit(1)
                                    
                                    // Time column
                                    Text(formatDayDuration(for: dayEntry.0))
                                        .font(.custom("Major Mono Display Regular", size: 12))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                    
                                    // Earnings column
                                    Text(String(format: "%.0f€", formatDayEarnings(for: dayEntry.0)))
                                        .font(.custom("Major Mono Display Regular", size: 12))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .frame(minWidth: 50, alignment: .trailing)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(isSelected ? Color.secondary.opacity(0.3) : Color.clear)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    selectedDay = dayEntry.0
                                }
                            }
                            
                            if monthEntries.isEmpty {
                                Text("no time tracked this month")
                                    .font(.custom("Major Mono Display Regular", size: 12))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Settings button at bottom
                VStack(spacing: 20) {
                    Divider()
                        .padding(.horizontal, 40)
                    
                    Button(action: {
                        showingSettings = true
                    }) {
                        Text("settings")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemBackground))
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        if value.translation.height > 100 && abs(value.translation.width) < 100 {
                            dismiss()
                        }
                    }
            )
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
}

#Preview {
    UnifiedMonthView()
}

