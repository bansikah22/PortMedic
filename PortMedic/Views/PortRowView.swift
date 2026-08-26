//
//  PortRowView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Displays a single active port/process row with a one-click kill action,
/// styled to match the PortMedic dashboard mockup.
struct PortRowView: View {
    let process: PortProcessInfo
    let badge: FrameworkBadge?
    let isSelected: Bool
    let onKillTapped: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.statusGreen)
                    .frame(width: 6, height: 6)
                Text(verbatim: String(process.port))
                    .foregroundStyle(Theme.portText)
            }
            .font(.system(.body, design: .monospaced))
            .frame(width: 90, alignment: .leading)

            Text("\(process.pid)")
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 70, alignment: .leading)

            HStack(spacing: 6) {
                Image(systemName: processIcon)
                    .foregroundStyle(Theme.secondaryText)
                    .frame(width: 16)
                Text(process.processName)
                    .foregroundStyle(Theme.primaryText)
            }
            .frame(minWidth: 160, alignment: .leading)

            Group {
                if let badge {
                    FrameworkBadgeView(badge: badge)
                } else {
                    EmptyView()
                }
            }
            .frame(minWidth: 160, alignment: .leading)

            Spacer()

            Button(action: onKillTapped) {
                Text("Kill")
            }
            .buttonStyle(.bordered)
            .tint(Theme.killRed)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Theme.rowSelectedBackground : Color.clear)
        .contentShape(Rectangle())
    }

    private var processIcon: String {
        let name = process.processName.lowercased()
        if name.contains("java") { return "cup.and.saucer.fill" }
        if name.contains("node") { return "curlybraces" }
        if name.contains("chrome") || name.contains("safari") { return "globe" }
        if name.contains("postgres") || name.contains("mysql") || name.contains("mongo") { return "cylinder.fill" }
        if name.contains("redis") { return "bolt.fill" }
        if name.contains("docker") { return "shippingbox.fill" }
        if name.contains("python") { return "chevron.left.forwardslash.chevron.right" }
        return "terminal.fill"
    }
}

#Preview {
    let java = PortProcessInfo(
        pid: 4512, port: 8080, transportProtocol: .tcp, processName: "java", user: "joetec"
    )
    let node = PortProcessInfo(
        pid: 1104, port: 3000, transportProtocol: .tcp, processName: "node", user: "joetec"
    )

    return VStack(spacing: 0) {
        PortRowView(
            process: java,
            badge: FrameworkBadge(label: "Spring Boot", tint: .blue),
            isSelected: false,
            onKillTapped: {}
        )
        PortRowView(
            process: node,
            badge: FrameworkBadge(label: "Next.js", tint: .orange),
            isSelected: true,
            onKillTapped: {}
        )
    }
    .background(Theme.contentBackground)
}
