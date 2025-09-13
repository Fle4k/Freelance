//
//  CalendarView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct CalendarView: View {
    let period: StatisticsPeriod
    @ObservedObject private var timeTracker = TimeTracker.shared
    
    var body: some View {
        VStack(spacing: 13) {
            // Days of week header
            HStack {
                ForEach(["su", "mo", "tu", "we", "th", "fr", "sa"], id: \.self) { day in
                    Text(day)
                        .font(.custom("Major Mono Display Regular", size: 15))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 9) {
                ForEach(getCalendarDays(), id: \.self) { day in
                    CalendarDayView(
                        day: day,
                        hasTimeEntry: hasTimeEntry(for: day),
                        isToday: isToday(day)
                    )
                }
            }
            .padding(.bottom, 10)
        }
    }
    
    private func getCalendarDays() -> [Int] {
        let calendar = Calendar.current
        let now = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: now) else {
            return Array(1...31)
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 31
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        var days: [Int] = []
        
        // Add empty days for proper alignment
        for _ in 1..<firstWeekday {
            days.append(0) // 0 represents empty day
        }
        
        // Add actual days
        for day in 1...daysInMonth {
            days.append(day)
        }
        
        return days
    }
    
    private func hasTimeEntry(for day: Int) -> Bool {
        guard day > 0 else { return false }
        
        let calendar = Calendar.current
        let now = Date()
        
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start,
              let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else {
            return false
        }
        
        let dayStart = calendar.startOfDay(for: dayDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayDate
        
        return timeTracker.timeEntries.contains { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd
        }
    }
    
    private func isToday(_ day: Int) -> Bool {
        guard day > 0 else { return false }
        let today = Calendar.current.component(.day, from: Date())
        return day == today
    }
}

struct CalendarDayView: View {
    let day: Int
    let hasTimeEntry: Bool
    let isToday: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            if day > 0 {
                    Text("\(day)")
                        .font(.custom("Major Mono Display Regular", size: 18))
                    .foregroundColor(textColor)
                        .frame(width: 35, height: 35)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(backgroundColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )
            } else {
                // Empty day
                Text("")
                    .frame(width: 35, height: 35)
            }
        }
    }
    
    private var backgroundColor: Color {
        if isToday {
            return colorScheme == .dark ? .white : .black
        } else {
            return .clear
        }
    }
    
    private var textColor: Color {
        if isToday {
            return colorScheme == .dark ? .black : .white
        } else {
            return .primary
        }
    }
    
    private var borderColor: Color {
        if isToday {
            return colorScheme == .dark ? .white : .black
        } else if hasTimeEntry {
            return .secondary
        } else {
            return .clear
        }
    }
}

#Preview {
    CalendarView(period: .thisMonth)
}
