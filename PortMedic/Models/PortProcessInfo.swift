//
//  PortProcessInfo.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// A single listening port owned by a running process, as reported by `lsof`.
struct PortProcessInfo: Identifiable, Equatable, Hashable {
    enum TransportProtocol: String, Equatable {
        case tcp = "TCP"
        case udp = "UDP"
    }

    /// Stable identity for SwiftUI diffing; a pid can own more than one port.
    let id: String
    let pid: pid_t
    let port: Int
    let transportProtocol: TransportProtocol
    let processName: String
    let user: String

    init(
        pid: pid_t,
        port: Int,
        transportProtocol: TransportProtocol,
        processName: String,
        user: String,
        fileDescriptor: String = "0"
    ) {
        // Include the lsof file descriptor since a process can listen on the
        // same port/protocol over multiple sockets (e.g. IPv4 + IPv6), which
        // would otherwise produce colliding SwiftUI `Identifiable` ids.
        self.id = "\(pid)-\(fileDescriptor)-\(port)-\(transportProtocol.rawValue)"
        self.pid = pid
        self.port = port
        self.transportProtocol = transportProtocol
        self.processName = processName
        self.user = user
    }
}

extension PortProcessInfo {
    /// Search haystack combining the fields a user is likely to search by.
    var searchableText: String {
        "\(port) \(pid) \(processName) \(user)".lowercased()
    }
}
