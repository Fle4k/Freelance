//
//  StatisticsOverviewView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

extension StatisticsPeriod {
    var displayName: String {
        switch self {
        case .today: return "today"
        case .thisWeek: return "this week"
        case .lastWeek: return "last week"
        }
    }
}

struct StatisticsOverviewView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var settings = AppSettings.shared
    @State private var showingDailyStats = false
    @State private var selectedPeriod: StatisticsPeriod = .today
    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss
    
    private let periods: [StatisticsPeriod] = [.today, .thisWeek, .lastWeek]
    
    init() {
        // Load persisted selected period
        if let savedPeriodRaw = UserDefaults.standard.object(forKey: "selectedPeriod") as? String {
            switch savedPeriodRaw {
            case "today": 
                _selectedPeriod = State(initialValue: .today)
                _currentIndex = State(initialValue: 0)
            case "thisWeek": 
                _selectedPeriod = State(initialValue: .thisWeek)
                _currentIndex = State(initialValue: 1)
            case "lastWeek": 
                _selectedPeriod = State(initialValue: .lastWeek)
                _currentIndex = State(initialValue: 2)
            default: 
                _selectedPeriod = State(initialValue: .today)
                _currentIndex = State(initialValue: 0)
            }
        } else {
            _selectedPeriod = State(initialValue: .today)
            _currentIndex = State(initialValue: 0)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Spacer()
                        
                        Text("statistics")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    Spacer(minLength: 30)
                    
                    VStack(spacing: 30) {
                        // Always show total time and earnings
                        VStack(spacing: 15) {
                            HStack {
                                Text("total time")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(timeTracker.formattedTotalTime(for: .today))
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                            }
                            
                            HStack {
                                Text("total earnings")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(String(format: "%.0f euro", timeTracker.getEarnings(for: .today)))
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        // Time periods with chart interaction
                        VStack(spacing: 20) {
                            Button(action: { 
                                withAnimation {
                                    currentIndex = 0
                                    selectedPeriod = periods[currentIndex]
                                }
                                saveSelectedPeriod()
                            }) {
                                StatisticRow(
                                    title: "today",
                                    value: timeTracker.formattedTotalTime(for: .today),
                                    unit: ""
                                )
                            }
                            .foregroundColor(.primary)
                            
                            Button(action: { 
                                withAnimation {
                                    currentIndex = 1
                                    selectedPeriod = periods[currentIndex]
                                }
                                saveSelectedPeriod()
                            }) {
                                StatisticRow(
                                    title: "this week",
                                    value: String(format: "%.0f", timeTracker.getTotalHours(for: .thisWeek)),
                                    unit: "h"
                                )
                            }
                            .foregroundColor(.primary)
                            
                            Button(action: { 
                                withAnimation {
                                    currentIndex = 2
                                    selectedPeriod = periods[currentIndex]
                                }
                                saveSelectedPeriod()
                            }) {
                                StatisticRow(
                                    title: "last week",
                                    value: String(format: "%.0f", timeTracker.getTotalHours(for: .lastWeek)),
                                    unit: "h"
                                )
                            }
                            .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 40)
                        
                        // Chart carousel (always visible with fixed size)
                        Divider()
                            .padding(.horizontal, 40)
                        
                        TabView(selection: $currentIndex) {
                            ForEach(0..<periods.count, id: \.self) { index in
                                ChartView(period: periods[index])
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        .frame(height: 160)
                        .onChange(of: currentIndex) { newIndex in
                            selectedPeriod = periods[newIndex]
                            saveSelectedPeriod()
                        }
                        
                        Spacer(minLength: 40)
                    }
                    
                    // Settings at the bottom
                    VStack(spacing: 20) {
                        Divider()
                            .padding(.horizontal, 40)
                        
                        Text("settings")
                            .font(.custom("Major Mono Display Regular", size: 18))
                            .foregroundColor(.primary)
                            .padding(.bottom, 10)
                        
                        VStack(spacing: 20) {
                            // Dead Man Switch
                            VStack(spacing: 8) {
                                HStack {
                                    Text("check in every")
                                        .font(.custom("Major Mono Display Regular", size: 17))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        settings.deadManSwitchEnabled.toggle()
                                    }) {
                                        Text("\(Int(settings.deadManSwitchInterval))min")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(settings.deadManSwitchEnabled ? .primary : .secondary)
                                    }
                                }
                            }
                            
                            // Motion Detection
                            VStack(spacing: 8) {
                                HStack {
                                    Text("ask when i")
                                        .font(.custom("Major Mono Display Regular", size: 17))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        settings.askWhenMoving.toggle()
                                    }) {
                                        Text(settings.askWhenMoving ? "move" : "don't move")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(.primary)
                                    }
                                }
                                
                                HStack {
                                    Text("longer than")
                                        .font(.custom("Major Mono Display Regular", size: 17))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        settings.motionDetectionEnabled.toggle()
                                    }) {
                                        Text("\(Int(settings.motionThreshold))min")
                                            .font(.custom("Major Mono Display Regular", size: 17))
                                            .foregroundColor(settings.motionDetectionEnabled ? .primary : .secondary)
                                    }
                                }
                            }
                            
                            // Salary Setting
                            HStack {
                                Text("salary")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                                            HStack(spacing: 0) {
                                TextField("80", value: $settings.hourlyRate, format: .number)
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: 60)
                                
                                Text("/H")
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.primary)
                            }
                            }
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .onDisappear {
            settings.saveSettings()
        }
    }
    
    private func saveSelectedPeriod() {
        let periodString: String
        switch selectedPeriod {
        case .today: periodString = "today"
        case .thisWeek: periodString = "thisWeek"
        case .lastWeek: periodString = "lastWeek"
        }
        UserDefaults.standard.set(periodString, forKey: "selectedPeriod")
    }
}

struct ChartView: View {
    let period: StatisticsPeriod
    
    var body: some View {
        VStack(spacing: 0) {
            // Chart title at top
            Text("chart for \(period.displayName)")
                .font(.custom("Major Mono Display Regular", size: 17))
                .foregroundColor(.secondary)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            Spacer()
            
            // Chart bars with day labels for week views
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(0..<7) { index in
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.primary.opacity(0.3))
                                .frame(width: 2, height: getBarHeight(for: index))
                            
                            if period == .thisWeek || period == .lastWeek {
                                Text(getDayLabel(for: index))
                                    .font(.custom("Major Mono Display Regular", size: 17))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if index < 6 {
                            Spacer()
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
    }
    
    private func getBarHeight(for index: Int) -> CGFloat {
        // Static heights for consistent display (no animation)
        let heights: [CGFloat] = [45, 25, 60, 30, 40, 55, 20]
        return heights[index]
    }
    
    private func getDayLabel(for index: Int) -> String {
        let labels = ["m", "d", "m", "d", "f", "s", "s"]
        return labels[index]
    }
}

struct StatisticRow: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(title)
                                                    .font(.custom("Major Mono Display Regular", size: 17))
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                                                        .font(.custom("Major Mono Display Regular", size: 17))
                    .foregroundColor(.primary)
                
                Text(unit)
                    .font(.custom("Major Mono Display Regular", size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    StatisticsOverviewView()
}
