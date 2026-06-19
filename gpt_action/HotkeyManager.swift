import Carbon
import Combine
import Foundation

final class HotkeyManager {
    private static let signature: OSType = 0x514C4D31

    private let settings: AppSettings
    private let action: () -> Void
    private var eventHandlerRef: EventHandlerRef?
    private var eventHotKeyRef: EventHotKeyRef?
    private var settingsCancellable: AnyCancellable?

    init(settings: AppSettings, action: @escaping () -> Void) {
        self.settings = settings
        self.action = action
        installEventHandler()
        register(settings.hotkeyShortcut)

        settingsCancellable = settings.$selectedHotkeyID
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                self.register(self.settings.hotkeyShortcut)
            }
    }

    deinit {
        unregisterHotkey()

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            HotkeyManager.hotkeyEventHandler,
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    private func register(_ shortcut: HotkeyShortcut) {
        unregisterHotkey()

        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = HotkeyManager.signature
        hotKeyID.id = 1

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &eventHotKeyRef
        )

        // Option + Space can fail if another app or input source owns it. Pick another preset in Preferences.
        if status != noErr {
            NSLog("QuickLM could not register hotkey %@. OSStatus: %d", shortcut.displayName, status)
            eventHotKeyRef = nil
        }
    }

    private func unregisterHotkey() {
        if let eventHotKeyRef {
            UnregisterEventHotKey(eventHotKeyRef)
            self.eventHotKeyRef = nil
        }
    }

    private func handleHotkey() {
        action()
    }

    private static let hotkeyEventHandler: EventHandlerUPP = { _, _, userData in
        guard let userData else {
            return noErr
        }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        DispatchQueue.main.async {
            manager.handleHotkey()
        }

        return noErr
    }
}
