import Foundation
import Security

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

        let status = SecItemCopyMatching(baseQuery() as CFDictionary, nil)
        return status == errSecSuccess
    }

    func readAPIKey() throws -> String? {
        if APIKeyCache.isRunningTests {
            return nil
        }
        if let cachedKey = APIKeyCache.read(service: service, account: account) {
            return cachedKey
        }

        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw OpenAIAPIKeyStoreError.keychainStatus(status)
        }
        guard let data = item as? Data,
              let key = String(data: data, encoding: .utf8) else {
            throw OpenAIAPIKeyStoreError.invalidStoredKey
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
        guard let data = trimmedKey.data(using: .utf8) else {
            throw OpenAIAPIKeyStoreError.invalidStoredKey
        }

        SecItemDelete(baseQuery() as CFDictionary)

        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw OpenAIAPIKeyStoreError.keychainStatus(status)
        }
        APIKeyCache.write(trimmedKey, service: service, account: account)
    }

    func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw OpenAIAPIKeyStoreError.keychainStatus(status)
        }
        APIKeyCache.remove(service: service, account: account)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
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

enum OpenAIAPIKeyStoreError: LocalizedError {
    case emptyKey
    case invalidStoredKey
    case maskedPlaceholder
    case keychainStatus(OSStatus)

    var errorDescription: String? {
        switch self {
        case .emptyKey:
            AppText.openAIAPIKeyEmpty
        case .invalidStoredKey:
            AppText.openAIAPIKeyInvalidStoredValue
        case .maskedPlaceholder:
            AppText.openAIAPIKeyMaskedPlaceholder
        case let .keychainStatus(status):
            AppText.openAIAPIKeychainFailed(status)
        }
    }
}
