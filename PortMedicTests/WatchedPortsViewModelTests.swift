//
//  WatchedPortsViewModelTests.swift
//  PortMedicTests
//

import XCTest
@testable import PortMedic

private final class FakeWatchedPortStore: WatchedPortStoring {
    var storedPorts: [WatchedPort]
    private(set) var savedPorts: [[WatchedPort]] = []

    init(storedPorts: [WatchedPort] = []) {
        self.storedPorts = storedPorts
    }

    func loadWatchedPorts() -> [WatchedPort] {
        storedPorts
    }

    func saveWatchedPorts(_ ports: [WatchedPort]) {
        storedPorts = ports
        savedPorts.append(ports)
    }
}

@MainActor
final class WatchedPortsViewModelTests: XCTestCase {
    func test_init_loadsPortsSortedByNumber() {
        let store = FakeWatchedPortStore(storedPorts: [
            WatchedPort(port: 8080, label: "Backend"),
            WatchedPort(port: 3000, label: nil)
        ])

        let viewModel = WatchedPortsViewModel(store: store)

        XCTAssertEqual(viewModel.watchedPorts.map(\.port), [3000, 8080])
    }

    func test_add_persistsTrimmedLabelAndSortsPorts() {
        let store = FakeWatchedPortStore(storedPorts: [WatchedPort(port: 8080, label: nil)])
        let viewModel = WatchedPortsViewModel(store: store)

        viewModel.add(port: 3000, label: "  Frontend  ")

        XCTAssertEqual(viewModel.watchedPorts, [
            WatchedPort(port: 3000, label: "Frontend"),
            WatchedPort(port: 8080, label: nil)
        ])
        XCTAssertEqual(store.savedPorts.last, viewModel.watchedPorts)
    }

    func test_add_rejectsDuplicatePort() {
        let store = FakeWatchedPortStore(storedPorts: [WatchedPort(port: 8080, label: nil)])
        let viewModel = WatchedPortsViewModel(store: store)

        viewModel.add(port: 8080, label: "Duplicate")

        XCTAssertEqual(viewModel.watchedPorts.count, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(store.savedPorts.isEmpty)
    }

    func test_add_rejectsPortOutsideValidRange() {
        let store = FakeWatchedPortStore()
        let viewModel = WatchedPortsViewModel(store: store)

        viewModel.add(port: 65_536, label: "Invalid")

        XCTAssertTrue(viewModel.watchedPorts.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(store.savedPorts.isEmpty)
    }

    func test_remove_persistsRemainingPorts() {
        let port = WatchedPort(port: 8080, label: nil)
        let store = FakeWatchedPortStore(storedPorts: [port])
        let viewModel = WatchedPortsViewModel(store: store)

        viewModel.remove(port)

        XCTAssertTrue(viewModel.watchedPorts.isEmpty)
        XCTAssertEqual(store.savedPorts.last, [])
    }
}
