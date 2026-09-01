//
//  GlobalShortcutManaging.swift
//  PortMedic
//

import Carbon
import Foundation

protocol GlobalShortcutManaging: AnyObject {
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool) throws
}

enum GlobalShortcutError: LocalizedError {
    case registrationFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "The global shortcut could not be registered. It may be in use by another app."
        }
    }
}

final class CarbonGlobalShortcutManager: GlobalShortcutManaging {
    private let handler: () -> Void
    private var eventHandlerReference: EventHandlerRef?
    private var hotKeyReference: EventHotKeyRef?

    var isEnabled: Bool { hotKeyReference != nil }

    init(handler: @escaping () -> Void) {
        self.handler = handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(
            GetEventDispatcherTarget(),
            Self.eventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerReference
        )
    }

    deinit {
        unregister()
        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
        }
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try register()
        } else {
            unregister()
        }
    }

    private func register() throws {
        guard hotKeyReference == nil else { return }

        var identifier = EventHotKeyID(signature: OSType(0x504D4544), id: 1)
        let status = RegisterEventHotKey(
            UInt32(kVK_ANSI_P),
            UInt32(optionKey | cmdKey),
            identifier,
            GetEventDispatcherTarget(),
            0,
            &hotKeyReference
        )
        guard status == noErr else {
            hotKeyReference = nil
            throw GlobalShortcutError.registrationFailed(status)
        }
    }

    private func unregister() {
        guard let hotKeyReference else { return }
        UnregisterEventHotKey(hotKeyReference)
        self.hotKeyReference = nil
    }

    private static let eventHandler: EventHandlerUPP = { _, _, userData in
        guard let userData else { return noErr }
        let manager = Unmanaged<CarbonGlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
            manager.handler()
        }
        return noErr
    }
}
