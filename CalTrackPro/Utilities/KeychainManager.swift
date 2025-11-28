import Foundation
import Security

/// Secure storage manager using iOS Keychain
final class KeychainManager {
    static let shared = KeychainManager()
    
    private init() {}
    
    private let serviceName = "com.easyaiflows.CalTrackProFixed"
    
    enum KeychainError: Error {
        case duplicateEntry
        case unknown(OSStatus)
        case itemNotFound
        case invalidData
    }
    
    // MARK: - Public Methods
    
    /// Saves a string value to the keychain
    func save(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        try save(data, for: key)
    }
    
    /// Retrieves a string value from the keychain
    func getString(for key: String) throws -> String? {
        guard let data = try getData(for: key) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return string
    }
    
    /// Saves data to the keychain
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // First try to delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add the new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Retrieves data from the keychain
    func getData(for key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status != errSecItemNotFound else {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    /// Updates an existing keychain item
    func update(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status != errSecItemNotFound else {
            // Item doesn't exist, create it
            try save(value, for: key)
            return
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Deletes an item from the keychain
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
    
    /// Deletes all items for this app from the keychain
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unknown(status)
        }
    }
}

// MARK: - Convenience Methods
extension KeychainManager {
    /// Simple get method for compatibility
    func get(key: String) -> String? {
        try? getString(for: key)
    }

    /// Simple set method for compatibility
    func set(value: String, forKey key: String) {
        try? save(value, for: key)
    }

    /// Simple delete method for compatibility
    func removeValue(forKey key: String) {
        try? delete(for: key)
    }
}

// MARK: - API Key Storage Extension
extension KeychainManager {
    private enum Keys {
        static let edamamAppId = "EDAMAM_APP_ID_SECURE"
        static let edamamAppKey = "EDAMAM_APP_KEY_SECURE"
        static let openAIAPIKey = "OPENAI_API_KEY_SECURE"
    }

    // MARK: - OpenAI API Key Methods

    func setOpenAIAPIKey(_ key: String) {
        try? save(key, for: Keys.openAIAPIKey)
    }

    func getOpenAIAPIKey() -> String? {
        try? getString(for: Keys.openAIAPIKey)
    }

    func deleteOpenAIAPIKey() {
        try? delete(for: Keys.openAIAPIKey)
    }

    var hasOpenAIAPIKey: Bool {
        if let key = getOpenAIAPIKey(), !key.isEmpty {
            return true
        }
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return true
        }
        return false
    }
    
    /// Stores API credentials securely
    func storeAPICredentials(appId: String, appKey: String) {
        do {
            try save(appId, for: Keys.edamamAppId)
            try save(appKey, for: Keys.edamamAppKey)
            CrashlyticsManager.shared.log("API credentials stored securely", category: "Security")
        } catch {
            CrashlyticsManager.shared.recordError(error, additionalInfo: ["action": "store_api_credentials"])
        }
    }
    
    /// Retrieves Edamam App ID from secure storage
    func getEdamamAppId() -> String? {
        do {
            return try getString(for: Keys.edamamAppId)
        } catch {
            CrashlyticsManager.shared.recordError(error, additionalInfo: ["key": "edamam_app_id"])
            return nil
        }
    }
    
    /// Retrieves Edamam App Key from secure storage
    func getEdamamAppKey() -> String? {
        do {
            return try getString(for: Keys.edamamAppKey)
        } catch {
            CrashlyticsManager.shared.recordError(error, additionalInfo: ["key": "edamam_app_key"])
            return nil
        }
    }
    
    /// Checks if API credentials are stored
    var hasStoredCredentials: Bool {
        return getEdamamAppId() != nil && getEdamamAppKey() != nil
    }
}