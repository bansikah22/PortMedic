//
//  FrameworkDetecting.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Abstraction over "identify the framework/technology running a port", so the
/// ViewModel can be unit tested against a fake instead of the heuristic rules.
protocol FrameworkDetecting: Sendable {
    func badge(for process: PortProcessInfo) -> FrameworkBadge?
}
