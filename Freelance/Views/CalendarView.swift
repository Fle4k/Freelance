//
//  CalendarView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct CalendarView: View {
    let period: StatisticsPeriod
    let monthDate: Date
    let onDaySelected: ((Date) -> Void)?
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    
    init(period: StatisticsPeriod, monthDate: Date = Date(), onDaySelected: ((Date) -> Void)? = nil) {
        self.period = period
        self.monthDate = monthDate
        self.onDaySelected = onDaySelected
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Days of week header
            HStack(spacing: 0) {
                ForEach(getWeekdayHeaders(), id: \.self) { day in
                    Text(day)
                        .font(.custom("Major Mono Display Regular", size: 14))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Calculate cell size based on available width
            GeometryReader { geometry in
                let spacing: CGFloat = themeManager.currentTheme == .liquidGlass ? 12 : 8
                let totalSpacing = spacing * 6 // 6 gaps between 7 columns
                let cellWidth = (geometry.size.width - totalSpacing) / 7
                
                // Match list row height: font size 14 + vertical padding
                let verticalPadding: CGFloat = themeManager.currentTheme == .liquidGlass ? themeManager.spacing.itemSpacing : 8
                let cellHeight: CGFloat = 14 + (verticalPadding * 2)
                
                // Calendar grid - aligned to top
                VStack(spacing: 0) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: spacing), count: 7), spacing: spacing) {
                        ForEach(Array(getCalendarDays().enumerated()), id: \.offset) { index, day in
                            CalendarDayView(
                                day: day,
                                hasTimeEntry: hasTimeEntry(for: day),
                                isToday: isToday(day),
                                cellWidth: cellWidth,
                                cellHeight: cellHeight,
                                onTap: { selectedDay in
                                    onDaySelected?(selectedDay)
                                },
                                getDateForDay: getDateForDay
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
    
    private func getWeekdayHeaders() -> [String] {
        // System weekday numbering: 1=Sunday, 2=Monday, 3=Tuesday, etc.
        // Our array: [0=Sunday, 1=Monday, 2=Tuesday, etc.]
        let weekdays = ["su", "mo", "tu", "we", "th", "fr", "sa"]
        let startIndex = settings.weekStartsOn - 1
        return Array(weekdays[startIndex...] + weekdays[..<startIndex])
    }
    
    private func getCalendarDays() -> [Int] {
        let calendar = Calendar.current
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate) else {
            return Array(1...31)
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: monthDate)?.count ?? 31
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        
        // Calculate offset based on user's week start preference
        // firstWeekday: 1=Sunday, 2=Monday, 3=Tuesday, etc.
        // weekStartsOn: 1=Sunday, 2=Monday, 3=Tuesday, etc.
        // We need to convert the system's firstWeekday to our custom week start
        let systemFirstWeekday = firstWeekday // 1=Sunday, 2=Monday, etc.
        let userWeekStart = settings.weekStartsOn // 1=Sunday, 2=Monday, etc.
        
        // Calculate how many days to shift to align with user's week start
        let offset = (systemFirstWeekday - userWeekStart + 7) % 7
        
        var days: [Int] = []
        
        // Add empty days for proper alignment
        for _ in 0..<offset {
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
        
        guard let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start,
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
        let calendar = Calendar.current
        let today = Date()
        
        // Check if the monthDate is the current month
        let currentMonth = calendar.component(.month, from: today)
        let viewMonth = calendar.component(.month, from: monthDate)
        let currentYear = calendar.component(.year, from: today)
        let viewYear = calendar.component(.year, from: monthDate)
        
        guard currentMonth == viewMonth && currentYear == viewYear else { return false }
        
        let todayDay = calendar.component(.day, from: today)
        return day == todayDay
    }
    
    private func getDateForDay(_ day: Int) -> Date? {
        guard day > 0 else { return nil }
        
        let calendar = Calendar.current
        guard let monthStart = calendar.dateInterval(of: .month, for: monthDate)?.start else {
            return nil
        }
        
        return calendar.date(byAdding: .day, value: day - 1, to: monthStart)
    }
}

struct CalendarDayView: View {
    let day: Int
    let hasTimeEntry: Bool
    let isToday: Bool
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    let onTap: ((Date) -> Void)?
    let getDateForDay: (Int) -> Date?
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            if day > 0 {
                // Use the smaller dimension for circle size
                let circleSize = min(cellWidth, cellHeight) * 0.85
                
                Text("\(day)")
                    .font(.custom("Major Mono Display Regular", size: 14))
                    .foregroundColor(isToday ? (colorScheme == .dark ? .black : .white) : .primary)
                    .frame(width: circleSize, height: circleSize)
                    .background(
                        Group {
                            if isToday {
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white : Color.black)
                                    .shadow(
                                        color: (colorScheme == .dark ? Color.white : Color.black).opacity(0.3),
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            } else if hasTimeEntry && themeManager.currentTheme != .liquidGlass {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 1)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                            }
                        }
                    )
                    .modifier(
                        ConditionalGlassCircle(
                            isLiquidGlass: themeManager.currentTheme == .liquidGlass && hasTimeEntry && !isToday,
                            circleSize: circleSize
                        )
                    )
                    .frame(width: cellWidth, height: cellHeight)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if let date = getDateForDay(day) {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                            impactFeedback.impactOccurred()
                            onTap?(date)
                        }
                    }
            } else {
                // Empty day
                Text("")
                    .frame(width: cellWidth, height: cellHeight)
            }
        }
    }
}

// MARK: - Conditional Glass Circle Modifier

struct ConditionalGlassCircle: ViewModifier {
    let isLiquidGlass: Bool
    let circleSize: CGFloat
    
    func body(content: Content) -> some View {
        if isLiquidGlass {
            content
                .glassEffect(.regular.tint(Color.white.opacity(0.0)))
        } else {
            content
        }
    }
}

#Preview {
    CalendarView(period: .thisMonth, monthDate: Date())
}
