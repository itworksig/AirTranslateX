import SwiftUI

struct FloatingCaptionWindowView: View {
    @Bindable var session: TranslationSessionStore

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 7) {
                content
            }
            .padding(.horizontal, session.floatingCaptionPlacement == .notchIsland ? 24 : 30)
            .padding(.vertical, session.floatingCaptionPlacement == .notchIsland ? 13 : 18)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: capsuleCornerRadius, style: .continuous)
                    .fill(backgroundColor.opacity(session.floatingCaptionBackgroundOpacity))
                    .shadow(color: .black.opacity(session.floatingCaptionPlacement == .notchIsland ? 0.42 : 0.32), radius: 18, x: 0, y: 8)
                    .shadow(color: .black.opacity(0.22), radius: 4, x: 0, y: 1)
            }
            .overlay {
                RoundedRectangle(cornerRadius: capsuleCornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
            }
            .padding(.horizontal, session.floatingCaptionPlacement == .notchIsland ? 14 : 24)
            .padding(.vertical, session.floatingCaptionPlacement == .notchIsland ? 8 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(
            minWidth: windowWidth.minimum,
            idealWidth: windowWidth.ideal,
            maxWidth: windowWidth.maximum,
            minHeight: 72,
            idealHeight: preferredHeight,
            maxHeight: preferredHeight
        )
        .contentShape(Rectangle())
        .gesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
        .overlay {
            FloatingCaptionDragSurface()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            FloatingWindowConfigurator(
                preferredContentHeight: preferredHeight,
                preferredContentWidth: windowWidth.ideal,
                placement: session.floatingCaptionPlacement
            )
        )
    }

    @ViewBuilder
    private var content: some View {
        switch session.floatingCaptionDisplayMode {
        case .original:
            subtitleText(sourceText, font: primaryFont)
        case .originalAndTranslation:
            if !sourceText.isEmpty {
                subtitleText(sourceText, font: secondaryFont)
                    .opacity(0.74)
                subtitleText(translationText.isEmpty ? " " : translationText, font: primaryFont)
                    .opacity(translationText.isEmpty ? 0 : 1)
            }
            if sourceText.isEmpty && translationText.isEmpty {
                subtitleText(AppText.noFloatingCaptionsYet, font: primaryFont)
            }
        case .translation:
            if !translationText.isEmpty {
                subtitleText(translationText, font: primaryFont)
            } else if sourceText.isEmpty {
                subtitleText(AppText.noFloatingCaptionsYet, font: primaryFont)
            }
        }
    }

    private var sourceText: String {
        session.floatingSourceText
    }

    private var translationText: String {
        session.floatingTranslationText
    }

    private var lineLimit: Int {
        session.floatingCaptionLineCount.rawValue
    }

    private var preferredHeight: CGFloat {
        let textSize = session.floatingCaptionTextSize
        let lineCount = CGFloat(effectiveLineLimit)
        let primaryHeight = textSize.primaryLineHeight * lineCount + CGFloat(lineLimit - 1) * 5
        let secondaryHeight = textSize.secondaryLineHeight * lineCount + CGFloat(lineLimit - 1) * 5
        let textHeight: CGFloat

        switch session.floatingCaptionDisplayMode {
        case .original, .translation:
            textHeight = primaryHeight
        case .originalAndTranslation:
            textHeight = primaryHeight + secondaryHeight + 8
        }

        let verticalChrome: CGFloat = session.floatingCaptionPlacement == .notchIsland ? 54 : 72
        let minimumHeight: CGFloat = session.floatingCaptionPlacement == .notchIsland ? 86 : 112
        return min(max(minimumHeight, textHeight + verticalChrome), 720)
    }

    private var windowWidth: (minimum: CGFloat, ideal: CGFloat, maximum: CGFloat) {
        switch session.floatingCaptionPlacement {
        case .lowerThird:
            (420, 760, 1080)
        case .notchIsland:
            (280, 520, 680)
        }
    }

    private var effectiveLineLimit: Int {
        switch session.floatingCaptionPlacement {
        case .lowerThird:
            lineLimit
        case .notchIsland:
            min(lineLimit, session.floatingCaptionDisplayMode == .originalAndTranslation ? 2 : 3)
        }
    }

    private var primaryFont: Font {
        switch session.floatingCaptionPlacement {
        case .lowerThird:
            session.floatingCaptionTextSize.primaryFont(style: session.floatingCaptionFontStyle)
        case .notchIsland:
            .system(size: notchPrimaryPointSize, weight: .semibold, design: session.floatingCaptionFontStyle.design)
        }
    }

    private var secondaryFont: Font {
        switch session.floatingCaptionPlacement {
        case .lowerThird:
            session.floatingCaptionTextSize.secondaryFont(style: session.floatingCaptionFontStyle)
        case .notchIsland:
            .system(size: notchSecondaryPointSize, weight: .medium, design: session.floatingCaptionFontStyle.design)
        }
    }

    private var notchPrimaryPointSize: CGFloat {
        switch session.floatingCaptionTextSize {
        case .small: 17
        case .medium: 20
        case .large: 24
        case .extraLarge: 29
        }
    }

    private var notchSecondaryPointSize: CGFloat {
        switch session.floatingCaptionTextSize {
        case .small: 12
        case .medium: 14
        case .large: 16
        case .extraLarge: 19
        }
    }

    private var capsuleCornerRadius: CGFloat {
        session.floatingCaptionPlacement == .notchIsland ? 28 : 18
    }

    private var foregroundColor: Color {
        ColorHex.color(from: session.floatingCaptionTextColorHex, fallback: Color(red: 0.97, green: 0.96, blue: 0.92))
    }

    private var backgroundColor: Color {
        ColorHex.color(from: session.floatingCaptionBackgroundColorHex, fallback: .black)
    }

    private func subtitleText(_ text: String, font: Font) -> some View {
        StreamingTranscriptText(
            text: text.isEmpty ? AppText.noFloatingCaptionsYet : text,
            font: font,
            foregroundColor: foregroundColor,
            isTextSelectionEnabled: false,
            lineLimit: effectiveLineLimit,
            textAlignment: .center,
            frameAlignment: .center,
            truncationMode: .tail
        )
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, alignment: .center)
        .lineSpacing(6)
        .shadow(color: .black.opacity(0.96), radius: 2.2, x: 0, y: 1)
        .shadow(color: .black.opacity(0.48), radius: 7, x: 0, y: 2)
    }
}
