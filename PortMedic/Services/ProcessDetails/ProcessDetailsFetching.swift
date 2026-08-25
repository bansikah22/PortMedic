//
//  ProcessDetailsFetching.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Abstraction over "look up extended details for a PID", so the ViewModel
/// can be unit tested against a fake instead of shelling out to `lsof`.
protocol ProcessDetailsFetching: Sendable {
    func fetch(for pid: pid_t) async throws -> ProcessDetails
}
