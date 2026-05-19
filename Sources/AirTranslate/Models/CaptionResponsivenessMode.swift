import Foundation

enum CaptionResponsivenessMode: String, CaseIterable, Identifiable {
    case realtime
    case balanced
    case accurate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .realtime:
            AppText.localized(english: "Realtime", korean: "실시간", japanese: "リアルタイム", chineseSimplified: "实时优先")
        case .balanced:
            AppText.localized(english: "Balanced", korean: "균형", japanese: "バランス", chineseSimplified: "平衡")
        case .accurate:
            AppText.localized(english: "Accurate", korean: "정확도", japanese: "精度優先", chineseSimplified: "准确优先")
        }
    }

    var mergeDelayMultiplier: Double {
        switch self {
        case .realtime: 0.55
        case .balanced: 1.0
        case .accurate: 1.55
        }
    }

    var immediateCharacterMultiplier: Double {
        switch self {
        case .realtime: 0.75
        case .balanced: 1.0
        case .accurate: 1.35
        }
    }
}
