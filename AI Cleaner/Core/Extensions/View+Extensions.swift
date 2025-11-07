//
//  View+Extensions.swift
//  AI Cleaner
//
//  Useful SwiftUI View extensions - Dark Theme Design System
//

import SwiftUI

// MARK: - Typography System

enum CleanerFont {
    case largeTitle
    case title
    case subtitle
    case body
    case label
    case caption

    var font: Font {
        switch self {
        case .largeTitle:
            return .system(size: 32, weight: .bold)
        case .title:
            return .system(size: 24, weight: .bold)
        case .subtitle:
            return .system(size: 18, weight: .medium)
        case .body:
            return .system(size: 16, weight: .regular)
        case .label:
            return .system(size: 14, weight: .medium)
        case .caption:
            return .system(size: 12, weight: .regular)
        }
    }

    var color: Color {
        switch self {
        case .largeTitle, .title:
            return CleanerTheme.textPrimary
        case .subtitle, .body:
            return CleanerTheme.textPrimary
        case .label, .caption:
            return CleanerTheme.textSecondary
        }
    }
}

extension View {
    /// Apply Cleaner typography style
    func cleanerFont(_ style: CleanerFont) -> some View {
        self
            .font(style.font)
            .foregroundColor(style.color)
    }

    /// Hides the keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Conditionally apply a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditionally apply one of two modifiers
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}

// MARK: - Card Modifier (Dark Theme)

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var shadowRadius: CGFloat = 8
    var backgroundColor: Color = CleanerTheme.surface

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: shadowRadius, x: 0, y: 4)
    }
}

extension View {
    func card(
        cornerRadius: CGFloat = 20,
        shadowRadius: CGFloat = 8,
        backgroundColor: Color = CleanerTheme.surface
    ) -> some View {
        modifier(CardModifier(
            cornerRadius: cornerRadius,
            shadowRadius: shadowRadius,
            backgroundColor: backgroundColor
        ))
    }
}
