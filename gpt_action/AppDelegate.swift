import AppKit

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var sharedDelegate: AppDelegate?

    private let settings = AppSettings.shared
    private var viewModel: QuickAskViewModel?
    private var quickAskWindowController: QuickAskWindowController?
    private var preferencesWindowController: PreferencesWindowController?
    private var menuBarController: MenuBarController?
    private var hotkeyManager: HotkeyManager?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        sharedDelegate = delegate
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        NSApp.setActivationPolicy(.accessory)

        let viewModel = QuickAskViewModel(settings: settings)
        self.viewModel = viewModel
        quickAskWindowController = QuickAskWindowController(viewModel: viewModel)
        preferencesWindowController = PreferencesWindowController(settings: settings)
        menuBarController = MenuBarController(
            openAction: { [weak self] in self?.showQuickAsk() },
            preferencesAction: { [weak self] in self?.showPreferences() },
            quitAction: { NSApp.terminate(nil) }
        )
        hotkeyManager = HotkeyManager(settings: settings) { [weak self] in
            self?.toggleQuickAsk()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func showQuickAsk() {
        quickAskWindowController?.show()
    }

    private func toggleQuickAsk() {
        quickAskWindowController?.toggle()
    }

    private func showPreferences() {
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindowController?.show()
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit QuickLM", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
}
