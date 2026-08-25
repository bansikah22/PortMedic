//
//  Theme.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Centralized color palette so the dashboard's fixed dark theme (matching the
/// product mockups) stays consistent across views instead of scattering literals.
enum Theme {
    // Explicit (not semantic) colors throughout: the whole app uses a fixed dark
    // theme regardless of system Dark Mode, so `.primary`/`.secondary` are avoided.
    static let sidebarBackground = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let sidebarPrimaryText = Color.white.opacity(0.92)
    static let sidebarSecondaryText = Color.white.opacity(0.5)
    static let sidebarDisabledText = Color.white.opacity(0.28)
    static let sidebarSelectedBackground = Color.accentColor
    static let contentBackground = Color(red: 0.07, green: 0.08, blue: 0.11)
    static let rowBackground = Color(red: 0.09, green: 0.10, blue: 0.14)
    static let rowBorder = Color.white.opacity(0.06)
    static let headerText = Color.white.opacity(0.45)
    static let primaryText = Color.white.opacity(0.92)
    static let secondaryText = Color.white.opacity(0.5)
    static let statusGreen = Color(red: 0.30, green: 0.85, blue: 0.45)
    static let killRed = Color(red: 0.95, green: 0.36, blue: 0.36)

    static func badgeColor(for tint: FrameworkBadge.Tint) -> Color {
        switch tint {
        case .blue: return Color(red: 0.35, green: 0.55, blue: 0.95)
        case .orange: return Color(red: 0.92, green: 0.62, blue: 0.30)
        case .green: return Color(red: 0.40, green: 0.78, blue: 0.55)
        case .red: return Color(red: 0.90, green: 0.45, blue: 0.45)
        case .cyan: return Color(red: 0.35, green: 0.78, blue: 0.85)
        case .yellow: return Color(red: 0.90, green: 0.80, blue: 0.35)
        case .gray: return Color.white.opacity(0.65)
        }
    }
}
