//
//  SignalProcessTerminator.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Terminates processes by sending POSIX signals directly, avoiding the overhead
/// of spawning `/bin/kill`.
struct SignalProcessTerminator: ProcessTerminating {
    func terminate(pid: pid_t) throws {
        try send(signal: SIGTERM, to: pid)
    }

    func forceTerminate(pid: pid_t) throws {
        try send(signal: SIGKILL, to: pid)
    }

    /// `kill(2)` assigns special meaning to non-positive PIDs: 0 signals the
    /// caller's entire process group, -1 signals every process the user may
    /// signal, and any other negative value signals a whole process group.
    /// Scanned PIDs must never be able to reach those paths.
    static func isSafeTarget(_ pid: pid_t) -> Bool {
        pid > 1 && pid != getpid()
    }

    private func send(signal: Int32, to pid: pid_t) throws {
        guard Self.isSafeTarget(pid) else {
            throw ProcessTerminationError.unsafeTarget(pid: pid)
        }

        let result = kill(pid, signal)
        guard result == 0 else {
            switch errno {
            case ESRCH:
                throw ProcessTerminationError.noSuchProcess(pid: pid)
            case EPERM:
                throw ProcessTerminationError.permissionDenied(pid: pid)
            default:
                throw ProcessTerminationError.signalFailed(pid: pid, errno: errno)
            }
        }
    }
}
