import Foundation

// MARK: - Secure API Configuration
struct SecureAPIConfig {
    
    static var edamamAppId: String {
        // 1. Try Keychain first (most secure)
        if let keychainValue = KeychainManager.shared.getEdamamAppId() {
            return keychainValue
        }
        
        // 2. Try environment variable (for CI/CD)
        if let envValue = ProcessInfo.processInfo.environment["EDAMAM_APP_ID"], !envValue.isEmpty {
            // Store in keychain for next time
            KeychainManager.shared.storeAPICredentials(
                appId: envValue,
                appKey: edamamAppKey
            )
            return envValue
        }
        
        // 3. Try Info.plist (for build configurations)
        if let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_ID") as? String, !infoPlistValue.isEmpty {
            // Store in keychain for next time
            KeychainManager.shared.storeAPICredentials(
                appId: infoPlistValue,
                appKey: edamamAppKey
            )
            return infoPlistValue
        }
        
        // 4. Fatal error in production
        #if DEBUG
        // For development only - will be removed before App Store submission
        let devId = "temporary_dev_id"
        KeychainManager.shared.storeAPICredentials(
            appId: devId,
            appKey: edamamAppKey
        )
        return devId
        #else
        fatalError("EDAMAM_APP_ID not configured. Please set it in environment variables or Info.plist")
        #endif
    }
    
    static var edamamAppKey: String {
        // 1. Try Keychain first (most secure)
        if let keychainValue = KeychainManager.shared.getEdamamAppKey() {
            return keychainValue
        }
        
        // 2. Try environment variable (for CI/CD)
        if let envValue = ProcessInfo.processInfo.environment["EDAMAM_APP_KEY"], !envValue.isEmpty {
            // Store in keychain for next time
            KeychainManager.shared.storeAPICredentials(
                appId: edamamAppId,
                appKey: envValue
            )
            return envValue
        }
        
        // 3. Try Info.plist (for build configurations)
        if let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_KEY") as? String, !infoPlistValue.isEmpty {
            // Store in keychain for next time
            KeychainManager.shared.storeAPICredentials(
                appId: edamamAppId,
                appKey: infoPlistValue
            )
            return infoPlistValue
        }
        
        // 4. Fatal error in production
        #if DEBUG
        // For development only - will be removed before App Store submission
        let devKey = "temporary_dev_key"
        KeychainManager.shared.storeAPICredentials(
            appId: edamamAppId,
            appKey: devKey
        )
        return devKey
        #else
        fatalError("EDAMAM_APP_KEY not configured. Please set it in environment variables or Info.plist")
        #endif
    }
}

// MARK: - Migration Helper
extension SecureAPIConfig {
    /// Migrates from old APIConfig to secure storage
    static func migrateFromOldConfig() {
        // This will automatically store credentials in Keychain
        // when accessed for the first time
        _ = edamamAppId
        _ = edamamAppKey
    }
}