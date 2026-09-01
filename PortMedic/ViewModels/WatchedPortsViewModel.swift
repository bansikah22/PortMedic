//
//  WatchedPortsViewModel.swift
//  PortMedic
//

import Foundation

@MainActor
final class WatchedPortsViewModel: ObservableObject {
    @Published private(set) var watchedPorts: [WatchedPort]
    @Published var errorMessage: String?

    private let store: WatchedPortStoring

    init(store: WatchedPortStoring = UserDefaultsWatchedPortStore()) {
        self.store = store
        self.watchedPorts = store.loadWatchedPorts().sorted { $0.port < $1.port }
    }

    func add(port: Int, label: String) {
        guard (1...65535).contains(port) else {
            errorMessage = "Enter a port number from 1 to 65535."
            return
        }
        guard !watchedPorts.contains(where: { $0.port == port }) else {
            errorMessage = "Port \(port) is already being watched."
            return
        }

        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        watchedPorts.append(WatchedPort(port: port, label: trimmedLabel.isEmpty ? nil : trimmedLabel))
        watchedPorts.sort { $0.port < $1.port }
        store.saveWatchedPorts(watchedPorts)
    }

    func remove(_ watchedPort: WatchedPort) {
        watchedPorts.removeAll { $0.id == watchedPort.id }
        store.saveWatchedPorts(watchedPorts)
    }
}
