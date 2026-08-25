//
//  CommandRunner.swift
//  PortMedic
//
//  Created by bansikah on 25/08/2026.
//

import Foundation

struct CommandResult {
    let standardOutput: String
    let standardError: String
    let exitCode: Int32
}

/// Runs a trusted, absolute-path executable and captures its output.
///
/// Pipes are drained concurrently with process execution: reading only inside
/// `terminationHandler` deadlocks as soon as a child writes more than the
/// 64 KB pipe buffer, because the child blocks on write while we wait for it
/// to exit.
enum CommandRunner {
    /// Arguments are passed as an array and the executable is an absolute path,
    /// so no shell is involved and there is no interpolation to inject into.
    static func run(executablePath: String, arguments: [String]) async throws -> CommandResult {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw PortScanningError.executableNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: executablePath)
                process.arguments = arguments

                let stdoutPipe = Pipe()
                let stderrPipe = Pipe()
                process.standardOutput = stdoutPipe
                process.standardError = stderrPipe
                process.standardInput = FileHandle.nullDevice

                do {
                    try process.run()
                } catch {
                    continuation.resume(throwing: error)
                    return
                }

                // Drain stderr on a second queue so neither pipe can fill up and
                // stall the child while we are reading the other.
                let stderrQueue = DispatchQueue(label: "com.portmedic.command.stderr")
                var stderrData = Data()
                let stderrDone = DispatchSemaphore(value: 0)
                stderrQueue.async {
                    stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                    stderrDone.signal()
                }

                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                stderrDone.wait()
                process.waitUntilExit()

                continuation.resume(
                    returning: CommandResult(
                        standardOutput: String(bytes: stdoutData, encoding: .utf8) ?? "",
                        standardError: String(bytes: stderrData, encoding: .utf8) ?? "",
                        exitCode: process.terminationStatus
                    )
                )
            }
        }
    }
}
