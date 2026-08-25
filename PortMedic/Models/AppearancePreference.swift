//
//  AppearancePreference.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// User-selectable appearance override for the app, persisted in Settings.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case light, dark, system

    var id: String { rawValue }
    var label: String { rawValue.capitalized }

    /// `nil` means "follow the system appearance".
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
