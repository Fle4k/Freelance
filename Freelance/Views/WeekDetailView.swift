//
//  WeekDetailView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct WeekDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var selectedDay: Date?
    @State private var showingDayDetail = false
    @State private var precomputedDayData: (entries: [TimeEntry], totalTime: TimeInterval, earnings: Double, title: String)?
    
    private var weekEntries: [(Date, [TimeEntry])] {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current  // Ensure we use local timezone
        let now = Date()
        
        // Use the same week calculation logic as the TimeTracker
        let startOfWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
        
        var entries: [(Date, [TimeEntry])] = []
        
        for i in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                let dayStart = calendar.startOfDay(for: dayDate)
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayDate
                
                print("🗓️ Day \(i): dayDate=\(dayDate), dayStart=\(dayStart)")
                
                let dayEntries = timeTracker.timeEntries.filter { entry in
                    entry.startDate >= dayStart && entry.startDate < dayEnd
                }
                
                // Always include the day, even if it has no entries
                entries.append((dayStart, dayEntries))
            }
        }
        
        // Sort by weekday order starting with Monday
        return entries.sorted { first, second in
            let calendar = Calendar.current
            let firstWeekday = calendar.component(.weekday, from: first.0)
            let secondWeekday = calendar.component(.weekday, from: second.0)
            
            // Convert weekday to Monday=0, Tuesday=1, ..., Sunday=6
            let firstDay = (firstWeekday - 2 + 7) % 7
            let secondDay = (secondWeekday - 2 + 7) % 7
            
            return firstDay < secondDay
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        return AppSettings.shared.formatTime(date)
    }
    
    private func formatDuration(from start: Date, to end: Date) -> String {
        let duration = end.timeIntervalSince(start)
        return formatDuration(from: duration)
    }
    
    private func formatDuration(from duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Week entries with smaller font
                    ScrollView(.vertical, showsIndicators: false) {
                        ZStack(alignment: .topLeading) {
                            VStack(spacing: 15) {
                                ForEach(weekEntries, id: \.0) { dayEntry in
                                    HStack(spacing: 0) {
                                        // Rollover indicator dot for days that are part of cross-midnight sessions
                                        if hasRolloverSession(for: dayEntry.0) {
                                            Text("·")
                                                .font(.custom("Major Mono Display Regular", size: 20))
                                                .foregroundColor(.white)
                                                .frame(width: 9)
                                                .padding(.trailing, 8)
                                        } else {
                                            // Invisible spacer to maintain alignment
                                            Spacer()
                                                .frame(width: 9)
                                                .padding(.trailing, 8)
                                        }
                                    
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
                                    print("📱 Week list item tapped: \(dayEntry.0)")
                                    print("📱 Using normalized date (should be 00:00:00): \(dayEntry.0)")
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    precomputeDayData(for: dayEntry.0)
                                    selectedDay = dayEntry.0
                                    showingDayDetail = true
                                    print("📱 Week list sheet should show: \(showingDayDetail)")
                                }
                            }
                                    
                            if weekEntries.isEmpty {
                                Text("no time tracked this week")
                                    .font(.custom("Major Mono Display Regular", size: 15))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .multilineTextAlignment(.center)
                                }
                            }
                            
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTimeSheet(
                period: .thisWeek,
                currentTime: timeTracker.formattedTimeHMS(for: .thisWeek),
                isPresented: $showingEditSheet,
                customTitle: getCustomTitle(for: .thisWeek)
            )
        }
        .sheet(isPresented: $showingDayDetail) {
            if let selectedDay = selectedDay {
                DayDetailView(selectedDate: selectedDay, precomputedData: precomputedDayData)
                    .onAppear {
                        print("📋 Week sheet presenting for day: \(selectedDay)")
                        print("📋 Precomputed data: \(precomputedDayData != nil)")
                    }
            } else {
                Text("No day selected")
                    .onAppear {
                        print("❌ No selected day for week sheet")
                    }
            }
        }
        .onChange(of: showingDayDetail) { oldValue, isShowing in
            if isShowing {
                print("📋 Week sheet state changed to showing: \(isShowing)")
                print("📋 Selected day: \(selectedDay?.description ?? "nil")")
            }
        }
        .onChange(of: timeTracker.timeEntries) { oldValue, newValue in
            print("🔄 WeekDetailView: TimeTracker entries changed, triggering view refresh")
            // This will cause the view to recompute weekEntries
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E dd.MM.yyyy"
        return formatter.string(from: date).lowercased()
    }
    
    private func formatTimeRange(_ start: Date, _ end: Date?) -> String {
        let startTime = formatTime(start)
        if let end = end {
            let endTime = formatTime(end)
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
    
    private func getStartOfWeek(for date: Date, calendar: Calendar, weekStartsOn: Int) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromStartOfWeek = (weekday - weekStartsOn + 7) % 7
        let startOfDay = calendar.startOfDay(for: date)
        let startOfWeek = calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: startOfDay) ?? date
        print("📅 StartOfWeek calculation: date=\(date), startOfDay=\(startOfDay), startOfWeek=\(startOfWeek)")
        return startOfWeek
    }
    
    private func hasRolloverSession(for date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        // Check if this day has a rollover session (either starting or ending at midnight)
        return timeTracker.timeEntries.contains { entry in
            // Case 1: Entry starts at midnight (continuation from previous day)
            let startsAtMidnight = abs(entry.startDate.timeIntervalSince(dayStart)) < 60
            
            // Case 2: Entry ends at midnight (continues to next day)  
            let endsAtMidnight = entry.endDate != nil && abs(entry.endDate!.timeIntervalSince(dayEnd)) < 60
            
            // Case 3: Entry spans across this day's midnight boundaries
            let spansFromPrevious = entry.startDate < dayStart && (entry.endDate == nil || entry.endDate! > dayStart)
            let spansToNext = entry.startDate < dayEnd && (entry.endDate == nil || entry.endDate! >= dayEnd)
            
            return startsAtMidnight || endsAtMidnight || spansFromPrevious || spansToNext
        }
    }
    
    
    private func precomputeDayData(for date: Date) {
        print("🔍 Precomputing data for date: \(date)")
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.current  // Ensure we use local timezone
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
}

#Preview {
    WeekDetailView()
}
