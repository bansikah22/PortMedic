//
//  PortListViewModel.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Drives the port list screen: owns state, talks to the scanning/termination
/// services, and exposes everything the View needs as `@Published` properties.
@MainActor
final class PortListViewModel: ObservableObject {
    @Published private(set) var ports: [PortProcessInfo] = []
    @Published private(set) var isLoading = false
    @Published var searchText = ""
    @Published var errorMessage: String?
    @Published var pendingKillTarget: PortProcessInfo?
    @Published var selectedProcess: PortProcessInfo?
    @Published private(set) var lastRefreshedAt: Date?

    @Published var isAutoRefreshEnabled = true {
        didSet {
            guard isAutoRefreshEnabled != oldValue else { return }
            isAutoRefreshEnabled ? startAutoRefresh() : stopAutoRefresh()
        }
    }

    @Published var autoRefreshIntervalSeconds: Double = 5 {
        didSet {
            guard isAutoRefreshEnabled, autoRefreshIntervalSeconds != oldValue else { return }
            startAutoRefresh()
        }
    }

    var filteredPorts: [PortProcessInfo] {
        guard !searchText.isEmpty else { return ports }
        let query = searchText.lowercased()
        return ports.filter { process in
            // Also match the detected framework label (e.g. "postgres" should find a
            // container process named "docker"/"com.docker.backend" running Postgres).
            if process.searchableText.contains(query) { return true }
            return frameworkBadge(for: process)?.label.lowercased().contains(query) ?? false
        }
    }

    private let scanner: PortScanning
    private let terminator: ProcessTerminating
    private let frameworkDetector: FrameworkDetecting
    private let detailsFetcher: ProcessDetailsFetching
    private var autoRefreshTask: Task<Void, Never>?

    init(
        scanner: PortScanning = LsofPortScanner(),
        terminator: ProcessTerminating = SignalProcessTerminator(),
        frameworkDetector: FrameworkDetecting = HeuristicFrameworkDetector(),
        detailsFetcher: ProcessDetailsFetching = LsofProcessDetailsFetcher(),
        autoRefreshIntervalSeconds: Double = 5
    ) {
        self.scanner = scanner
        self.terminator = terminator
        self.frameworkDetector = frameworkDetector
        self.detailsFetcher = detailsFetcher
        self.autoRefreshIntervalSeconds = autoRefreshIntervalSeconds
    }

    func frameworkBadge(for process: PortProcessInfo) -> FrameworkBadge? {
        frameworkDetector.badge(for: process)
    }

    func processDetails(for process: PortProcessInfo) async -> ProcessDetails {
        (try? await detailsFetcher.fetch(for: process.pid)) ?? ProcessDetails()
    }

    deinit {
        autoRefreshTask?.cancel()
    }

    func onAppear() {
        startAutoRefresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            ports = try await scanner.scan()
                .sorted { $0.port < $1.port }
            errorMessage = nil
            lastRefreshedAt = Date()
            // The selected process may have exited or released its port; drop a stale selection.
            if let selectedProcess, !ports.contains(selectedProcess) {
                self.selectedProcess = nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestKill(_ process: PortProcessInfo) {
        pendingKillTarget = process
    }

    func cancelPendingKill() {
        pendingKillTarget = nil
    }

    func confirmKill(force: Bool = true) async {
        guard let target = pendingKillTarget else { return }
        await kill(target, force: force)
    }

    /// Takes the target explicitly: SwiftUI clears `pendingKillTarget` via the
    /// alert's `isPresented` binding *before* the button action runs, so reading
    /// it here would always find nil.
    func kill(_ target: PortProcessInfo, force: Bool = true) async {
        pendingKillTarget = nil

        // The scan is a snapshot: the process may have exited since, and the OS
        // may have recycled its PID onto something unrelated. Re-scan and only
        // proceed if the same PID still holds the same port.
        await refresh()
        guard ports.contains(target) else {
            errorMessage = "Port \(target.port) is no longer held by PID \(target.pid). Nothing to terminate."
            return
        }

        do {
            if force {
                try terminator.forceTerminate(pid: target.pid)
            } else {
                try terminator.terminate(pid: target.pid)
            }
            // Give the OS a moment to reap the process before re-scanning ports.
            try? await Task.sleep(for: .milliseconds(300))
            await refresh()

            if ports.contains(target) {
                errorMessage = """
                Port \(target.port) is still in use by PID \(target.pid). \
                It may be a supervised service (e.g. Docker Desktop) that restarts \
                automatically, or require administrator privileges to stop.
                """
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                await self.refresh()
                try? await Task.sleep(for: .seconds(self.autoRefreshIntervalSeconds))
            }
        }
    }

    func stopAutoRefresh() {
        autoRefreshTask?.cancel()
        autoRefreshTask = nil
    }
}
