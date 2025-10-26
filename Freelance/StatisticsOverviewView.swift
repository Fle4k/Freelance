//
//  StatisticsOverviewView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI
import UIKit

struct FocusableTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let font: UIFont
    let shouldFocus: Bool
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.font = font
        textField.textAlignment = .center
        textField.keyboardType = .numberPad
        textField.backgroundColor = .clear
        textField.borderStyle = .none
        textField.delegate = context.coordinator
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        // Only update text if it's different to avoid unnecessary updates
        if uiView.text != text {
            uiView.text = text
        }
        
        if shouldFocus && !uiView.isFirstResponder {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                
                // If there's existing text, select it all for easy replacement
                if !text.isEmpty {
                    uiView.selectAll(nil)
                } else {
                    // Center the cursor by setting an empty selection
                    uiView.selectedTextRange = uiView.textRange(from: uiView.beginningOfDocument, to: uiView.beginningOfDocument)
                }
            }
        } else if !shouldFocus && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: FocusableTextField
        
        init(_ parent: FocusableTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let newText = (textField.text as NSString?)?.replacingCharacters(in: range, with: string) ?? string
            parent.text = newText
            return true
        }
    }
}

extension StatisticsPeriod {
    var displayName: String {
        switch self {
        case .today: return "today"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        case .thisMonth: return "this month"
        case .total: return "total"
        }
    }
}

struct StatisticsOverviewView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingUnifiedView = false
    @State private var showingSettings = false
    @Environment(\.dismiss) private var dismiss
    
    
    
    private func exportCSV(for period: StatisticsPeriod) {
        print("📊 Exporting CSV for \(period.displayName)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        let csvContent = generateCSVContent(for: period)
        let fileName = getCSVFileName(for: period)
        
        shareCSV(content: csvContent, fileName: fileName)
    }
    
    private func generateCSVContent(for period: StatisticsPeriod) -> String {
        let calendar = Calendar.current
        let now = Date()
        let settings = AppSettings.shared
        
        // Get time entries for the period
        var entries: [TimeEntry]
        
        switch period {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            entries = timeTracker.timeEntries.filter { $0.startDate >= startOfDay && $0.startDate < endOfDay }
            
        case .thisWeek:
            let startOfWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
            let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
            entries = timeTracker.timeEntries.filter { $0.startDate >= startOfWeek && $0.startDate < endOfWeek }
            
        case .thisMonth:
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            entries = timeTracker.timeEntries.filter { $0.startDate >= startOfMonth && $0.startDate < endOfMonth }
            
        case .lastWeek:
            let startOfThisWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
            let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
            entries = timeTracker.timeEntries.filter { $0.startDate >= startOfLastWeek && $0.startDate < startOfThisWeek }
            
        case .total:
            entries = timeTracker.timeEntries
        }
        
        // Include current session if it's running and falls within the period
        if let currentStart = timeTracker.currentSessionStart, timeTracker.isRunning {
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
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
                shouldInclude = currentStart >= startOfMonth && currentStart < endOfMonth
            case .lastWeek:
                let startOfThisWeek = getStartOfWeek(for: now, calendar: calendar, weekStartsOn: settings.weekStartsOn)
                let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfThisWeek)!
                shouldInclude = currentStart >= startOfLastWeek && currentStart < startOfThisWeek
            case .total:
                shouldInclude = true
            }
            
            if shouldInclude {
                entries.append(currentEntry)
            }
        }
        
        // Sort entries by start date
        entries.sort { $0.startDate < $1.startDate }
        
        // Create CSV content
        var csvLines: [String] = []
        
        // Header
        csvLines.append("Date,Start Time,End Time,Duration (Hours),Duration (Minutes),Earnings (€)")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = settings.timeFormat()
        
        for entry in entries {
            let date = dateFormatter.string(from: entry.startDate)
            let startTime = timeFormatter.string(from: entry.startDate)
            let endTime: String
            let duration: TimeInterval
            
            if let endDate = entry.endDate {
                endTime = timeFormatter.string(from: endDate)
                duration = endDate.timeIntervalSince(entry.startDate)
            } else {
                // Current running session
                endTime = "Running"
                duration = Date().timeIntervalSince(entry.startDate)
            }
            
            let durationHours = duration / 3600.0
            let durationMinutes = duration / 60.0
            let earnings = durationHours * settings.hourlyRate
            
            let line = "\(date),\(startTime),\(endTime),\(String(format: "%.2f", durationHours)),\(String(format: "%.0f", durationMinutes)),\(String(format: "%.2f", earnings))"
            csvLines.append(line)
        }
        
        // Add totals
        let totalDuration = entries.reduce(0) { $0 + $1.duration }
        let totalHours = totalDuration / 3600.0
        let totalMinutes = totalDuration / 60.0
        let totalEarnings = totalHours * settings.hourlyRate
        
        csvLines.append("")
        csvLines.append("Total,,,,\(String(format: "%.2f", totalHours)),\(String(format: "%.0f", totalMinutes)),\(String(format: "%.2f", totalEarnings))")
        
        return csvLines.joined(separator: "\n")
    }
    
    private func getCSVFileName(for period: StatisticsPeriod) -> String {
        let dateFormatter = DateFormatter()
        let now = Date()
        
        switch period {
        case .today:
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return "Freelance_Today_\(dateFormatter.string(from: now)).csv"
        case .thisWeek:
            dateFormatter.dateFormat = "yyyy-'W'ww"
            return "Freelance_Week_\(dateFormatter.string(from: now)).csv"
        case .thisMonth:
            dateFormatter.dateFormat = "yyyy-MM"
            return "Freelance_Month_\(dateFormatter.string(from: now)).csv"
        case .lastWeek:
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!
            dateFormatter.dateFormat = "yyyy-'W'ww"
            return "Freelance_LastWeek_\(dateFormatter.string(from: lastWeek)).csv"
        case .total:
            dateFormatter.dateFormat = "yyyy-MM-dd"
            return "Freelance_Total_\(dateFormatter.string(from: now)).csv"
        }
    }
    
    private func shareCSV(content: String, fileName: String) {
        // Create temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            
            // Present share sheet
            let activityViewController = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            
            // Get the root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {
                
                // Present from the top-most view controller
                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }
                
                // Configure for iPad
                if let popover = activityViewController.popoverPresentationController {
                    popover.sourceView = topController.view
                    popover.sourceRect = CGRect(x: topController.view.bounds.midX, y: topController.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                topController.present(activityViewController, animated: true)
            }
            
        } catch {
            print("Error creating CSV file: \(error)")
        }
    }
    
    private func getStartOfWeek(for date: Date, calendar: Calendar, weekStartsOn: Int) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        let daysFromStartOfWeek = (weekday - weekStartsOn + 7) % 7
        return calendar.date(byAdding: .day, value: -daysFromStartOfWeek, to: calendar.startOfDay(for: date)) ?? date
    }
    
    
    
    // MARK: - View Modifiers
    private var mainView: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    // Unified view is now accessed directly from menu button
                    // No cards needed here anymore
                    
                    Spacer()
                }
                .themedBackground()
                
                // Settings button at bottom
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        Divider()
                            .padding(.horizontal, 40)
                        
                        Button(action: {
                            showingSettings = true
                        }) {
                            Text("settings")
                                .font(.custom("Major Mono Display Regular", size: 18))
                                .foregroundColor(.primary)
                        }
                        .padding(.bottom, 24)
                    }
                }
            }
        }
        }
    
    var body: some View {
        UnifiedMonthView()
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                // Update timer display if running
                if timeTracker.isRunning {
                    timeTracker.updateElapsedTime()
                }
            }
            .onDisappear {
                settings.saveSettings()
            }
    }
}



#Preview {
    StatisticsOverviewView()
}
