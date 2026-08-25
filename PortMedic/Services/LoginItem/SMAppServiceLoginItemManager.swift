//
//  SMAppServiceLoginItemManager.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import ServiceManagement

/// Registers/unregisters PortMedic as a login item using the modern
/// ServiceManagement API (macOS 13+). See Apple's SMAppService documentation.
struct SMAppServiceLoginItemManager: LoginItemManaging {
    // SMAppService talks to a system XPC service that misbehaves (hangs/crashes)
    // when the app is launched as an XCTest host bundle rather than normally,
    // so it's skipped entirely under test.
    private var isRunningInTestHost: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    var isEnabled: Bool {
        guard !isRunningInTestHost else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) throws {
        guard !isRunningInTestHost else { return }
        if enabled {
            guard SMAppService.mainApp.status != .enabled else { return }
            try SMAppService.mainApp.register()
        } else {
            guard SMAppService.mainApp.status == .enabled else { return }
            try SMAppService.mainApp.unregister()
        }
    }
}
