//
//  TodayDetailView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct TodayDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    
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
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Time entries with smaller font
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 15) {
                            if timeTracker.isDayManuallyEdited(for: Date()) {
                                // Show single "changed by user" message for manually edited days
                                HStack {
                                    Text("changed by user")
                                        .font(.custom("Major Mono Display Regular", size: 15))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                    
                                    Text(formatDuration(from: timeTracker.getTotalHours(for: .today) * 3600))
                                        .font(.custom("Major Mono Display Regular", size: 15))
                                        .foregroundColor(.primary)
                                }
                            } else {
                                ForEach(todayEntries) { entry in
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
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTimeSheet(
                period: .today,
                currentTime: timeTracker.formattedTimeHMS(for: .today),
                isPresented: $showingEditSheet,
                customTitle: getCustomTitle(for: .today)
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
}

struct ActiveTimerView: View {
    let startDate: Date
    @State private var currentTime = Date()
    
    private func formatTime(_ date: Date) -> String {
        return AppSettings.shared.formatTime(date)
    }
    
    var body: some View {
        Text("\(formatTime(startDate))-\(formatTime(currentTime))")
            .font(.custom("Major Mono Display Regular", size: 15))
            .foregroundColor(.primary)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                currentTime = Date()
            }
    }
}

#Preview {
    TodayDetailView()
}
