import Foundation

final class DeepgramSpeechOutput: @unchecked Sendable {
    private static let sampleRate = 24_000.0

    private let audioOutput = RealtimeAudioOutput()
    private let fallbackOutput = TranslatedSpeechOutput()
    private let queue = DispatchQueue(label: "AirTranslate.DeepgramSpeechOutput")
    private var spokenKeys: Set<String> = []

    func preferredEngineDescription(for language: LanguageOption) -> String {
        if GoogleTTSAPIKeyStore.hasAPIKey() {
            return "Google Cloud TTS (\(language.id))"
        }
        if let voice = Self.deepgramVoiceModel(for: language) {
            return "Deepgram Aura (\(voice))"
        }
        return "macOS Voice (\(language.localizedTitle))"
    }

    func speak(_ text: String, language: LanguageOption, statusHandler: (@MainActor (String) -> Void)? = nil) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let key = normalizedSpeechKey(trimmedText, language: language)
        var shouldSpeak = false
        queue.sync {
            if !spokenKeys.contains(key) {
                spokenKeys.insert(key)
                shouldSpeak = true
            }
        }
        guard shouldSpeak else { return }

        Task { [weak self] in
            guard let self else { return }
            if GoogleTTSAPIKeyStore.hasAPIKey() {
                do {
                    await statusHandler?("Google Cloud TTS (\(language.id))")
                    let audioData = try await synthesizeWithGoogle(trimmedText, language: language)
                    audioOutput.playPCM16Data(audioData, sampleRate: Self.sampleRate)
                    return
                } catch {
                    await statusHandler?("Google Cloud TTS failed, trying fallback")
                }
            }
            guard let voiceModel = Self.deepgramVoiceModel(for: language) else {
                await statusHandler?("macOS Voice (\(language.localizedTitle))")
                fallbackOutput.speak(trimmedText, language: language)
                return
            }
            do {
                await statusHandler?("Deepgram Aura (\(voiceModel))")
                let audioData = try await synthesizeWithDeepgram(trimmedText, voiceModel: voiceModel)
                audioOutput.playPCM16Data(audioData, sampleRate: Self.sampleRate)
            } catch {
                await statusHandler?("macOS Voice fallback (\(language.localizedTitle))")
                fallbackOutput.speak(trimmedText, language: language)
            }
        }
    }

    func testGoogleConnection() async throws {
        _ = try await synthesizeWithGoogle("hello", language: .english)
    }

    func stop() {
        queue.sync {
            spokenKeys.removeAll()
        }
        audioOutput.stop()
        fallbackOutput.stop()
    }

    private func synthesizeWithDeepgram(_ text: String, voiceModel: String) async throws -> Data {
        guard let apiKey = try DeepgramAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingAPIKey
        }

        var components = URLComponents(string: "https://api.deepgram.com/v1/speak")!
        components.queryItems = [
            URLQueryItem(name: "model", value: voiceModel),
            URLQueryItem(name: "encoding", value: "linear16"),
            URLQueryItem(name: "sample_rate", value: "\(Int(Self.sampleRate))")
        ]
        guard let url = components.url else {
            throw OpenAITranslationError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(DeepgramSpeakRequest(text: text))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITranslationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode), !data.isEmpty else {
            throw OpenAITranslationError.requestFailed(statusCode: httpResponse.statusCode, message: nil)
        }
        return data
    }

    private func synthesizeWithGoogle(_ text: String, language: LanguageOption) async throws -> Data {
        guard let apiKey = try GoogleTTSAPIKeyStore.readAPIKey(), !apiKey.isEmpty else {
            throw OpenAITranslationError.missingGoogleAPIKey
        }

        var components = URLComponents(string: "https://texttospeech.googleapis.com/v1/text:synthesize")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = components.url else {
            throw OpenAITranslationError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GoogleTTSRequest(
            input: .init(text: text),
            voice: .init(languageCode: language.id),
            audioConfig: .init(
                audioEncoding: "LINEAR16",
                speakingRate: 1.05,
                pitch: 0,
                volumeGainDb: 10,
                sampleRateHertz: Int(Self.sampleRate)
            )
        ))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITranslationError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let errorResponse = try? JSONDecoder().decode(GoogleTTSErrorResponse.self, from: data)
            throw OpenAITranslationError.requestFailed(statusCode: httpResponse.statusCode, message: errorResponse?.error.message)
        }
        let body = try JSONDecoder().decode(GoogleTTSResponse.self, from: data)
        guard let audioData = Data(base64Encoded: body.audioContent), !audioData.isEmpty else {
            throw OpenAITranslationError.emptyOutput
        }
        return Self.stripWAVHeaderIfNeeded(from: audioData)
    }

    private static func stripWAVHeaderIfNeeded(from data: Data) -> Data {
        guard data.count > 44,
              String(data: data.prefix(4), encoding: .ascii) == "RIFF",
              String(data: data.dropFirst(8).prefix(4), encoding: .ascii) == "WAVE"
        else {
            return data
        }

        var offset = 12
        while offset + 8 <= data.count {
            let chunkID = String(data: data[offset..<offset + 4], encoding: .ascii)
            let sizeRange = offset + 4..<offset + 8
            let chunkSize = data[sizeRange].withUnsafeBytes { rawBuffer -> UInt32 in
                rawBuffer.load(as: UInt32.self).littleEndian
            }
            let dataStart = offset + 8
            let dataEnd = dataStart + Int(chunkSize)
            if chunkID == "data", dataEnd <= data.count {
                return Data(data[dataStart..<dataEnd])
            }
            offset = dataEnd + (Int(chunkSize) % 2)
        }
        return data
    }

    private static func deepgramVoiceModel(for language: LanguageOption) -> String? {
        switch language.id.split(separator: "-").first.map(String.init) {
        case "en":
            "aura-2-thalia-en"
        case "es":
            "aura-2-luna-es"
        case "de":
            "aura-2-florian-de"
        case "fr":
            "aura-2-aurelie-fr"
        case "it":
            "aura-2-gino-it"
        case "ja":
            "aura-2-akari-ja"
        case "nl":
            "aura-2-bram-nl"
        default:
            nil
        }
    }

    private func normalizedSpeechKey(_ text: String, language: LanguageOption) -> String {
        text
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: language.locale)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DeepgramSpeakRequest: Encodable {
    let text: String
}

private struct GoogleTTSRequest: Encodable {
    struct Input: Encodable {
        let text: String
    }

    struct Voice: Encodable {
        let languageCode: String
    }

    struct AudioConfig: Encodable {
        let audioEncoding: String
        let speakingRate: Double
        let pitch: Double
        let volumeGainDb: Double
        let sampleRateHertz: Int
    }

    let input: Input
    let voice: Voice
    let audioConfig: AudioConfig
}

private struct GoogleTTSResponse: Decodable {
    let audioContent: String
}

private struct GoogleTTSErrorResponse: Decodable {
    struct ErrorBody: Decodable {
        let message: String?
    }

    let error: ErrorBody
}
