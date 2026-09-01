//
//  WatchedPortStoring.swift
//  PortMedic
//

import Foundation

protocol WatchedPortStoring {
    func loadWatchedPorts() -> [WatchedPort]
    func saveWatchedPorts(_ ports: [WatchedPort])
}

struct UserDefaultsWatchedPortStore: WatchedPortStoring {
    private static let defaultsKey = "com.portmedic.watchedPorts"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadWatchedPorts() -> [WatchedPort] {
        guard let data = userDefaults.data(forKey: Self.defaultsKey),
              let ports = try? JSONDecoder().decode([WatchedPort].self, from: data) else {
            return []
        }
        return ports.filter { (1...65535).contains($0.port) }
    }

    func saveWatchedPorts(_ ports: [WatchedPort]) {
        guard let data = try? JSONEncoder().encode(ports) else { return }
        userDefaults.set(data, forKey: Self.defaultsKey)
    }
}
