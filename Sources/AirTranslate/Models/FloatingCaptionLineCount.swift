import Foundation

enum FloatingCaptionLineCount: Int, CaseIterable, Identifiable {
    case two = 2

    var id: String { "\(rawValue)" }

    var title: String {
        AppText.lineCount(rawValue)
    }
}
