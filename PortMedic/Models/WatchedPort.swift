//
//  WatchedPort.swift
//  PortMedic
//

import Foundation

struct WatchedPort: Identifiable, Codable, Equatable, Hashable {
    let port: Int
    let label: String?

    var id: Int { port }
}
