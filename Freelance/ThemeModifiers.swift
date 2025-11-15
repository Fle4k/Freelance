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
                    // Background image only - no overlay
                    Image("fle4k_red_ultra_realistic_rough_used_steel_surface_with_parti_faa2c405-5c0d-4d2c-b693-ecaf4c2cd805_0")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .ignoresSafeArea()
                )
        } else {
            content
                .background(
                    Color(.systemBackground)
                        .ignoresSafeArea()
                )
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
                .glassEffect(.regular.tint(.white.opacity(0.05)))
        } else {
            content
                .background(Color(.systemBackground))
                .overlay(
                    Color.white.opacity(0.05)
                )
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
                .glassEffect(.regular.tint(.white.opacity(0.0)))
        } else {
            content
                .background(Color.clear)
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

// MARK: - Major Mono Font Modifier (enforces lowercase)

struct MajorMonoFontModifier: ViewModifier {
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom("Major Mono Display Regular", size: size))
            .textCase(.lowercase) // Force lowercase display
    }
}

// MARK: - Text Extension for Major Mono Font with Lowercase

extension Text {
    /// Creates a Text view with Major Mono Display Regular font, automatically lowercasing the content
    /// This ensures the font always displays in lowercase regardless of input
    static func majorMono(_ content: String, size: CGFloat) -> some View {
        Text(content.lowercased())
            .font(.custom("Major Mono Display Regular", size: size))
            .textCase(.lowercase)
    }
    
    /// Applies Major Mono Display Regular font with automatic lowercase enforcement
    func majorMonoFont(size: CGFloat) -> some View {
        self
            .modifier(MajorMonoFontModifier(size: size))
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
    
    /// Applies Major Mono Display Regular font with automatic lowercase enforcement
    /// Use this modifier to ensure text is always displayed in lowercase with this font
    func majorMonoFont(size: CGFloat) -> some View {
        modifier(MajorMonoFontModifier(size: size))
    }
}

