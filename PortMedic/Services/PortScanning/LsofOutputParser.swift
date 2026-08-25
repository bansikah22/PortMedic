//
//  LsofOutputParser.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Pure, side-effect-free parsing of `lsof` text output into domain models.
/// Kept separate from process invocation so it can be unit tested without spawning subprocesses.
enum LsofOutputParser {
    /// Parses the output of `lsof -nP -iTCP -sTCP:LISTEN -iUDP` (with `-FpcnPu` field mode disabled, plain columns).
    /// Expected columns: COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
    static func parse(_ output: String) -> [PortProcessInfo] {
        var results: [PortProcessInfo] = []

        for line in output.split(separator: "\n").dropFirst() {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            guard columns.count >= 9 else { continue }

            let command = String(columns[0])
            // Reject non-positive PIDs at the boundary: they have special,
            // destructive meaning when passed to kill(2).
            guard let pid = pid_t(columns[1]), pid > 0 else { continue }
            let user = String(columns[2])
            let fileDescriptor = String(columns[3])
            let node = columns[7].uppercased()
            let name = columns[8...].joined(separator: " ")

            guard let transportProtocol = PortProcessInfo.TransportProtocol(rawValue: node) else { continue }
            guard let port = extractPort(from: name), (1...65535).contains(port) else { continue }

            results.append(
                PortProcessInfo(
                    pid: pid,
                    port: port,
                    transportProtocol: transportProtocol,
                    processName: command,
                    user: user,
                    fileDescriptor: fileDescriptor
                )
            )
        }

        return results
    }

    /// Extracts the port number from an lsof NAME field such as "*:8080 (LISTEN)" or "127.0.0.1:5432 (LISTEN)"
    /// or "[::1]:3000 (LISTEN)".
    static func extractPort(from name: String) -> Int? {
        let withoutState = name.split(separator: " ", maxSplits: 1).first.map(String.init) ?? name
        guard let lastColonIndex = withoutState.lastIndex(of: ":") else { return nil }
        let portSubstring = withoutState[withoutState.index(after: lastColonIndex)...]
        return Int(portSubstring)
    }
}
