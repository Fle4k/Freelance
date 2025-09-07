//
//  Models.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import Foundation
import SwiftUI

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
    }
    
    private func loadSettings() {
        hourlyRate = UserDefaults.standard.object(forKey: "hourlyRate") as? Double ?? 80.0
        deadManSwitchEnabled = UserDefaults.standard.object(forKey: "deadManSwitchEnabled") as? Bool ?? true
        deadManSwitchInterval = UserDefaults.standard.object(forKey: "deadManSwitchInterval") as? Double ?? 10.0
        motionDetectionEnabled = UserDefaults.standard.object(forKey: "motionDetectionEnabled") as? Bool ?? false
        motionThreshold = UserDefaults.standard.object(forKey: "motionThreshold") as? Double ?? 5.0
        askWhenMoving = UserDefaults.standard.object(forKey: "askWhenMoving") as? Bool ?? true
    }
}

// Time tracking manager
class TimeTracker: ObservableObject {
    @Published var isRunning = false
    @Published var currentSessionStart: Date?
    @Published var timeEntries: [TimeEntry] = []
    @Published var elapsedTime: TimeInterval = 0
    
    static let shared = TimeTracker()
    
    private init() {
        loadTimeEntries()
        loadCurrentSession()
    }
    
    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = Int(elapsedTime) % 3600 / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%dh%02dm%02ds", hours, minutes, seconds)
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
        if currentSessionStart == nil {
            currentSessionStart = Date()
            elapsedTime = 0
        }
        isRunning = true
        saveCurrentSession()
    }
    
    func pauseTimer() {
        isRunning = false
        saveCurrentSession()
    }
    
    func recordTimer() {
        guard let startDate = currentSessionStart else { return }
        
        let entry = TimeEntry(
            startDate: startDate,
            endDate: Date(),
            isActive: false
        )
        
        timeEntries.append(entry)
        currentSessionStart = nil
        isRunning = false
        elapsedTime = 0
        
        saveTimeEntries()
        clearCurrentSession()
    }
    
    func updateElapsedTime() {
        if let startDate = currentSessionStart, isRunning {
            elapsedTime = Date().timeIntervalSince(startDate)
        }
    }
    
    // MARK: - Statistics
    
    func getTotalHours(for period: StatisticsPeriod) -> Double {
        let calendar = Calendar.current
        let now = Date()
        
        var entries: [TimeEntry]
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            entries = timeEntries.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
            
        case .thisWeek:
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            entries = timeEntries.filter { $0.startDate >= startOfWeek && $0.startDate < endOfWeek }
            
        case .lastWeek:
            let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
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
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
                shouldInclude = currentStart >= startOfWeek && currentStart < endOfWeek
            case .lastWeek:
                let startOfThisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
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
}

enum StatisticsPeriod {
    case today, thisWeek, lastWeek, thisMonth, total
}
