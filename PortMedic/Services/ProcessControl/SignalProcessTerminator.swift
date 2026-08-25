//
//  SignalProcessTerminator.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Terminates processes by sending POSIX signals directly, avoiding the overhead
/// of spawning `/bin/kill`. SIGTERM is tried first to allow graceful shutdown;
/// callers may retry with `force: true` to send SIGKILL.
struct SignalProcessTerminator: ProcessTerminating {
    func terminate(pid: pid_t) throws {
        try send(signal: SIGTERM, to: pid)
    }

    func forceTerminate(pid: pid_t) throws {
        try send(signal: SIGKILL, to: pid)
    }

    private func send(signal: Int32, to pid: pid_t) throws {
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
