//
//  DashboardView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// The "Active Ports" screen: search bar + table of listening ports + status bar.
struct DashboardView: View {
    @ObservedObject var viewModel: PortListViewModel

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar
                PortTableHeaderView()

                if viewModel.filteredPorts.isEmpty {
                    emptyState
                } else {
                    List(viewModel.filteredPorts, selection: $viewModel.selectedProcess) { process in
                        PortRowView(
                            process: process,
                            badge: viewModel.frameworkBadge(for: process),
                            isSelected: viewModel.selectedProcess == process
                        ) {
                            viewModel.requestKill(process)
                        }
                        .tag(process)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparatorTint(Theme.rowBorder)
                        .listRowBackground(Theme.rowBackground)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                StatusBarView(activeCount: viewModel.ports.count, lastRefreshedAt: viewModel.lastRefreshedAt)
            }

            if let selected = viewModel.selectedProcess {
                Divider()
                ProcessDetailPanel(
                    process: selected,
                    badge: viewModel.frameworkBadge(for: selected),
                    viewModel: viewModel
                )
            }
        }
        .background(Theme.contentBackground)
        .task { viewModel.onAppear() }
        .alert(
            "Kill \(viewModel.pendingKillTarget?.processName ?? "") (PID \(viewModel.pendingKillTarget?.pid ?? 0))?",
            isPresented: Binding(
                get: { viewModel.pendingKillTarget != nil },
                set: { isPresented in if !isPresented { viewModel.cancelPendingKill() } }
            ),
            presenting: viewModel.pendingKillTarget
        ) { target in
            Button("Cancel", role: .cancel) { viewModel.cancelPendingKill() }
            Button("Kill", role: .destructive) { Task { await viewModel.kill(target) } }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { isPresented in if !isPresented { viewModel.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var topBar: some View {
        HStack {
            Text("Active Ports")
                .font(.title2.weight(.semibold))
                .foregroundStyle(Theme.primaryText)

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Theme.secondaryText)
                TextField("Search ports, PID…", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Theme.primaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(width: 220)
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 6))

            Button {
                Task { await viewModel.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.secondaryText)
            .disabled(viewModel.isLoading)
        }
        .padding(16)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "network.slash")
                .font(.largeTitle)
                .foregroundStyle(Theme.secondaryText)
            Text(viewModel.isLoading ? "Scanning ports…" : "No active ports found")
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    DashboardView(viewModel: PortListViewModel())
        .frame(width: 900, height: 500)
}
