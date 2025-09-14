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
struct TimeEntry: Identifiable, Codable {
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
    @Published var deadManSwitchEnabled: Bool = false
    @Published var deadManSwitchInterval: Double = 10.0
    @Published var motionDetectionEnabled: Bool = false
    @Published var motionThreshold: Double = 5.0
    @Published var askWhenMoving: Bool = true // true = ask when moving, false = ask when not moving
    @Published var weekStartsOn: Int = 2 // 1 = Sunday, 2 = Monday, 3 = Tuesday, etc.
    
    static let shared = AppSettings()
    
    private init() {
        loadSettings()
    }
    
    func saveSettings() {
        UserDefaults.standard.set(hourlyRate, forKey: "hourlyRate")
        UserDefaults.standard.set(deadManSwitchEnabled, forKey: "deadManSwitchEnabled")
        UserDefaults.standard.set(deadManSwitchInterval, forKey: "deadManSwitchInterval")
        UserDefaults.standard.set(motionDetectionEnabled, forKey: "motionDetectionEnabled")
        UserDefaults.standard.set(motionThreshold, forKey: "motionThreshold")
        UserDefaults.standard.set(askWhenMoving, forKey: "askWhenMoving")
        UserDefaults.standard.set(weekStartsOn, forKey: "weekStartsOn")
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
        hourlyRate = UserDefaults.standard.object(forKey: "hourlyRate") as? Double ?? 80.0
        deadManSwitchEnabled = UserDefaults.standard.object(forKey: "deadManSwitchEnabled") as? Bool ?? false
        deadManSwitchInterval = UserDefaults.standard.object(forKey: "deadManSwitchInterval") as? Double ?? 10.0
        motionDetectionEnabled = UserDefaults.standard.object(forKey: "motionDetectionEnabled") as? Bool ?? false
        motionThreshold = UserDefaults.standard.object(forKey: "motionThreshold") as? Double ?? 5.0
        askWhenMoving = UserDefaults.standard.object(forKey: "askWhenMoving") as? Bool ?? true
        weekStartsOn = UserDefaults.standard.object(forKey: "weekStartsOn") as? Int ?? 2
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
    
    private var lastDeadManCheck: Date?
    private var notificationTimeoutTimer: Timer?
    private let notificationCenter = UNUserNotificationCenter.current()
    
    private init() {
        loadTimeEntries()
        loadCurrentSession()
        loadAccumulatedTime()
        setupNotificationCategories()
    }
    
    func setupNotificationCategories() {
        let continueAction = UNNotificationAction(
            identifier: "CONTINUE",
            title: "Continue",
            options: [.foreground]
        )
        
        let stopAction = UNNotificationAction(
            identifier: "STOP",
            title: "Stop",
            options: [.destructive, .foreground]
        )
        
        let deadManCategory = UNNotificationCategory(
            identifier: "DEAD_MAN_SWITCH",
            actions: [continueAction, stopAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        // Timer stopped notification actions
        let continueWithTimeAction = UNNotificationAction(
            identifier: "CONTINUE_WITH_TIME",
            title: "Continue & Add Time",
            options: [.foreground]
        )
        
        let newTimerAction = UNNotificationAction(
            identifier: "NEW_TIMER",
            title: "New Timer",
            options: [.foreground]
        )
        
        let timerStoppedCategory = UNNotificationCategory(
            identifier: "TIMER_STOPPED",
            actions: [continueWithTimeAction, newTimerAction],
            intentIdentifiers: [],
            options: [.customDismissAction, .allowInCarPlay]
        )
        
        notificationCenter.setNotificationCategories([deadManCategory, timerStoppedCategory])
        
    }
    
    var formattedElapsedTime: String {
        let totalTime = totalAccumulatedTime + (isRunning ? elapsedTime : 0)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        let seconds = Int(totalTime) % 60
        
        // Show only necessary units
        if hours > 0 {
            // After 59 minutes, show "1h00m"
            return String(format: "%dh%02dm", hours, minutes)
        } else if minutes > 0 {
            // After 59 seconds, show "1m00s"
            return String(format: "%dm%02ds", minutes, seconds)
        } else {
            // Start with only seconds
            return String(format: "%ds", seconds)
        }
    }
    
    // Computed properties for timer display components (MVVM compliance)
    var timerDisplayComponents: [(digits: String, unit: String)] {
        let totalTime = totalAccumulatedTime + (isRunning ? elapsedTime : 0)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        let seconds = Int(totalTime) % 60
        
        var components: [(digits: String, unit: String)] = []
        
        if hours > 0 {
            components.append((digits: String(hours), unit: "h"))
            components.append((digits: String(format: "%02d", minutes), unit: "m"))
        } else if minutes > 0 {
            components.append((digits: String(minutes), unit: "m"))
            components.append((digits: String(format: "%02d", seconds), unit: "s"))
        } else {
            components.append((digits: String(seconds), unit: "s"))
        }
        
        return components
    }
    
    func formattedTotalTime(for period: StatisticsPeriod) -> String {
        let totalHours = getTotalHours(for: period)
        let hours = Int(totalHours)
        let minutes = Int((totalHours - Double(hours)) * 60)
        
        if hours > 0 {
            return String(format: "%dh%02dm", hours, minutes)
        } else {
            return String(format: "%dm", minutes)
        }
    }
    
    func formattedTimeHMS(for period: StatisticsPeriod) -> String {
        let totalSeconds = getTotalHours(for: period) * 3600
        let hours = Int(totalSeconds) / 3600
        let minutes = Int(totalSeconds) % 3600 / 60
        let seconds = Int(totalSeconds) % 60
        
        // Show only relevant time units, removing leading zeros
        if hours > 0 {
            if minutes > 0 {
                return String(format: "%dh%02dm%02ds", hours, minutes, seconds)
            } else if seconds > 0 {
                return String(format: "%dh%02ds", hours, seconds)
            } else {
                return String(format: "%dh", hours)
            }
        } else if minutes > 0 {
            if seconds > 0 {
                return String(format: "%dm%02ds", minutes, seconds)
            } else {
                return String(format: "%dm", minutes)
            }
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    func startTimer() {
        currentSessionStart = Date()
        elapsedTime = 0
        isRunning = true
        saveCurrentSession()
        startDeadManSwitch()
    }
    
    func pauseTimer() {
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
        }
        
        isRunning = false
        currentSessionStart = nil
        elapsedTime = 0
        saveAccumulatedTime()
        clearCurrentSession()
        stopDeadManSwitch()
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
        stopDeadManSwitch()
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
        
        print("Midnight rollover detected - storing current day and starting new day")
        
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
        
        // Start a new session for the new day
        currentSessionStart = midnight
        elapsedTime = Date().timeIntervalSince(midnight)
        
        print("Midnight rollover completed - new day started at \(midnight)")
    }
    
    // MARK: - Dead Man Switch
    
    private func startDeadManSwitch() {
        stopDeadManSwitch() // Stop any existing timer
        
        let settings = AppSettings.shared
        guard settings.deadManSwitchEnabled else { return }
        
        lastDeadManCheck = Date()
        scheduleDeadManNotification()
    }
    
    private func stopDeadManSwitch() {
        lastDeadManCheck = nil
        clearNotificationBadge()
        cancelScheduledNotifications()
        
        // Cancel timeout timer
        notificationTimeoutTimer?.invalidate()
        notificationTimeoutTimer = nil
    }
    
    private func scheduleDeadManNotification() {
        let settings = AppSettings.shared
        let intervalMinutes = settings.deadManSwitchInterval
        
        
        let content = UNMutableNotificationContent()
        content.title = "Are you still working?"
        content.body = "Tap Continue to keep tracking time, or Stop to pause. You have 2 minutes to respond."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "DEAD_MAN_SWITCH"
        content.userInfo = ["type": "dead_man_switch"]
        
        // Calculate the next clock-aligned time
        let nextNotificationTime = calculateNextClockAlignment(intervalMinutes: intervalMinutes)
        
        // Use UNCalendarNotificationTrigger for better background reliability
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: nextNotificationTime)
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "dead_man_switch",
            content: content,
            trigger: trigger
        )
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        print("Scheduling dead man switch notification for \(formatter.string(from: nextNotificationTime)) (every \(Int(intervalMinutes)) minutes)")
        
        // Start the 2-minute timeout timer when the notification is scheduled
        // This ensures it works whether the app is in foreground or background
        startNotificationTimeout()
        print("Date components: \(dateComponents)")
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    private func calculateNextClockAlignment(intervalMinutes: Double) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current time components
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentSecond = calendar.component(.second, from: now)
        
        // Calculate how many minutes have passed since the last interval boundary
        let minutesSinceLastBoundary = currentMinute % Int(intervalMinutes)
        
        // Calculate the next boundary
        var nextMinute: Int
        if minutesSinceLastBoundary == 0 && currentSecond == 0 {
            // We're exactly on a boundary, schedule for the next one
            nextMinute = currentMinute + Int(intervalMinutes)
        } else {
            // Calculate next boundary
            nextMinute = currentMinute - minutesSinceLastBoundary + Int(intervalMinutes)
        }
        
        // Handle hour overflow
        var nextHour = currentHour
        if nextMinute >= 60 {
            nextHour += nextMinute / 60
            nextMinute = nextMinute % 60
        }
        
        // Create the next notification time
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        dateComponents.hour = nextHour
        dateComponents.minute = nextMinute
        dateComponents.second = 0
        
        return calendar.date(from: dateComponents) ?? now
    }
    
    private func cancelScheduledNotifications() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["dead_man_switch"])
    }
    
    
    
    private func clearNotificationBadge() {
        notificationCenter.setBadgeCount(0)
    }
    
    private func sendTimerStoppedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Timer stopped"
        content.body = "No response received within 2 minutes. Timer has been paused."
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "TIMER_STOPPED"
        content.userInfo = ["type": "timer_stopped"]
        
        let request = UNNotificationRequest(
            identifier: "timer_stopped_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error sending timer stopped notification: \(error)")
            }
        }
    }
    
    func startNotificationTimeout() {
        // Cancel any existing timeout timer
        notificationTimeoutTimer?.invalidate()
        
        print("Starting 2-minute notification timeout")
        
        // Start 2-minute timeout timer
        notificationTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { _ in
            self.handleNotificationTimeout()
        }
    }
    
    private func handleNotificationTimeout() {
        print("Notification timeout - stopping timer and subtracting 2 minutes")
        
        // Stop the timeout timer
        notificationTimeoutTimer?.invalidate()
        notificationTimeoutTimer = nil
        
        // Subtract 2 minutes from accumulated time
        totalAccumulatedTime = max(0, totalAccumulatedTime - 120) // 120 seconds = 2 minutes
        saveAccumulatedTime()
        
        // Stop the timer
        pauseTimer()
        
        // Send notification that timer stopped
        sendTimerStoppedNotification()
    }
    
    
    func handleDeadManResponse(continue: Bool) {
        // Cancel timeout timer since user responded
        notificationTimeoutTimer?.invalidate()
        notificationTimeoutTimer = nil
        
        clearNotificationBadge()
        
        if `continue` {
            // Reset the timer for the next check
            lastDeadManCheck = Date()
            // Schedule the next notification at the next clock-aligned interval
            scheduleDeadManNotification()
        } else {
            // Stop the timer
            pauseTimer()
        }
    }
    
    func restartDeadManSwitch() {
        if isRunning {
            startDeadManSwitch()
        }
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) {
        switch response.actionIdentifier {
        case "CONTINUE":
            handleDeadManResponse(continue: true)
        case "STOP":
            handleDeadManResponse(continue: false)
        case "CONTINUE_WITH_TIME":
            handleContinueWithTime()
        case "NEW_TIMER":
            handleNewTimer()
        default:
            break
        }
    }
    
    private func handleContinueWithTime() {
        print("User chose to continue with time that passed")
        
        // Clear notification badge
        clearNotificationBadge()
        
        // Add the time that passed since the last dead man check to accumulated time
        if let lastCheck = lastDeadManCheck {
            let timePassed = Date().timeIntervalSince(lastCheck)
            totalAccumulatedTime += timePassed
            saveAccumulatedTime()
            print("Added \(Int(timePassed)) seconds to accumulated time")
        }
        
        // Start a new timer session
        startTimer()
    }
    
    private func handleNewTimer() {
        print("User chose to start a new timer")
        
        // Clear notification badge
        clearNotificationBadge()
        
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
    }
    
    private func loadAccumulatedTime() {
        totalAccumulatedTime = UserDefaults.standard.object(forKey: "totalAccumulatedTime") as? TimeInterval ?? 0
    }
}

enum StatisticsPeriod {
    case today, thisWeek, lastWeek, thisMonth, total
}


