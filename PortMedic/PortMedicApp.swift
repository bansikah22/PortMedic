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
    @StateObject private var settingsViewModel = SettingsViewModel()
    @StateObject private var watchedPortsViewModel = WatchedPortsViewModel()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(portListViewModel)
                .environmentObject(settingsViewModel)
                .environmentObject(watchedPortsViewModel)
                .preferredColorScheme(settingsViewModel.appearance.colorScheme)
        }

        MenuBarExtra("PortMedic", systemImage: "bandage.fill") {
            MenuBarContentView(viewModel: portListViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
