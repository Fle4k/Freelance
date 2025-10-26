//
//  ThemeModifiers.swift
//  Freelance
//
//  Created by Theme System
//

import SwiftUI

// MARK: - Themed Background Modifier

struct ThemedBackgroundModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        if themeManager.useMaterialBackground {
            content
                .background(themeManager.backgroundMaterial)
        } else {
            content
                .background(Color(.systemBackground))
        }
    }
}

// MARK: - Themed Card Modifier

struct ThemedCardModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    let padding: CGFloat
    
    init(padding: CGFloat = 16) {
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        if themeManager.currentTheme == .liquidGlass {
            content
                .padding(padding)
                .background(themeManager.ultraThinMaterial)
                .cornerRadius(themeManager.cornerRadius.large)
                .shadow(
                    color: Color.primary.opacity(themeManager.shadow.opacity),
                    radius: themeManager.shadow.radius,
                    x: 0,
                    y: 4
                )
        } else {
            content
                .padding(padding)
                .background(Color(.systemBackground))
                .cornerRadius(themeManager.cornerRadius.medium)
        }
    }
}

// MARK: - Themed Section Background Modifier

struct ThemedSectionBackgroundModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        if themeManager.currentTheme == .liquidGlass {
            content
                .background(themeManager.thinMaterial)
        } else {
            content
                .background(Color(.systemBackground))
        }
    }
}

// MARK: - Themed Button Modifier

struct ThemedButtonModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    let style: ButtonStyleType
    
    enum ButtonStyleType {
        case primary
        case secondary
    }
    
    func body(content: Content) -> some View {
        if themeManager.currentTheme == .liquidGlass {
            content
                .padding(.horizontal, themeManager.spacing.medium)
                .padding(.vertical, themeManager.spacing.itemSpacing)
                .background(themeManager.ultraThinMaterial)
                .cornerRadius(themeManager.cornerRadius.medium)
                .shadow(
                    color: Color.primary.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        } else {
            content
                .padding(.horizontal, themeManager.spacing.medium)
                .padding(.vertical, themeManager.spacing.itemSpacing)
        }
    }
}

// MARK: - Themed List Row Modifier

struct ThemedListRowModifier: ViewModifier {
    @ObservedObject var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        if themeManager.currentTheme == .liquidGlass {
            content
                .padding(.vertical, themeManager.spacing.itemSpacing)
                .background(
                    RoundedRectangle(cornerRadius: themeManager.cornerRadius.medium)
                        .fill(themeManager.ultraThinMaterial)
                        .shadow(
                            color: Color.primary.opacity(0.03),
                            radius: 2,
                            x: 0,
                            y: 1
                        )
                )
        } else {
            content
                .padding(.vertical, themeManager.spacing.itemSpacing)
        }
    }
}

// MARK: - SwiftUI View Extensions

extension View {
    func themedBackground() -> some View {
        modifier(ThemedBackgroundModifier())
    }
    
    func themedCard(padding: CGFloat = 16) -> some View {
        modifier(ThemedCardModifier(padding: padding))
    }
    
    func themedSectionBackground() -> some View {
        modifier(ThemedSectionBackgroundModifier())
    }
    
    func themedButton(style: ThemedButtonModifier.ButtonStyleType = .primary) -> some View {
        modifier(ThemedButtonModifier(style: style))
    }
    
    func themedListRow() -> some View {
        modifier(ThemedListRowModifier())
    }
}

