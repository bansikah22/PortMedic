//
//  FrameworkBadge.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// A small label identifying the framework/technology behind a listening process,
/// e.g. "Spring Boot" for a Java process on port 8080.
struct FrameworkBadge: Equatable, Hashable {
    /// Semantic color name; Views map this to a concrete `Color`.
    enum Tint: String {
        case blue, orange, green, red, cyan, yellow, gray
    }

    let label: String
    let tint: Tint
}
