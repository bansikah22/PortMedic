//
//  ProcessDetailPanel.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Right-hand detail panel shown when a row is selected in the dashboard,
/// matching the "Process Details" mockup.
struct ProcessDetailPanel: View {
    let process: PortProcessInfo
    let badge: FrameworkBadge?
    @ObservedObject var viewModel: PortListViewModel

    @State private var details: ProcessDetails?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            statusGrid
            infoBox(title: "EXECUTABLE PATH", value: details?.executablePath)
            infoBox(title: "WORKING DIRECTORY", value: details?.workingDirectory)

            Spacer()

            Button {
                viewModel.requestKill(process)
            } label: {
                Text("Terminate Process")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.killRed)
        }
        .padding(16)
        .frame(width: 260)
        .background(Theme.rowBackground)
        .task(id: process.id) {
            details = await viewModel.processDetails(for: process)
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Theme.searchFieldBackground)
                .frame(width: 36, height: 36)
                .overlay(Image(systemName: "curlybraces").foregroundStyle(Theme.primaryText))

            VStack(alignment: .leading, spacing: 2) {
                Text(process.processName)
                    .font(.headline)
                    .foregroundStyle(Theme.primaryText)
                Text(verbatim: "PID: \(process.pid)")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer()

            if let badge {
                FrameworkBadgeView(badge: badge)
            }
        }
    }

    private var statusGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 14) {
            statusItem(title: "STATUS") {
                HStack(spacing: 6) {
                    Circle().fill(Theme.statusGreen).frame(width: 6, height: 6)
                    Text("Listening")
                }
            }
            statusItem(title: "PROTOCOL") {
                Text(process.transportProtocol.rawValue)
            }
            statusItem(title: "PORT") {
                Text(verbatim: String(process.port)).foregroundStyle(Theme.portText)
            }
            statusItem(title: "USER") {
                Text(process.user)
            }
        }
    }

    private func statusItem<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.headerText)
            content()
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Theme.primaryText)
        }
    }

    private func infoBox(title: String, value: String?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Theme.headerText)
            Text(value ?? "Not available")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(value == nil ? Theme.secondaryText : Theme.primaryText)
                .lineLimit(2)
                .truncationMode(.middle)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.searchFieldBackground, in: RoundedRectangle(cornerRadius: 6))
        }
    }
}

#Preview {
    ProcessDetailPanel(
        process: PortProcessInfo(pid: 4512, port: 8080, transportProtocol: .tcp, processName: "java", user: "joetec"),
        badge: FrameworkBadge(label: "Spring Boot", tint: .blue),
        viewModel: PortListViewModel()
    )
    .frame(height: 500)
}
