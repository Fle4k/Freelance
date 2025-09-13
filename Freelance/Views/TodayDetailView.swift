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
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 30)
                
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
                    ScrollView(.vertical, showsIndicators: false) {
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
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
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

#Preview {
    TodayDetailView()
}
