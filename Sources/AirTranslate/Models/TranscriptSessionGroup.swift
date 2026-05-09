import Foundation

struct TranscriptSessionGroup: Identifiable, Equatable {
    let id: UUID
    let startedAt: Date
    let languageSummary: String
    var lines: [CaptionLine]
    var isExpanded: Bool

    init(
        id: UUID = UUID(),
        startedAt: Date,
        languageSummary: String,
        lines: [CaptionLine],
        isExpanded: Bool
    ) {
        self.id = id
        self.startedAt = startedAt
        self.languageSummary = languageSummary
        self.lines = lines
        self.isExpanded = isExpanded
    }
}
