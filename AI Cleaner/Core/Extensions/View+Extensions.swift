//
//  View+Extensions.swift
//  AI Cleaner
//
//  Useful SwiftUI View extensions
//

import SwiftUI

extension View {
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

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 4

    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .cornerRadius(cornerRadius)
            .shadow(radius: shadowRadius)
    }
}

extension View {
    func card(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 4) -> some View {
        modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}
