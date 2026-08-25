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
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw PortScanningError.executableNotFound
        }

        let output = try await runLsof()
        return LsofOutputParser.parse(output)
    }

    private func runLsof() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = ["-nP", "-iTCP", "-sTCP:LISTEN", "-iUDP"]

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            process.terminationHandler = { finishedProcess in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""

                // lsof exits with status 1 when it simply finds no matches; treat that as an empty result.
                if finishedProcess.terminationStatus == 0 || finishedProcess.terminationStatus == 1 {
                    continuation.resume(returning: stdout)
                } else {
                    let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    let stderrMessage = String(data: stderrData, encoding: .utf8) ?? "unknown error"
                    continuation.resume(
                        throwing: PortScanningError.commandFailed(
                            status: finishedProcess.terminationStatus,
                            message: stderrMessage
                        )
                    )
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
