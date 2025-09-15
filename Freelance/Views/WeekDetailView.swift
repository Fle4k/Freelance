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

#Preview {
    WeekDetailView()
}
