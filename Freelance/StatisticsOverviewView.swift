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
    @State private var showingTodayDetail = false
    @State private var showingWeekDetail = false
    @State private var showingMonthDetail = false
    @State private var showingSettings = false
    // Unified edit state
    @State private var showingEditSheet = false
    @State private var editingPeriod: StatisticsPeriod = .today
    @State private var showingResetConfirmation = false
    @State private var resettingPeriod: StatisticsPeriod = .today
    @Environment(\.dismiss) private var dismiss
    
    
    private func copyTime(for period: StatisticsPeriod) {
        TimeTracker.shared.copyTime(for: period)
    }
    
    private func editTime(for period: StatisticsPeriod) {
        print("🔧 editTime called for period: \(period)")
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        editingPeriod = period
        showingEditSheet = true
    }
    
    private func resetTime(for period: StatisticsPeriod) {
        resettingPeriod = period
        showingResetConfirmation = true
    }
    
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
    
    // MARK: - Card Views
    private var todayCard: some View {
                    Button(action: {
                        showingTodayDetail = true
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
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .today)
                        }
                        Button("edit") {
                            editTime(for: .today)
                        }
                        Button("export csv") {
                            exportCSV(for: .today)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .today)
            }
                        }
                    }
                    
    private var weekCard: some View {
                    Button(action: {
                        showingWeekDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this week")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                ProportionalTimeDisplay(
                    timeString: timeTracker.formattedTimeHMS(for: .thisWeek),
                    digitFontSize: 20
                )
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisWeek)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .thisWeek)
                        }
                        Button("edit") {
                            editTime(for: .thisWeek)
                        }
                        Button("export csv") {
                            exportCSV(for: .thisWeek)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .thisWeek)
            }
                        }
                    }
                    
    private var monthCard: some View {
                    Button(action: {
                        showingMonthDetail = true
                    }) {
                        VStack(spacing: 10) {
                        Text("this month")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.secondary)
                        
                ProportionalTimeDisplay(
                    timeString: timeTracker.formattedTimeHMS(for: .thisMonth),
                    digitFontSize: 20
                )
                            
                            Text(String(format: "%.0f€", timeTracker.getEarnings(for: .thisMonth)))
                                .font(.custom("Major Mono Display Regular", size: 20))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
            .frame(minHeight: 80)
            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contextMenu {
                        Button("copy") {
                            copyTime(for: .thisMonth)
                        }
                        Button("edit") {
                            editTime(for: .thisMonth)
                        }
                        Button("export csv") {
                            exportCSV(for: .thisMonth)
                        }
                        Button("reset", role: .destructive) {
                            resetTime(for: .thisMonth)
                        }
                    }
                }
    
    
    // MARK: - View Modifiers
    private var mainView: some View {
        GeometryReader { geometry in
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    Spacer(minLength: 40)
                    
                    // Current timer display (if running)
                    if timeTracker.isRunning {
                        VStack(spacing: 8) {
                            Text("current session")
                                .font(.custom("Major Mono Display Regular", size: 14))
                                .foregroundColor(.secondary)
                            
                            ProportionalTimeDisplay(
                                timeString: timeTracker.formattedElapsedTime,
                                digitFontSize: 24
                            )
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    }
                    
                    // Overview Page
                    VStack(spacing: 20) {
                        todayCard
                        
                        weekCard
                        
                        monthCard
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                    
                    Spacer()
                }
                .background(Color(.systemBackground))
                
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
    
    
    private func confirmReset() {
        TimeTracker.shared.resetTime(for: resettingPeriod)
        showingResetConfirmation = false
    }
    
    
    
    var body: some View {
        mainView
            .blur(radius: (showingTodayDetail || showingWeekDetail || showingMonthDetail || showingSettings || showingEditSheet) ? 3 : 0)
            .animation(.easeInOut(duration: 0.2), value: showingTodayDetail || showingWeekDetail || showingMonthDetail || showingSettings || showingEditSheet)
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                // Update timer display if running
                if timeTracker.isRunning {
                    timeTracker.updateElapsedTime()
                }
            }
            .onDisappear {
                settings.saveSettings()
            }
        .sheet(isPresented: $showingTodayDetail) {
            TodayDetailView()
        }
        .sheet(isPresented: $showingWeekDetail) {
            WeekDetailView()
        }
        .sheet(isPresented: $showingMonthDetail) {
            MonthDetailView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .presentationDetents([.height(450), .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog("reset \(resettingPeriod.displayName)", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
            Button("reset", role: .destructive) {
                confirmReset()
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text("are you sure you want to reset \(resettingPeriod.displayName)? this will permanently delete all time data for this period.")
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTimeSheet(
                period: editingPeriod,
                currentTime: timeTracker.formattedTimeHMS(for: editingPeriod),
                isPresented: $showingEditSheet,
                customTitle: getCustomTitle(for: editingPeriod)
            )
        }
    }
}



#Preview {
    StatisticsOverviewView()
}
