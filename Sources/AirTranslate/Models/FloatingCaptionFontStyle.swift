import SwiftUI

enum FloatingCaptionFontStyle: String, CaseIterable, Identifiable {
    case system
    case rounded
    case serif
    case monospaced

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            AppText.localized(english: "System", korean: "시스템", japanese: "システム", chineseSimplified: "系统")
        case .rounded:
            AppText.localized(english: "Rounded", korean: "라운드", japanese: "丸ゴシック", chineseSimplified: "圆体")
        case .serif:
            AppText.localized(english: "Serif", korean: "세리프", japanese: "セリフ", chineseSimplified: "衬线")
        case .monospaced:
            AppText.localized(english: "Mono", korean: "고정폭", japanese: "等幅", chineseSimplified: "等宽")
        }
    }

    var design: Font.Design {
        switch self {
        case .system:
            .default
        case .rounded:
            .rounded
        case .serif:
            .serif
        case .monospaced:
            .monospaced
        }
    }
}

