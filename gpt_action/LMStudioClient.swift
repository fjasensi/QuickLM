import Foundation

enum LMStudioError: LocalizedError {
    case invalidBaseURL
    case noModels
    case httpStatus(Int, String?)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "The Base URL is invalid. Check Preferences."
        case .noModels:
            return "No model is loaded in LM Studio. Open LM Studio, load a model, and start the local server."
        case let .httpStatus(code, message):
            if let message, !message.isEmpty {
                return "LM Studio returned HTTP \(code): \(message)"
            }
            return "LM Studio returned HTTP \(code)."
        case .emptyResponse:
            return "LM Studio returned an empty response."
        }
    }
}

struct LMStudioClient {
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(session: URLSession = .shared) {
        self.session = session
    }

    func ask(messages: [ChatMessage], settings: AppSettingsSnapshot) async throws -> QuickLMAnswer {
        let model = try await firstAvailableModel(settings: settings)
        let url = try endpoint("chat/completions", baseURL: settings.baseURL)

        let payload = ChatCompletionRequest(
            model: model.id,
            messages: messages,
            temperature: settings.temperature,
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = settings.responseTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(payload)

        let data = try await send(request)
        let response = try decoder.decode(ChatCompletionResponse.self, from: data)
        let content = response.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let content, !content.isEmpty else {
            throw LMStudioError.emptyResponse
        }

        return QuickLMAnswer(model: model.id, content: content)
    }

    func firstAvailableModel(settings: AppSettingsSnapshot) async throws -> LMModel {
        let url = try endpoint("models", baseURL: settings.baseURL)

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        let data = try await send(request)
        let response = try decoder.decode(LMModelsResponse.self, from: data)

        guard let model = response.data.first else {
            throw LMStudioError.noModels
        }

        return model
    }

    private func endpoint(_ path: String, baseURL: String) throws -> URL {
        guard var components = URLComponents(string: baseURL), components.scheme != nil, components.host != nil else {
            throw LMStudioError.invalidBaseURL
        }

        if components.host?.lowercased() == "localhost" {
            components.host = "127.0.0.1"
        }

        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        components.path = "/" + ([basePath, path].filter { !$0.isEmpty }.joined(separator: "/"))

        guard let url = components.url else {
            throw LMStudioError.invalidBaseURL
        }

        return url
    }

    private func send(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            return data
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let apiMessage = try? decoder.decode(APIErrorResponse.self, from: data).error.message
            let rawMessage = String(data: data, encoding: .utf8)
            throw LMStudioError.httpStatus(httpResponse.statusCode, apiMessage ?? rawMessage)
        }

        return data
    }
}
