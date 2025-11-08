//
//  ProjectTimerCard.swift
//  Freelance
//
//  Created for multi-project support
//

import SwiftUI
import CoreMotion

// Motion manager for gyroscope-based shadow
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var shadowOffset: CGSize = .zero
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        motionManager.deviceMotionUpdateInterval = 1/60
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion else { return }
            
            // Use attitude to create shadow offset
            // Multiply by -50 to create more distance and dramatic 3D effect
            let x = CGFloat(motion.attitude.roll) * -50
            let y = CGFloat(motion.attitude.pitch) * -50
            
            self?.shadowOffset = CGSize(width: x, height: y)
        }
    }
    
    func stopMonitoring() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    deinit {
        stopMonitoring()
    }
}

struct ProjectTimerCard: View {
    let project: Project
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var motionManager = MotionManager()
    @State private var showingResetAlert = false
    @State private var showingRemoveConfirmation = false
    @State private var showingRenameAlert = false
    @State private var newProjectName = ""
    @State private var isPressed = false
    @State private var elapsedTime: TimeInterval = 0
    
    private let longPressDuration: Double = 0.8
    
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
            VStack(spacing: project.name.isEmpty ? 0 : 12) {
                // Project title inside the capsule
                if !project.name.isEmpty {
                    Text(project.name)
                        .font(.custom("Major Mono Display Regular", size: 17))
                        .textCase(nil)
                        .foregroundColor(project.isRunning ? .primary : .secondary)
                        .shadow(
                            color: Color.black.opacity(0.9),
                            radius: 15,
                            x: motionManager.shadowOffset.width,
                            y: motionManager.shadowOffset.height
                        )
                        .shadow(
                            color: Color.black.opacity(0.6),
                            radius: 8,
                            x: motionManager.shadowOffset.width * 0.5,
                            y: motionManager.shadowOffset.height * 0.5
                        )
                        .onTapGesture {
                            newProjectName = project.name
                            showingRenameAlert = true
                        }
                }
                
                // Timer display
                Text(formattedTime)
                    .font(.custom("Major Mono Display Regular", size: 36))
                    .textCase(nil)
                    .foregroundColor(project.isRunning ? .primary : .secondary)
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.2), value: project.isRunning)
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.horizontal, themeManager.spacing.xLarge)
            .padding(.top, project.name.isEmpty ? 32 : 16)
            .padding(.bottom, project.name.isEmpty ? 32 : 16)
            .themedSectionBackground()
            .clipShape(Capsule())
            .opacity(project.isRunning ? 1.0 : 0.6)
            .padding(.horizontal, themeManager.spacing.contentHorizontal)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? 0.1 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .contentShape(Capsule())
            .onTapGesture {
                // Stronger haptic feedback for tap
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                // Toggle timer
                if project.isRunning {
                    timeTracker.pauseTimer(for: project.id)
                } else {
                    timeTracker.startTimer(for: project.id)
                }
            }
            .onLongPressGesture(minimumDuration: longPressDuration) {
                // Warning haptic feedback for long press (reset action)
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
                showingResetAlert = true
            } onPressingChanged: { pressing in
                isPressed = pressing
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: project.name.isEmpty ? 112 : 120)
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
    }
}

