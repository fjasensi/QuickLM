import AppKit
import Combine
import Foundation

final class QuickAskViewModel: ObservableObject {
    @Published var prompt = ""
    @Published var answer = ""
    @Published var errorMessage: String?
    @Published var activeModel: String?
    @Published var isLoading = false
    @Published var isCheckingModel = false
    @Published var focusToken = UUID()
    private var history: [ChatMessage] = []

    private let settings: AppSettings
    private let client: LMStudioClient

    init(settings: AppSettings, client: LMStudioClient = LMStudioClient()) {
        self.settings = settings
        self.client = client
    }

    func prepareForPresentation() {
        errorMessage = nil
        refreshActiveModel()
        focusPrompt()
    }

    func sendCurrentPrompt() {
        guard !isLoading else { return }

        let question = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else {
            errorMessage = "Type a question first."
            focusPrompt()
            return
        }

        prompt = ""

        Task {
            await ask(question)
        }
    }

    func startNewChat() {
        prompt = ""
        answer = ""
        history = []
        errorMessage = nil
        focusPrompt()
    }

    func copyAnswer() {
        guard !answer.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(answer, forType: .string)
    }

    private func ask(_ question: String) async {
        isLoading = true
        errorMessage = nil
        answer = ""

        let currentSettings = settings.snapshot()
        let messages = [ChatMessage(role: "system", content: currentSettings.systemPrompt)] + history + [ChatMessage(role: "user", content: question)]

        do {
            let result = try await client.ask(messages: messages, settings: currentSettings)
            answer = result.content
            activeModel = result.model
            
            history.append(ChatMessage(role: "user", content: question))
            history.append(ChatMessage(role: "assistant", content: result.content))
        } catch {
            errorMessage = userFacingMessage(for: error)
        }

        isLoading = false
        focusPrompt()
    }

    private func refreshActiveModel() {
        guard !isCheckingModel else { return }

        isCheckingModel = true

        Task {
            do {
                let model = try await client.firstAvailableModel(settings: settings.snapshot())
                activeModel = model.id
            } catch {
                activeModel = nil
            }

            isCheckingModel = false
        }
    }

    private func focusPrompt() {
        focusToken = UUID()
    }

    private func userFacingMessage(for error: Error) -> String {
        if let lmStudioError = error as? LMStudioError {
            return lmStudioError.localizedDescription
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .cannotConnectToHost, .cannotFindHost, .networkConnectionLost, .notConnectedToInternet:
                return "LM Studio is not reachable. Open LM Studio, load a model, and check that the local server is running."
            case .timedOut:
                return "LM Studio timed out. The model may still be loading or busy."
            default:
                return "Network error: \(urlError.localizedDescription)"
            }
        }

        if error is DecodingError {
            return "LM Studio returned JSON that QuickLM could not read."
        }

        return "Unexpected error: \(error.localizedDescription)"
    }
}
