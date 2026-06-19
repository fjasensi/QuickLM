import AppKit
import SwiftUI

final class PreferencesWindowController {
    private let window: NSWindow

    init(settings: AppSettings) {
        let content = PreferencesView(settings: settings)
        let hostingView = NSHostingView(rootView: content)

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 430),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "QuickLM Preferences"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
    }

    func show() {
        if !window.isVisible {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
    }
}
