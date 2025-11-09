//
//  Color+Extensions.swift
//  AI Cleaner
//
//  Color palette and extensions - Dark Theme Design System
//

import SwiftUI

// MARK: - Cleaner Theme
enum CleanerTheme {
    // MARK: - Primary Colors
    static let primary = Color(hex: "#0077F9")        // Primary Blue
    static let accent = Color(hex: "#F9C200")         // Accent Yellow
    static let accentGreen = Color(hex: "#5BAE1F")    // Accent Green
    static let accentRed = Color(hex: "#DE4841")      // Accent Red

    // MARK: - Background Colors
    static let background = Color(hex: "#0F0D1C")     // Dark Gray Background
    static let surface = Color(hex: "#212126")        // Secondary Gray Surface
    static let cardBackground = Color(hex: "#2A2B35") // Darker Gray Cards/Containers (reduced opacity for better dark theme)

    // MARK: - Text Colors
    static let textPrimary = Color.white              // White Text
    static let textSecondary = Color(hex: "#6677B1")  // Secondary Blue-Gray Text
    static let textTertiary = Color(hex: "#8E90A6")   // Tertiary Gray Text

    // MARK: - Semantic Colors
    static let success = Color(hex: "#5BAE1F")        // Green
    static let warning = Color(hex: "#F9C200")        // Yellow
    static let danger = Color(hex: "#DE4841")         // Red
    static let info = Color(hex: "#0077F9")           // Blue

    // MARK: - Icon Colors
    static let iconPrimary = Color(hex: "#A0A3BD")    // Light Gray Icons
    static let iconActive = Color(hex: "#0077F9")     // Active Blue Icons
}

extension Color {
    // MARK: - App Colors (Legacy Support - Redirects to CleanerTheme)
    static let appPrimary = CleanerTheme.primary
    static let appSecondary = CleanerTheme.surface
    static let appAccent = CleanerTheme.accent

    // MARK: - Semantic Colors (Legacy Support)
    static let success = CleanerTheme.success
    static let warning = CleanerTheme.warning
    static let danger = CleanerTheme.danger
    static let info = CleanerTheme.info

    // MARK: - Background Colors (Legacy Support)
    static let backgroundPrimary = CleanerTheme.background
    static let backgroundSecondary = CleanerTheme.surface
    static let backgroundTertiary = CleanerTheme.cardBackground

    // MARK: - Custom Initializers

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
