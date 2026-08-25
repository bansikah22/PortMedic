//
//  LoginItemManaging.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Abstraction over "run PortMedic at login", so `SettingsViewModel` can be
/// unit tested without touching the real login item registry.
protocol LoginItemManaging: Sendable {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}
