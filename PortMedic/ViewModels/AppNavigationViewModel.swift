//
//  AppNavigationViewModel.swift
//  PortMedic
//

import AppKit
import Foundation

@MainActor
final class AppNavigationViewModel: ObservableObject {
    @Published var selectedSection: AppSection = .dashboard
    @Published private(set) var searchFocusRequest = UUID()

    func openDashboardAndFocusSearch() {
        selectedSection = .dashboard
        searchFocusRequest = UUID()
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
}
