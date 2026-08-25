//
//  FrameworkBadgeView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Small colored pill identifying a detected framework/technology, e.g. "Next.js".
struct FrameworkBadgeView: View {
    let badge: FrameworkBadge

    var body: some View {
        let color = Theme.badgeColor(for: badge.tint)
        Text(badge.label)
            .font(.caption.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(color.opacity(0.35), lineWidth: 1)
            )
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        FrameworkBadgeView(badge: FrameworkBadge(label: "Spring Boot", tint: .blue))
        FrameworkBadgeView(badge: FrameworkBadge(label: "Next.js", tint: .orange))
        FrameworkBadgeView(badge: FrameworkBadge(label: "Vite Dev Server", tint: .gray))
        FrameworkBadgeView(badge: FrameworkBadge(label: "PostgreSQL", tint: .blue))
    }
    .padding()
    .background(Theme.contentBackground)
}
