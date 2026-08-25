//
//  PortTableHeaderView.swift
//  PortMedic
//
//  Created by bansikah on 24/08/2026.
//

import SwiftUI

/// Column headers for the active ports table.
struct PortTableHeaderView: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("PORT")
                .frame(width: 90, alignment: .leading)
            Text("PID")
                .frame(width: 70, alignment: .leading)
            Text("PROCESS")
                .frame(minWidth: 160, alignment: .leading)
            Text("FRAMEWORK/INFO")
                .frame(minWidth: 160, alignment: .leading)
            Spacer()
            Text("ACTION")
                .frame(width: 70, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Theme.headerText)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(Theme.rowBorder).frame(height: 1), alignment: .bottom)
    }
}

#Preview {
    PortTableHeaderView()
        .background(Theme.contentBackground)
}
