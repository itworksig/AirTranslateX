import Foundation

struct LanguageOption: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let locale: Locale

    var localizedTitle: String {
        AppText.languageTitle(for: id, fallback: title)
    }

    static let english = LanguageOption(id: "en-US", title: "English", locale: Locale(identifier: "en-US"))
    static let korean = LanguageOption(id: "ko-KR", title: "Korean", locale: Locale(identifier: "ko-KR"))
    static let russian = LanguageOption(id: "ru-RU", title: "Russian", locale: Locale(identifier: "ru-RU"))
    static let arabic = LanguageOption(id: "ar-SA", title: "Arabic", locale: Locale(identifier: "ar-SA"))
    static let persian = LanguageOption(id: "fa-IR", title: "Persian", locale: Locale(identifier: "fa-IR"))
    static let indonesian = LanguageOption(id: "id-ID", title: "Indonesian", locale: Locale(identifier: "id-ID"))

    static let supported: [LanguageOption] = [
        english,
        korean,
        .init(id: "ja-JP", title: "Japanese", locale: Locale(identifier: "ja-JP")),
        .init(id: "zh-CN", title: "Chinese Simplified", locale: Locale(identifier: "zh-CN")),
        .init(id: "es-ES", title: "Spanish", locale: Locale(identifier: "es-ES")),
        .init(id: "fr-FR", title: "French", locale: Locale(identifier: "fr-FR")),
        .init(id: "de-DE", title: "German", locale: Locale(identifier: "de-DE")),
        russian,
        arabic,
        persian,
        indonesian
    ]

    static func prioritizedAutoDetectionCandidates(
        sourceLanguage _: LanguageOption,
        targetLanguage: LanguageOption
    ) -> [LanguageOption] {
        LanguageOption.supported.filter { language in
            language != targetLanguage
        }
    }

    static func preferredSystemLanguage(fallback: LanguageOption) -> LanguageOption {
        for identifier in Locale.preferredLanguages {
            let normalizedIdentifier = identifier.lowercased().replacingOccurrences(of: "_", with: "-")
            if let exactMatch = supported.first(where: { $0.id.lowercased() == normalizedIdentifier }) {
                return exactMatch
            }

            let languageCode = normalizedIdentifier.split(separator: "-").first.map(String.init) ?? normalizedIdentifier
            if let languageMatch = supported.first(where: { $0.id.lowercased().hasPrefix("\(languageCode)-") }) {
                return languageMatch
            }
        }

        return fallback
    }
}
