import AVFoundation
import CoreMedia
import Foundation

final class AIRealtimeTranscriber: @unchecked Sendable {
    private static let realtimeAudioSampleRate = 24_000
    private static let maxAudioChunkMilliseconds = 80
    private static let bytesPerPCM16Sample = 2
    private static let maxPCM16AudioChunkByteCount = realtimeAudioSampleRate
        * bytesPerPCM16Sample
        * maxAudioChunkMilliseconds
        / 1_000

    enum OutputMode {
        case transcription
        case translationOnly
    }

    weak var delegate: LiveSpeechTranscriberDelegate?

    private let stateLock = NSLock()
    private let conversionLock = NSLock()
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var language = LanguageOption.supported[0]
    private var outputMode = OutputMode.transcription
    private var isPaused = false
    private var realtimeTranscriptText = ""

    func start(language: LanguageOption, model: AITranscriptionModel) async throws {
        try await start(
            language: language,
            modelID: model.rawValue,
            outputMode: .transcription,
            isEnabled: model.isEnabled
        )
    }

    func startRealtimeTranslationOnly(language: LanguageOption, model: AITranslationModel) async throws {
        try await start(
            language: language,
            modelID: model.apiModelID,
            outputMode: .translationOnly,
            isEnabled: model.usesRealtimeAudioTranslation
        )
    }

    private func start(
        language: LanguageOption,
        modelID: String,
        outputMode: OutputMode,
        isEnabled: Bool
    ) async throws {
        stop()

        guard isEnabled else { return }
        guard let apiKey = try OpenAIAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        self.language = language
        self.outputMode = outputMode
        realtimeTranscriptText = ""
        let url: URL
        switch outputMode {
        case .transcription:
            url = URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!
        case .translationOnly:
            url = URL(string: "wss://api.openai.com/v1/realtime/translations?model=\(modelID)")!
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let webSocketTask = URLSession.shared.webSocketTask(with: request)
        self.webSocketTask = webSocketTask
        webSocketTask.resume()

        try await sendSessionUpdate(language: language, modelID: modelID)
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        stateLock.lock()
        let isPaused = isPaused
        let webSocketTask = webSocketTask
        let audioAppendEventType = outputMode.audioAppendEventType
        stateLock.unlock()

        guard !isPaused, let webSocketTask else { return }

        conversionLock.lock()
        let audioChunks = pcm16Base64AudioChunks(from: sampleBuffer)
        conversionLock.unlock()

        for audio in audioChunks {
            let event = RealtimeAudioAppendEvent(
                type: audioAppendEventType,
                audio: audio
            )
            guard let data = try? JSONEncoder().encode(event),
                  let text = String(data: data, encoding: .utf8) else { continue }

            webSocketTask.send(.string(text)) { [weak self] error in
                guard let error, let self else { return }
                self.delegate?.liveSpeechTranscriber(self.proxyTranscriber, didFail: error)
            }
        }
    }

    func setPaused(_ isPaused: Bool) {
        stateLock.lock()
        self.isPaused = isPaused
        stateLock.unlock()
    }

    func stop() {
        setPaused(false)
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        realtimeTranscriptText = ""
    }

    private func sendSessionUpdate(language: LanguageOption, modelID: String) async throws {
        let data: Data
        switch outputMode {
        case .transcription:
            let event = RealtimeTranscriptionSessionUpdateEvent(
                session: RealtimeTranscriptionSession(
                    type: "transcription",
                    audio: RealtimeTranscriptionAudio(
                        input: RealtimeTranscriptionAudioInput(
                            format: RealtimeAudioFormat(type: "audio/pcm", rate: Self.realtimeAudioSampleRate),
                            transcription: RealtimeTranscriptionConfig(
                                model: modelID,
                                language: language.openAILanguageCode
                            ),
                            turnDetection: .lowLatencyServerVAD,
                            noiseReduction: RealtimeNoiseReduction(type: "near_field")
                        )
                    )
                )
            )
            data = try JSONEncoder().encode(event)
        case .translationOnly:
            let event = RealtimeTranslationSessionUpdateEvent(
                session: RealtimeTranslationSession(
                    audio: RealtimeTranslationAudio(
                        output: RealtimeTranslationAudioOutput(
                            language: language.openAILanguageCode
                        )
                    )
                )
            )
            data = try JSONEncoder().encode(event)
        }
        guard let text = String(data: data, encoding: .utf8) else { return }
        try await send(text)
    }

    private func send(_ text: String) async throws {
        guard let webSocketTask else { return }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            webSocketTask.send(.string(text)) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    private func receiveLoop() async {
        while !Task.isCancelled {
            guard let webSocketTask else { return }
            do {
                let message = try await webSocketTask.receive()
                guard case let .string(text) = message else { continue }
                handleEventText(text)
            } catch {
                guard !Task.isCancelled else { return }
                delegate?.liveSpeechTranscriber(proxyTranscriber, didFail: error)
                return
            }
        }
    }

    private func handleEventText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let event = try? JSONDecoder().decode(RealtimeTranscriptionEvent.self, from: data)
        else { return }

        switch event.type {
        case "conversation.item.input_audio_transcription.delta":
            guard let delta = event.delta, !delta.isEmpty else { return }
            appendRealtimeTranscriptDelta(delta)
        case "conversation.item.input_audio_transcription.completed":
            guard let transcript = event.transcript, !transcript.isEmpty else { return }
            publish(text: transcript)
            realtimeTranscriptText = ""
        case "session.output_transcript.delta":
            guard outputMode == .translationOnly,
                  let delta = event.delta,
                  !delta.isEmpty else { return }
            appendRealtimeTranscriptDelta(delta)
        case "session.output_transcript.done":
            guard outputMode == .translationOnly,
                  let transcript = event.transcript,
                  !transcript.isEmpty else { return }
            publish(text: transcript)
            realtimeTranscriptText = ""
        case "session.output_audio.delta":
            guard outputMode == .translationOnly,
                  let delta = event.delta,
                  !delta.isEmpty else { return }
            delegate?.liveSpeechTranscriber(
                proxyTranscriber,
                didOutputAudioPCM16Base64: delta,
                sampleRate: Double(Self.realtimeAudioSampleRate)
            )
        case "error":
            delegate?.liveSpeechTranscriber(proxyTranscriber, didFail: AIRealtimeTranscriberError.server(event.error?.message))
        default:
            return
        }
    }

    private func appendRealtimeTranscriptDelta(_ delta: String) {
        realtimeTranscriptText += delta
        publish(text: realtimeTranscriptText)
    }

    private func publish(text: String) {
        switch outputMode {
        case .transcription:
            delegate?.liveSpeechTranscriber(
                proxyTranscriber,
                didRecognize: text,
                language: language,
                confidence: 0.5
            )
        case .translationOnly:
            delegate?.liveSpeechTranscriber(
                proxyTranscriber,
                didTranslate: text,
                language: language,
                confidence: 0.5
            )
        }
    }

    private var proxyTranscriber: LiveSpeechTranscriber {
        LiveSpeechTranscriber()
    }

    private func pcm16Base64AudioChunks(from sampleBuffer: CMSampleBuffer) -> [String] {
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let streamDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        else {
            return []
        }

        var listSize = 0
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: &listSize,
            bufferListOut: nil,
            bufferListSize: 0,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: nil
        )
        guard listSize > 0 else { return [] }

        return withUnsafeTemporaryAllocation(
            byteCount: listSize,
            alignment: MemoryLayout<AudioBufferList>.alignment
        ) { rawList -> [String] in
            guard let baseAddress = rawList.baseAddress else { return [] }

            let audioBufferList = baseAddress.bindMemory(to: AudioBufferList.self, capacity: 1)
            var blockBuffer: CMBlockBuffer?
            let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
                sampleBuffer,
                bufferListSizeNeededOut: nil,
                bufferListOut: audioBufferList,
                bufferListSize: listSize,
                blockBufferAllocator: kCFAllocatorDefault,
                blockBufferMemoryAllocator: kCFAllocatorDefault,
                flags: kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                blockBufferOut: &blockBuffer
            )
            guard status == noErr else { return [] }

            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var audioData = Data()
            let sourceIsFloat = streamDescription.pointee.mFormatFlags & kAudioFormatFlagIsFloat != 0
            for buffer in buffers {
                guard let data = buffer.mData else { continue }

                if sourceIsFloat {
                    let sampleCount = Int(buffer.mDataByteSize) / MemoryLayout<Float>.size
                    let samples = data.bindMemory(to: Float.self, capacity: sampleCount)
                    for index in 0..<sampleCount {
                        let clamped = max(-1, min(1, samples[index]))
                        var sample = Int16(clamped * Float(Int16.max)).littleEndian
                        withUnsafeBytes(of: &sample) { audioData.append(contentsOf: $0) }
                    }
                } else {
                    audioData.append(data.assumingMemoryBound(to: UInt8.self), count: Int(buffer.mDataByteSize))
                }
            }

            guard !audioData.isEmpty else { return [] }
            return base64PCM16Chunks(from: audioData)
        }
    }

    private func base64PCM16Chunks(from audioData: Data) -> [String] {
        guard audioData.count > Self.maxPCM16AudioChunkByteCount else {
            return [audioData.base64EncodedString()]
        }

        var chunks: [String] = []
        var offset = 0
        while offset < audioData.count {
            let end = min(offset + Self.maxPCM16AudioChunkByteCount, audioData.count)
            chunks.append(Data(audioData[offset..<end]).base64EncodedString())
            offset = end
        }
        return chunks
    }
}

private struct RealtimeTranscriptionSessionUpdateEvent: Encodable {
    let type = "session.update"
    let session: RealtimeTranscriptionSession
}

private struct RealtimeTranslationSessionUpdateEvent: Encodable {
    let type = "session.update"
    let session: RealtimeTranslationSession
}

private struct RealtimeTranscriptionSession: Encodable {
    let type: String
    let audio: RealtimeTranscriptionAudio
}

private struct RealtimeTranscriptionAudio: Encodable {
    let input: RealtimeTranscriptionAudioInput
}

private struct RealtimeTranscriptionAudioInput: Encodable {
    let format: RealtimeAudioFormat
    let transcription: RealtimeTranscriptionConfig
    let turnDetection: RealtimeTurnDetection
    let noiseReduction: RealtimeNoiseReduction

    private enum CodingKeys: String, CodingKey {
        case format
        case transcription
        case turnDetection = "turn_detection"
        case noiseReduction = "noise_reduction"
    }
}

private struct RealtimeAudioFormat: Encodable {
    let type: String
    let rate: Int
}

private struct RealtimeTranslationSession: Encodable {
    let audio: RealtimeTranslationAudio
}

private struct RealtimeTranslationAudio: Encodable {
    let output: RealtimeTranslationAudioOutput
}

private struct RealtimeTranslationAudioOutput: Encodable {
    let language: String
}

private struct RealtimeTranscriptionConfig: Encodable {
    let model: String
    let language: String
}

private struct RealtimeTurnDetection: Encodable {
    let type: String
    let threshold: Double?
    let prefixPaddingMilliseconds: Int?
    let silenceDurationMilliseconds: Int?

    static let lowLatencyServerVAD = RealtimeTurnDetection(
        type: "server_vad",
        threshold: 0.42,
        prefixPaddingMilliseconds: 120,
        silenceDurationMilliseconds: 220
    )

    init(
        type: String,
        threshold: Double? = nil,
        prefixPaddingMilliseconds: Int? = nil,
        silenceDurationMilliseconds: Int? = nil
    ) {
        self.type = type
        self.threshold = threshold
        self.prefixPaddingMilliseconds = prefixPaddingMilliseconds
        self.silenceDurationMilliseconds = silenceDurationMilliseconds
    }

    private enum CodingKeys: String, CodingKey {
        case type
        case threshold
        case prefixPaddingMilliseconds = "prefix_padding_ms"
        case silenceDurationMilliseconds = "silence_duration_ms"
    }
}

private struct RealtimeNoiseReduction: Encodable {
    let type: String
}

private struct RealtimeAudioAppendEvent: Encodable {
    let type: String
    let audio: String
}

private struct RealtimeTranscriptionEvent: Decodable {
    let type: String
    let delta: String?
    let transcript: String?
    let error: RealtimeErrorBody?
}

private struct RealtimeErrorBody: Decodable {
    let message: String?
}

private enum AIRealtimeTranscriberError: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case let .server(message):
            message ?? AppText.openAIInvalidResponse
        }
    }
}

private extension AIRealtimeTranscriber.OutputMode {
    var audioAppendEventType: String {
        switch self {
        case .transcription:
            "input_audio_buffer.append"
        case .translationOnly:
            "session.input_audio_buffer.append"
        }
    }
}

private extension LanguageOption {
    var openAILanguageCode: String {
        String(id.prefix(2))
    }
}
