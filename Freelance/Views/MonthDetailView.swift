//
//  MonthDetailView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct MonthDetailView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @Environment(\.dismiss) private var dismiss
    @State private var currentMonthIndex = 0
    @State private var months: [Date] = []
    @State private var showingEditSheet = false
    
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
                                    CalendarView(period: .thisMonth, monthDate: months[index])
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
                            CalendarView(period: .thisMonth, monthDate: Date())
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
        }
    }
    
    private func getCustomTitle(for period: StatisticsPeriod) -> String {
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

#Preview {
    MonthDetailView()
}
