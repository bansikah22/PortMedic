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
    @ObservedObject var watchedPortsViewModel: WatchedPortsViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider()

            if watchedPortsViewModel.watchedPorts.isEmpty, viewModel.ports.isEmpty {
                Text("No active ports")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                if !watchedPortsViewModel.watchedPorts.isEmpty {
                    sectionHeader("Watched Ports")
                    ForEach(watchedPortsViewModel.watchedPorts) { watchedPort in
                        watchedPortRow(watchedPort)
                    }
                }

                if !otherActivePorts.isEmpty {
                    if !watchedPortsViewModel.watchedPorts.isEmpty {
                        Divider()
                    }
                    sectionHeader("Other Active Ports")
                    ForEach(otherActivePorts.prefix(6)) { process in
                        activePortRow(process)
                    }
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
        .alert(
            terminationAlertTitle,
            isPresented: Binding(
                get: { viewModel.pendingKillTarget != nil },
                set: { isPresented in if !isPresented { viewModel.cancelPendingKill() } }
            ),
            presenting: viewModel.pendingKillTarget
        ) { target in
            Button("Cancel", role: .cancel) { viewModel.cancelPendingKill() }
            Button("Terminate", role: .destructive) { Task { await viewModel.kill(target, force: false) } }
        } message: { _ in
            Text("PortMedic will ask before using Force Kill if the process does not stop gracefully.")
        }
        .alert(
            "Process Did Not Terminate",
            isPresented: Binding(
                get: { viewModel.forceKillTarget != nil },
                set: { isPresented in if !isPresented { viewModel.cancelForceKill() } }
            ),
            presenting: viewModel.forceKillTarget
        ) { target in
            Button("Cancel", role: .cancel) { viewModel.cancelForceKill() }
            Button("Force Kill", role: .destructive) { Task { await viewModel.kill(target, force: true) } }
        } message: { target in
            Text("\(target.processName) is still using port \(String(target.port)).")
        }
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

    private var otherActivePorts: [PortProcessInfo] {
        let watchedPortNumbers = Set(watchedPortsViewModel.watchedPorts.map(\.port))
        return viewModel.ports.filter { !watchedPortNumbers.contains($0.port) }
    }

    private var terminationAlertTitle: String {
        guard let target = viewModel.pendingKillTarget else { return "Terminate Process" }
        return "Terminate \(target.processName) (PID \(String(target.pid)))?"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private func watchedPortRow(_ watchedPort: WatchedPort) -> some View {
        let process = viewModel.ports.first { $0.port == watchedPort.port }
        return HStack(spacing: 8) {
            Circle()
                .fill(process == nil ? Theme.statusGreen : .orange)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: String(watchedPort.port))
                    .font(.system(.body, design: .monospaced))
                Text(watchedPort.label ?? process?.processName ?? "Available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let process {
                terminateButton(for: process)
            } else {
                Text("Available")
                    .font(.caption)
                    .foregroundStyle(Theme.statusGreen)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func activePortRow(_ process: PortProcessInfo) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.statusGreen)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(verbatim: String(process.port))
                    .font(.system(.body, design: .monospaced))
                Text(viewModel.frameworkBadge(for: process)?.label ?? process.processName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            terminateButton(for: process)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    private func terminateButton(for process: PortProcessInfo) -> some View {
        Button {
            viewModel.requestKill(process)
        } label: {
            Image(systemName: "xmark")
        }
        .buttonStyle(.bordered)
        .tint(Theme.killRed)
        .help("Terminate process")
        .accessibilityLabel("Terminate \(process.processName)")
    }
}

#Preview {
    MenuBarContentView(
        viewModel: PortListViewModel(),
        watchedPortsViewModel: WatchedPortsViewModel()
    )
}
