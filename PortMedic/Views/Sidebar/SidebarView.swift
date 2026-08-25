//
//  SidebarView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Left-hand navigation matching the PortMedic mockups: app header, section
/// list, and a footer with secondary links.
struct SidebarView: View {
    @Binding var selection: AppSection

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 2) {
                ForEach(AppSection.allCases) { section in
                    row(for: section)
                }
            }
            .padding(.horizontal, 8)

            Spacer()
            footer
        }
        .background(Theme.sidebarBackground)
    }

    private func row(for section: AppSection) -> some View {
        let isSelected = selection == section
        return Button {
            guard section.isAvailable else { return }
            selection = section
        } label: {
            Label(section.rawValue, systemImage: section.systemImage)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(
                    isSelected ? .white
                        : section.isAvailable ? Theme.sidebarPrimaryText : Theme.sidebarDisabledText
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    isSelected ? Theme.sidebarSelectedBackground : Color.clear,
                    in: RoundedRectangle(cornerRadius: 6)
                )
        }
        .buttonStyle(.plain)
        .disabled(!section.isAvailable)
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(nsImage: Self.appIcon)
                .resizable()
                .interpolation(.high)
                .frame(width: 36, height: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("PortMedic")
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundStyle(Theme.sidebarPrimaryText)
                Text("v\(Bundle.main.appVersion)")
                    .font(.caption2)
                    .foregroundStyle(Theme.sidebarSecondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }

    /// Reads the real app icon so the sidebar can never drift from the bundle icon.
    private static let appIcon: NSImage =
        NSImage(named: "AppIcon") ?? NSApplication.shared.applicationIconImage

    private var footer: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Help", systemImage: "questionmark.circle")
            Label("Feedback", systemImage: "bubble.left")
        }
        .font(.subheadline)
        .foregroundStyle(Theme.sidebarSecondaryText)
        .padding(16)
    }
}

private extension Bundle {
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
}

#Preview {
    SidebarView(selection: .constant(.dashboard))
        .frame(width: 220, height: 500)
}
