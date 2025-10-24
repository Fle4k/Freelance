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
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var selectedDay: Date?
    @State private var showingEditSheet = false
    @State private var showingDayEditSheet = false
    @State private var showingRemoveConfirmation = false
    
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
                    // Selected day info at top
                    if let dayInfo = getSelectedDayInfo() {
                        VStack(spacing: 8) {
                            Text(dayInfo.title)
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Text(dayInfo.time)
                                    .font(.custom("Major Mono Display Regular", size: 18))
                                    .foregroundColor(.primary)
                                
                                Text("/")
                                    .font(.custom("Major Mono Display Regular", size: 18))
                                    .foregroundColor(.primary)
                                
                                Text(dayInfo.earnings)
                                    .font(.custom("Major Mono Display Regular", size: 18))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Month overview with calendar
                    VStack(spacing: 15) {
                        if !months.isEmpty {
                            TabView(selection: $currentMonthIndex) {
                                ForEach(0..<months.count, id: \.self) { index in
                                    VStack(spacing: 12) {
                                        // Month title and stats
                                        VStack(spacing: 5) {
                                            Text(getMonthTitle(for: months[index]))
                                                .font(.custom("Major Mono Display Regular", size: 15))
                                                .foregroundColor(.primary)
                                            
                                            HStack(spacing: 8) {
                                                Text(formatTime(getMonthTime(for: months[index])))
                                                    .font(.custom("Major Mono Display Regular", size: 14))
                                                    .foregroundColor(.secondary)
                                                
                                                Text("/")
                                                    .font(.custom("Major Mono Display Regular", size: 14))
                                                    .foregroundColor(.secondary)
                                                
                                                Text(String(format: "%.0f€", getMonthEarnings(for: months[index])))
                                                    .font(.custom("Major Mono Display Regular", size: 14))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        // Calendar
                                        CalendarView(period: .thisMonth, monthDate: months[index]) { selectedDate in
                                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                            impactFeedback.impactOccurred()
                                            selectedDay = selectedDate
                                        }
                                        .frame(height: 280)
                                    }
                                    .tag(index)
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                            .frame(height: 360)
                        }
                    }
                    
                    // Scrollable list of tracked days
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(monthEntries, id: \.0) { dayEntry in
                                GeometryReader { listGeometry in
                                    VStack(spacing: 0) {
                                        HStack(spacing: 4) {
                                            // Date column
                                            Text(formatDate(dayEntry.0))
                                                .font(.custom("Major Mono Display Regular", size: 12))
                                                .foregroundColor(.primary)
                                                .frame(width: listGeometry.size.width * 0.42, alignment: .leading)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            
                                            Spacer(minLength: 2)
                                            
                                            // Time column
                                            Text(formatDayDuration(for: dayEntry.0))
                                                .font(.custom("Major Mono Display Regular", size: 12))
                                                .foregroundColor(.primary)
                                                .frame(width: listGeometry.size.width * 0.28, alignment: .trailing)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                            
                                            Text("/")
                                                .font(.custom("Major Mono Display Regular", size: 12))
                                                .foregroundColor(.primary)
                                            
                                            // Earnings column (5 digits + €)
                                            Text(String(format: "%.0f€", formatDayEarnings(for: dayEntry.0)))
                                                .font(.custom("Major Mono Display Regular", size: 12))
                                                .foregroundColor(.primary)
                                                .frame(width: listGeometry.size.width * 0.22, alignment: .trailing)
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                        
                                        // Underline for selected day
                                        Rectangle()
                                            .fill(selectedDay != nil && Calendar.current.isDate(dayEntry.0, inSameDayAs: selectedDay!) ? Color.primary : Color.clear)
                                            .frame(height: 1)
                                            .padding(.top, 2)
                                    }
                                }
                                .frame(height: 20)
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
                
                // Action buttons
                if selectedDay != nil {
                    VStack(spacing: 20) {
                        Button(action: editDayTime) {
                            Text("edit")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.primary)
                        }
                        
                        Button(action: removeDayData) {
                            Text("remove")
                                .font(.custom("Major Mono Display Regular", size: 16))
                                .foregroundColor(.primary)
                        }
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

