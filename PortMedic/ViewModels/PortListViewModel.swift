//
//  PortListViewModel.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import AppKit
import Foundation

/// Drives the port list screen: owns state, talks to the scanning/termination
/// services, and exposes everything the View needs as `@Published` properties.
@MainActor
final class PortListViewModel: ObservableObject {
    @Published private(set) var ports: [PortProcessInfo] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var pendingKillTarget: PortProcessInfo?
    @Published var forceKillTarget: PortProcessInfo?
    @Published var selectedProcess: PortProcessInfo?
    @Published private(set) var lastRefreshedAt: Date?

    /// Search results, recomputed only when the query or the scan changes.
    /// A computed property would re-filter on every SwiftUI body evaluation.
    @Published private(set) var filteredPorts: [PortProcessInfo] = []

    @Published var searchText = "" {
        didSet {
            guard searchText != oldValue else { return }
            updateFilteredPorts()
        }
    }

    @Published var isAutoRefreshEnabled = true {
        didSet {
            guard isAutoRefreshEnabled != oldValue else { return }
            if isAutoRefreshEnabled {
                startAutoRefresh()
            } else {
                stopAutoRefresh()
            }
        }
    }

    @Published var autoRefreshIntervalSeconds: Double = 5 {
        didSet {
            guard isAutoRefreshEnabled, autoRefreshIntervalSeconds != oldValue else { return }
            startAutoRefresh()
        }
    }

    private let scanner: PortScanning
    private let terminator: ProcessTerminating
    private let frameworkDetector: FrameworkDetecting
    private let detailsFetcher: ProcessDetailsFetching
    private let quickActionService: ProcessQuickActionPerforming
    private var autoRefreshTask: Task<Void, Never>?
    private var activationObservers: [NSObjectProtocol] = []

    /// Framework detection is deterministic per process name and port, so it is
    /// resolved once per scan instead of on every row render.
    private var badgeCache: [String: FrameworkBadge?] = [:]
    private static let webDevelopmentPorts: Set<Int> = [
        3000, 4200, 5000, 5173, 8000, 8080, 8081, 8888, 9000, 9090
    ]

    init(
        scanner: PortScanning = LsofPortScanner(),
        terminator: ProcessTerminating = SignalProcessTerminator(),
        frameworkDetector: FrameworkDetecting = HeuristicFrameworkDetector(),
        detailsFetcher: ProcessDetailsFetching = LsofProcessDetailsFetcher(),
        quickActionService: ProcessQuickActionPerforming = AppKitProcessQuickActionService(),
        autoRefreshIntervalSeconds: Double = 5
    ) {
        self.scanner = scanner
        self.terminator = terminator
        self.frameworkDetector = frameworkDetector
        self.detailsFetcher = detailsFetcher
        self.quickActionService = quickActionService
        self.autoRefreshIntervalSeconds = autoRefreshIntervalSeconds
    }

    func frameworkBadge(for process: PortProcessInfo) -> FrameworkBadge? {
        let key = "\(process.processName)|\(process.port)"
        if let cached = badgeCache[key] { return cached }
        let badge = frameworkDetector.badge(for: process)
        badgeCache[key] = badge
        return badge
    }

    func processDetails(for process: PortProcessInfo) async -> ProcessDetails {
        (try? await detailsFetcher.fetch(for: process.pid)) ?? ProcessDetails()
    }

    func copyPID(for process: PortProcessInfo) {
        quickActionService.copyToClipboard(String(process.pid))
    }

    func copyLocalhostURL(for process: PortProcessInfo) {
        quickActionService.copyToClipboard(localhostURLString(for: process))
    }

    func openLocalhostURL(for process: PortProcessInfo) {
        guard let url = URL(string: localhostURLString(for: process)), quickActionService.openInBrowser(url) else {
            errorMessage = "Unable to open the localhost URL in your default browser."
            return
        }
    }

    func isLikelyHTTPService(_ process: PortProcessInfo) -> Bool {
        Self.webDevelopmentPorts.contains(process.port)
    }

    private func localhostURLString(for process: PortProcessInfo) -> String {
        "http://localhost:\(process.port)"
    }

    deinit {
        autoRefreshTask?.cancel()
        activationObservers.forEach(NotificationCenter.default.removeObserver)
    }

    func onAppear() {
        observeAppActivation()
        startAutoRefresh()
    }

    /// Polling only earns its keep while the user is looking at the app, so it
    /// is suspended whenever PortMedic is not the active application.
    private func observeAppActivation() {
        guard activationObservers.isEmpty else { return }

        let center = NotificationCenter.default
        activationObservers = [
            center.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.stopAutoRefresh() }
            },
            center.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self, self.isAutoRefreshEnabled else { return }
                    self.startAutoRefresh()
                }
            }
        ]
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let scanned = try await scanner.scan().sorted { $0.port < $1.port }
            // Skip republishing identical results so SwiftUI does not re-render
            // the whole table every poll when nothing has changed.
            if scanned != ports {
                ports = scanned
                updateFilteredPorts()
            }
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

    private func updateFilteredPorts() {
        guard !searchText.isEmpty else {
            filteredPorts = ports
            return
        }

        let query = searchText.lowercased()
        filteredPorts = ports.filter { process in
            // Also match the detected framework label (e.g. "postgres" should find a
            // container process named "docker"/"com.docker.backend" running Postgres).
            if process.searchableText.contains(query) { return true }
            return frameworkBadge(for: process)?.label.lowercased().contains(query) ?? false
        }
    }

    func requestKill(_ process: PortProcessInfo) {
        pendingKillTarget = process
    }

    func cancelPendingKill() {
        pendingKillTarget = nil
    }

    func cancelForceKill() {
        forceKillTarget = nil
    }

    func confirmKill() async {
        guard let target = pendingKillTarget else { return }
        await kill(target, force: false)
    }

    func confirmForceKill() async {
        guard let target = forceKillTarget else { return }
        await kill(target, force: true)
    }

    /// Takes the target explicitly: SwiftUI clears `pendingKillTarget` via the
    /// alert's `isPresented` binding *before* the button action runs, so reading
    /// it here would always find nil.
    func kill(_ target: PortProcessInfo, force: Bool) async {
        pendingKillTarget = nil
        forceKillTarget = nil

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
                if force {
                    errorMessage = """
                    Port \(target.port) is still in use by PID \(target.pid). \
                    It may be a supervised service (e.g. Docker Desktop) that restarts \
                    automatically, or require administrator privileges to stop.
                    """
                } else {
                    forceKillTarget = target
                }
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
