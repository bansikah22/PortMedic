//
//  SettingsViewModelTests.swift
//  PortMedicTests
//
//  Created by bansikah on 24/08/2026.
//

import XCTest
@testable import PortMedic

private final class FakeLoginItemManager: LoginItemManaging, @unchecked Sendable {
    var isEnabled: Bool
    var errorToThrow: Error?
    private(set) var setEnabledCalls: [Bool] = []

    init(isEnabled: Bool = false) {
        self.isEnabled = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        setEnabledCalls.append(enabled)
        if let errorToThrow { throw errorToThrow }
        isEnabled = enabled
    }
}

private struct TestError: LocalizedError {
    var errorDescription: String? { "boom" }
}

@MainActor
final class SettingsViewModelTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "SettingsViewModelTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fatalError("Could not create UserDefaults suite \(suiteName)")
        }
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func test_init_reflectsCurrentLoginItemStatus() {
        let manager = FakeLoginItemManager(isEnabled: true)
        let viewModel = SettingsViewModel(loginItemManager: manager, userDefaults: makeDefaults())

        XCTAssertTrue(viewModel.launchAtLoginEnabled)
    }

    func test_togglingLaunchAtLogin_registersWithLoginItemManager() {
        let manager = FakeLoginItemManager(isEnabled: false)
        let viewModel = SettingsViewModel(loginItemManager: manager, userDefaults: makeDefaults())

        viewModel.launchAtLoginEnabled = true

        XCTAssertEqual(manager.setEnabledCalls, [true])
    }

    func test_togglingLaunchAtLogin_revertsOnFailure() {
        let manager = FakeLoginItemManager(isEnabled: false)
        manager.errorToThrow = TestError()
        let viewModel = SettingsViewModel(loginItemManager: manager, userDefaults: makeDefaults())

        viewModel.launchAtLoginEnabled = true

        XCTAssertFalse(viewModel.launchAtLoginEnabled)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_appearance_defaultsToSystemWhenNoStoredValue() {
        let viewModel = SettingsViewModel(loginItemManager: FakeLoginItemManager(), userDefaults: makeDefaults())
        XCTAssertEqual(viewModel.appearance, .system)
    }

    func test_appearance_persistsToUserDefaults() {
        let defaults = makeDefaults()
        let viewModel = SettingsViewModel(loginItemManager: FakeLoginItemManager(), userDefaults: defaults)

        viewModel.appearance = .dark

        XCTAssertEqual(defaults.string(forKey: "com.portmedic.appearancePreference"), "dark")
    }
}
