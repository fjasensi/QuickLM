import Combine
import Foundation

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var baseURL: String {
        didSet { defaults.set(baseURL, forKey: Keys.baseURL) }
    }

    @Published var systemPrompt: String {
        didSet { defaults.set(systemPrompt, forKey: Keys.systemPrompt) }
    }

    @Published var temperature: Double {
        didSet { defaults.set(temperature, forKey: Keys.temperature) }
    }

    @Published var responseTimeout: Double {
        didSet { defaults.set(responseTimeout, forKey: Keys.responseTimeout) }
    }

    @Published var selectedHotkeyID: String {
        didSet { defaults.set(selectedHotkeyID, forKey: Keys.selectedHotkeyID) }
    }

    private let defaults: UserDefaults

    var hotkeyShortcut: HotkeyShortcut {
        HotkeyShortcut.presets.first { $0.id == selectedHotkeyID } ?? .optionSpace
    }

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        baseURL = defaults.string(forKey: Keys.baseURL) ?? Defaults.baseURL
        systemPrompt = defaults.string(forKey: Keys.systemPrompt) ?? Defaults.systemPrompt

        if defaults.object(forKey: Keys.temperature) == nil {
            temperature = Defaults.temperature
        } else {
            temperature = defaults.double(forKey: Keys.temperature)
        }

        if defaults.object(forKey: Keys.responseTimeout) == nil {
            responseTimeout = Defaults.responseTimeout
        } else {
            responseTimeout = defaults.double(forKey: Keys.responseTimeout)
        }

        selectedHotkeyID = defaults.string(forKey: Keys.selectedHotkeyID) ?? HotkeyShortcut.optionSpace.id
    }

    func snapshot() -> AppSettingsSnapshot {
        AppSettingsSnapshot(
            baseURL: baseURL.trimmingCharacters(in: .whitespacesAndNewlines),
            systemPrompt: systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines),
            temperature: max(0, min(temperature, 2)),
            responseTimeout: max(30, min(responseTimeout, 600))
        )
    }

    func resetDefaults() {
        baseURL = Defaults.baseURL
        systemPrompt = Defaults.systemPrompt
        temperature = Defaults.temperature
        responseTimeout = Defaults.responseTimeout
        selectedHotkeyID = HotkeyShortcut.optionSpace.id
    }

    private enum Keys {
        static let baseURL = "baseURL"
        static let systemPrompt = "systemPrompt"
        static let temperature = "temperature"
        static let responseTimeout = "responseTimeout"
        static let selectedHotkeyID = "selectedHotkeyID"
    }

    private enum Defaults {
        static let baseURL = "http://localhost:1234/v1"
        static let systemPrompt = "You are a concise assistant for quick questions. Answer clearly and directly."
        static let temperature = 0.3
        static let responseTimeout = 180.0
    }
}
