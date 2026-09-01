//
//  SettingsView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Preferences screen matching the PortMedic mockup: a tab sidebar plus a
/// "General Preferences" form.
struct SettingsView: View {
    @ObservedObject var settingsViewModel: SettingsViewModel
    @ObservedObject var portListViewModel: PortListViewModel
    @ObservedObject var watchedPortsViewModel: WatchedPortsViewModel

    private enum Tab: String, CaseIterable, Identifiable {
        case general = "General"
        case favorites = "Watched Ports"
        case notifications = "Notifications"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .general: return "gearshape"
            case .favorites: return "eye"
            case .notifications: return "bell"
            }
        }
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(Tab.allCases) { tab in
                    tabRow(tab)
                }
                Spacer()
            }
            .padding(8)
            .frame(width: 180)
            .background(Theme.sidebarBackground)

            Divider()

            Group {
                switch selectedTab {
                case .general: generalPreferences
                case .favorites:
                    WatchedPortsView(
                        watchedPortsViewModel: watchedPortsViewModel,
                        portListViewModel: portListViewModel
                    )
                case .notifications: placeholder("Notifications")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(selectedTab == .favorites ? 0 : 24)
            .background(Theme.contentBackground)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { settingsViewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { settingsViewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { settingsViewModel.errorMessage = nil }
        } message: {
            Text(settingsViewModel.errorMessage ?? "")
        }
    }

    private func tabRow(_ tab: Tab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            Label(tab.rawValue, systemImage: tab.systemImage)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Theme.sidebarPrimaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.sidebarSelectedBackground : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
    }

    private var generalPreferences: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General Preferences")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.primaryText)

            Toggle(isOn: $settingsViewModel.launchAtLoginEnabled) {
                labeled("Launch at Login", "Automatically start PortMedic in the menu bar when you log in.")
            }

            Toggle(isOn: $portListViewModel.isAutoRefreshEnabled) {
                labeled("Auto-refresh Ports", "Periodically scan for new port activity in the background.")
            }

            Divider().overlay(Theme.rowBorder)

            HStack {
                Text("Refresh Interval")
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                TextField("", value: $portListViewModel.autoRefreshIntervalSeconds, format: .number)
                    .frame(width: 50)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.roundedBorder)
                Text("seconds")
                    .foregroundStyle(Theme.secondaryText)
            }

            Divider().overlay(Theme.rowBorder)

            HStack {
                Text("Appearance")
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Picker("", selection: $settingsViewModel.appearance) {
                    ForEach(AppearancePreference.allCases) { preference in
                        Text(preference.label).tag(preference)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 220)
            }
        }
    }

    private func labeled(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundStyle(Theme.primaryText)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Theme.secondaryText)
        }
    }

    private func placeholder(_ title: String) -> some View {
        Text("\(title) settings coming soon")
            .foregroundStyle(Theme.secondaryText)
    }
}

#Preview {
    SettingsView(
        settingsViewModel: SettingsViewModel(),
        portListViewModel: PortListViewModel(),
        watchedPortsViewModel: WatchedPortsViewModel()
    )
        .frame(width: 700, height: 450)
}
