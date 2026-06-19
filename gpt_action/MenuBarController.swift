import AppKit

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let actionTarget = MenuActionTarget()

    init(openAction: @escaping () -> Void, preferencesAction: @escaping () -> Void, quitAction: @escaping () -> Void) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        actionTarget.openAction = openAction
        actionTarget.preferencesAction = preferencesAction
        actionTarget.quitAction = quitAction

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: "QuickLM")
            button.image?.isTemplate = true
            button.toolTip = "QuickLM"
        }

        let menu = NSMenu()
        menu.addItem(makeItem(title: "Open QuickLM", action: #selector(MenuActionTarget.openQuickLM), keyEquivalent: "o"))
        menu.addItem(makeItem(title: "Preferences", action: #selector(MenuActionTarget.openPreferences), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(makeItem(title: "Quit", action: #selector(MenuActionTarget.quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func makeItem(title: String, action: Selector, keyEquivalent: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
        item.target = actionTarget
        return item
    }
}

private final class MenuActionTarget: NSObject {
    var openAction: (() -> Void)?
    var preferencesAction: (() -> Void)?
    var quitAction: (() -> Void)?

    @objc func openQuickLM() {
        openAction?()
    }

    @objc func openPreferences() {
        preferencesAction?()
    }

    @objc func quit() {
        quitAction?()
    }
}
