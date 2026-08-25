//
//  SettingsViewModel.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import Foundation

/// Drives the Settings screen: login item registration and appearance
/// preference. Auto-refresh preferences live on `PortListViewModel` directly
/// since that's the single source of truth for scanning behavior.
@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var launchAtLoginEnabled: Bool {
        didSet {
            // Guards against infinite `didSet` recursion: reverting the value below
            // would otherwise re-trigger this observer and loop forever on failure.
            guard !isRevertingLoginItemChange, launchAtLoginEnabled != oldValue else { return }
            do {
                try loginItemManager.setEnabled(launchAtLoginEnabled)
            } catch {
                errorMessage = error.localizedDescription
                isRevertingLoginItemChange = true
                launchAtLoginEnabled = oldValue
                isRevertingLoginItemChange = false
            }
        }
    }

    @Published var appearance: AppearancePreference {
        didSet {
            userDefaults.set(appearance.rawValue, forKey: Self.appearanceDefaultsKey)
        }
    }

    @Published var errorMessage: String?

    private let loginItemManager: LoginItemManaging
    private let userDefaults: UserDefaults
    private var isRevertingLoginItemChange = false
    private static let appearanceDefaultsKey = "com.portmedic.appearancePreference"

    init(
        loginItemManager: LoginItemManaging = SMAppServiceLoginItemManager(),
        userDefaults: UserDefaults = .standard
    ) {
        self.loginItemManager = loginItemManager
        self.userDefaults = userDefaults
        self.launchAtLoginEnabled = loginItemManager.isEnabled
        let storedValue = userDefaults.string(forKey: Self.appearanceDefaultsKey)
        self.appearance = storedValue.flatMap(AppearancePreference.init(rawValue:)) ?? .system
    }
}
