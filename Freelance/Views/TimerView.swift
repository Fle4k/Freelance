//
//  TimerView.swift
//  Freelance
//
//  Created by Shahin on 04.09.25.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject private var timeTracker = TimeTracker.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showingAddProject = false
    @State private var newProjectName = ""
    @State private var expandedProjectId: UUID?
    @State private var statisticsProjectId: UUID?
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
            
            // Show centered single timer or list with swipe actions based on project count
            if timeTracker.projects.count == 1, let project = timeTracker.projects.first {
                // Single timer - centered like original
                VStack(spacing: 0) {
                    Spacer()
                    ProjectTimerCard(
                        project: project,
                        isExpanded: expandedProjectId == project.id,
                        isAnyCardExpanded: expandedProjectId != nil || statisticsProjectId != nil,
                        onDetailToggle: {
                            // Allow collapsing if this card is expanded
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if expandedProjectId == project.id {
                                    expandedProjectId = nil
                                } else {
                                    // Only allow expanding if no other card is expanded
                                    if expandedProjectId == nil && statisticsProjectId == nil {
                                        expandedProjectId = project.id
                                        statisticsProjectId = nil
                                    }
                                }
                            }
                        },
                        onStatisticsToggle: {
                            // Allow collapsing if this card is expanded
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                if statisticsProjectId == project.id {
                                    statisticsProjectId = nil
                                } else {
                                    // Only allow expanding if no other card is expanded
                                    if expandedProjectId == nil && statisticsProjectId == nil {
                                        statisticsProjectId = project.id
                                        expandedProjectId = nil
                                    }
                                }
                            }
                        }
                    )
                    
                    // Inline detail view when expanded
                    if expandedProjectId == project.id {
                        ProjectDetailView(project: project)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                    
                    // Statistics view when menu button is tapped (dropdown below card)
                    if statisticsProjectId == project.id {
                        StatisticsOverviewView()
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, themeManager.spacing.small)
                            .padding(.vertical, themeManager.spacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.cornerRadius.large)
                                    .fill(Color.clear)
                            )
                            .padding(.top, 12)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .top)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            ))
                    }
                    
                    Spacer()
                }
            } else {
                // Multiple timers - restructured for sticky card when expanded
                if let expandedId = expandedProjectId,
                   let expandedProject = timeTracker.projects.first(where: { $0.id == expandedId }) {
                    // Show expanded card in fixed VStack (sticky) - no List scrolling
                    VStack(spacing: 0) {
                        ProjectTimerCard(
                            project: expandedProject,
                            isExpanded: true,
                            isAnyCardExpanded: true,
                            onDetailToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                    expandedProjectId = nil
                                }
                            },
                            onStatisticsToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                    statisticsProjectId = expandedProject.id
                                    expandedProjectId = nil
                                }
                            }
                        )
                        .padding(.horizontal, themeManager.spacing.small)
                        .padding(.top, themeManager.spacing.small)
                        
                        // Detail view below the card - sticky header, scrollable days
                        ProjectDetailView(project: expandedProject)
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                } else if let statisticsId = statisticsProjectId,
                          let statisticsProject = timeTracker.projects.first(where: { $0.id == statisticsId }) {
                    // Show statistics card in fixed VStack (sticky)
                    VStack(spacing: 0) {
                        ProjectTimerCard(
                            project: statisticsProject,
                            isExpanded: false,
                            isAnyCardExpanded: true,
                            onDetailToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                    expandedProjectId = statisticsProject.id
                                    statisticsProjectId = nil
                                }
                            },
                            onStatisticsToggle: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                    statisticsProjectId = nil
                                }
                            }
                        )
                        .padding(.horizontal, themeManager.spacing.small)
                        .padding(.top, themeManager.spacing.small)
                        
                        // Statistics view below the card
                        StatisticsOverviewView()
                            .frame(maxWidth: .infinity)
                            .frame(height: 600)
                            .padding(.horizontal, themeManager.spacing.small)
                            .padding(.vertical, themeManager.spacing.small)
                            .background(
                                RoundedRectangle(cornerRadius: themeManager.cornerRadius.large)
                                    .fill(Color.clear)
                            )
                            .padding(.top, 12)
                            .transition(.opacity)
                    }
                } else {
                    // Show all cards in scrollable List when nothing is expanded
                    ScrollViewReader { proxy in
                        List {
                            ForEach(timeTracker.projects) { project in
                                VStack(spacing: 0) {
                                    ProjectTimerCard(
                                        project: project,
                                        isExpanded: false,
                                        isAnyCardExpanded: false,
                                        onDetailToggle: {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                                expandedProjectId = project.id
                                                statisticsProjectId = nil
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                                    proxy.scrollTo(project.id, anchor: .top)
                                                }
                                            }
                                        },
                                        onStatisticsToggle: {
                                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0.25)) {
                                                statisticsProjectId = project.id
                                                expandedProjectId = nil
                                            }
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                                    proxy.scrollTo(project.id, anchor: .top)
                                                }
                                            }
                                        }
                                    )
                                }
                                .fixedSize(horizontal: false, vertical: true)
                                .id(project.id)
                                .listRowInsets(EdgeInsets(
                                    top: 8,
                                    leading: 0,
                                    bottom: 8,
                                    trailing: 0
                                ))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        timeTracker.deleteProject(project)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .listRowSeparator(.hidden)
                        .listRowSeparatorTint(.clear)
                    }
                }
            }
            
            // Bottom button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    // Add project button (bottom right)
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
                    .padding(.trailing, themeManager.spacing.medium)
                    .padding(.bottom, themeManager.spacing.medium)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .alert("new project", isPresented: $showingAddProject) {
            TextField("project name", text: $newProjectName)
            Button("cancel", role: .cancel) {
                newProjectName = ""
            }
            Button("create") {
                let trimmedName = newProjectName.trimmingCharacters(in: .whitespaces)
                // Allow creating projects with empty names
                timeTracker.createProject(name: trimmedName)
                newProjectName = ""
            }
        } message: {
            Text("enter a name for your new project (optional)")
        }
    }
}

#Preview {
    TimerView()
}
