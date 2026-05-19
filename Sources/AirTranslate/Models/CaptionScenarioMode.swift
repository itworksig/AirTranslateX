import Foundation

enum CaptionScenarioMode: String, CaseIterable, Identifiable {
    case standard
    case conversation
    case news
    case movie
    case lecture

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard:
            AppText.localized(english: "Default", korean: "기본", japanese: "標準", chineseSimplified: "默认模式")
        case .conversation:
            AppText.localized(english: "Call", korean: "통화", japanese: "通話", chineseSimplified: "通话模式")
        case .news:
            AppText.localized(english: "News", korean: "뉴스", japanese: "ニュース", chineseSimplified: "新闻模式")
        case .movie:
            AppText.localized(english: "Movie", korean: "영화", japanese: "映画", chineseSimplified: "电影模式")
        case .lecture:
            AppText.localized(english: "Lecture", korean: "강의", japanese: "講座", chineseSimplified: "讲座模式")
        }
    }

    var systemImage: String {
        switch self {
        case .standard: "sparkles"
        case .conversation: "phone.bubble"
        case .news: "newspaper"
        case .movie: "play.rectangle"
        case .lecture: "studentdesk"
        }
    }

    var subtitleStyleHint: String {
        switch self {
        case .standard:
            "Use balanced live subtitle phrasing."
        case .conversation:
            "Prefer short conversational turns. Preserve speaker intent and casual phrasing."
        case .news:
            "Use broadcast-news style: concise, factual, neutral, and complete when possible."
        case .movie:
            "Use natural cinematic subtitle phrasing. Keep emotion and timing, avoid stiff literal wording."
        case .lecture:
            "Use lecture style: preserve terms, definitions, and logical connectors clearly."
        }
    }

    var liveCueMergeDelayMilliseconds: Int {
        switch self {
        case .conversation: 120
        case .news: 260
        case .movie: 220
        case .lecture: 320
        case .standard: 180
        }
    }

    var liveCueImmediateCharacterCount: Int {
        switch self {
        case .conversation: 72
        case .news: 118
        case .movie: 92
        case .lecture: 140
        case .standard: 96
        }
    }

    var deepgramEndpointingMilliseconds: Int {
        switch self {
        case .conversation: 180
        case .news: 350
        case .movie: 280
        case .lecture: 520
        case .standard: 300
        }
    }

    var deepgramUtteranceEndMilliseconds: Int {
        switch self {
        case .conversation: 700
        case .news: 1200
        case .movie: 900
        case .lecture: 1500
        case .standard: 1000
        }
    }
}
