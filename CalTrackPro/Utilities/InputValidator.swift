import Foundation

/// Centralized input validation for security and data integrity
struct InputValidator {
    
    // MARK: - String Validation
    
    /// Validates and sanitizes a general text input
    static func validateText(_ input: String, maxLength: Int = 100, allowEmpty: Bool = false) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !allowEmpty && trimmed.isEmpty {
            return .failure("This field cannot be empty")
        }
        
        if trimmed.count > maxLength {
            return .failure("Maximum \(maxLength) characters allowed")
        }
        
        // Check for potentially malicious patterns
        if containsMaliciousPatterns(trimmed) {
            return .failure("Invalid characters detected")
        }
        
        return .success(sanitizeText(trimmed))
    }
    
    /// Validates food name input
    static func validateFoodName(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .failure("Food name is required")
        }
        
        if trimmed.count > 100 {
            return .failure("Food name is too long")
        }
        
        // Allow letters, numbers, spaces, and common food punctuation
        let pattern = "^[a-zA-Z0-9\\s\\-',&().]+$"
        if !trimmed.matches(pattern) {
            return .failure("Food name contains invalid characters")
        }
        
        return .success(sanitizeText(trimmed))
    }
    
    /// Validates brand name input
    static func validateBrandName(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Brand name is optional
        if trimmed.isEmpty {
            return .success("")
        }
        
        if trimmed.count > 50 {
            return .failure("Brand name is too long")
        }
        
        // Allow letters, numbers, spaces, and common brand punctuation
        let pattern = "^[a-zA-Z0-9\\s\\-'&.®™]+$"
        if !trimmed.matches(pattern) {
            return .failure("Brand name contains invalid characters")
        }
        
        return .success(sanitizeText(trimmed))
    }
    
    // MARK: - Numeric Validation
    
    /// Validates numeric input for nutrition values
    static func validateNutritionValue(_ input: String, fieldName: String, min: Double = 0, max: Double = 10000) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .failure("\(fieldName) is required")
        }
        
        // Allow numbers with optional decimal point
        let pattern = "^\\d+(\\.\\d{0,2})?$"
        if !trimmed.matches(pattern) {
            return .failure("\(fieldName) must be a valid number")
        }
        
        guard let value = Double(trimmed) else {
            return .failure("\(fieldName) must be a number")
        }
        
        if value < min {
            return .failure("\(fieldName) cannot be negative")
        }
        
        if value > max {
            return .failure("\(fieldName) value is too high")
        }
        
        return .success(trimmed)
    }
    
    /// Validates serving size input
    static func validateServingSize(_ input: String) -> ValidationResult {
        return validateNutritionValue(input, fieldName: "Serving size", min: 0.1, max: 5000)
    }
    
    /// Validates quantity input
    static func validateQuantity(_ input: String) -> ValidationResult {
        return validateNutritionValue(input, fieldName: "Quantity", min: 0.1, max: 100)
    }
    
    // MARK: - Search Query Validation
    
    /// Validates search query input
    static func validateSearchQuery(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .failure("Please enter a search term")
        }
        
        if trimmed.count < 2 {
            return .failure("Search term too short")
        }
        
        if trimmed.count > 100 {
            return .failure("Search term too long")
        }
        
        // Remove any potential SQL/Script injection attempts
        let sanitized = sanitizeSearchQuery(trimmed)
        
        return .success(sanitized)
    }
    
    // MARK: - Barcode Validation
    
    /// Validates barcode format
    static func validateBarcode(_ input: String) -> ValidationResult {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .failure("Invalid barcode")
        }
        
        // Common barcode formats: UPC (12 digits), EAN (13 digits)
        let pattern = "^\\d{8,20}$"
        if !trimmed.matches(pattern) {
            return .failure("Invalid barcode format")
        }
        
        return .success(trimmed)
    }
    
    // MARK: - Helper Methods
    
    /// Checks for potentially malicious patterns
    private static func containsMaliciousPatterns(_ input: String) -> Bool {
        let dangerousPatterns = [
            "<script", "</script>", "javascript:",
            "onclick", "onerror", "onload",
            "'; DROP TABLE", "-- ", "/*", "*/",
            "UNION SELECT", "INSERT INTO", "DELETE FROM",
            "../", "..\\", "%00", "\u{0000}"
        ]
        
        let lowercased = input.lowercased()
        return dangerousPatterns.contains { lowercased.contains($0.lowercased()) }
    }
    
    /// Sanitizes text by removing potentially dangerous characters
    private static func sanitizeText(_ input: String) -> String {
        // Remove null bytes and other control characters
        let sanitized = input.replacingOccurrences(of: "\u{0000}", with: "")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
        
        // Collapse multiple spaces
        let collapsed = sanitized.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return collapsed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Sanitizes search query
    private static func sanitizeSearchQuery(_ input: String) -> String {
        // Remove special characters that might be used in injection attacks
        let allowedCharacters = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-,'"))
        let sanitized = input.unicodeScalars.filter { allowedCharacters.contains($0) }.map { String($0) }.joined()
        
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Validation Result
enum ValidationResult {
    case success(String)
    case failure(String)
    
    var isValid: Bool {
        if case .success = self { return true }
        return false
    }
    
    var value: String? {
        if case .success(let value) = self { return value }
        return nil
    }
    
    var error: String? {
        if case .failure(let error) = self { return error }
        return nil
    }
}

// MARK: - String Extension
private extension String {
    func matches(_ pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }
}