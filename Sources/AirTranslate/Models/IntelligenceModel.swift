import Foundation

enum IntelligenceModel: String, CaseIterable, Identifiable {
    case appleSystem = "apple-system"
    case appleOnDevice = "apple-on-device"
    case appleSpeechOnly = "apple-speech-only"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .appleSystem:
            AppText.localized(english: "Apple System", korean: "Apple 시스템")
        case .appleOnDevice:
            AppText.localized(english: "Apple On-Device", korean: "Apple 온디바이스")
        case .appleSpeechOnly:
            AppText.localized(english: "Speech Captions", korean: "음성 전사")
        }
    }

    var detail: String {
        switch self {
        case .appleSystem:
            AppText.localized(
                english: "Speech plus Translation frameworks.",
                korean: "Speech와 Translation 프레임워크를 사용합니다."
            )
        case .appleOnDevice:
            AppText.localized(
                english: "Uses downloaded language assets when ready.",
                korean: "준비된 다운로드 언어 자산을 사용합니다."
            )
        case .appleSpeechOnly:
            AppText.localized(
                english: "Transcribes without translating.",
                korean: "번역 없이 전사만 수행합니다."
            )
        }
    }
}
