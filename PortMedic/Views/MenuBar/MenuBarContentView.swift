//
//  MenuBarContentView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Compact popover shown from the menu bar icon, matching the mockup:
/// a short list of active ports plus quick actions.
struct MenuBarContentView: View {
    @ObservedObject var viewModel: PortListViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if viewModel.ports.isEmpty {
                Text("No active ports")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ForEach(viewModel.ports.prefix(6)) { process in
                    row(for: process)
                }
            }

            Divider()

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Label("Refresh List", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Label("Open Full App", systemImage: "macwindow")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Label("Quit PortMedic", systemImage: "power")
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(width: 260)
        .task { viewModel.onAppear() }
    }

    private var header: some View {
        HStack {
            Text("PortMedic")
                .font(.headline)
            Spacer()
            Text("Active Ports")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func row(for process: PortProcessInfo) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.statusGreen)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text("\(process.port)")
                    .font(.system(.body, design: .monospaced))
                Text(viewModel.frameworkBadge(for: process)?.label ?? process.processName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

#Preview {
    MenuBarContentView(viewModel: PortListViewModel())
}
