import Foundation

enum OpenAIAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.OpenAI", account: "OPENAI_API_KEY")

    static func hasAPIKey() -> Bool {
        storage.hasAPIKey()
    }

    static func readAPIKey() throws -> String? {
        try storage.readAPIKey()
    }

    static func saveAPIKey(_ key: String) throws {
        try storage.saveAPIKey(key)
    }

    static func deleteAPIKey() throws {
        try storage.deleteAPIKey()
    }
}

enum DeepgramAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.Deepgram", account: "DEEPGRAM_API_KEY")

    static func hasAPIKey() -> Bool {
        storage.hasAPIKey()
    }

    static func readAPIKey() throws -> String? {
        try storage.readAPIKey()
    }

    static func saveAPIKey(_ key: String) throws {
        try storage.saveAPIKey(key)
    }

    static func deleteAPIKey() throws {
        try storage.deleteAPIKey()
    }
}

enum GoogleTranslateAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.GoogleTranslate", account: "GOOGLE_TRANSLATE_API_KEY")

    static func hasAPIKey() -> Bool { storage.hasAPIKey() }
    static func readAPIKey() throws -> String? { try storage.readAPIKey() }
    static func saveAPIKey(_ key: String) throws { try storage.saveAPIKey(key) }
    static func deleteAPIKey() throws { try storage.deleteAPIKey() }
}

enum GoogleTTSAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.GoogleTTS", account: "GOOGLE_TTS_API_KEY")

    static func hasAPIKey() -> Bool { storage.hasAPIKey() }
    static func readAPIKey() throws -> String? { try storage.readAPIKey() }
    static func saveAPIKey(_ key: String) throws { try storage.saveAPIKey(key) }
    static func deleteAPIKey() throws { try storage.deleteAPIKey() }
}

enum DeepLFreeAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.DeepLFree", account: "DEEPL_FREE_API_KEY")

    static func hasAPIKey() -> Bool { storage.hasAPIKey() }
    static func readAPIKey() throws -> String? { try storage.readAPIKey() }
    static func saveAPIKey(_ key: String) throws { try storage.saveAPIKey(key) }
    static func deleteAPIKey() throws { try storage.deleteAPIKey() }
}

enum DeepLProAPIKeyStore {
    private static let storage = APIKeychainStorage(service: "AirTranslateX.DeepLPro", account: "DEEPL_PRO_API_KEY")

    static func hasAPIKey() -> Bool { storage.hasAPIKey() }
    static func readAPIKey() throws -> String? { try storage.readAPIKey() }
    static func saveAPIKey(_ key: String) throws { try storage.saveAPIKey(key) }
    static func deleteAPIKey() throws { try storage.deleteAPIKey() }
}

private struct APIKeychainStorage {
    let service: String
    let account: String

    func hasAPIKey() -> Bool {
        if APIKeyCache.isRunningTests {
            return false
        }
        if let cachedKey = APIKeyCache.read(service: service, account: account) {
            return !cachedKey.isEmpty
        }

        return (try? APIConfigFileStorage.readValue(for: account))?.isEmpty == false
    }

    func readAPIKey() throws -> String? {
        if APIKeyCache.isRunningTests {
            return nil
        }
        if let cachedKey = APIKeyCache.read(service: service, account: account) {
            return cachedKey
        }

        guard let key = try APIConfigFileStorage.readValue(for: account) else {
            return nil
        }
        guard !isMaskedPlaceholder(key) else {
            throw OpenAIAPIKeyStoreError.maskedPlaceholder
        }
        APIKeyCache.write(key, service: service, account: account)
        return key
    }

    func saveAPIKey(_ key: String) throws {
        let trimmedKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw OpenAIAPIKeyStoreError.emptyKey
        }
        guard !isMaskedPlaceholder(trimmedKey) else {
            throw OpenAIAPIKeyStoreError.maskedPlaceholder
        }

        try APIConfigFileStorage.writeValue(trimmedKey, for: account)
        APIKeyCache.write(trimmedKey, service: service, account: account)
    }

    func deleteAPIKey() throws {
        try APIConfigFileStorage.deleteValue(for: account)
        APIKeyCache.remove(service: service, account: account)
    }

    private func isMaskedPlaceholder(_ key: String) -> Bool {
        key.allSatisfy { character in
            character == "*" || character == "•" || character == "●"
        }
    }
}

private enum APIKeyCache {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var values: [String: String] = [:]

    static var isRunningTests: Bool {
        ProcessInfo.processInfo.arguments.contains { argument in
            argument.contains("PackageTests") || argument.contains(".xctest")
        }
    }

    static func read(service: String, account: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return values[cacheKey(service: service, account: account)]
    }

    static func write(_ value: String, service: String, account: String) {
        lock.lock()
        defer { lock.unlock() }
        values[cacheKey(service: service, account: account)] = value
    }

    static func remove(service: String, account: String) {
        lock.lock()
        defer { lock.unlock() }
        values.removeValue(forKey: cacheKey(service: service, account: account))
    }

    private static func cacheKey(service: String, account: String) -> String {
        "\(service):\(account)"
    }
}

private enum APIConfigFileStorage {
    private static let sectionName = "api"

    static var configDirectoryURL: URL {
        AppFileLocations.appDocumentsDirectoryURL
    }

    static var configFileURL: URL {
        AppFileLocations.configFileURL
    }

    static func readValue(for account: String) throws -> String? {
        let values = try readValues()
        guard let key = configKey(for: account),
              let value = values[key]?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else {
            return nil
        }
        return value
    }

    static func writeValue(_ value: String, for account: String) throws {
        guard let key = configKey(for: account) else {
            throw OpenAIAPIKeyStoreError.invalidStoredKey
        }

        var values = try readValues()
        values[key] = value
        try writeValues(values)
    }

    static func deleteValue(for account: String) throws {
        guard let key = configKey(for: account) else { return }

        var values = try readValues()
        values.removeValue(forKey: key)
        try writeValues(values)
    }

    private static func configKey(for account: String) -> String? {
        switch account {
        case "OPENAI_API_KEY":
            "openai_api_key"
        case "DEEPGRAM_API_KEY":
            "deepgram_api_key"
        case "GOOGLE_TRANSLATE_API_KEY":
            "google_translate_api_key"
        case "GOOGLE_TTS_API_KEY":
            "google_tts_api_key"
        case "DEEPL_FREE_API_KEY":
            "deepl_free_api_key"
        case "DEEPL_PRO_API_KEY":
            "deepl_pro_api_key"
        default:
            nil
        }
    }

    private static func readValues() throws -> [String: String] {
        let url = configFileURL
        guard FileManager.default.fileExists(atPath: url.path) else {
            try ensureConfigFileExists()
            return [:]
        }

        let content = try String(contentsOf: url, encoding: .utf8)
        var isAPISection = false
        var values: [String: String] = [:]

        for rawLine in content.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty, !line.hasPrefix("#"), !line.hasPrefix(";") else { continue }

            if line.hasPrefix("["), line.hasSuffix("]") {
                isAPISection = line.dropFirst().dropLast().trimmingCharacters(in: .whitespacesAndNewlines) == sectionName
                continue
            }

            guard isAPISection,
                  let separatorIndex = line.firstIndex(of: "=")
            else {
                continue
            }

            let key = line[..<separatorIndex].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = line[line.index(after: separatorIndex)...].trimmingCharacters(in: .whitespacesAndNewlines)
            values[key] = value
        }

        return values
    }

    private static func writeValues(_ values: [String: String]) throws {
        try FileManager.default.createDirectory(at: configDirectoryURL, withIntermediateDirectories: true)

        let orderedKeys = [
            "openai_api_key",
            "deepgram_api_key",
            "google_translate_api_key",
            "google_tts_api_key",
            "deepl_free_api_key",
            "deepl_pro_api_key"
        ]
        var lines = [
            "# AirTranslateX config",
            "# File: \(configFileURL.path)",
            "# Plain text API keys. Keep this file private.",
            "",
            "[api]"
        ]
        for key in orderedKeys {
            lines.append("\(key)=\(values[key] ?? "")")
        }
        lines.append("")

        try lines.joined(separator: "\n").write(to: configFileURL, atomically: true, encoding: .utf8)
    }

    private static func ensureConfigFileExists() throws {
        try writeValues([:])
    }
}

enum OpenAIAPIKeyStoreError: LocalizedError {
    case emptyKey
    case invalidStoredKey
    case maskedPlaceholder
    case configFileFailed(String)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            AppText.openAIAPIKeyEmpty
        case .invalidStoredKey:
            AppText.openAIAPIKeyInvalidStoredValue
        case .maskedPlaceholder:
            AppText.openAIAPIKeyMaskedPlaceholder
        case let .configFileFailed(message):
            message
        }
    }
}
