//
//  LsofProcessDetailsFetcher.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Fetches a process's executable path and working directory via `lsof`'s
/// field-oriented output (`-F`), which is friendlier to parse than the default
/// column layout. See `man lsof` for the `-F`/`-d` flag reference.
struct LsofProcessDetailsFetcher: ProcessDetailsFetching {
    private let executablePath = "/usr/sbin/lsof"

    func fetch(for pid: pid_t) async throws -> ProcessDetails {
        async let executable = firstName(arguments: ["-a", "-p", "\(pid)", "-d", "txt", "-Fn"])
        async let workingDirectory = firstName(arguments: ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"])
        return try await ProcessDetails(executablePath: executable, workingDirectory: workingDirectory)
    }

    /// Parses `lsof -Fn` output, returning the first line's `n<value>` payload.
    private func firstName(arguments: [String]) async throws -> String? {
        let output = try await run(arguments: arguments)
        return output
            .split(separator: "\n")
            .first { $0.hasPrefix("n") }
            .map { String($0.dropFirst()) }
    }

    private func run(arguments: [String]) async throws -> String {
        guard FileManager.default.isExecutableFile(atPath: executablePath) else {
            throw PortScanningError.executableNotFound
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments

            let stdoutPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = Pipe()

            process.terminationHandler = { finishedProcess in
                let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""
                // Status 1 just means lsof found nothing for that descriptor type.
                if finishedProcess.terminationStatus == 0 || finishedProcess.terminationStatus == 1 {
                    continuation.resume(returning: output)
                } else {
                    continuation.resume(throwing: PortScanningError.commandFailed(
                        status: finishedProcess.terminationStatus,
                        message: "lsof detail lookup failed"
                    ))
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
