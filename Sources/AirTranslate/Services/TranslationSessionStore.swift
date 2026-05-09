import AVFAudio
import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class TranslationSessionStore {
    var isRunning = false
    var isDubbingEnabled = false
    var sourceLanguage = LanguageOption.supported[0]
    var targetLanguage = LanguageOption.supported[1]
    var selectedModel = IntelligenceModel.appleSystem
    var statusMessage = AppText.ready
    var lines: [CaptionLine] = []
    var savedTranscripts: [SavedTranscript] = []
    var selectedSavedTranscriptID: UUID?
    var savedDraftTitle = ""
    var savedDraftSourceText = ""
    var savedDraftTranslatedText = ""

    private let capture = SystemAudioCapture()
    private let transcriber = LiveSpeechTranscriber()
    private let translator = AppleTranslationService()
    private let speaker = AVSpeechSynthesizer()
    private var audioSampleCount = 0
    private var latestAudioLevel: Float?
    private var lastRecognizedText = ""
    private var lastRecognizedWasFinal = false
    private var lastRecognitionAt = Date.distantPast
    private var currentLineID: UUID?
    private var transcriptCleanupTask: Task<Void, Never>?
    private var committedSourceText = ""
    private var currentPartialText = ""
    private var pendingParagraphBreakBeforePartial = false
    private var pendingTranslationSourceText = ""
    private var translatedSegmentsBySource: [String: String] = [:]

    init() {
        capture.delegate = self
        transcriber.delegate = self
        loadSavedTranscripts()
    }

    func start() {
        guard !isRunning else { return }

        isRunning = true
        statusMessage = AppText.checkingScreenPermission

        Task {
            do {
                try capture.requestScreenRecordingAccess()
                statusMessage = AppText.checkingSpeechPermission
                try await startCaptioners()
                statusMessage = AppText.startingCapture
                try await capture.start()
                statusMessage = AppText.listeningForSpeech
            } catch {
                isRunning = false
                stopCaptioners()
                await capture.stop()
                statusMessage = AppText.startFailed(error.localizedDescription)
            }
        }
    }

    func stop() {
        guard isRunning else { return }

        isRunning = false
        statusMessage = AppText.stopped
        audioSampleCount = 0
        latestAudioLevel = nil
        lastRecognizedText = ""
        lastRecognizedWasFinal = false
        currentLineID = nil
        committedSourceText = ""
        currentPartialText = ""
        pendingParagraphBreakBeforePartial = false
        pendingTranslationSourceText = ""
        transcriptCleanupTask?.cancel()
        transcriptCleanupTask = nil
        stopCaptioners()

        Task {
            await capture.stop()
        }
    }

    func openPrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    var languageSummary: String {
        AppText.languageSummary(source: sourceLanguage.localizedTitle, target: targetLanguage.localizedTitle)
    }

    var canSaveCurrentTranscript: Bool {
        lines.contains { !$0.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func saveCurrentTranscript() {
        let sourceText = lines
            .map(\.sourceText)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sourceText.isEmpty else { return }

        let translatedText = lines
            .map(\.translatedText)
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let title = transcriptTitle(from: sourceText)
        let transcript = SavedTranscript(
            title: title,
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLanguageID: sourceLanguage.id,
            targetLanguageID: targetLanguage.id
        )

        savedTranscripts.insert(transcript, at: 0)
        selectSavedTranscript(transcript.id)
        persistSavedTranscripts()
    }

    func selectSavedTranscript(_ id: UUID) {
        guard let transcript = savedTranscripts.first(where: { $0.id == id }) else { return }

        selectedSavedTranscriptID = id
        savedDraftTitle = transcript.title
        savedDraftSourceText = transcript.sourceText
        savedDraftTranslatedText = transcript.translatedText
    }

    func saveSelectedTranscriptEdits() {
        guard let selectedSavedTranscriptID,
              let index = savedTranscripts.firstIndex(where: { $0.id == selectedSavedTranscriptID })
        else {
            return
        }

        savedTranscripts[index].title = savedDraftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if savedTranscripts[index].title.isEmpty {
            savedTranscripts[index].title = transcriptTitle(from: savedDraftSourceText)
        }
        savedTranscripts[index].sourceText = savedDraftSourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        savedTranscripts[index].translatedText = savedDraftTranslatedText.trimmingCharacters(in: .whitespacesAndNewlines)
        savedTranscripts[index].updatedAt = Date()
        persistSavedTranscripts()
    }

    func deleteSelectedTranscript() {
        guard let selectedSavedTranscriptID else { return }

        savedTranscripts.removeAll { $0.id == selectedSavedTranscriptID }
        self.selectedSavedTranscriptID = nil
        savedDraftTitle = ""
        savedDraftSourceText = ""
        savedDraftTranslatedText = ""
        persistSavedTranscripts()
    }

    private func startCaptioners() async throws {
        try await transcriber.start(languages: [sourceLanguage])
    }

    private func stopCaptioners() {
        transcriber.stop()
    }

    private func loadSavedTranscripts() {
        do {
            let data = try Data(contentsOf: savedTranscriptsURL)
            savedTranscripts = try JSONDecoder().decode([SavedTranscript].self, from: data)
        } catch {
            savedTranscripts = []
        }
    }

    private func persistSavedTranscripts() {
        do {
            let url = savedTranscriptsURL
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(savedTranscripts)
            try data.write(to: url, options: .atomic)
        } catch {
            statusMessage = AppText.saveLibraryFailed(error.localizedDescription)
        }
    }

    private var savedTranscriptsURL: URL {
        let supportDirectory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        return supportDirectory
            .appendingPathComponent("AirTranslate", isDirectory: true)
            .appendingPathComponent("saved-transcripts.json")
    }

    private func transcriptTitle(from text: String) -> String {
        let firstLine = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .first
            .map(String.init) ?? AppText.untitledTranscript
        return String(firstLine.prefix(48))
    }

    private func appendCaption(
        sourceText: String,
        recognizedLanguage: LanguageOption,
        confidence _: Double,
        isFinal: Bool
    ) async {
        guard isRunning else { return }
        guard sourceText != lastRecognizedText || isFinal != lastRecognizedWasFinal else { return }
        guard let direction = translationDirection(for: sourceText, recognizedLanguage: recognizedLanguage) else { return }

        let now = Date()
        let hadLongSilence = now.timeIntervalSince(lastRecognitionAt) > 5

        let updatedSourceText = accumulatedTranscript(
            incoming: sourceText,
            hadLongSilence: hadLongSilence
        )
        guard !updatedSourceText.isEmpty else { return }

        lastRecognizedText = sourceText
        lastRecognizedWasFinal = isFinal
        lastRecognitionAt = now
        transcriptCleanupTask?.cancel()

        let line: CaptionLine
        if let currentLineID,
           let index = lines.firstIndex(where: { $0.id == currentLineID }) {
            let existingLine = lines[index]
            guard updatedSourceText != existingLine.sourceText else { return }

            line = CaptionLine(
                id: existingLine.id,
                sourceText: updatedSourceText,
                translatedText: existingLine.translatedText,
                translatedSourceText: existingLine.translatedSourceText,
                createdAt: existingLine.createdAt,
                isFinal: isFinal,
                revision: existingLine.revision + 1
            )
            lines[index] = line
        } else {
            line = CaptionLine(
                sourceText: updatedSourceText,
                translatedText: AppText.translating,
                createdAt: Date(),
                isFinal: isFinal,
                revision: 1
            )
            currentLineID = line.id
            lines.append(line)
        }

        requestTranslation(for: line, source: direction.source, target: direction.target)
    }

    private func accumulatedTranscript(incoming: String, hadLongSilence: Bool) -> String {
        let trimmedIncoming = incoming.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIncoming.isEmpty else { return visibleTranscript() }

        if hadLongSilence, !currentPartialText.isEmpty {
            commitCurrentPartial()
            pendingParagraphBreakBeforePartial = !committedSourceText.isEmpty
        }

        if currentPartialText.isEmpty {
            if committedTextAlreadyContains(trimmedIncoming) {
                return visibleTranscript()
            }
            currentPartialText = trimmedIncoming
            return visibleTranscript()
        }

        if trimmedIncoming.count + 2 >= currentPartialText.count
            || trimmedIncoming.hasPrefix(currentPartialText)
            || currentPartialText.hasPrefix(trimmedIncoming) {
            currentPartialText = trimmedIncoming.count >= currentPartialText.count ? trimmedIncoming : currentPartialText
            return visibleTranscript()
        }

        commitCurrentPartial()
        pendingParagraphBreakBeforePartial = hadLongSilence && !committedSourceText.isEmpty
        currentPartialText = trimmedIncoming
        return visibleTranscript()
    }

    private func commitCurrentPartial() {
        let partial = currentPartialText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !partial.isEmpty else { return }

        if committedSourceText.isEmpty {
            committedSourceText = partial
        } else if !committedSourceText.hasSuffix(partial) && !committedSourceText.contains(partial) {
            let separator = pendingParagraphBreakBeforePartial ? "\n\n" : "\n"
            committedSourceText += separator + partial
        }
        pendingParagraphBreakBeforePartial = false
        currentPartialText = ""
    }

    private func committedTextAlreadyContains(_ text: String) -> Bool {
        let committed = committedSourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !committed.isEmpty else { return false }

        return committed == text
            || committed.hasSuffix(text)
            || committed.contains("\n" + text)
    }

    private func visibleTranscript() -> String {
        let committed = committedSourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let partial = currentPartialText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !committed.isEmpty else {
            return organizeTranscript(partial, language: sourceLanguage)
        }
        guard !partial.isEmpty else {
            return organizeTranscript(committed, language: sourceLanguage)
        }

        let separator = pendingParagraphBreakBeforePartial ? "\n\n" : "\n"
        return organizeTranscript(committed + separator + partial, language: sourceLanguage)
    }

    private func scheduleTranscriptCleanup() {
        guard isRunning, currentLineID != nil else { return }
        guard Date().timeIntervalSince(lastRecognitionAt) > 1.5 else { return }

        transcriptCleanupTask?.cancel()
        transcriptCleanupTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            organizeCurrentTranscript()
        }
    }

    private func organizeCurrentTranscript() {
        guard isRunning,
              let currentLineID,
              let index = lines.firstIndex(where: { $0.id == currentLineID })
        else {
            return
        }

        let line = lines[index]
        let organizedSourceText = organizeTranscript(line.sourceText, language: sourceLanguage)
        let organizedTranslatedText = organizeTranslatedText(line.translatedText)
        let sourceChanged = organizedSourceText != line.sourceText
        let translationChanged = organizedTranslatedText != line.translatedText
        let needsTranslationRefresh = line.translatedSourceText != organizedSourceText

        if !sourceChanged,
           !translationChanged,
           needsTranslationRefresh,
           pendingTranslationSourceText == organizedSourceText {
            return
        }

        guard sourceChanged || translationChanged || needsTranslationRefresh else {
            return
        }

        committedSourceText = organizedSourceText
        currentPartialText = ""
        lines[index] = CaptionLine(
            id: line.id,
            sourceText: organizedSourceText,
            translatedText: organizedTranslatedText,
            translatedSourceText: line.translatedSourceText,
            createdAt: line.createdAt,
            isFinal: line.isFinal,
            revision: line.revision + 1
        )

        let updatedLine = lines[index]
        if updatedLine.translatedSourceText != updatedLine.sourceText {
            requestTranslation(for: updatedLine, source: sourceLanguage, target: targetLanguage)
        }
    }

    private func organizeTranslatedText(_ text: String) -> String {
        guard text != AppText.translating else { return text }
        return organizeTranscript(text, language: targetLanguage)
    }

    private func organizeTranscript(_ text: String, language: LanguageOption) -> String {
        paragraphParts(from: text)
            .map { organizeParagraph($0, language: language) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    private func organizeParagraph(_ text: String, language: LanguageOption) -> String {
        var organized = text
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        organized = organized.replacingOccurrences(
            of: #"([.!?。！？]+)\s+"#,
            with: "$1\n",
            options: .regularExpression
        )

        if language.id == "ko-KR" {
            organized = organized.replacingOccurrences(
                of: #"(습니다|니다|어요|아요|세요|군요|네요|죠|지요|다)\s+"#,
                with: "$1\n",
                options: .regularExpression
            )
        }

        return organized
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func paragraphParts(from text: String) -> [String] {
        let marker = "\u{1E}"
        let normalized = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: #"[ \t]*\n{2,}[ \t]*"#, with: marker, options: .regularExpression)

        return normalized
            .components(separatedBy: marker)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func translateTranscript(
        _ text: String,
        source: LanguageOption,
        target: LanguageOption
    ) async throws -> String {
        let paragraphs = paragraphParts(from: text)

        guard !paragraphs.isEmpty else { return "" }

        var translatedParagraphs: [String] = []
        for paragraph in paragraphs {
            let segments = paragraph
                .split(separator: "\n", omittingEmptySubsequences: true)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            var translatedSegments: [String] = []

            for segment in segments {
                let cacheKey = translationCacheKey(segment: segment, source: source, target: target)
                if let cachedSegment = translatedSegmentsBySource[cacheKey] {
                    translatedSegments.append(cachedSegment)
                    continue
                }

                let translatedSegment = try await translator.translate(
                    segment,
                    source: source,
                    target: target,
                    model: selectedModel
                )
                let organizedSegment = organizeTranscript(translatedSegment, language: target)
                translatedSegmentsBySource[cacheKey] = organizedSegment
                translatedSegments.append(organizedSegment)
            }

            translatedParagraphs.append(translatedSegments.joined(separator: "\n"))
        }

        return translatedParagraphs.joined(separator: "\n\n")
    }

    private func translationCacheKey(segment: String, source: LanguageOption, target: LanguageOption) -> String {
        "\(source.id)\t\(target.id)\t\(selectedModel.id)\t\(segment)"
    }

    private func requestTranslation(for line: CaptionLine, source: LanguageOption, target: LanguageOption) {
        let sourceText = line.sourceText
        guard pendingTranslationSourceText != sourceText else { return }
        pendingTranslationSourceText = sourceText

        Task {
            do {
                let translatedText = try await translateTranscript(
                    sourceText,
                    source: source,
                    target: target
                )
                updateTranslation(translatedText, for: line, matching: sourceText)
            } catch {
                if pendingTranslationSourceText == sourceText {
                    pendingTranslationSourceText = ""
                }
                statusMessage = error.localizedDescription
            }
        }
    }

    private func updateTranslation(_ translatedText: String, for line: CaptionLine, matching sourceText: String) {
        guard let index = lines.firstIndex(where: { $0.id == line.id }) else { return }
        guard lines[index].sourceText == sourceText else {
            if pendingTranslationSourceText == sourceText {
                pendingTranslationSourceText = ""
            }
            return
        }
        let organizedTranslatedText = organizeTranscript(translatedText, language: targetLanguage)
        if pendingTranslationSourceText == sourceText {
            pendingTranslationSourceText = ""
        }

        lines[index] = CaptionLine(
            id: line.id,
            sourceText: sourceText,
            translatedText: organizedTranslatedText,
            translatedSourceText: sourceText,
            createdAt: line.createdAt,
            isFinal: line.isFinal,
            revision: lines[index].revision + 1
        )

        if isRunning, isDubbingEnabled, line.isFinal {
            speak(organizedTranslatedText)
        }
    }

    private func translationDirection(
        for text: String,
        recognizedLanguage: LanguageOption
    ) -> (source: LanguageOption, target: LanguageOption)? {
        (sourceLanguage, targetLanguage)
    }

    private func speak(_ text: String) {
        guard !text.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: targetLanguage.id)
        speaker.speak(utterance)
    }
}

extension TranslationSessionStore: SystemAudioCaptureDelegate {
    nonisolated func systemAudioCapture(_ capture: SystemAudioCapture, didOutput sampleBuffer: CMSampleBuffer) {
        transcriber.append(sampleBuffer)
    }

    nonisolated func systemAudioCapture(_ capture: SystemAudioCapture, didReceiveAudioSampleCount count: Int, level: Float?) {
        Task { @MainActor in
            audioSampleCount = count
            latestAudioLevel = level
            if isRunning, lines.isEmpty {
                statusMessage = audioStatusMessage(sampleCount: count, level: level)
            }
            if let level, level < -50 {
                scheduleTranscriptCleanup()
            }
        }
    }

    private func audioStatusMessage(sampleCount: Int, level: Float?) -> String {
        guard let level else {
            return AppText.receivingAudioWaiting(sampleCount: sampleCount)
        }

        let roundedLevel = Int(level.rounded())
        if level < -55 {
            return AppText.receivingSilentAudio(sampleCount: sampleCount, level: roundedLevel)
        }

        return AppText.receivingAudioTranscribing(sampleCount: sampleCount, level: roundedLevel)
    }
}

extension TranslationSessionStore: LiveSpeechTranscriberDelegate {
    nonisolated func liveSpeechTranscriber(
        _ transcriber: LiveSpeechTranscriber,
        didRecognize text: String,
        language: LanguageOption,
        confidence: Double
    ) {
        Task { @MainActor in
            await appendCaption(
                sourceText: text,
                recognizedLanguage: language,
                confidence: confidence,
                isFinal: false
            )
        }
    }

    nonisolated func liveSpeechTranscriber(_ transcriber: LiveSpeechTranscriber, didFail error: Error) {
        Task { @MainActor in
            statusMessage = error.localizedDescription
        }
    }
}
