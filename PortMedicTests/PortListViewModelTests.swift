//
//  PortListViewModelTests.swift
//  PortMedicTests
//
//  Created by bansikah on 24/08/2026.
//

import XCTest
@testable import PortMedic

private final class FakePortScanner: PortScanning, @unchecked Sendable {
    var portsToReturn: [PortProcessInfo] = []
    var errorToThrow: Error?

    init(portsToReturn: [PortProcessInfo] = [], errorToThrow: Error? = nil) {
        self.portsToReturn = portsToReturn
        self.errorToThrow = errorToThrow
    }

    func scan() async throws -> [PortProcessInfo] {
        if let errorToThrow { throw errorToThrow }
        return portsToReturn
    }
}

private final class FakeProcessTerminator: ProcessTerminating, @unchecked Sendable {
    private(set) var terminatedPIDs: [pid_t] = []
    private(set) var forceTerminatedPIDs: [pid_t] = []
    var errorToThrow: Error?
    /// Lets a test model the port actually being released by the signal.
    var onSignal: (() -> Void)?

    func terminate(pid: pid_t) throws {
        if let errorToThrow { throw errorToThrow }
        terminatedPIDs.append(pid)
        onSignal?()
    }

    func forceTerminate(pid: pid_t) throws {
        if let errorToThrow { throw errorToThrow }
        forceTerminatedPIDs.append(pid)
        onSignal?()
    }
}

@MainActor
final class PortListViewModelTests: XCTestCase {
    private func makeProcess(pid: pid_t = 100, port: Int = 8080, name: String = "java") -> PortProcessInfo {
        PortProcessInfo(pid: pid, port: port, transportProtocol: .tcp, processName: name, user: "joetec")
    }

    func test_refresh_populatesPortsSortedByPort() async {
        let scanner = FakePortScanner(portsToReturn: [
            makeProcess(pid: 1, port: 8080),
            makeProcess(pid: 2, port: 3000),
        ])
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())

        await viewModel.refresh()

        XCTAssertEqual(viewModel.ports.map(\.port), [3000, 8080])
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_refresh_setsErrorMessageOnFailure() async {
        let scanner = FakePortScanner(errorToThrow: PortScanningError.executableNotFound)
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())

        await viewModel.refresh()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.ports.isEmpty)
    }

    func test_filteredPorts_matchesSearchTextAcrossFields() async {
        let scanner = FakePortScanner(portsToReturn: [
            makeProcess(pid: 42, port: 5432, name: "postgres"),
            makeProcess(pid: 99, port: 3000, name: "node"),
        ])
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())
        await viewModel.refresh()

        viewModel.searchText = "postgres"
        XCTAssertEqual(viewModel.filteredPorts.map(\.pid), [42])

        viewModel.searchText = "3000"
        XCTAssertEqual(viewModel.filteredPorts.map(\.pid), [99])

        viewModel.searchText = ""
        XCTAssertEqual(viewModel.filteredPorts.count, 2)
    }

    func test_filteredPorts_matchesDetectedFrameworkLabel() async {
        // A dockerized Postgres reports as process "docker", not "postgres";
        // search should still find it via the detected framework badge.
        let scanner = FakePortScanner(portsToReturn: [
            makeProcess(pid: 7, port: 5432, name: "docker"),
            makeProcess(pid: 8, port: 3000, name: "node"),
        ])
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())
        await viewModel.refresh()

        viewModel.searchText = "postgres"

        XCTAssertEqual(viewModel.filteredPorts.map(\.pid), [7])
    }

    func test_confirmKill_terminatesPendingTargetAndRefreshes() async {
        let target = makeProcess(pid: 4512, port: 8080)
        let scanner = FakePortScanner(portsToReturn: [target])
        let terminator = FakeProcessTerminator()
        let viewModel = PortListViewModel(scanner: scanner, terminator: terminator)
        await viewModel.refresh()

        viewModel.requestKill(target)
        XCTAssertEqual(viewModel.pendingKillTarget, target)

        terminator.onSignal = { scanner.portsToReturn = [] }
        await viewModel.confirmKill()

        // The default kill action sends SIGKILL directly, since supervised
        // daemons (e.g. Docker) often ignore SIGTERM.
        XCTAssertEqual(terminator.forceTerminatedPIDs, [4512])
        XCTAssertNil(viewModel.pendingKillTarget)
    }

    func test_kill_terminatesTargetEvenWhenPendingTargetAlreadyCleared() async {
        // Regression: SwiftUI's alert clears `pendingKillTarget` via its
        // `isPresented` binding before the button action fires, so `kill` must
        // not depend on that state.
        let target = makeProcess(pid: 32018, port: 5173)
        let scanner = FakePortScanner(portsToReturn: [target])
        let terminator = FakeProcessTerminator()
        let viewModel = PortListViewModel(scanner: scanner, terminator: terminator)
        await viewModel.refresh()

        viewModel.requestKill(target)
        viewModel.cancelPendingKill()
        terminator.onSignal = { scanner.portsToReturn = [] }
        await viewModel.kill(target)

        XCTAssertEqual(terminator.forceTerminatedPIDs, [32018])
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_kill_doesNotSignalWhenTargetNoLongerHoldsThePort() async {
        // Guards against PID reuse: if the process exited between the scan and
        // the click, the PID may now belong to something unrelated.
        let target = makeProcess(pid: 4512, port: 8080)
        let scanner = FakePortScanner(portsToReturn: [target])
        let terminator = FakeProcessTerminator()
        let viewModel = PortListViewModel(scanner: scanner, terminator: terminator)
        await viewModel.refresh()

        scanner.portsToReturn = []
        await viewModel.kill(target)

        XCTAssertTrue(terminator.forceTerminatedPIDs.isEmpty)
        XCTAssertTrue(terminator.terminatedPIDs.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_confirmKill_setsErrorMessageWhenProcessSurvives() async {
        // Some processes (e.g. supervised system services) get respawned or
        // ignore the kill signal; the port stays occupied after a refresh.
        let target = makeProcess(pid: 4512, port: 8080)
        let scanner = FakePortScanner(portsToReturn: [target])
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())
        await viewModel.refresh()

        viewModel.requestKill(target)
        await viewModel.confirmKill()

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_confirmKill_withGracefulTerminate_sendsTerminate() async {
        let target = makeProcess(pid: 7, port: 9090)
        let scanner = FakePortScanner(portsToReturn: [target])
        let terminator = FakeProcessTerminator()
        let viewModel = PortListViewModel(scanner: scanner, terminator: terminator)

        viewModel.requestKill(target)
        terminator.onSignal = { scanner.portsToReturn = [] }
        await viewModel.confirmKill(force: false)

        XCTAssertEqual(terminator.terminatedPIDs, [7])
        XCTAssertTrue(terminator.forceTerminatedPIDs.isEmpty)
    }

    func test_cancelPendingKill_clearsTargetWithoutTerminating() async {
        let target = makeProcess()
        let terminator = FakeProcessTerminator()
        let viewModel = PortListViewModel(scanner: FakePortScanner(), terminator: terminator)

        viewModel.requestKill(target)
        viewModel.cancelPendingKill()

        XCTAssertNil(viewModel.pendingKillTarget)
        XCTAssertTrue(terminator.terminatedPIDs.isEmpty)
    }

    func test_confirmKill_setsErrorMessageOnFailure() async {
        let target = makeProcess()
        let terminator = FakeProcessTerminator()
        terminator.errorToThrow = ProcessTerminationError.permissionDenied(pid: target.pid)
        let viewModel = PortListViewModel(scanner: FakePortScanner(), terminator: terminator)

        viewModel.requestKill(target)
        await viewModel.confirmKill()

        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_refresh_clearsSelectionWhenSelectedProcessDisappears() async {
        let target = makeProcess(pid: 4512, port: 8080)
        let scanner = FakePortScanner(portsToReturn: [target])
        let viewModel = PortListViewModel(scanner: scanner, terminator: FakeProcessTerminator())
        await viewModel.refresh()

        viewModel.selectedProcess = target
        scanner.portsToReturn = []
        await viewModel.refresh()

        XCTAssertNil(viewModel.selectedProcess)
    }
}