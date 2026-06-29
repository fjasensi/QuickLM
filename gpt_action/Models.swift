import Carbon
import Foundation

struct AppSettingsSnapshot {
    let baseURL: String
    let systemPrompt: String
    let temperature: Double
    let responseTimeout: TimeInterval
}

struct HotkeyShortcut: Identifiable, Equatable {
    let id: String
    let keyCode: UInt32
    let modifiers: UInt32
    let displayName: String

    static let optionSpace = HotkeyShortcut(
        id: "option-space",
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(optionKey),
        displayName: "Option + Space"
    )

    static let controlSpace = HotkeyShortcut(
        id: "control-space",
        keyCode: UInt32(kVK_Space),
        modifiers: UInt32(controlKey),
        displayName: "Control + Space"
    )

    static let optionReturn = HotkeyShortcut(
        id: "option-return",
        keyCode: UInt32(kVK_Return),
        modifiers: UInt32(optionKey),
        displayName: "Option + Return"
    )

    static let presets: [HotkeyShortcut] = [
        .optionSpace,
        .controlSpace,
        .optionReturn
    ]
}

struct LMModel: Decodable, Identifiable {
    let id: String
}

struct LMModelsResponse: Decodable {
    let data: [LMModel]
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let stream: Bool
}

struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String?
        }

        let message: Message
    }

    let choices: [Choice]
}

struct APIErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError
}

struct QuickLMAnswer {
    let model: String
    let content: String
}
