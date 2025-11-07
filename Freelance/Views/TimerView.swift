//
//  TimerView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct ProgressCapsule: View {
    let progress: Double
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        ZStack {
            // Base subtle grey stroke
            Capsule()
                .trim(from: 0, to: progress)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                .frame(width: width, height: height)
            
            // Shiny effect overlay with dissolve near the end
            Capsule()
                .trim(from: max(0, progress - 0.15), to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.6 * shineOpacity),
                            Color.white.opacity(0.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
                .frame(width: width, height: height)
        }
    }
    
    private var shineOpacity: Double {
        // Fade out the shine when progress > 0.85
        if progress > 0.85 {
            return max(0, (1.0 - progress) / 0.15)
        }
        return 1.0
    }
}

struct TimerView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingStatistics = false
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Background matching statistics view
            Color.clear
                .themedBackground()
                .ignoresSafeArea()
            
            // White particles (always visible, behavior changes based on any running timer)
            TimerParticleView(isActive: timeTracker.projects.contains(where: { $0.isRunning }))
                .ignoresSafeArea()
            
            // Show centered single timer or scrollable list based on project count
            if timeTracker.projects.count == 1, let project = timeTracker.projects.first {
                // Single timer - centered like original
                VStack {
                    Spacer()
                    ProjectTimerCard(project: project)
                    Spacer()
                }
            } else {
                // Multiple timers - scrollable list
                ScrollView {
                    VStack(spacing: themeManager.spacing.large) {
                        ForEach(timeTracker.projects) { project in
                            ProjectTimerCard(project: project)
                        }
                    }
                    .padding(.vertical, themeManager.spacing.contentHorizontal)
                }
            }
            
            // Bottom buttons
            VStack {
                Spacer()
                HStack {
                    // Add project button (bottom left)
                    Button(action: {
                        showingAddProject = true
                    }) {
                        ZStack {
                            Color.clear
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                    .modifier(GlassButtonModifier(
                        isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                        size: 64
                    ))
                    .contentShape(Circle())
                    .padding(.leading, themeManager.spacing.medium)
                    .padding(.bottom, themeManager.spacing.medium)
                    
                    Spacer()
                    
                    // Menu button (bottom right)
                    Button(action: {
                        showingStatistics = true
                    }) {
                        ZStack {
                            Color.clear
                                .frame(width: 64, height: 64)
                            
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 20, weight: .regular))
                                .foregroundColor(.primary)
                        }
                    }
                    .modifier(GlassButtonModifier(
                        isLiquidGlass: themeManager.currentTheme == .liquidGlass,
                        size: 64
                    ))
                    .contentShape(Circle())
                    .padding(.trailing, themeManager.spacing.medium)
                    .padding(.bottom, themeManager.spacing.medium)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsOverviewView()
        }
        .alert("new project", isPresented: $showingAddProject) {
            TextField("project name", text: $newProjectName)
            Button("cancel", role: .cancel) {
                newProjectName = ""
            }
            Button("create") {
                let trimmedName = newProjectName.trimmingCharacters(in: .whitespaces)
                if !trimmedName.isEmpty {
                    timeTracker.createProject(name: trimmedName)
                }
                newProjectName = ""
            }
        } message: {
            Text("enter a name for your new project")
        }
    }
}

#Preview {
    TimerView()
}
