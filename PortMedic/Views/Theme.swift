//
//  Theme.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Centralized colour palette. Every colour is defined as a dynamic `NSColor`
/// with explicit light and dark variants, so the Appearance preference in
/// Settings (which sets `preferredColorScheme`) actually re-tints the whole UI
/// rather than only the system controls.
enum Theme {
    static let sidebarBackground = adaptive(
        light: Color(red: 0.96, green: 0.96, blue: 0.97),
        dark: Color(red: 0.10, green: 0.11, blue: 0.15)
    )
    static let sidebarPrimaryText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15),
        dark: Color.white.opacity(0.92)
    )
    static let sidebarSecondaryText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.6),
        dark: Color.white.opacity(0.5)
    )
    static let sidebarDisabledText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.32),
        dark: Color.white.opacity(0.28)
    )
    static let sidebarSelectedBackground = Color.accentColor

    static let contentBackground = adaptive(
        light: Color(red: 1.0, green: 1.0, blue: 1.0),
        dark: Color(red: 0.07, green: 0.08, blue: 0.11)
    )
    static let rowBackground = adaptive(
        light: Color(red: 0.98, green: 0.98, blue: 0.99),
        dark: Color(red: 0.09, green: 0.10, blue: 0.14)
    )
    static let rowBorder = adaptive(
        light: Color.black.opacity(0.09),
        dark: Color.white.opacity(0.06)
    )
    static let rowSelectedBackground = adaptive(
        light: Color.black.opacity(0.05),
        dark: Color.white.opacity(0.06)
    )
    static let searchFieldBackground = adaptive(
        light: Color.black.opacity(0.05),
        dark: Color.white.opacity(0.06)
    )

    static let headerText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.55),
        dark: Color.white.opacity(0.45)
    )
    static let primaryText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15),
        dark: Color.white.opacity(0.92)
    )
    static let secondaryText = adaptive(
        light: Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.6),
        dark: Color.white.opacity(0.5)
    )

    static let portText = adaptive(
        light: Color(red: 0.10, green: 0.38, blue: 0.85),
        dark: Color(red: 0.40, green: 0.65, blue: 1.0)
    )
    static let statusGreen = adaptive(
        light: Color(red: 0.13, green: 0.63, blue: 0.30),
        dark: Color(red: 0.30, green: 0.85, blue: 0.45)
    )
    static let killRed = adaptive(
        light: Color(red: 0.80, green: 0.18, blue: 0.18),
        dark: Color(red: 0.95, green: 0.36, blue: 0.36)
    )

    static func badgeColor(for tint: FrameworkBadge.Tint) -> Color {
        switch tint {
        case .blue:
            return adaptive(
                light: Color(red: 0.16, green: 0.38, blue: 0.80),
                dark: Color(red: 0.35, green: 0.55, blue: 0.95)
            )
        case .orange:
            return adaptive(
                light: Color(red: 0.72, green: 0.42, blue: 0.09),
                dark: Color(red: 0.92, green: 0.62, blue: 0.30)
            )
        case .green:
            return adaptive(
                light: Color(red: 0.15, green: 0.52, blue: 0.31),
                dark: Color(red: 0.40, green: 0.78, blue: 0.55)
            )
        case .red:
            return adaptive(
                light: Color(red: 0.72, green: 0.20, blue: 0.20),
                dark: Color(red: 0.90, green: 0.45, blue: 0.45)
            )
        case .cyan:
            return adaptive(
                light: Color(red: 0.11, green: 0.48, blue: 0.55),
                dark: Color(red: 0.35, green: 0.78, blue: 0.85)
            )
        case .yellow:
            return adaptive(
                light: Color(red: 0.60, green: 0.48, blue: 0.06),
                dark: Color(red: 0.90, green: 0.80, blue: 0.35)
            )
        case .gray:
            return adaptive(
                light: Color(red: 0.11, green: 0.12, blue: 0.15).opacity(0.7),
                dark: Color.white.opacity(0.65)
            )
        }
    }

    /// Resolves per-appearance at draw time, which is what lets a single static
    /// palette follow both the system setting and an explicit override.
    private static func adaptive(light: Color, dark: Color) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(isDark ? dark : light)
        })
    }
}
