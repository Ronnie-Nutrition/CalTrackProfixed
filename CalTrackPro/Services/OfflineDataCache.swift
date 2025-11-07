import Foundation
import SwiftData

/// Manages offline data caching for food items and search results
class OfflineDataCache {
    static let shared = OfflineDataCache()
    
    private let cacheDirectory: URL
    private let searchCacheFile = "search_cache.json"
    private let recentFoodsFile = "recent_foods.json"
    private let cacheDuration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    
    private init() {
        // Create cache directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        cacheDirectory = documentsPath.appendingPathComponent("CalTrackProCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Search Cache
    
    struct CachedSearch: Codable {
        let query: String
        let results: [FoodItem]
        let timestamp: Date
    }
    
    /// Cache search results
    func cacheSearchResults(query: String, results: [FoodItem]) {
        var cache = loadSearchCache()
        
        // Remove old entries
        cache.removeAll { entry in
            Date().timeIntervalSince(entry.timestamp) > cacheDuration
        }
        
        // Add new entry
        let newEntry = CachedSearch(query: query.lowercased(), results: results, timestamp: Date())
        cache.append(newEntry)
        
        // Keep only last 50 searches
        if cache.count > 50 {
            cache = Array(cache.suffix(50))
        }
        
        // Save to disk
        saveSearchCache(cache)
        
        CrashlyticsManager.shared.log("Cached search results for: \(query)", category: "OfflineCache")
    }
    
    /// Get cached search results
    func getCachedSearchResults(for query: String) -> [FoodItem]? {
        let cache = loadSearchCache()
        let lowercasedQuery = query.lowercased()
        
        // Find exact match first
        if let exactMatch = cache.first(where: { $0.query == lowercasedQuery }) {
            if Date().timeIntervalSince(exactMatch.timestamp) < cacheDuration {
                CrashlyticsManager.shared.log("Cache hit for query: \(query)", category: "OfflineCache")
                return exactMatch.results
            }
        }
        
        // Find partial matches
        let partialMatches = cache.filter { entry in
            entry.query.contains(lowercasedQuery) || lowercasedQuery.contains(entry.query)
        }.flatMap { $0.results }
        
        if !partialMatches.isEmpty {
            CrashlyticsManager.shared.log("Partial cache hit for query: \(query)", category: "OfflineCache")
            return Array(Set(partialMatches)) // Remove duplicates
        }
        
        return nil
    }
    
    private func loadSearchCache() -> [CachedSearch] {
        let url = cacheDirectory.appendingPathComponent(searchCacheFile)
        
        guard let data = try? Data(contentsOf: url),
              let cache = try? JSONDecoder().decode([CachedSearch].self, from: data) else {
            return []
        }
        
        return cache
    }
    
    private func saveSearchCache(_ cache: [CachedSearch]) {
        let url = cacheDirectory.appendingPathComponent(searchCacheFile)
        
        if let data = try? JSONEncoder().encode(cache) {
            try? data.write(to: url)
        }
    }
    
    // MARK: - Recent Foods Cache
    
    struct RecentFood: Codable {
        let foodItem: FoodItem
        let lastUsed: Date
        let useCount: Int
    }
    
    /// Add food to recent foods
    func addToRecentFoods(_ foodItem: FoodItem) {
        var recentFoods = loadRecentFoods()
        
        if let index = recentFoods.firstIndex(where: { $0.foodItem.foodId == foodItem.foodId }) {
            // Update existing entry
            var updated = recentFoods[index]
            updated = RecentFood(
                foodItem: foodItem,
                lastUsed: Date(),
                useCount: updated.useCount + 1
            )
            recentFoods[index] = updated
        } else {
            // Add new entry
            recentFoods.append(RecentFood(
                foodItem: foodItem,
                lastUsed: Date(),
                useCount: 1
            ))
        }
        
        // Sort by last used and keep top 100
        recentFoods.sort { $0.lastUsed > $1.lastUsed }
        if recentFoods.count > 100 {
            recentFoods = Array(recentFoods.prefix(100))
        }
        
        saveRecentFoods(recentFoods)
    }
    
    /// Get recent foods for offline access
    func getRecentFoods(matching query: String? = nil) -> [FoodItem] {
        let recentFoods = loadRecentFoods()
        
        if let query = query, !query.isEmpty {
            let lowercased = query.lowercased()
            return recentFoods
                .filter { $0.foodItem.label.lowercased().contains(lowercased) }
                .map { $0.foodItem }
        }
        
        return recentFoods.map { $0.foodItem }
    }
    
    /// Get frequently used foods
    func getFrequentFoods(limit: Int = 10) -> [FoodItem] {
        let recentFoods = loadRecentFoods()
        return recentFoods
            .sorted { $0.useCount > $1.useCount }
            .prefix(limit)
            .map { $0.foodItem }
    }
    
    private func loadRecentFoods() -> [RecentFood] {
        let url = cacheDirectory.appendingPathComponent(recentFoodsFile)
        
        guard let data = try? Data(contentsOf: url),
              let foods = try? JSONDecoder().decode([RecentFood].self, from: data) else {
            return []
        }
        
        return foods
    }
    
    private func saveRecentFoods(_ foods: [RecentFood]) {
        let url = cacheDirectory.appendingPathComponent(recentFoodsFile)
        
        if let data = try? JSONEncoder().encode(foods) {
            try? data.write(to: url)
        }
    }
    
    // MARK: - Cache Management
    
    /// Clear all cached data
    func clearCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        CrashlyticsManager.shared.log("Cache cleared", category: "OfflineCache")
    }
    
    /// Get cache size in bytes
    func getCacheSize() -> Int64 {
        let contents = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        
        return contents.reduce(0) { total, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + Int64(size ?? 0)
        }
    }
    
    /// Format cache size for display
    func getFormattedCacheSize() -> String {
        let size = getCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - FoodItem Codable Extension
extension FoodItem: Codable {
    enum CodingKeys: String, CodingKey {
        case foodId, label, categoryLabel, nutrients, image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodId = try container.decode(String.self, forKey: .foodId)
        label = try container.decode(String.self, forKey: .label)
        categoryLabel = try container.decodeIfPresent(String.self, forKey: .categoryLabel)
        nutrients = try container.decode(FoodNutrients.self, forKey: .nutrients)
        image = try container.decodeIfPresent(String.self, forKey: .image)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(foodId, forKey: .foodId)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(categoryLabel, forKey: .categoryLabel)
        try container.encode(nutrients, forKey: .nutrients)
        try container.encodeIfPresent(image, forKey: .image)
    }
}

// MARK: - FoodNutrients Codable Extension  
extension FoodNutrients: Codable {
    enum CodingKeys: String, CodingKey {
        case calories, protein, carbs, fat, fiber, sugar, sodium
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        calories = try container.decode(Double.self, forKey: .calories)
        protein = try container.decode(Double.self, forKey: .protein)
        carbs = try container.decode(Double.self, forKey: .carbs)
        fat = try container.decode(Double.self, forKey: .fat)
        fiber = try container.decodeIfPresent(Double.self, forKey: .fiber)
        sugar = try container.decodeIfPresent(Double.self, forKey: .sugar)
        sodium = try container.decodeIfPresent(Double.self, forKey: .sodium)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(calories, forKey: .calories)
        try container.encode(protein, forKey: .protein)
        try container.encode(carbs, forKey: .carbs)
        try container.encode(fat, forKey: .fat)
        try container.encodeIfPresent(fiber, forKey: .fiber)
        try container.encodeIfPresent(sugar, forKey: .sugar)
        try container.encodeIfPresent(sodium, forKey: .sodium)
    }
}