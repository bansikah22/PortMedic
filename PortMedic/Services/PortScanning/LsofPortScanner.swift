//
//  LsofPortScanner.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Concrete `PortScanning` implementation backed by the `lsof` command-line tool.
/// See `man lsof` for flag reference (-n: no DNS lookups, -P: no port name lookups,
/// -i: select internet sockets).
struct LsofPortScanner: PortScanning {
    private let executablePath = "/usr/sbin/lsof"

    func scan() async throws -> [PortProcessInfo] {
        let result = try await CommandRunner.run(
            executablePath: executablePath,
            arguments: ["-nP", "-iTCP", "-sTCP:LISTEN", "-iUDP"]
        )

        // lsof exits with status 1 when it simply finds no matches.
        guard result.exitCode == 0 || result.exitCode == 1 else {
            throw PortScanningError.commandFailed(status: result.exitCode, message: "lsof scan failed")
        }

        return LsofOutputParser.parse(result.standardOutput)
    }
}
