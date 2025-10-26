//
//  Theme.swift
//  Freelance
//
//  Created by Theme System
//

import SwiftUI

// MARK: - App Theme Enum

enum AppTheme: String, CaseIterable {
    case `default` = "default"
    case liquidGlass = "liquid glass"
    
    var displayName: String {
        return self.rawValue
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .default
    
    static let shared = ThemeManager()
    
    private init() {
        // Load theme from AppSettings
        loadTheme()
    }
    
    func loadTheme() {
        let themeString = AppSettings.shared.selectedTheme
        currentTheme = AppTheme(rawValue: themeString) ?? .default
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        AppSettings.shared.selectedTheme = theme.rawValue
        AppSettings.shared.saveSettings()
    }
    
    // MARK: - Spacing Values (Apple HIG 8pt grid)
    
    var spacing: ThemeSpacing {
        ThemeSpacing()
    }
    
    // MARK: - Corner Radius
    
    var cornerRadius: ThemeCornerRadius {
        switch currentTheme {
        case .default:
            return ThemeCornerRadius(small: 4, medium: 8, large: 12)
        case .liquidGlass:
            return ThemeCornerRadius(small: 6, medium: 10, large: 16)
        }
    }
    
    // MARK: - Shadow
    
    var shadow: ThemeShadow {
        switch currentTheme {
        case .default:
            return ThemeShadow(radius: 0, opacity: 0)
        case .liquidGlass:
            return ThemeShadow(radius: 8, opacity: 0.1)
        }
    }
    
    // MARK: - Background Style
    
    var useMaterialBackground: Bool {
        currentTheme == .liquidGlass
    }
    
    var backgroundMaterial: Material {
        .regularMaterial
    }
    
    var thinMaterial: Material {
        .thinMaterial
    }
    
    var ultraThinMaterial: Material {
        .ultraThinMaterial
    }
    
    var thickMaterial: Material {
        .thickMaterial
    }
}

// MARK: - Theme Spacing

struct ThemeSpacing {
    let tiny: CGFloat = 4
    let small: CGFloat = 8
    let medium: CGFloat = 16
    let large: CGFloat = 24
    let xLarge: CGFloat = 32
    let xxLarge: CGFloat = 40
    let xxxLarge: CGFloat = 48
    let huge: CGFloat = 60
    
    // Semantic spacing
    let contentHorizontal: CGFloat = 20  // Standard content margins
    let contentVertical: CGFloat = 16
    let sectionSpacing: CGFloat = 32
    let itemSpacing: CGFloat = 12
    let buttonSpacing: CGFloat = 16
    
    // Safe area additions
    let safeAreaTop: CGFloat = 50
    let safeAreaBottom: CGFloat = 24
    
    // Touch targets
    let minTouchTarget: CGFloat = 44
}

// MARK: - Theme Corner Radius

struct ThemeCornerRadius {
    let small: CGFloat
    let medium: CGFloat
    let large: CGFloat
}

// MARK: - Theme Shadow

struct ThemeShadow {
    let radius: CGFloat
    let opacity: Double
}

// MARK: - Animation Constants

extension ThemeManager {
    var defaultAnimation: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    var fastAnimation: Animation {
        .spring(response: 0.2, dampingFraction: 0.8)
    }
}

