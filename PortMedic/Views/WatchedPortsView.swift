//
//  WatchedPortsView.swift
//  PortMedic
//

import SwiftUI

struct WatchedPortsView: View {
    @ObservedObject var watchedPortsViewModel: WatchedPortsViewModel
    @ObservedObject var portListViewModel: PortListViewModel
    @State private var portText = ""
    @State private var labelText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Watched Ports")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.primaryText)

            addPortControls

            if watchedPortsViewModel.watchedPorts.isEmpty {
                ContentUnavailableView(
                    "No Watched Ports",
                    systemImage: "eye",
                    description: Text("Add a port to see whether it is available or occupied.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(watchedPortsViewModel.watchedPorts) { watchedPort in
                    watchedPortRow(watchedPort)
                        .listRowBackground(Theme.rowBackground)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.contentBackground)
        .alert(
            "Unable to Watch Port",
            isPresented: Binding(
                get: { watchedPortsViewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { watchedPortsViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { watchedPortsViewModel.errorMessage = nil }
        } message: {
            Text(watchedPortsViewModel.errorMessage ?? "")
        }
    }

    private var addPortControls: some View {
        HStack(spacing: 8) {
            TextField("Port", text: $portText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 90)
            TextField("Label (optional)", text: $labelText)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 240)
            Button {
                guard let port = Int(portText) else {
                    watchedPortsViewModel.errorMessage = "Enter a port number from 1 to 65535."
                    return
                }
                watchedPortsViewModel.add(port: port, label: labelText)
                guard watchedPortsViewModel.errorMessage == nil else { return }
                portText = ""
                labelText = ""
            } label: {
                Image(systemName: "plus")
            }
            .help("Watch port")
            .disabled(portText.isEmpty)
        }
    }

    private func watchedPortRow(_ watchedPort: WatchedPort) -> some View {
        let process = portListViewModel.ports.first { $0.port == watchedPort.port }
        return HStack(spacing: 10) {
            Circle()
                .fill(process == nil ? Theme.statusGreen : .orange)
                .frame(width: 8, height: 8)
            Text(verbatim: String(watchedPort.port))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Theme.portText)
                .frame(width: 70, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(watchedPort.label ?? process?.processName ?? "Available")
                    .foregroundStyle(Theme.primaryText)
                Text(process == nil ? "Available" : "Occupied by \(process?.processName ?? "")")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
            }
            Spacer()
            Button(role: .destructive) {
                watchedPortsViewModel.remove(watchedPort)
            } label: {
                Image(systemName: "trash")
            }
            .help("Remove watched port")
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WatchedPortsView(
        watchedPortsViewModel: WatchedPortsViewModel(),
        portListViewModel: PortListViewModel()
    )
    .frame(width: 700, height: 450)
}
