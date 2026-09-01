//
//  PortMedicApp.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

@main
struct PortMedicApp: App {
    @StateObject private var portListViewModel = PortListViewModel()
    @StateObject private var settingsViewModel: SettingsViewModel
    @StateObject private var watchedPortsViewModel = WatchedPortsViewModel()
    @StateObject private var navigationViewModel: AppNavigationViewModel

    init() {
        let navigationViewModel = AppNavigationViewModel()
        _navigationViewModel = StateObject(wrappedValue: navigationViewModel)
        _settingsViewModel = StateObject(
            wrappedValue: SettingsViewModel(
                globalShortcutManager: CarbonGlobalShortcutManager {
                    Task { @MainActor in
                        navigationViewModel.openDashboardAndFocusSearch()
                    }
                }
            )
        )
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(portListViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(watchedPortsViewModel)
                .environmentObject(navigationViewModel)
                .preferredColorScheme(settingsViewModel.appearance.colorScheme)
        }

        MenuBarExtra("PortMedic", systemImage: "bandage.fill") {
            MenuBarContentView(
                viewModel: portListViewModel,
                watchedPortsViewModel: watchedPortsViewModel
            )
        }
        .menuBarExtraStyle(.window)
    }
}
