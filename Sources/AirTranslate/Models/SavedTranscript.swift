import Foundation

struct SavedTranscript: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var sourceText: String
    var translatedText: String
    let sourceLanguageID: String
    let targetLanguageID: String
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        sourceText: String,
        translatedText: String,
        sourceLanguageID: String,
        targetLanguageID: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLanguageID = sourceLanguageID
        self.targetLanguageID = targetLanguageID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
