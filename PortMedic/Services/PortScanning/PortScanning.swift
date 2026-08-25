//
//  PortScanning.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Abstraction over "list the ports currently in use", so the ViewModel can be
/// unit tested against a fake instead of shelling out to `lsof`.
protocol PortScanning: Sendable {
    func scan() async throws -> [PortProcessInfo]
}

enum PortScanningError: LocalizedError {
    case commandFailed(status: Int32, message: String)
    case executableNotFound

    var errorDescription: String? {
        switch self {
        case .commandFailed(let status, let message):
            return "lsof exited with status \(status): \(message)"
        case .executableNotFound:
            return "Could not locate /usr/sbin/lsof on this system."
        }
    }
}
