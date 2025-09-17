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
        uiView.text = text
        
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
                        Button("reset", role: .destructive) {
                            resetTime(for: .thisMonth)
                        }
                    }
                }
    
    // MARK: - View Modifiers
    private var mainView: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                // Overview Page
                    VStack(spacing: 20) {
                    todayCard
                    
                    weekCard
                    
                    monthCard
                    }
                    .padding(.horizontal, 40)
                .padding(.bottom, 40)
                
                // Settings section
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
                    .padding(.bottom, 10)
                }
                
                Spacer()
            }
            .background(Color(.systemBackground))
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
            .onDisappear {
                settings.saveSettings()
                TimeTracker.shared.restartDeadManSwitch()
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