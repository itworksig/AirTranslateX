import Foundation

actor OpenAITranslationService: TranslationProvider {
    private let endpoint = URL(string: "https://api.openai.com/v1/responses")!
    private let googleTranslateEndpoint = URL(string: "https://translation.googleapis.com/language/translate/v2")!
    private let deepLFreeEndpoint = URL(string: "https://api-free.deepl.com/v2/translate")!
    private let deepLProEndpoint = URL(string: "https://api.deepl.com/v2/translate")!
    private var lastProviderRequestAt = Date.distantPast
    private let minimumProviderRequestInterval: TimeInterval = 0.18

    func translate(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        model selectedModel: AITranslationModel
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        guard selectedModel.isEnabled else { return text }
        guard let apiKey = try OpenAIAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        await throttleProviderRequest()

        let request = try Self.makeOpenAIResponseRequest(
            apiKey: apiKey,
            text: text,
            source: source,
            target: target,
            model: selectedModel.textFallbackModelID
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let responseBody = try JSONDecoder().decode(OpenAIResponseBody.self, from: data)
        guard let outputText = responseBody.firstOutputText else {
            throw OpenAITranslationError.emptyOutput
        }
        return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func translateWithChatCompletions(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        configuration: CustomLLMAPIConfiguration,
        context: TranslationContext? = nil,
        scenarioMode: CaptionScenarioMode = .standard
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        guard let apiKey = try OpenAIAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }
        guard configuration.chatCompletionsURL != nil else {
            throw OpenAITranslationError.invalidEndpoint
        }
        let model = configuration.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else {
            throw OpenAITranslationError.missingModel
        }

        await throttleProviderRequest()

        let request = try Self.makeChatCompletionsRequest(
            apiKey: apiKey,
            text: text,
            source: source,
            target: target,
            configuration: configuration,
            context: context,
            scenarioMode: scenarioMode
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let responseBody = try JSONDecoder().decode(OpenAIChatCompletionResponse.self, from: data)
        guard let outputText = responseBody.firstOutputText else {
            throw OpenAITranslationError.emptyOutput
        }
        return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func translateWithGoogle(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        guard let apiKey = try GoogleTranslateAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingGoogleAPIKey
        }
        await throttleProviderRequest()

        let request = try Self.makeGoogleTranslateRequest(
            apiKey: apiKey,
            text: text,
            source: source,
            target: target
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let responseBody = try JSONDecoder().decode(GoogleTranslateResponse.self, from: data)
        guard let outputText = responseBody.data.translations.first?.translatedText else {
            throw OpenAITranslationError.emptyOutput
        }
        return outputText.decodingBasicHTMLEntities().trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func translateWithDeepL(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        plan: DeepLPlan
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        let apiKey: String?
        switch plan {
        case .free:
            apiKey = try DeepLFreeAPIKeyStore.readAPIKey()
        case .pro:
            apiKey = try DeepLProAPIKeyStore.readAPIKey()
        }
        guard let apiKey, !apiKey.isEmpty else {
            throw OpenAITranslationError.missingDeepLAPIKey
        }

        await throttleProviderRequest()

        let request = try Self.makeDeepLTranslateRequest(
            apiKey: apiKey,
            text: text,
            source: source,
            target: target,
            plan: plan
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let responseBody = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
        guard let outputText = responseBody.translations.first?.text else {
            throw OpenAITranslationError.emptyOutput
        }
        return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    nonisolated static func makeOpenAIResponseRequest(
        apiKey: String,
        text: String,
        source: LanguageOption,
        target: LanguageOption,
        model: String,
        context: TranslationContext? = nil,
        scenarioMode: CaptionScenarioMode = .standard
    ) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            OpenAIResponseRequest(
                model: model,
                instructions: AppText.openAITranslationInstructions(source: source.localizedTitle, target: target.localizedTitle, scenarioMode: scenarioMode),
                input: Self.translationInput(text: text, context: context),
                store: false
            )
        )
        return request
    }

    nonisolated static func makeChatCompletionsRequest(
        apiKey: String,
        text: String,
        source: LanguageOption,
        target: LanguageOption,
        configuration: CustomLLMAPIConfiguration,
        context: TranslationContext? = nil,
        scenarioMode: CaptionScenarioMode = .standard
    ) throws -> URLRequest {
        guard let endpoint = configuration.chatCompletionsURL else {
            throw OpenAITranslationError.invalidEndpoint
        }
        let model = configuration.model.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !model.isEmpty else {
            throw OpenAITranslationError.missingModel
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if endpoint.host?.contains("openrouter.ai") == true {
            request.setValue("https://github.com/himomohi/AirTranslate", forHTTPHeaderField: "HTTP-Referer")
            request.setValue(AppText.appName, forHTTPHeaderField: "X-OpenRouter-Title")
        } else {
            request.setValue(AppText.appName, forHTTPHeaderField: "X-Title")
        }
        request.httpBody = try JSONEncoder().encode(
            OpenAIChatCompletionRequest(
                model: model,
                messages: [
                    .init(role: "system", content: AppText.openAITranslationInstructions(source: source.localizedTitle, target: target.localizedTitle, scenarioMode: scenarioMode)),
                    .init(role: "user", content: Self.translationInput(text: text, context: context))
                ],
                temperature: 0.2
            )
        )
        return request
    }

    nonisolated private static func translationInput(text: String, context: TranslationContext?) -> String {
        guard let context, !context.isEmpty else { return text }

        return """
        Previous source:
        \(context.previousSourceText)

        Previous translation:
        \(context.previousTranslatedText)

        Current source to translate:
        \(text)

        Return only the translation for the current source.
        """
    }

    nonisolated static func makeGoogleTranslateRequest(
        apiKey: String,
        text: String,
        source: LanguageOption,
        target: LanguageOption
    ) throws -> URLRequest {
        guard var components = URLComponents(string: "https://translation.googleapis.com/language/translate/v2") else {
            throw OpenAITranslationError.invalidEndpoint
        }
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw OpenAITranslationError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            GoogleTranslateRequest(q: text, source: source.googleTranslateCode, target: target.googleTranslateCode, format: "text")
        )
        return request
    }

    nonisolated static func makeDeepLTranslateRequest(
        apiKey: String,
        text: String,
        source: LanguageOption,
        target: LanguageOption,
        plan: DeepLPlan
    ) throws -> URLRequest {
        var request = URLRequest(url: plan == .free ? URL(string: "https://api-free.deepl.com/v2/translate")! : URL(string: "https://api.deepl.com/v2/translate")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = [
            URLQueryItem(name: "text", value: text),
            URLQueryItem(name: "source_lang", value: source.deepLLanguageCode),
            URLQueryItem(name: "target_lang", value: target.deepLLanguageCode)
        ].formURLEncodedData()
        return request
    }

    private func throttleProviderRequest() async {
        let elapsed = Date().timeIntervalSince(lastProviderRequestAt)
        if elapsed < minimumProviderRequestInterval {
            try? await Task.sleep(for: .milliseconds(Int((minimumProviderRequestInterval - elapsed) * 1_000)))
        }
        lastProviderRequestAt = Date()
    }

    func testConnection(
        translationModel: AITranslationModel,
        configuration: CustomLLMAPIConfiguration
    ) async throws {
        let output: String
        if translationModel == .customLLMAPI {
            output = try await translateWithChatCompletions(
                "hello",
                source: .english,
                target: .english,
                configuration: configuration
            )
        } else if translationModel == .googleTranslate {
            output = try await translateWithGoogle(
                "hello",
                source: .english,
                target: LanguageOption.german
            )
        } else if translationModel == .deepLFree {
            output = try await translateWithDeepL(
                "hello",
                source: .english,
                target: LanguageOption.german,
                plan: .free
            )
        } else if translationModel == .deepLPro {
            output = try await translateWithDeepL(
                "hello",
                source: .english,
                target: LanguageOption.german,
                plan: .pro
            )
        } else {
            throw OpenAITranslationError.missingModel
        }

        guard !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw OpenAITranslationError.emptyOutput
        }
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITranslationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data)
            throw OpenAITranslationError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.error.message
            )
        }
    }
}

enum DeepLPlan {
    case free
    case pro
}

struct CustomLLMAPIConfiguration: Equatable {
    static let openRouterBaseURL = "https://openrouter.ai/api/v1"
    static let aiHubMixBaseURL = "https://aihubmix.com/v1"

    let baseURL: String
    let model: String

    var chatCompletionsURL: URL? {
        let trimmedBaseURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseURL.isEmpty else { return nil }

        if trimmedBaseURL.hasSuffix("/chat/completions") {
            return URL(string: trimmedBaseURL)
        }

        let normalizedBaseURL = trimmedBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return URL(string: "\(normalizedBaseURL)/chat/completions")
    }
}

struct TranslationContext: Equatable {
    let previousSourceText: String
    let previousTranslatedText: String

    var isEmpty: Bool {
        previousSourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || previousTranslatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct OpenAIResponseRequest: Encodable {
    let model: String
    let instructions: String
    let input: String
    let store: Bool
}

private struct OpenAIResponseBody: Decodable {
    let outputText: String?
    let output: [OpenAIOutputItem]?

    var firstOutputText: String? {
        if let outputText, !outputText.isEmpty {
            return outputText
        }

        return output?
            .flatMap(\.content)
            .compactMap(\.text)
            .first { !$0.isEmpty }
    }

    private enum CodingKeys: String, CodingKey {
        case outputText = "output_text"
        case output
    }
}

private struct OpenAIOutputItem: Decodable {
    let content: [OpenAIContentItem]
}

private struct OpenAIContentItem: Decodable {
    let text: String?
}

private struct OpenAIChatCompletionRequest: Encodable {
    let model: String
    let messages: [OpenAIChatMessage]
    let temperature: Double
}

private struct OpenAIChatMessage: Encodable {
    let role: String
    let content: String
}

private struct OpenAIChatCompletionResponse: Decodable {
    let choices: [OpenAIChatChoice]

    var firstOutputText: String? {
        choices
            .map(\.message.content)
            .first { !$0.isEmpty }
    }
}

private struct OpenAIChatChoice: Decodable {
    let message: OpenAIChatMessageBody
}

private struct OpenAIChatMessageBody: Decodable {
    let content: String
}

private struct OpenAIErrorResponse: Decodable {
    let error: OpenAIErrorBody
}

private struct OpenAIErrorBody: Decodable {
    let message: String
}

private struct GoogleTranslateRequest: Encodable {
    let q: String
    let source: String
    let target: String
    let format: String
}

private struct GoogleTranslateResponse: Decodable {
    let data: GoogleTranslateData
}

private struct GoogleTranslateData: Decodable {
    let translations: [GoogleTranslateOutput]
}

private struct GoogleTranslateOutput: Decodable {
    let translatedText: String
}

private struct DeepLTranslateResponse: Decodable {
    let translations: [DeepLTranslateOutput]
}

private struct DeepLTranslateOutput: Decodable {
    let text: String
}

enum OpenAITranslationError: LocalizedError {
    case missingAPIKey
    case missingGoogleAPIKey
    case missingDeepLAPIKey
    case missingModel
    case invalidEndpoint
    case invalidResponse
    case emptyOutput
    case requestFailed(statusCode: Int, message: String?)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            AppText.openAIAPIKeyMissing
        case .missingGoogleAPIKey:
            AppText.googleTranslateAPIKeyMissing
        case .missingDeepLAPIKey:
            AppText.deepLAPIKeyMissing
        case .missingModel:
            AppText.customLLMModelMissing
        case .invalidEndpoint:
            AppText.customLLMEndpointInvalid
        case .invalidResponse:
            AppText.openAIInvalidResponse
        case .emptyOutput:
            AppText.openAIEmptyOutput
        case let .requestFailed(statusCode, message):
            AppText.openAIRequestFailed(statusCode: statusCode, message: message)
        }
    }
}

private extension LanguageOption {
    static let german = LanguageOption(id: "de-DE", title: "German", locale: Locale(identifier: "de-DE"))

    var googleTranslateCode: String {
        switch id {
        case "zh-CN":
            "zh-CN"
        default:
            String(id.prefix(2))
        }
    }

    var deepLLanguageCode: String {
        switch id {
        case "zh-CN":
            "ZH-HANS"
        case "en-US":
            "EN"
        default:
            String(id.prefix(2)).uppercased()
        }
    }
}

private extension Array where Element == URLQueryItem {
    func formURLEncodedData() -> Data? {
        var components = URLComponents()
        components.queryItems = self
        return components.percentEncodedQuery?.data(using: .utf8)
    }
}

private extension String {
    func decodingBasicHTMLEntities() -> String {
        replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
    }
}
