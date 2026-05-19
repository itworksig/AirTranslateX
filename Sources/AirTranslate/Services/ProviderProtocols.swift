import CoreMedia
import Foundation

protocol TranscriptionProvider: AnyObject {
    var delegate: LiveSpeechTranscriberDelegate? { get set }
    func start(language: LanguageOption) async throws
    func append(_ sampleBuffer: CMSampleBuffer)
    func setPaused(_ isPaused: Bool)
    func stop()
}

protocol TranslationProvider {
    func translate(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption,
        model: AITranslationModel
    ) async throws -> String
}

