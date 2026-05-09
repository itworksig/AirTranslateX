import Foundation
@preconcurrency import Translation

@MainActor
final class AppleTranslationService {
    private let availability = LanguageAvailability()

    func translate(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        model: IntelligenceModel
    ) async throws -> String {
        guard !text.isEmpty else { return text }
        guard model != .appleSpeechOnly else { return text }

        let sourceLanguage = Locale.Language(identifier: source.id)
        let targetLanguage = Locale.Language(identifier: target.id)
        let status = await availability.status(from: sourceLanguage, to: targetLanguage)

        guard status != .unsupported else {
            throw TranslationServiceError.unsupportedPair(source.localizedTitle, target.localizedTitle)
        }

        let session = TranslationSession(installedSource: sourceLanguage, target: targetLanguage)
        if !(await session.isReady) {
            try await session.prepareTranslation()
        }

        let response = try await session.translate(text)
        return response.targetText
    }
}

enum TranslationServiceError: LocalizedError {
    case unsupportedPair(String, String)

    var errorDescription: String? {
        switch self {
        case let .unsupportedPair(source, target):
            AppText.unsupportedTranslation(source: source, target: target)
        }
    }
}
