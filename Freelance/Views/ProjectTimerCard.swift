//
//  ProjectTimerCard.swift
//  Freelance
//
//  Created for multi-project support
//

import SwiftUI

struct ProjectTimerCard: View {
    let project: Project
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingResetAlert = false
    @State private var showingRemoveConfirmation = false
    @State private var showingRenameAlert = false
    @State private var newProjectName = ""
    @State private var longPressProgress: Double = 0.0
    @State private var isLongPressing = false
    @State private var longPressTimer: Timer?
    @State private var isTapped = false
    @State private var elapsedTime: TimeInterval = 0
    
    private let longPressDuration: Double = 0.8
    private let progressDelay: Double = 0.2
    
    // Computed property to format the elapsed time display
    private var formattedTime: String {
        let totalTime = project.totalAccumulatedTime + (project.isRunning ? elapsedTime : 0)
        let hours = Int(totalTime) / 3600
        let minutes = Int(totalTime) % 3600 / 60
        let seconds = Int(totalTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Project title above the capsule
                if !project.name.isEmpty {
                    Text(project.name)
                        .font(.custom("Major Mono Display Regular", size: 17))
                        .textCase(nil)
                        .foregroundColor(project.isRunning ? .primary : .secondary)
                        .onTapGesture {
                            newProjectName = project.name
                            showingRenameAlert = true
                        }
                }
                
                // Timer display capsule
                VStack(spacing: 8) {
                    Text(formattedTime)
                        .font(.custom("Major Mono Display Regular", size: 36))
                        .textCase(nil)
                        .foregroundColor(project.isRunning ? .primary : .secondary)
                        .monospacedDigit()
                        .animation(.easeInOut(duration: 0.2), value: project.isRunning)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, themeManager.spacing.xLarge)
                .padding(.vertical, 32)
                .themedSectionBackground()
                .clipShape(Capsule())
                .opacity(project.isRunning ? 1.0 : 0.6)
                .overlay(
                    Group {
                        if isLongPressing && longPressProgress > 0 {
                            ProgressCapsule(
                                progress: longPressProgress,
                                width: geometry.size.width - (themeManager.spacing.contentHorizontal * 2),
                                height: 112
                            )
                        }
                    }
                )
                .padding(.horizontal, themeManager.spacing.contentHorizontal)
                .scaleEffect(isTapped ? 0.95 : 1.0)
                .opacity(isTapped ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isTapped)
                .contentShape(Capsule())
                .onTapGesture {
                    if project.isRunning {
                        timeTracker.pauseTimer(for: project.id)
                    } else {
                        timeTracker.startTimer(for: project.id)
                    }
                }
                .onLongPressGesture(minimumDuration: longPressDuration) {
                    // Long press completed - show reset alert
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    showingResetAlert = true
                } onPressingChanged: { pressing in
                    isTapped = pressing
                    if pressing {
                        isLongPressing = true
                        startLongPress()
                    } else {
                        endLongPress()
                        if longPressProgress < 1.0 {
                            isLongPressing = false
                            longPressProgress = 0.0
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: project.name.isEmpty ? 112 : 140)
        .alert("reset timer", isPresented: $showingResetAlert) {
            Button("store and reset") {
                timeTracker.recordTimer(for: project.id)
            }
            Button("reset", role: .destructive) {
                timeTracker.resetTimer(for: project.id)
            }
            Button("remove", role: .destructive) {
                showingRemoveConfirmation = true
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text("store time and start a new session, reset without storing, or remove project?")
        }
        .alert("rename project", isPresented: $showingRenameAlert) {
            TextField("project name", text: $newProjectName)
            Button("cancel", role: .cancel) {
                newProjectName = ""
            }
            Button("save") {
                let trimmedName = newProjectName.trimmingCharacters(in: .whitespaces)
                if !trimmedName.isEmpty {
                    timeTracker.renameProject(project, to: trimmedName)
                }
                newProjectName = ""
            }
        } message: {
            Text("enter a new name for the project")
        }
        .alert("remove project", isPresented: $showingRemoveConfirmation) {
            Button("cancel", role: .cancel) { }
            Button("remove", role: .destructive) {
                timeTracker.deleteProject(project)
            }
        } message: {
            Text("are you sure you want to remove this project? all time entries will be deleted.")
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if project.isRunning {
                elapsedTime = timeTracker.getElapsedTime(for: project)
            } else {
                elapsedTime = 0
            }
        }
        .onDisappear {
            longPressTimer?.invalidate()
            longPressTimer = nil
        }
    }
    
    private func startLongPress() {
        longPressProgress = 0.0
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: progressDelay, repeats: false) { _ in
            self.isLongPressing = true
            self.animateProgress()
        }
    }
    
    private func animateProgress() {
        let startTime = Date()
        
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            let elapsed = Date().timeIntervalSince(startTime)
            let normalizedTime = min(elapsed / self.longPressDuration, 1.0)
            let easedProgress = normalizedTime * normalizedTime
            self.longPressProgress = easedProgress
            
            if normalizedTime >= 1.0 {
                timer.invalidate()
                self.longPressTimer = nil
                self.longPressProgress = 1.0
            }
        }
    }
    
    private func endLongPress() {
        longPressTimer?.invalidate()
        longPressTimer = nil
        
        if longPressProgress < 1.0 {
            isLongPressing = false
            longPressProgress = 0.0
        }
    }
}

