import AVFoundation
import CoreMedia
import Foundation

final class DeepgramRealtimeTranscriber: TranscriptionProvider, @unchecked Sendable {
    private static let sampleRate = 24_000
    private static let maxAudioChunkMilliseconds = 100
    private static let bytesPerPCM16Sample = 2
    private static let maxPCM16AudioChunkByteCount = sampleRate
        * bytesPerPCM16Sample
        * maxAudioChunkMilliseconds
        / 1_000

    weak var delegate: LiveSpeechTranscriberDelegate?
    let delegateToken = LiveSpeechTranscriber()

    private let stateLock = NSLock()
    private let conversionLock = NSLock()
    private var webSocketTask: URLSessionWebSocketTask?
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempts = 0
    private var lastAPIKey = ""
    private var language = LanguageOption.english
    private var scenarioMode = CaptionScenarioMode.standard
    private var isPaused = false
    private var isStopped = true

    func start(language: LanguageOption) async throws {
        try await start(language: language, scenarioMode: .standard)
    }

    func start(language: LanguageOption, scenarioMode: CaptionScenarioMode) async throws {
        stop()

        guard let apiKey = try DeepgramAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        lastAPIKey = apiKey
        self.language = language
        self.scenarioMode = scenarioMode
        isStopped = false
        reconnectAttempts = 0
        try await connect(apiKey: apiKey, language: language, scenarioMode: scenarioMode)
    }

    private func connect(apiKey: String, language: LanguageOption, scenarioMode: CaptionScenarioMode) async throws {
        var components = URLComponents(string: "wss://api.deepgram.com/v1/listen")!
        components.queryItems = [
            URLQueryItem(name: "model", value: "nova-3"),
            URLQueryItem(name: "language", value: language.deepgramLanguageCode),
            URLQueryItem(name: "encoding", value: "linear16"),
            URLQueryItem(name: "sample_rate", value: "\(Self.sampleRate)"),
            URLQueryItem(name: "channels", value: "1"),
            URLQueryItem(name: "interim_results", value: "true"),
            URLQueryItem(name: "punctuate", value: "true"),
            URLQueryItem(name: "smart_format", value: "true"),
            URLQueryItem(name: "endpointing", value: "\(scenarioMode.deepgramEndpointingMilliseconds)"),
            URLQueryItem(name: "utterance_end_ms", value: "\(scenarioMode.deepgramUtteranceEndMilliseconds)"),
            URLQueryItem(name: "vad_events", value: "true")
        ]
        guard let url = components.url else {
            throw OpenAITranslationError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let webSocketTask = URLSession.shared.webSocketTask(with: request)
        self.webSocketTask = webSocketTask
        webSocketTask.resume()
        delegate?.liveSpeechTranscriber(delegateToken, didUpdateStatus: AppText.deepgramConnectedStatus)

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
        let chunks = pcm16AudioChunks(from: sampleBuffer)
        conversionLock.unlock()

        for chunk in chunks {
            webSocketTask.send(.data(chunk)) { [weak self] error in
                guard let error, let self else { return }
                self.delegate?.liveSpeechTranscriber(self.delegateToken, didFail: error)
            }
        }
    }

    func setPaused(_ isPaused: Bool) {
        stateLock.lock()
        self.isPaused = isPaused
        stateLock.unlock()
    }

    func stop() {
        isStopped = true
        setPaused(false)
        reconnectTask?.cancel()
        reconnectTask = nil
        receiveTask?.cancel()
        receiveTask = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
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
                scheduleReconnect(after: error)
                return
            }
        }
    }

    private func scheduleReconnect(after error: Error) {
        stateLock.lock()
        let shouldReconnect = !isStopped && reconnectTask == nil && reconnectAttempts < 5
        reconnectAttempts += 1
        let attempt = reconnectAttempts
        stateLock.unlock()

        guard shouldReconnect else {
            delegate?.liveSpeechTranscriber(delegateToken, didFail: error)
            return
        }

        delegate?.liveSpeechTranscriber(delegateToken, didUpdateStatus: AppText.deepgramReconnectingStatus(attempt: attempt))
        reconnectTask = Task { [weak self] in
            let delay = min(8, Double(attempt) * 1.5)
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            do {
                try await self.connect(apiKey: self.lastAPIKey, language: self.language, scenarioMode: self.scenarioMode)
                self.markReconnectSucceeded()
            } catch {
                self.markReconnectFailed()
                self.scheduleReconnect(after: error)
            }
        }
    }

    private func markReconnectSucceeded() {
        stateLock.lock()
        reconnectAttempts = 0
        reconnectTask = nil
        stateLock.unlock()
    }

    private func markReconnectFailed() {
        stateLock.lock()
        reconnectTask = nil
        stateLock.unlock()
    }

    private func handleEventText(_ text: String) {
        guard let data = text.data(using: .utf8),
              let response = try? JSONDecoder().decode(DeepgramTranscriptResponse.self, from: data),
              let transcript = response.channel?.alternatives.first?.transcript,
              !transcript.isEmpty
        else {
            return
        }

        delegate?.liveSpeechTranscriber(
            delegateToken,
            didRecognize: transcript,
            language: language,
            confidence: response.channel?.alternatives.first?.confidence ?? 0.8
        )
    }

    private func pcm16AudioChunks(from sampleBuffer: CMSampleBuffer) -> [Data] {
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
        ) { rawList -> [Data] in
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

            return pcm16Chunks(from: audioData)
        }
    }

    private func pcm16Chunks(from audioData: Data) -> [Data] {
        guard !audioData.isEmpty else { return [] }
        guard audioData.count > Self.maxPCM16AudioChunkByteCount else {
            return [audioData]
        }

        var chunks: [Data] = []
        var offset = 0
        while offset < audioData.count {
            let end = min(offset + Self.maxPCM16AudioChunkByteCount, audioData.count)
            chunks.append(Data(audioData[offset..<end]))
            offset = end
        }
        return chunks
    }

}

enum DeepgramAPIKeyTester {
    static func testConnection() async throws {
        guard let apiKey = try DeepgramAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: "https://api.deepgram.com/v1/projects")!)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITranslationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(DeepgramErrorResponse.self, from: data)
            throw OpenAITranslationError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.errMsg ?? errorResponse?.message
            )
        }
    }
}

private struct DeepgramErrorResponse: Decodable {
    let errMsg: String?
    let message: String?

    private enum CodingKeys: String, CodingKey {
        case errMsg = "err_msg"
        case message
    }
}

private struct DeepgramTranscriptResponse: Decodable {
    let channel: DeepgramChannel?
}

private struct DeepgramChannel: Decodable {
    let alternatives: [DeepgramAlternative]
}

private struct DeepgramAlternative: Decodable {
    let transcript: String
    let confidence: Double?
}

private extension LanguageOption {
    var deepgramLanguageCode: String {
        String(id.prefix(2))
    }
}
