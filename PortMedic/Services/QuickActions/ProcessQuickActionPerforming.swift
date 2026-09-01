//
//  ProcessQuickActionPerforming.swift
//  PortMedic
//

import AppKit
import Foundation

protocol ProcessQuickActionPerforming {
    func copyToClipboard(_ value: String)
    func openInBrowser(_ url: URL) -> Bool
}

struct AppKitProcessQuickActionService: ProcessQuickActionPerforming {
    func copyToClipboard(_ value: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
    }

    func openInBrowser(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }
}
