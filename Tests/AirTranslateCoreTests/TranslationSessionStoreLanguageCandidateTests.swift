import Foundation
import Testing
@testable import AirTranslate

@Suite
struct TranslationSessionStoreLanguageCandidateTests {
    private static let chineseSimplified = LanguageOption(
        id: "zh-CN",
        title: "Chinese Simplified",
        locale: Locale(identifier: "zh-CN")
    )

    @Test
    func russianIsAvailableAsASupportedLanguage() {
        #expect(LanguageOption.supported.contains(LanguageOption.russian))
        #expect(LanguageOption.russian.id == "ru-RU")
        #expect(LanguageOption.russian.title == "Russian")
    }

    @Test
    func arabicPersianAndIndonesianAreAvailableAsSupportedLanguages() {
        #expect(LanguageOption.supported.contains(LanguageOption.arabic))
        #expect(LanguageOption.supported.contains(LanguageOption.persian))
        #expect(LanguageOption.supported.contains(LanguageOption.indonesian))
        #expect(LanguageOption.arabic.id == "ar-SA")
        #expect(LanguageOption.persian.id == "fa-IR")
        #expect(LanguageOption.indonesian.id == "id-ID")
    }

    @Test
    func customLLMConfigurationBuildsChatCompletionsEndpoint() {
        let baseURLConfiguration = CustomLLMAPIConfiguration(
            baseURL: "https://openrouter.ai/api/v1",
            model: "openai/gpt-4o-mini"
        )
        #expect(baseURLConfiguration.chatCompletionsURL?.absoluteString == "https://openrouter.ai/api/v1/chat/completions")

        let endpointConfiguration = CustomLLMAPIConfiguration(
            baseURL: "https://aihubmix.com/v1/chat/completions",
            model: "gpt-4o-mini"
        )
        #expect(endpointConfiguration.chatCompletionsURL?.absoluteString == "https://aihubmix.com/v1/chat/completions")
    }

    @Test
    func aiModeUsesDeepgramAndCustomLLMDefaults() {
        #expect(TranslationSessionStore.aiModeDefaultTranscriptionModel == .deepgramStreaming)
        #expect(TranslationSessionStore.aiModeDefaultTranslationModel == .customLLMAPI)
        #expect(!AITranslationModel.customLLMAPI.usesRealtimeAudioTranslation)
    }

    @Test
    func floatingCaptionsKeepRecentSemanticCueInsteadOfTinyTailFragment() {
        let text = """
        Internal political implications in which Netanyahu replaced his appearance in his courtroom, which was scheduled for
        """

        let caption = text.floatingCaptionTail(maxLines: 2)

        #expect(caption.contains("Internal political implications"))
        #expect(caption.contains("scheduled for"))
        #expect(caption.split(separator: "\n").count == 2)
    }

    @Test
    func floatingCaptionsKeepChineseCueBeforeLatestShortFragment() {
        let text = """
        这是此前的一段内容，已经不应该继续显示。
        内塔尼亚胡取消出庭的内部政治影响，原定于
        """

        let caption = text.floatingCaptionTail(maxLines: 2)

        #expect(caption.contains("内塔尼亚胡取消出庭"))
        #expect(caption.contains("原定于"))
        #expect(!caption.contains("此前的一段内容"))
    }

    @Test
    func openRouterRequestUsesChatCompletionsEndpointAndHeaders() throws {
        let configuration = CustomLLMAPIConfiguration(
            baseURL: "https://openrouter.ai/api/v1",
            model: "google/gemini-2.5-flash-lite-preview"
        )

        let request = try OpenAITranslationService.makeChatCompletionsRequest(
            apiKey: "sk-test",
            text: "hello",
            source: .english,
            target: .russian,
            configuration: configuration
        )

        #expect(request.url?.absoluteString == "https://openrouter.ai/api/v1/chat/completions")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer sk-test")
        #expect(request.value(forHTTPHeaderField: "HTTP-Referer") == "https://github.com/himomohi/AirTranslate")
        #expect(request.value(forHTTPHeaderField: "X-OpenRouter-Title") == AppText.appName)

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["model"] as? String == "google/gemini-2.5-flash-lite-preview")
        #expect((json["messages"] as? [[String: String]])?.last?["content"] == "hello")
    }

    @Test
    func customLLMRequestCanIncludePreviousSubtitleContext() throws {
        let configuration = CustomLLMAPIConfiguration(
            baseURL: "https://openrouter.ai/api/v1",
            model: "google/gemini-2.5-flash-lite-preview"
        )

        let request = try OpenAITranslationService.makeChatCompletionsRequest(
            apiKey: "sk-test",
            text: "He said it will continue tomorrow.",
            source: .english,
            target: Self.chineseSimplified,
            configuration: configuration,
            context: TranslationContext(
                previousSourceText: "The talks started today.",
                previousTranslatedText: "会谈今天开始。"
            )
        )

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        let messages = try #require(json["messages"] as? [[String: String]])
        let userContent = try #require(messages.last?["content"])

        #expect(userContent.contains("Previous source:"))
        #expect(userContent.contains("The talks started today."))
        #expect(userContent.contains("Previous translation:"))
        #expect(userContent.contains("会谈今天开始。"))
        #expect(userContent.contains("Current source to translate:"))
        #expect(userContent.contains("Return only the translation for the current source."))
    }

    @Test
    func googleTranslateRequestUsesExpectedLanguageCodes() throws {
        let request = try OpenAITranslationService.makeGoogleTranslateRequest(
            apiKey: "google-key",
            text: "hello",
            source: .english,
            target: Self.chineseSimplified
        )

        #expect(request.url?.host == "translation.googleapis.com")
        #expect(request.url?.query?.contains("key=google-key") == true)
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let body = try #require(request.httpBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["q"] == "hello")
        #expect(json["source"] == "en")
        #expect(json["target"] == "zh-CN")
        #expect(json["format"] == "text")
    }

    @Test
    func deepLRequestsUseFreeAndProHostsWithAuthHeader() throws {
        let freeRequest = try OpenAITranslationService.makeDeepLTranslateRequest(
            apiKey: "deepl-key",
            text: "hello",
            source: .english,
            target: Self.chineseSimplified,
            plan: .free
        )
        let proRequest = try OpenAITranslationService.makeDeepLTranslateRequest(
            apiKey: "deepl-key",
            text: "hello",
            source: .english,
            target: Self.chineseSimplified,
            plan: .pro
        )

        #expect(freeRequest.url?.host == "api-free.deepl.com")
        #expect(proRequest.url?.host == "api.deepl.com")
        #expect(freeRequest.value(forHTTPHeaderField: "Authorization") == "DeepL-Auth-Key deepl-key")
        #expect(proRequest.value(forHTTPHeaderField: "Authorization") == "DeepL-Auth-Key deepl-key")

        let body = String(data: try #require(freeRequest.httpBody), encoding: .utf8)
        #expect(body?.contains("text=hello") == true)
        #expect(body?.contains("source_lang=EN") == true)
        #expect(body?.contains("target_lang=ZH-HANS") == true)
    }

    @Test
    func supportedLanguageOrderIsUsedForAutoDetectionCandidateSelection() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.korean
        )

        #expect(candidates.first == LanguageOption.english)
    }

    @Test
    func targetLanguageIsExcludedFromAutoDetectionCandidates() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.english
        )

        #expect(!candidates.contains(LanguageOption.english))
    }

    @Test
    func targetLanguageIsExcludedWhenManualSourceMatchesTarget() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.korean
        )

        #expect(candidates.first == LanguageOption.english)
        #expect(!candidates.contains(LanguageOption.korean))
    }

    @Test
    func autoDetectionCandidatesIncludeAllNonTargetSupportedLanguagesInSourcePriorityOrder() {
        let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
            sourceLanguage: LanguageOption.korean,
            targetLanguage: LanguageOption.english
        )
        let expected = LanguageOption.supported.filter { $0 != LanguageOption.english }

        #expect(candidates == expected)
        #expect(Set(candidates.map({ $0.id })) == Set(expected.map({ $0.id })))
    }

    @Test
    func everySupportedLanguageIsExcludedWhenItIsTheTarget() {
        for target in LanguageOption.supported {
            let candidates = LanguageOption.prioritizedAutoDetectionCandidates(
                sourceLanguage: LanguageOption.english,
                targetLanguage: target
            )

            #expect(!candidates.contains(target))
            #expect(candidates.count == LanguageOption.supported.count - 1)
        }
    }

    @Test
    func autoDetectionRequestsConfirmationForLanguageChangeAfterSilence() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: true,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationWithoutSilence() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: false,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationForLowConfidenceSwitch() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: LanguageOption.english,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.5,
            hadLongSilence: true,
            hasVisibleTranscript: true,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func autoDetectionDoesNotRequestConfirmationForInitialLanguageDetection() {
        let shouldConfirm = AutoDetectionLanguageChangePolicy.shouldRequestConfirmation(
            isAutoDetectionEnabled: true,
            activeLanguage: nil,
            detectedLanguage: LanguageOption.supported[2],
            confidence: 0.9,
            hadLongSilence: true,
            hasVisibleTranscript: false,
            minimumSwitchConfidence: 0.72
        )

        #expect(!shouldConfirm)
    }

    @Test
    func longSessionCaptionLineTrimsDisplayOnly() {
        let text = (1...500)
            .map { "Live transcript line \($0) keeps accumulating during a long session." }
            .joined(separator: "\n")
        let line = CaptionLine(
            sourceText: text,
            translatedText: text,
            createdAt: Date(),
            isFinal: false,
            usesLongSessionDisplay: true
        )

        #expect(line.sourceText == text)
        #expect(line.translatedText == text)
        #expect(line.sourceDisplayText != text)
        #expect(line.translatedDisplayText != text)
        #expect(line.sourceDisplayText.hasPrefix("..."))
        #expect(line.translatedDisplayText.hasPrefix("..."))
    }
}
