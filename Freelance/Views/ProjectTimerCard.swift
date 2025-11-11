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
    let isExpanded: Bool
    let isAnyCardExpanded: Bool
    let onDetailToggle: () -> Void
    let onStatisticsToggle: (() -> Void)?
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var motionManager = MotionManager()
    @State private var showingResetAlert = false
    @State private var showingRemoveConfirmation = false
    @State private var showingRenameAlert = false
    @State private var newProjectName = ""
    @State private var isPressed = false
    @State private var timerTick = 0
    @State private var detailButtonAppeared = false
    
    private let longPressDuration: Double = 0.8
    
    // Simple timer display using TimeTracker's method
    private var formattedTime: String {
        _ = timerTick // Force update dependency
        return timeTracker.formattedElapsedTime(for: project)
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                // Project title above the card
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
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, themeManager.spacing.medium)
                }
                
                ZStack(alignment: .trailing) {
                    // Timer display in card (tappable area)
                    HStack {
                Text(formattedTime)
                    .font(.custom("Major Mono Display Regular", size: 36))
                    .textCase(nil)
                    .foregroundColor(project.isRunning ? .primary : .secondary)
                    .monospacedDigit()
                    .animation(.easeInOut(duration: 0.2), value: project.isRunning)
                            .frame(maxWidth: .infinity)
                        
                        // Spacer for button area
                        Spacer()
                            .frame(width: 44)
                    }
                    .padding(.vertical, 32)
                    .padding(.horizontal, themeManager.spacing.medium)
            .themedSectionBackground()
            .clipShape(Capsule())
            .opacity(project.isRunning ? 1.0 : 0.6)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .brightness(isPressed ? 0.1 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .contentShape(Capsule())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                if !isPressed {
                                    isPressed = true
                                    
                                    // Haptic feedback instantly on press for start/restart
                                    if !project.isRunning && !isAnyCardExpanded {
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                        impactFeedback.impactOccurred()
                                    }
                                }
                            }
                            .onEnded { _ in
                                isPressed = false
                
                                // Prevent timer toggle if any card is expanded
                                guard !isAnyCardExpanded else { return }
                                
                                // Haptic feedback on release for pause
                                if project.isRunning {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                }
                                
                                // Toggle timer
                                if project.isRunning {
                                    timeTracker.pauseTimer(for: project.id)
                                } else {
                                    timeTracker.startTimer(for: project.id)
                                }
                            }
                    )
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: longPressDuration).onEnded { _ in
                // Warning haptic feedback for long press (reset action)
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.warning)
                showingResetAlert = true
                        }
                    )
                    
                    // Detail button with ellipsis rotated 90° with animation (separate tappable area)
                    // Using high priority gesture to ensure it receives touches above the capsule
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(detailButtonAppeared ? (project.isRunning ? .primary : .secondary) : .white)
                        .symbolEffect(.bounce, value: detailButtonAppeared)
                        .rotationEffect(.degrees(90))
                        .frame(width: 44, height: 44)
                        .opacity(detailButtonAppeared ? 0.6 : 1.0)
                        .contentShape(Rectangle())
                        .padding(.trailing, themeManager.spacing.medium)
                        .zIndex(10)
                        .highPriorityGesture(
                            TapGesture().onEnded {
                                if let onStatisticsToggle = onStatisticsToggle {
                                    onStatisticsToggle()
                                } else {
                                    onDetailToggle()
                                }
                            }
                        )
                        .onAppear {
                            // Trigger bounce and color fade
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    detailButtonAppeared = true
                                }
                            }
                        }
                }
                .padding(.horizontal, themeManager.spacing.small)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: project.name.isEmpty ? 112 : 130)
        .alert("reset timer", isPresented: $showingResetAlert) {
            Button("store and reset") {
                timeTracker.recordTimer(for: project.id)
            }
            Button("reset", role: .destructive) {
                timeTracker.resetTimer(for: project.id)
            }
            Button("cancel", role: .cancel) { }
        } message: {
            Text("store time and start a new session or reset without storing?")
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
            timerTick += 1
        }
    }
}

#Preview {
    ProjectTimerCard(
        project: Project(
            name: "sample project",
            timeEntries: [],
            isRunning: false,
            totalAccumulatedTime: 3600
        ),
        isExpanded: false,
        isAnyCardExpanded: false,
        onDetailToggle: {},
        onStatisticsToggle: {}
    )
    .padding()
}

