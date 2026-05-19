import Foundation

enum ProviderRuntimeStatus: String {
    case idle
    case stable
    case delayed
    case rateLimited
    case reconnecting
    case fallback
    case failed

    var title: String {
        switch self {
        case .idle:
            AppText.localized(english: "Ready", korean: "준비됨", japanese: "待機中", chineseSimplified: "就绪")
        case .stable:
            AppText.localized(english: "Stable", korean: "안정", japanese: "安定", chineseSimplified: "稳定")
        case .delayed:
            AppText.localized(english: "Delayed", korean: "지연", japanese: "遅延", chineseSimplified: "延迟")
        case .rateLimited:
            AppText.localized(english: "Rate limited", korean: "속도 제한", japanese: "レート制限", chineseSimplified: "限流")
        case .reconnecting:
            AppText.localized(english: "Reconnecting", korean: "재연결", japanese: "再接続中", chineseSimplified: "重连中")
        case .fallback:
            AppText.localized(english: "Fallback", korean: "대체", japanese: "代替", chineseSimplified: "已降级")
        case .failed:
            AppText.localized(english: "Failed", korean: "실패", japanese: "失敗", chineseSimplified: "失败")
        }
    }
}
