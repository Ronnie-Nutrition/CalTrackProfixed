import Foundation

// MARK: - API Configuration
struct APIConfig {
    // These values should be stored in environment variables or a secure configuration file
    // For development, you can temporarily use these values
    // For production, use Xcode's environment variables or a .plist file not checked into git
    
    static var edamamAppId: String {
        // Try to get from environment variable first
        if let envValue = ProcessInfo.processInfo.environment["EDAMAM_APP_ID"], !envValue.isEmpty {
            return envValue
        }
        
        // Try to get from Info.plist
        if let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_ID") as? String, !infoPlistValue.isEmpty {
            return infoPlistValue
        }
        
        // Fallback for development only - REMOVE FOR PRODUCTION
        #if DEBUG
        return "fce081fe"
        #else
        fatalError("EDAMAM_APP_ID not configured. Please set it in environment variables or Info.plist")
        #endif
    }
    
    static var edamamAppKey: String {
        // Try to get from environment variable first
        if let envValue = ProcessInfo.processInfo.environment["EDAMAM_APP_KEY"], !envValue.isEmpty {
            return envValue
        }
        
        // Try to get from Info.plist
        if let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: "EDAMAM_APP_KEY") as? String, !infoPlistValue.isEmpty {
            return infoPlistValue
        }
        
        // Fallback for development only - REMOVE FOR PRODUCTION
        #if DEBUG
        return "b1ce256719fa10b335802c08577cef51"
        #else
        fatalError("EDAMAM_APP_KEY not configured. Please set it in environment variables or Info.plist")
        #endif
    }
}