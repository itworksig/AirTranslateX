import SwiftUI

enum FloatingCaptionPlacement: String, CaseIterable, Identifiable {
    case lowerThird
    case topCenter
    case lowerFifth
    case notchIsland

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowerThird:
            AppText.localized(english: "Lower third", korean: "하단", japanese: "下部", chineseSimplified: "底部字幕")
        case .topCenter:
            AppText.localized(english: "Top", korean: "상단", japanese: "上部", chineseSimplified: "顶部")
        case .lowerFifth:
            AppText.localized(english: "Lower 20%", korean: "하단 20%", japanese: "下20%", chineseSimplified: "屏幕下 20%")
        case .notchIsland:
            AppText.localized(english: "Notch island", korean: "노치 아일랜드", japanese: "ノッチアイランド", chineseSimplified: "刘海灵动岛")
        }
    }

    var systemImage: String {
        switch self {
        case .lowerThird:
            "rectangle.bottomthird.inset.filled"
        case .topCenter:
            "rectangle.topthird.inset.filled"
        case .lowerFifth:
            "rectangle.inset.bottomleft.filled"
        case .notchIsland:
            "macbook"
        }
    }
}
