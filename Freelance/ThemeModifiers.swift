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
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        if themeManager.useMaterialBackground {
            content
                .background(
                    ZStack {
                        // Anthracite to black gradient
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.2, green: 0.2, blue: 0.2), // Anthracite
                                Color.black
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        
                        // Material overlay for depth
                        Color.clear
                            .background(themeManager.backgroundMaterial)
                    }
                    .ignoresSafeArea()
                )
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
                .glassEffect(.regular.tint(.white.opacity(0.0)))
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
                .glassEffect(.regular.tint(Color.primary.opacity(0.0)))
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
                .glassEffect(.regular.tint(.primary.opacity(0.0)).interactive())
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
                .glassEffect(.regular.tint(.white.opacity(0.0)))
        } else {
            content
                .padding(.vertical, themeManager.spacing.itemSpacing)
        }
    }
}

// MARK: - Glass List Row Modifier (for custom glass effect application)

struct GlassListRowModifier: ViewModifier {
    let isLiquidGlass: Bool
    let isHighlighted: Bool
    @Environment(\.colorScheme) var colorScheme
    
    init(isLiquidGlass: Bool, isHighlighted: Bool = false) {
        self.isLiquidGlass = isLiquidGlass
        self.isHighlighted = isHighlighted
    }
    
    func body(content: Content) -> some View {
        if isLiquidGlass {
            content
                .glassEffect(.regular.tint(isHighlighted ? Color.white.opacity(0.05) : .white.opacity(0.0)))
        } else {
            content
                .background(
                    isHighlighted ? 
                    Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06) : 
                    Color.clear
                )
        }
    }
}

// MARK: - Glass Button Modifier (for circular glass buttons like in TimerView)

struct GlassButtonModifier: ViewModifier {
    let isLiquidGlass: Bool
    let size: CGFloat
    
    func body(content: Content) -> some View {
        if isLiquidGlass {
            content
                .glassEffect(
                    .regular
                        .tint(Color.white.opacity(0.0))
                        .interactive(),
                    in: Circle()
                )
        } else {
            content
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

