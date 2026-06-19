import AppKit
import SwiftUI

final class QuickAskWindowController {
    private let viewModel: QuickAskViewModel
    private let panel: QuickAskPanel

    init(viewModel: QuickAskViewModel) {
        self.viewModel = viewModel
        panel = QuickAskPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 430),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let content = QuickAskView(viewModel: viewModel) { [weak panel] in
            panel?.orderOut(nil)
        }
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = panel.contentView?.bounds ?? NSRect(x: 0, y: 0, width: 720, height: 430)
        hostingView.autoresizingMask = [.width, .height]

        panel.contentView = hostingView
        panel.onEscape = { [weak panel] in panel?.orderOut(nil) }
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
    }

    var isVisible: Bool {
        panel.isVisible
    }

    func show() {
        positionPanel()
        viewModel.prepareForPresentation()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }

    func toggle() {
        isVisible ? hide() : show()
    }

    private func positionPanel() {
        let targetScreen = NSScreen.main ?? NSScreen.screens.first
        guard let visibleFrame = targetScreen?.visibleFrame else {
            panel.center()
            return
        }

        let size = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.midY - size.height / 2 + 80
        )

        panel.setFrameOrigin(origin)
    }
}

final class QuickAskPanel: NSPanel {
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command), !flags.contains(.control), !flags.contains(.option) else {
            return super.performKeyEquivalent(with: event)
        }

        let selector: Selector?
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "a":
            selector = #selector(NSText.selectAll(_:))
        case "c":
            selector = #selector(NSText.copy(_:))
        case "v":
            selector = #selector(NSText.paste(_:))
        case "x":
            selector = #selector(NSText.cut(_:))
        case "z":
            selector = flags.contains(.shift) ? Selector(("redo:")) : Selector(("undo:"))
        default:
            selector = nil
        }

        if let selector, NSApp.sendAction(selector, to: nil, from: self) {
            return true
        }

        return super.performKeyEquivalent(with: event)
    }
}
