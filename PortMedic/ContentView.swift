//
//  ContentView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedSection: AppSection = .dashboard
    @EnvironmentObject private var portListViewModel: PortListViewModel
    @EnvironmentObject private var settingsViewModel: SettingsViewModel
    @EnvironmentObject private var watchedPortsViewModel: WatchedPortsViewModel

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } detail: {
            switch selectedSection {
            case .dashboard:
                DashboardView(viewModel: portListViewModel)
            case .favorites:
                WatchedPortsView(
                    watchedPortsViewModel: watchedPortsViewModel,
                    portListViewModel: portListViewModel
                )
            case .settings:
                SettingsView(
                    settingsViewModel: settingsViewModel,
                    portListViewModel: portListViewModel,
                    watchedPortsViewModel: watchedPortsViewModel
                )
            case .history:
                comingSoon(for: selectedSection)
            }
        }
        .navigationTitle("")
    }

    private func comingSoon(for section: AppSection) -> some View {
        VStack(spacing: 8) {
            Image(systemName: section.systemImage)
                .font(.largeTitle)
                .foregroundStyle(Theme.secondaryText)
            Text("\(section.rawValue) is coming soon")
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.contentBackground)
    }
}

#Preview {
    ContentView()
        .environmentObject(PortListViewModel())
        .environmentObject(SettingsViewModel())
        .environmentObject(WatchedPortsViewModel())
}
