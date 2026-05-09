import Foundation

enum IntelligenceModel: String, CaseIterable, Identifiable {
    case appleSystem = "apple-system"
    case appleOnDevice = "apple-on-device"
    case appleSpeechOnly = "apple-speech-only"

    static var allCases: [IntelligenceModel] {
        [.appleSystem, .appleSpeechOnly]
    }

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleSystem:
            AppText.localized(
                english: "Live Transcription + Translation",
                korean: "실시간 전사 + 번역"
            )
        case .appleOnDevice:
            AppText.localized(
                english: "Translation Language Pack",
                korean: "번역 언어팩"
            )
        case .appleSpeechOnly:
            AppText.localized(
                english: "Transcribe Only",
                korean: "전사만"
            )
        }
    }

    var detail: String {
        switch self {
        case .appleSystem:
            AppText.localized(
                english: "Live transcription with SpeechTranscriber, then TranslationSession for the selected language pair.",
                korean: "SpeechTranscriber로 실시간 전사한 뒤 선택한 언어쌍을 TranslationSession으로 번역합니다."
            )
        case .appleOnDevice:
            AppText.localized(
                english: "Checks the installed Apple Translation language assets for the selected source and target languages.",
                korean: "선택한 원문/번역 언어쌍의 Apple 번역 언어 자산 설치 상태를 확인합니다."
            )
        case .appleSpeechOnly:
            AppText.localized(
                english: "Uses SpeechTranscriber for source-language captions only, without TranslationSession.",
                korean: "TranslationSession 없이 SpeechTranscriber만 사용해 원문 자막을 기록합니다."
            )
        }
    }

    var checkingDetail: String {
        AppText.localized(
            english: "Checking local assets for \(title)...",
            korean: "\(title) 로컬 자산을 확인하는 중입니다..."
        )
    }
}
