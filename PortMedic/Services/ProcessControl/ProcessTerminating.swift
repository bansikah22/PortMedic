//
//  ProcessTerminating.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Abstraction over "terminate a process by PID", so the ViewModel can be
/// unit tested without sending real signals.
protocol ProcessTerminating: Sendable {
    /// Requests graceful shutdown (SIGTERM).
    func terminate(pid: pid_t) throws
    /// Forces immediate termination (SIGKILL).
    func forceTerminate(pid: pid_t) throws
}

enum ProcessTerminationError: LocalizedError {
    case signalFailed(pid: pid_t, errno: Int32)
    case permissionDenied(pid: pid_t)
    case noSuchProcess(pid: pid_t)

    var errorDescription: String? {
        switch self {
        case .signalFailed(let pid, let errno):
            return "Failed to signal process \(pid) (errno \(errno))."
        case .permissionDenied(let pid):
            return "Permission denied terminating process \(pid). Try running PortMedic with elevated privileges."
        case .noSuchProcess(let pid):
            return "Process \(pid) no longer exists."
        }
    }
}
