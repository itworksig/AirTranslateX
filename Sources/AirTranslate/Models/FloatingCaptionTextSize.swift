import SwiftUI

enum FloatingCaptionTextSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case extraLarge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .small:
            AppText.textSizeSmall
        case .medium:
            AppText.textSizeMedium
        case .large:
            AppText.textSizeLarge
        case .extraLarge:
            AppText.textSizeExtraLarge
        }
    }

    func primaryFont(style: FloatingCaptionFontStyle) -> Font {
        .system(size: primaryPointSize, weight: .semibold, design: style.design)
    }

    func secondaryFont(style: FloatingCaptionFontStyle) -> Font {
        .system(size: secondaryPointSize, weight: .medium, design: style.design)
    }

    var primaryLineHeight: CGFloat {
        primaryPointSize * 1.24
    }

    var secondaryLineHeight: CGFloat {
        secondaryPointSize * 1.28
    }

    private var primaryPointSize: CGFloat {
        switch self {
        case .small:
            24
        case .medium:
            30
        case .large:
            38
        case .extraLarge:
            48
        }
    }

    private var secondaryPointSize: CGFloat {
        switch self {
        case .small:
            16
        case .medium:
            20
        case .large:
            24
        case .extraLarge:
            30
        }
    }
}
