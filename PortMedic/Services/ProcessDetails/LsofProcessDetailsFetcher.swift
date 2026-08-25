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
        guard pid > 0 else { return ProcessDetails() }

        async let executable = firstName(arguments: ["-a", "-p", "\(pid)", "-d", "txt", "-Fn"])
        async let workingDirectory = firstName(arguments: ["-a", "-p", "\(pid)", "-d", "cwd", "-Fn"])
        return try await ProcessDetails(executablePath: executable, workingDirectory: workingDirectory)
    }

    /// Parses `lsof -Fn` output, returning the first line's `n<value>` payload.
    private func firstName(arguments: [String]) async throws -> String? {
        let result = try await CommandRunner.run(executablePath: executablePath, arguments: arguments)

        // Status 1 just means lsof found nothing for that descriptor type.
        guard result.exitCode == 0 || result.exitCode == 1 else {
            throw PortScanningError.commandFailed(status: result.exitCode, message: "lsof detail lookup failed")
        }

        return result.standardOutput
            .split(separator: "\n")
            .first { $0.hasPrefix("n") }
            .map { String($0.dropFirst()) }
    }
}
