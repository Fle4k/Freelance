//
//  Models.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import Foundation
import SwiftUI
import UserNotifications

// Time tracking session
struct TimeEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    
    init(startDate: Date, endDate: Date?, isActive: Bool) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
    }
    
    var duration: TimeInterval {
        if let endDate = endDate {
            return endDate.timeIntervalSince(startDate)
        } else if isActive {
            return Date().timeIntervalSince(startDate)
        }
        return 0
    }
}

// App settings
class AppSettings: ObservableObject {
    @Published var hourlyRate: Double = 80.0
    @Published var motionDetectionEnabled: Bool = false
    @Published var motionThreshold: Double = 5.0
    @Published var askWhenMoving: Bool = true // true = ask when moving, false = ask when not moving
    @Published var weekStartsOn: Int = 2 // 1 = Sunday, 2 = Monday, 3 = Tuesday, etc.
    @Published var use24HourFormat: Bool = true // true = 24h, false = AM/PM
    
    static let shared = AppSettings()
    
    private init() {
        loadSettings()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(hourlyRate, forKey: "hourlyRate")
        UserDefaults.standard.set(motionDetectionEnabled, forKey: "motionDetectionEnabled")
        UserDefaults.standard.set(motionThreshold, forKey: "motionThreshold")
        UserDefaults.standard.set(askWhenMoving, forKey: "askWhenMoving")
        UserDefaults.standard.set(weekStartsOn, forKey: "weekStartsOn")
        UserDefaults.standard.set(use24HourFormat, forKey: "use24HourFormat")
    }
    
    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    // Set up notification categories after permission is granted
                    TimeTracker.shared.setupNotificationCategories()
                    
                    // Request critical alert permission for better lock screen visibility
                    UNUserNotificationCenter.current().requestAuthorization(options: [.criticalAlert]) { criticalGranted, criticalError in
                        print("Critical alert permission: \(criticalGranted)")
                    }
                }
                completion(granted)
            }
        }
    }
    
    private func loadSettings() {
        hourlyRate = UserDefaults.standard.object(forKey: "hourlyRate") as? Double ?? 0.0
        motionDetectionEnabled = UserDefaults.standard.object(forKey: "motionDetectionEnabled") as? Bool ?? false
        motionThreshold = UserDefaults.standard.object(forKey: "motionThreshold") as? Double ?? 5.0
        askWhenMoving = UserDefaults.standard.object(forKey: "askWhenMoving") as? Bool ?? true
        weekStartsOn = UserDefaults.standard.object(forKey: "weekStartsOn") as? Int ?? 2
        use24HourFormat = UserDefaults.standard.object(forKey: "use24HourFormat") as? Bool ?? true
    }
    
    // Helper for time formatting
    func timeFormat() -> String {
        return use24HourFormat ? "HH:mm" : "h:mm a"
    }
    
    // Helper to get formatted time string with lowercase am/pm
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = timeFormat()
        let timeString = formatter.string(from: date)
        // Convert AM/PM to lowercase am/pm for our custom font
        return timeString.replacingOccurrences(of: "AM", with: "am").replacingOccurrences(of: "PM", with: "pm")
    }
}

// Time tracking manager
class TimeTracker: ObservableObject {
    @Published var isRunning = false
    @Published var currentSessionStart: Date?
    @Published var timeEntries: [TimeEntry] = []
    @Published var elapsedTime: TimeInterval = 0
    @Published var totalAccumulatedTime: TimeInterval = 0 // Total time across all sessions
    static let shared = TimeTracker()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        loadTimeEntries()
        loadCurrentSession()
        loadAccumulatedTime()
        setupNotificationCategories()
        
        // Check if it's a new day and reset accumulated time
        checkForNewDayReset()
        
        // Set up notification observer for when app becomes active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        // Just log that app became active - let the notification system handle timer stopping
        print("🔔 App became active - timer state: isRunning=\(isRunning)")
    }
    
    func setupNotificationCategories() {
        // Timer stopped notification actions (for user-triggered stops)
        let continueWithTimeAction = UNNotificationAction(
            identifier: "CONTINUE_WITH_TIME",
            title: "continue & add time",
            options: [.foreground]
        )
        
        let newTimerAction = UNNotificationAction(
            identifier: "NEW_TIMER",
            title: "new timer",
            options: [.foreground]
        )
        
        let timerStoppedCategory = UNNotificationCategory(
            identifier: "TIMER_STOPPED",
            actions: [continueWithTimeAction, newTimerAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        notificationCenter.setNotificationCategories([timerStoppedCategory])
        
    }
    
    var formattedElapsedTime: String {
        let totalTime = totalAccumulatedTime + (isRunning ? elapsedTime : 0)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        let seconds = Int(totalTime) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // Computed properties for timer display components (MVVM compliance)
    var timerDisplayComponents: [(digits: String, unit: String)] {
        let totalTime = totalAccumulatedTime + (isRunning ? elapsedTime : 0)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        let seconds = Int(totalTime) % 60
        
        var components: [(digits: String, unit: String)] = []
        
        // Always show hours:minutes:seconds format
        components.append((digits: String(format: "%02d", hours), unit: ":"))
        components.append((digits: String(format: "%02d", minutes), unit: ":"))
        components.append((digits: String(format: "%02d", seconds), unit: ""))
        
        return components
    }
    
    func formattedTotalTime(for period: StatisticsPeriod) -> String {
        let totalSeconds = getTotalHours(for: period) * 3600
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func formattedTimeHMS(for period: StatisticsPeriod) -> String {
        let totalSeconds = getTotalHours(for: period) * 3600
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        let seconds = Int(totalSeconds) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    func startTimer() {
        print("▶️ startTimer called")
        currentSessionStart = Date()
        elapsedTime = 0
        isRunning = true
        saveCurrentSession()
        print("▶️ Timer started. isRunning: \(isRunning), start time: \(currentSessionStart?.description ?? "nil")")
    }
    
    func pauseTimer() {
        print("⏸️ pauseTimer called. Current state: isRunning=\(isRunning), currentSessionStart=\(currentSessionStart?.description ?? "nil")")
        
        if let startDate = currentSessionStart, isRunning {
            // Add current session time to accumulated time
            let sessionTime = Date().timeIntervalSince(startDate)
            totalAccumulatedTime += sessionTime
            
            // Create a time entry for this session
            let entry = TimeEntry(
                startDate: startDate,
                endDate: Date(),
                isActive: false
            )
            timeEntries.append(entry)
            saveTimeEntries()
            print("⏸️ Session saved: \(sessionTime) seconds")
        }
        
        isRunning = false
        currentSessionStart = nil
        elapsedTime = 0
        saveAccumulatedTime()
        clearCurrentSession()
        print("⏸️ Timer paused. Final state: isRunning=\(isRunning)")
    }
    
    func recordTimer() {
        // This is now called when storing and resetting from long press
        if isRunning {
            pauseTimer() // Stop current session and save it
        }
        
        // Reset all accumulated time
        totalAccumulatedTime = 0
        saveAccumulatedTime()
        
        // Start a new timer session
        startTimer()
    }
    
    func resetTimer() {
        // Reset without saving - discards current session and all accumulated time
        currentSessionStart = nil
        isRunning = false
        elapsedTime = 0
        totalAccumulatedTime = 0
        saveAccumulatedTime()
        clearCurrentSession()
    }
    
    func updateElapsedTime() {
        if let startDate = currentSessionStart, isRunning {
            elapsedTime = Date().timeIntervalSince(startDate)
            
            // Check for midnight rollover
            checkForMidnightRollover()
        }
    }
    
    private func checkForMidnightRollover() {
        guard isRunning, let sessionStart = currentSessionStart else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let sessionDay = calendar.startOfDay(for: sessionStart)
        let currentDay = calendar.startOfDay(for: now)
        
        // If we've crossed midnight (session started on a different day)
        if sessionDay < currentDay {
            performMidnightRollover()
        }
    }
    
    private func performMidnightRollover() {
        guard let sessionStart = currentSessionStart, isRunning else { return }
        
        print("Midnight rollover detected - splitting session across days")
        
        // Calculate the time worked until midnight
        let calendar = Calendar.current
        let sessionDay = calendar.startOfDay(for: sessionStart)
        let midnight = calendar.date(byAdding: .day, value: 1, to: sessionDay)!
        
        // Create time entry for the previous day (up to midnight)
        let previousDayEntry = TimeEntry(
            startDate: sessionStart,
            endDate: midnight,
            isActive: false
        )
        timeEntries.append(previousDayEntry)
        
        // Add the time worked to accumulated time
        let timeWorked = midnight.timeIntervalSince(sessionStart)
        totalAccumulatedTime += timeWorked
        
        // Save the changes
        saveTimeEntries()
        saveAccumulatedTime()
        
        // Continue timer for the new day starting at midnight
        currentSessionStart = midnight
        elapsedTime = Date().timeIntervalSince(midnight)
        totalAccumulatedTime = 0 // Reset accumulated time for new day
        saveAccumulatedTime()
        saveCurrentSession() // Save the new session start
        
        print("Midnight rollover completed - session split, timer continues on new day")
    }
    
    // MARK: - Notification Handling
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        print("🔔 handleNotificationResponse called with action: \(response.actionIdentifier)")
        print("🔔 Notification identifier: \(response.notification.request.identifier)")
        print("🔔 User info: \(response.notification.request.content.userInfo)")
        
        // Handle notification types
        switch response.actionIdentifier {
        case "CONTINUE_WITH_TIME":
            handleContinueWithTime()
        case "NEW_TIMER":
            handleNewTimer()
        default:
            print("🔔 Unknown notification action: \(response.actionIdentifier)")
            break
        }
    }
    
    private func handleContinueWithTime() {
        print("User chose to continue with time that passed")
        
        // Start a new timer session
        startTimer()
    }
    
    private func handleNewTimer() {
        print("User chose to start a new timer")
        
        // Store current session and reset (same as recordTimer but without starting)
        if isRunning {
            pauseTimer() // This will save the current session
        }
        
        // Reset all accumulated time
        totalAccumulatedTime = 0
        saveAccumulatedTime()
        
        // Start a new timer session
        startTimer()
    }
    
    // MARK: - Test Data
    
    func addTestCrossDaySession() {
        let calendar = Calendar.current
        let now = Date()
        
        // Get yesterday and today at midnight
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Create test session: yesterday 23:00 to today 00:30
        let sessionStart = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: yesterday)!
        let midnightSplit = today // midnight
        let sessionEnd = calendar.date(bySettingHour: 0, minute: 30, second: 0, of: today)!
        
        // First part: yesterday 23:00 - 00:00 (1 hour)
        let firstEntry = TimeEntry(startDate: sessionStart, endDate: midnightSplit, isActive: false)
        
        // Second part: today 00:00 - 00:30 (30 minutes)  
        let secondEntry = TimeEntry(startDate: midnightSplit, endDate: sessionEnd, isActive: false)
        
        // Clear all existing entries for clean test
        timeEntries.removeAll()
        
        // Add just these two entries for ONE simple rollover test
        timeEntries.append(firstEntry)
        timeEntries.append(secondEntry)
        
        saveTimeEntries()
        print("✅ Added simple test rollover: \(sessionStart) to \(sessionEnd)")
    }
    
    // MARK: - Time Management Actions
    
    func copyTime(for period: StatisticsPeriod) {
        let timeString = formattedTotalTime(for: period)
        UIPasteboard.general.string = timeString
        print("Copied time for \(period.displayName): \(timeString)")
    }
    
    func resetTime(for period: StatisticsPeriod) {
        switch period {
        case .today:
            // Reset only today's entries
            let calendar = Calendar.current
            let today = Date()
            timeEntries = timeEntries.filter { !calendar.isDate($0.startDate, inSameDayAs: today) }
            saveTimeEntries()
        case .thisWeek:
            // Reset this week's entries
            let calendar = Calendar.current
            let now = Date()
            let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            timeEntries = timeEntries.filter { $0.startDate < weekStart }
            saveTimeEntries()
        case .thisMonth:
            // Reset this month's entries
            let calendar = Calendar.current
            let now = Date()
            let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
            timeEntries = timeEntries.filter { $0.startDate < monthStart }
            saveTimeEntries()
        case .lastWeek, .total:
            // Reset all entries
            timeEntries = []
            totalAccumulatedTime = 0
            saveTimeEntries()
            saveAccumulatedTime()
        }
        
        // Stop current timer if running
        if isRunning {
            pauseTimer()
        }
        
        print("Reset time for \(period.displayName)")
    }
    
    func deleteDayData(for date: Date) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        // Remove all entries for this specific day
        timeEntries = timeEntries.filter { entry in
            !(entry.startDate >= dayStart && entry.startDate < dayEnd)
        }
        
        // Stop current timer if it's running on this day
        if let currentStart = currentSessionStart,
           currentStart >= dayStart && currentStart < dayEnd {
            pauseTimer()
        }
        
        saveTimeEntries()
        print("Deleted all data for date: \(date)")
    }
    
    func editDayTime(for date: Date, newTime: TimeInterval) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        // Remove all entries for this specific day
        timeEntries = timeEntries.filter { entry in
            !(entry.startDate >= dayStart && entry.startDate < dayEnd)
        }
        
        // Stop current timer if it's running on this day
        if let currentStart = currentSessionStart,
           currentStart >= dayStart && currentStart < dayEnd {
            pauseTimer()
        }
        
        // Add a single entry for this day with the new time
        if newTime > 0 {
            let endTime = dayStart.addingTimeInterval(newTime)
            let newEntry = TimeEntry(startDate: dayStart, endDate: endTime, isActive: false)
            timeEntries.append(newEntry)
        }
        
        saveTimeEntries()
        print("Edited day \(date) to \(newTime) seconds")
    }
    
    func isDayManuallyEdited(for date: Date) -> Bool {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? date
        
        // Get all entries for this day
        let dayEntries = timeEntries.filter { entry in
            entry.startDate >= dayStart && entry.startDate < dayEnd && entry.endDate != nil
        }
        
        // A day is manually edited if:
        // 1. It has exactly one entry
        // 2. That entry starts exactly at the beginning of the day (00:00:00)
        if dayEntries.count == 1,
           let entry = dayEntries.first {
            return entry.startDate == dayStart
        }
        
        return false
    }
    
    func editTime(for period: StatisticsPeriod, newTime: TimeInterval) {
        switch period {
        case .today:
            editTodayTime(newTime: newTime)
        case .thisWeek:
            editThisWeekTime(newTime: newTime)
        case .thisMonth:
            editThisMonthTime(newTime: newTime)
        case .lastWeek, .total:
            editTotalTime(newTime: newTime)
        }
        
        print("Edited time for \(period.displayName) to \(newTime) seconds")
    }
    
    func adjustTime(for period: StatisticsPeriod, newTime: TimeInterval) {
        let currentTime = getTotalHours(for: period) * 3600
        let difference = newTime - currentTime
        
        if abs(difference) < 1 { return } // No significant change
        
        // Create an adjustment entry
        let now = Date()
        let adjustmentEntry: TimeEntry
        
        if difference > 0 {
            // Adding time - create a positive entry
            adjustmentEntry = TimeEntry(
                startDate: now,
                endDate: now.addingTimeInterval(difference),
                isActive: false
            )
        } else {
            // Subtracting time - create a negative entry (end before start)
            adjustmentEntry = TimeEntry(
                startDate: now.addingTimeInterval(difference),
                endDate: now,
                isActive: false
            )
        }
        
        timeEntries.append(adjustmentEntry)
        saveTimeEntries()
        
        print("Adjusted \(period.displayName) by \(difference) seconds")
    }
    
    private func editTodayTime(newTime: TimeInterval) {
        let calendar = Calendar.current
        let today = Date()
        
        // Remove today's entries
        timeEntries = timeEntries.filter { !calendar.isDate($0.startDate, inSameDayAs: today) }
        
        // Add a single entry for today with the new time
        if newTime > 0 {
            let startTime = calendar.startOfDay(for: today)
            let endTime = startTime.addingTimeInterval(newTime)
            let newEntry = TimeEntry(startDate: startTime, endDate: endTime, isActive: false)
            timeEntries.append(newEntry)
        }
        
        saveTimeEntries()
    }
    
    private func editThisWeekTime(newTime: TimeInterval) {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        
        // Remove this week's entries
        timeEntries = timeEntries.filter { $0.startDate < weekStart }
        
        // Add a single entry for this week with the new time
        if newTime > 0 {
            let endTime = weekStart.addingTimeInterval(newTime)
            let newEntry = TimeEntry(startDate: weekStart, endDate: endTime, isActive: false)
            timeEntries.append(newEntry)
        }
        
        saveTimeEntries()
    }
    
    private func editThisMonthTime(newTime: TimeInterval) {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Remove this month's entries
        timeEntries = timeEntries.filter { $0.startDate < monthStart }
        
        // Add a single entry for this month with the new time
        if newTime > 0 {
            let endTime = monthStart.addingTimeInterval(newTime)
            let newEntry = TimeEntry(startDate: monthStart, endDate: endTime, isActive: false)
            timeEntries.append(newEntry)
        }
        
        saveTimeEntries()
    }
    
    private func editTotalTime(newTime: TimeInterval) {
        // Clear all entries and set total accumulated time
        timeEntries = []
        totalAccumulatedTime = newTime
        saveTimeEntries()
        saveAccumulatedTime()
    }

    // MARK: - Statistics
    
    private func getStartOfWeek(for date: Date, calendar: Calendar, weekStartsOn: Int) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromStartOfWeek = (weekday - weekStartsOn + 7) % 7
        return calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: calendar.startOfDay(for: date)) ?? date
    }
    
    func getTotalHours(for period: StatisticsPeriod) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let settings = AppSettings.shared
        
        var entries: [TimeEntry]
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            entries = timeEntries.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
            
        case .thisWeek:
            let startOfWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            entries = timeEntries.filter { $0.startDate >= startOfWeek && $0.startDate < endOfWeek }
            
        case .lastWeek:
            let startOfThisWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
            let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
            entries = timeEntries.filter { $0.startDate >= startOfLastWeek && $0.startDate < startOfThisWeek }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            entries = timeEntries.filter { $0.startDate >= startOfMonth && $0.startDate < endOfMonth }
            
        case .total:
            entries = timeEntries
        }
        
        // Include current session if it's running and falls within the period
        if let currentStart = currentSessionStart {
            let currentEntry = TimeEntry(startDate: currentStart, endDate: nil, isActive: true)
            
            let shouldInclude: Bool
            switch period {
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                shouldInclude = currentStart >= startOfDay && currentStart < endOfDay
            case .thisWeek:
                let startOfWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
                shouldInclude = currentStart >= startOfWeek && currentStart < endOfWeek
            case .lastWeek:
                let startOfThisWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
                let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
                shouldInclude = currentStart >= startOfLastWeek && currentStart < startOfThisWeek
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                shouldInclude = currentStart >= startOfMonth && currentStart < endOfMonth
            case .total:
                shouldInclude = true
            }
            
            if shouldInclude {
                entries.append(currentEntry)
            }
        }
        
        let totalSeconds = entries.reduce(0) { $0 + $1.duration }
        return totalSeconds / 3600.0
    }
    
    func getEarnings(for period: StatisticsPeriod) -> Double {
        return getTotalHours(for: period) * AppSettings.shared.hourlyRate
    }
    
    // MARK: - Persistence
    
    private func saveTimeEntries() {
        if let data = try? JSONEncoder().encode(timeEntries) {
            UserDefaults.standard.set(data, forKey: "timeEntries")
        }
    }
    
    private func loadTimeEntries() {
        if let data = UserDefaults.standard.data(forKey: "timeEntries"),
           let entries = try? JSONDecoder().decode([TimeEntry].self, from: data) {
            timeEntries = entries
        }
    }
    
    private func saveCurrentSession() {
        if let startDate = currentSessionStart {
            UserDefaults.standard.set(startDate, forKey: "currentSessionStart")
            UserDefaults.standard.set(isRunning, forKey: "isRunning")
        }
    }
    
    private func loadCurrentSession() {
        if let startDate = UserDefaults.standard.object(forKey: "currentSessionStart") as? Date,
           UserDefaults.standard.bool(forKey: "isRunning") {
            currentSessionStart = startDate
            isRunning = true
        }
    }
    
    private func clearCurrentSession() {
        UserDefaults.standard.removeObject(forKey: "currentSessionStart")
        UserDefaults.standard.removeObject(forKey: "isRunning")
    }
    
    private func saveAccumulatedTime() {
        UserDefaults.standard.set(totalAccumulatedTime, forKey: "totalAccumulatedTime")
        UserDefaults.standard.set(Date(), forKey: "lastAccumulatedTimeUpdate")
    }
    
    private func loadAccumulatedTime() {
        totalAccumulatedTime = UserDefaults.standard.object(forKey: "totalAccumulatedTime") as? TimeInterval ?? 0
    }
    
    private func checkForNewDayReset() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        
        // Get the last time we checked for new day (or when accumulated time was last saved)
        let lastAccumulatedTimeUpdate = UserDefaults.standard.object(forKey: "lastAccumulatedTimeUpdate") as? Date ?? Date.distantPast
        let lastUpdateDay = calendar.startOfDay(for: lastAccumulatedTimeUpdate)
        
        // If it's a new day since last update, reset accumulated time
        if today > lastUpdateDay {
            print("New day detected - resetting accumulated time from \(totalAccumulatedTime) to 0")
            totalAccumulatedTime = 0
            saveAccumulatedTime()
            
            // Update the last check date
            UserDefaults.standard.set(now, forKey: "lastAccumulatedTimeUpdate")
        }
    }
}

enum StatisticsPeriod {
    case today, thisWeek, lastWeek, thisMonth, total
}


