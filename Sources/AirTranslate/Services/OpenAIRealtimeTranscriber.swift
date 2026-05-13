import AVFoundation
import CoreMedia
import Foundation

final class OpenAIRealtimeTranscriber: @unchecked Sendable {
    weak var delegate: LiveSpeechTranscriberDelegate?

    private let stateLock = NSLock()
    private let conversionLock = NSLock()
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var language = LanguageOption.supported[0]
    private var isPaused = false

    func start(language: LanguageOption, model: OpenAIRealtimeTranscriptionModel) async throws {
        stop()

        guard model.isEnabled else { return }
        guard let apiKey = try OpenAIAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        self.language = language
        var request = URLRequest(url: URL(string: "wss://api.openai.com/v1/realtime?intent=transcription")!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("realtime=v1", forHTTPHeaderField: "OpenAI-Beta")

        let webSocketTask = URLSession.shared.webSocketTask(with: request)
        self.webSocketTask = webSocketTask
        webSocketTask.resume()

        try await sendSessionUpdate(language: language, model: model)
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    func append(_ sampleBuffer: CMSampleBuffer) {
        stateLock.lock()
        let isPaused = isPaused
        let webSocketTask = webSocketTask
        stateLock.unlock()

        guard !isPaused, let webSocketTask else { return }

        conversionLock.lock()
        let audio = pcm16Base64Audio(from: sampleBuffer)
        conversionLock.unlock()

        guard let audio else { return }
        let event = OpenAIRealtimeAudioAppendEvent(audio: audio)
        guard let data = try? JSONEncoder().encode(event),
              let text = String(data: data, encoding: .utf8) else { return }

        webSocketTask.send(.string(text)) { [weak self] error in
            guard let error, let self else { return }
            self.delegate?.liveSpeechTranscriber(self.proxyTranscriber, didFail: error)
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
    }

    private func sendSessionUpdate(language: LanguageOption, model: OpenAIRealtimeTranscriptionModel) async throws {
        let event = OpenAIRealtimeSessionUpdateEvent(
            session: OpenAIRealtimeSession(
                inputAudioFormat: "pcm16",
                inputAudioTranscription: OpenAIRealtimeTranscriptionConfig(
                    model: model.rawValue,
                    language: language.openAILanguageCode
                ),
                turnDetection: OpenAIRealtimeTurnDetection(type: "server_vad"),
                inputAudioNoiseReduction: OpenAIRealtimeNoiseReduction(type: "near_field")
            )
        )
        let data = try JSONEncoder().encode(event)
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
              let event = try? JSONDecoder().decode(OpenAIRealtimeTranscriptionEvent.self, from: data)
        else { return }

        switch event.type {
        case "conversation.item.input_audio_transcription.delta":
            guard let delta = event.delta, !delta.isEmpty else { return }
            delegate?.liveSpeechTranscriber(
                proxyTranscriber,
                didRecognize: delta,
                language: language,
                confidence: 0.5
            )
        case "conversation.item.input_audio_transcription.completed":
            guard let transcript = event.transcript, !transcript.isEmpty else { return }
            delegate?.liveSpeechTranscriber(
                proxyTranscriber,
                didRecognize: transcript,
                language: language,
                confidence: 0.5
            )
        case "error":
            delegate?.liveSpeechTranscriber(proxyTranscriber, didFail: OpenAIRealtimeTranscriberError.server(event.error?.message))
        default:
            return
        }
    }

    private var proxyTranscriber: LiveSpeechTranscriber {
        LiveSpeechTranscriber()
    }

    private func pcm16Base64Audio(from sampleBuffer: CMSampleBuffer) -> String? {
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
        guard listSize > 0 else { return nil }

        return withUnsafeTemporaryAllocation(
            byteCount: listSize,
            alignment: MemoryLayout<AudioBufferList>.alignment
        ) { rawList -> String? in
            guard let baseAddress = rawList.baseAddress else { return nil }

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
            guard status == noErr else { return nil }

            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            var audioData = Data()
            for buffer in buffers {
                guard let data = buffer.mData else { continue }
                audioData.append(data.assumingMemoryBound(to: UInt8.self), count: Int(buffer.mDataByteSize))
            }

            guard !audioData.isEmpty else { return nil }
            return audioData.base64EncodedString()
        }
    }
}

private struct OpenAIRealtimeSessionUpdateEvent: Encodable {
    let type = "transcription_session.update"
    let session: OpenAIRealtimeSession
}

private struct OpenAIRealtimeSession: Encodable {
    let inputAudioFormat: String
    let inputAudioTranscription: OpenAIRealtimeTranscriptionConfig
    let turnDetection: OpenAIRealtimeTurnDetection
    let inputAudioNoiseReduction: OpenAIRealtimeNoiseReduction

    private enum CodingKeys: String, CodingKey {
        case inputAudioFormat = "input_audio_format"
        case inputAudioTranscription = "input_audio_transcription"
        case turnDetection = "turn_detection"
        case inputAudioNoiseReduction = "input_audio_noise_reduction"
    }
}

private struct OpenAIRealtimeTranscriptionConfig: Encodable {
    let model: String
    let language: String
}

private struct OpenAIRealtimeTurnDetection: Encodable {
    let type: String
}

private struct OpenAIRealtimeNoiseReduction: Encodable {
    let type: String
}

private struct OpenAIRealtimeAudioAppendEvent: Encodable {
    let type = "input_audio_buffer.append"
    let audio: String
}

private struct OpenAIRealtimeTranscriptionEvent: Decodable {
    let type: String
    let delta: String?
    let transcript: String?
    let error: OpenAIRealtimeErrorBody?
}

private struct OpenAIRealtimeErrorBody: Decodable {
    let message: String?
}

private enum OpenAIRealtimeTranscriberError: LocalizedError {
    case server(String?)

    var errorDescription: String? {
        switch self {
        case let .server(message):
            message ?? AppText.openAIInvalidResponse
        }
    }
}

private extension LanguageOption {
    var openAILanguageCode: String {
        String(id.prefix(2))
    }
}
