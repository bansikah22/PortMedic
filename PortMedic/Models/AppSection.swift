//
//  AppSection.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Top-level sidebar destinations.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case dashboard = "Dashboard"
    case favorites = "Watched Ports"
    case history = "History"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .favorites: return "eye.fill"
        case .history: return "clock.arrow.circlepath"
        case .settings: return "gearshape.fill"
        }
    }

    /// Sections with a working implementation in this release.
    var isAvailable: Bool {
        self == .dashboard || self == .favorites || self == .settings
    }
}
