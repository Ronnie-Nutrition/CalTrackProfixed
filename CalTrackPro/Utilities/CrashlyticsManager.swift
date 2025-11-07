import Foundation
import FirebaseCrashlytics

/// Manager for handling crash reporting and analytics
final class CrashlyticsManager {
    
    static let shared = CrashlyticsManager()
    
    private init() {}
    
    // MARK: - User Identification
    
    /// Sets the user identifier for crash reports
    /// - Parameter userId: The user's unique identifier (never use email or personal info)
    func setUserId(_ userId: String?) {
        guard let userId = userId else {
            Crashlytics.crashlytics().setUserID("")
            return
        }
        Crashlytics.crashlytics().setUserID(userId)
    }
    
    // MARK: - Custom Logging
    
    /// Logs a custom event with Crashlytics
    /// - Parameters:
    ///   - message: The message to log
    ///   - category: The category of the log (e.g., "API", "Database", "UI")
    func log(_ message: String, category: String = "General") {
        let logMessage = "[\(category)] \(message)"
        Crashlytics.crashlytics().log(logMessage)
    }
    
    /// Records a non-fatal error
    /// - Parameters:
    ///   - error: The error to record
    ///   - additionalInfo: Additional context about the error
    func recordError(_ error: Error, additionalInfo: [String: Any]? = nil) {
        let nsError = error as NSError
        
        var userInfo = nsError.userInfo
        if let additionalInfo = additionalInfo {
            additionalInfo.forEach { userInfo[$0.key] = $0.value }
        }
        
        let recordableError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: userInfo
        )
        
        Crashlytics.crashlytics().record(error: recordableError)
    }
    
    // MARK: - Custom Keys
    
    /// Sets a custom key-value pair for crash reports
    /// - Parameters:
    ///   - value: The value to set
    ///   - key: The key for the value
    func setCustomValue(_ value: Any?, forKey key: String) {
        guard let value = value else {
            Crashlytics.crashlytics().setCustomValue(nil, forKey: key)
            return
        }
        
        if let stringValue = value as? String {
            Crashlytics.crashlytics().setCustomValue(stringValue, forKey: key)
        } else if let intValue = value as? Int {
            Crashlytics.crashlytics().setCustomValue(intValue, forKey: key)
        } else if let boolValue = value as? Bool {
            Crashlytics.crashlytics().setCustomValue(boolValue, forKey: key)
        } else {
            Crashlytics.crashlytics().setCustomValue(String(describing: value), forKey: key)
        }
    }
    
    // MARK: - Screen Tracking
    
    /// Logs screen views for better crash context
    /// - Parameter screenName: The name of the screen
    func logScreenView(_ screenName: String) {
        log("Screen viewed: \(screenName)", category: "Navigation")
        setCustomValue(screenName, forKey: "last_screen")
    }
    
    // MARK: - API Tracking
    
    /// Logs API requests for debugging
    /// - Parameters:
    ///   - endpoint: The API endpoint
    ///   - method: The HTTP method
    ///   - statusCode: The response status code (if available)
    func logAPIRequest(endpoint: String, method: String, statusCode: Int? = nil) {
        var message = "API Request: \(method) \(endpoint)"
        if let statusCode = statusCode {
            message += " - Status: \(statusCode)"
        }
        log(message, category: "API")
    }
    
    // MARK: - Debug Helpers
    
    #if DEBUG
    /// Forces a crash for testing Crashlytics integration
    /// WARNING: Only available in DEBUG builds
    func testCrash() {
        log("Test crash initiated by user", category: "Debug")
        fatalError("Test crash triggered for Crashlytics testing")
    }
    #endif
}

// MARK: - Convenience Extensions

extension CrashlyticsManager {
    
    /// Logs a food search
    func logFoodSearch(query: String, resultCount: Int) {
        log("Food search: '\(query)' returned \(resultCount) results", category: "FoodSearch")
        setCustomValue(query, forKey: "last_food_search")
    }
    
    /// Logs barcode scanning
    func logBarcodeScanned(barcode: String, found: Bool) {
        log("Barcode scanned: \(barcode) - Found: \(found)", category: "BarcodeScanner")
        setCustomValue(barcode, forKey: "last_barcode_scanned")
    }
    
    /// Logs recipe creation
    func logRecipeCreated(recipeName: String, ingredientCount: Int) {
        log("Recipe created: '\(recipeName)' with \(ingredientCount) ingredients", category: "Recipe")
    }
    
    /// Logs nutrition goal updates
    func logGoalUpdated(goalType: String, value: Any) {
        log("Goal updated: \(goalType) = \(value)", category: "UserProfile")
    }
}