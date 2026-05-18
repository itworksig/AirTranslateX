import SwiftUI

enum FloatingCaptionPlacement: String, CaseIterable, Identifiable {
    case lowerThird
    case notchIsland

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lowerThird:
            AppText.localized(english: "Lower third", korean: "하단", japanese: "下部", chineseSimplified: "底部字幕")
        case .notchIsland:
            AppText.localized(english: "Notch island", korean: "노치 아일랜드", japanese: "ノッチアイランド", chineseSimplified: "刘海灵动岛")
        }
    }

    var systemImage: String {
        switch self {
        case .lowerThird:
            "rectangle.bottomthird.inset.filled"
        case .notchIsland:
            "macbook"
        }
    }
}

