//
//  HeuristicFrameworkDetector.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Best-effort framework detection using well-known dev-server ports first,
/// falling back to process-name keywords. Pure/deterministic so it's unit testable.
struct HeuristicFrameworkDetector: FrameworkDetecting {
    private static let portHints: [Int: FrameworkBadge] = [
        5173: FrameworkBadge(label: "Vite Dev Server", tint: .gray),
        5432: FrameworkBadge(label: "PostgreSQL", tint: .blue),
        3306: FrameworkBadge(label: "MySQL", tint: .blue),
        6379: FrameworkBadge(label: "Redis", tint: .red),
        27017: FrameworkBadge(label: "MongoDB", tint: .green)
    ]

    private static let processNameHints: [(keyword: String, badge: FrameworkBadge)] = [
        ("java", FrameworkBadge(label: "Spring Boot", tint: .blue)),
        ("docker", FrameworkBadge(label: "Docker", tint: .cyan)),
        ("python", FrameworkBadge(label: "Python", tint: .yellow))
    ]

    func badge(for process: PortProcessInfo) -> FrameworkBadge? {
        if let hint = Self.portHints[process.port] {
            return hint
        }

        let name = process.processName.lowercased()

        if name.contains("node") {
            return process.port == 3000
                ? FrameworkBadge(label: "Next.js", tint: .orange)
                : FrameworkBadge(label: "Node.js", tint: .green)
        }

        return Self.processNameHints.first { name.contains($0.keyword) }?.badge
    }
}
