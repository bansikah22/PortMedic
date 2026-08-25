//
//  StatusBarView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Bottom status strip showing live port count and last refresh time.
struct StatusBarView: View {
    let activeCount: Int
    let lastRefreshedAt: Date?

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.statusGreen)
                    .frame(width: 6, height: 6)
                Text("Scanning \(activeCount) active port\(activeCount == 1 ? "" : "s")")
            }

            Spacer()

            Text("Last refreshed: \(relativeDescription)")
        }
        .font(.caption)
        .foregroundStyle(Theme.secondaryText)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .overlay(Rectangle().fill(Theme.rowBorder).frame(height: 1), alignment: .top)
    }

    private var relativeDescription: String {
        guard let lastRefreshedAt else { return "Never" }
        let seconds = Date().timeIntervalSince(lastRefreshedAt)
        if seconds < 2 { return "Just now" }
        return RelativeDateTimeFormatter().localizedString(for: lastRefreshedAt, relativeTo: Date())
    }
}

#Preview {
    StatusBarView(activeCount: 12, lastRefreshedAt: Date())
        .background(Theme.contentBackground)
}
