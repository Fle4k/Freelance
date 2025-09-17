//
//  DailyStatisticsView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct DailyStatisticsView: View {
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
        
        return entries.sorted { $0.startDate < $1.startDate }
    }
    
    var totalHours: Double {
        timeTracker.getTotalHours(for: .today)
    }
    
    var totalEarnings: Double {
        timeTracker.getEarnings(for: .today)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                HStack {
                    Spacer()
                    
                    Text("today")
                        .font(.custom("Major Mono Display Regular", size: 18))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f/8", totalHours))
                        .font(.custom("Major Mono Display Regular", size: 17))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Daily Schedule
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        ForEach(todayEntries) { entry in
                            TimeSlotRow(entry: entry)
                        }
                        
                        if todayEntries.isEmpty {
                            Text("no time tracked today")
                                .font(.custom("Major Mono Display Regular", size: 17))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer(minLength: 40)
                        
                        // Earnings
                        Text(String(format: "%.0f. euro", totalEarnings))
                            .font(.custom("Major Mono Display Regular", size: 22))
                            .foregroundColor(.primary)
                        
                        Spacer(minLength: 40)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .background(Color(.systemBackground))
        }
    }
}

struct TimeSlotRow: View {
    let entry: TimeEntry
    
    private func formatTime(_ date: Date) -> String {
        return AppSettings.shared.formatTime(date)
    }
    
    var body: some View {
        HStack {
            if let endDate = entry.endDate {
                Text("\(formatTime(entry.startDate)) – \(formatTime(endDate))")
                                                .font(.custom("Major Mono Display Regular", size: 17))
                    .foregroundColor(.primary)
            } else {
                Text("\(formatTime(entry.startDate)) – active")
                                                .font(.custom("Major Mono Display Regular", size: 17))
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Rectangle()
                .fill(entry.isActive ? Color.green : Color.primary)
                .frame(width: 60, height: 2)
        }
    }
}

#Preview {
    DailyStatisticsView()
}
