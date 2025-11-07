import Foundation
import CryptoKit

/// Security configuration and utilities
struct SecurityConfig {
    
    // MARK: - App Transport Security
    
    /// Ensures all network requests use HTTPS
    static func configureNetworkSecurity() {
        // ATS is enforced by default in iOS 9+
        // This method serves as documentation and future enhancement point
        CrashlyticsManager.shared.log("Network security configured - ATS enforced", category: "Security")
    }
    
    // MARK: - Data Protection
    
    /// Sets up data protection for sensitive files
    static func configureDataProtection() {
        // SwiftData automatically uses data protection
        // Additional configuration can be added here
        CrashlyticsManager.shared.log("Data protection configured", category: "Security")
    }
    
    // MARK: - Jailbreak Detection
    
    /// Checks if device is jailbroken
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        
        // Check 1: Existence of jailbreak files
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/usr/bin/ssh",
            "/usr/libexec/ssh-keysign",
            "/Applications/blackra1n.app",
            "/Applications/IntelliScreen.app",
            "/Applications/Snoop-itConfig.app"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                CrashlyticsManager.shared.log("Jailbreak detected - file exists: \(path)", category: "Security")
                return true
            }
        }
        
        // Check 2: Can write to system directories
        let testString = "jailbreak_test"
        do {
            try testString.write(toFile: "/private/jailbreak_test.txt", atomically: true, encoding: .utf8)
            // If we can write, device is jailbroken
            try FileManager.default.removeItem(atPath: "/private/jailbreak_test.txt")
            CrashlyticsManager.shared.log("Jailbreak detected - can write to system", category: "Security")
            return true
        } catch {
            // Expected behavior for non-jailbroken devices
        }
        
        // Check 3: Can open Cydia URL
        if let url = URL(string: "cydia://") {
            if UIApplication.shared.canOpenURL(url) {
                CrashlyticsManager.shared.log("Jailbreak detected - Cydia URL scheme", category: "Security")
                return true
            }
        }
        
        return false
        #endif
    }
    
    // MARK: - String Obfuscation
    
    /// Simple obfuscation for sensitive strings
    static func obfuscate(_ string: String) -> [UInt8] {
        let data = string.data(using: .utf8)!
        let key = UInt8.random(in: 1...255)
        
        var obfuscated = [key]
        for byte in data {
            obfuscated.append(byte ^ key)
        }
        
        return obfuscated
    }
    
    /// Deobfuscate string
    static func deobfuscate(_ obfuscated: [UInt8]) -> String? {
        guard obfuscated.count > 1 else { return nil }
        
        let key = obfuscated[0]
        var data = Data()
        
        for i in 1..<obfuscated.count {
            data.append(obfuscated[i] ^ key)
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    // MARK: - URL Validation
    
    /// Validates URL for security
    static func isSecureURL(_ url: URL) -> Bool {
        // Only allow HTTPS
        guard url.scheme == "https" else {
            CrashlyticsManager.shared.log("Insecure URL scheme: \(url.scheme ?? "nil")", category: "Security")
            return false
        }
        
        // Check against whitelist of allowed domains
        let allowedDomains = [
            "api.edamam.com",
            "world.openfoodfacts.org",
            "api.openfoodfacts.org"
        ]
        
        guard let host = url.host else {
            CrashlyticsManager.shared.log("URL has no host", category: "Security")
            return false
        }
        
        let isAllowed = allowedDomains.contains { domain in
            host == domain || host.hasSuffix(".\(domain)")
        }
        
        if !isAllowed {
            CrashlyticsManager.shared.log("URL host not in whitelist: \(host)", category: "Security")
        }
        
        return isAllowed
    }
    
    // MARK: - Hash Functions
    
    /// Creates SHA256 hash of input string
    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    // MARK: - Security Headers
    
    /// Returns security headers for API requests
    static var securityHeaders: [String: String] {
        return [
            "X-Requested-With": "XMLHttpRequest",
            "X-App-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "X-Platform": "iOS",
            "X-Device-ID": deviceIdentifier
        ]
    }
    
    /// Generates a device identifier (non-personal)
    private static var deviceIdentifier: String {
        if let existing = UserDefaults.standard.string(forKey: "device_identifier") {
            return existing
        }
        
        let identifier = UUID().uuidString
        UserDefaults.standard.set(identifier, forKey: "device_identifier")
        return identifier
    }
}

// MARK: - Security Alert
extension SecurityConfig {
    /// Shows security alert to user
    static func showSecurityAlert(in viewController: UIViewController, title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(alert, animated: true)
        }
    }
    
    /// Handles jailbreak detection
    static func handleJailbreakDetection() {
        if isJailbroken {
            CrashlyticsManager.shared.log("App running on jailbroken device", category: "Security")
            // In production, you might want to:
            // - Disable certain features
            // - Show a warning to the user
            // - Refuse to run the app
        }
    }
}