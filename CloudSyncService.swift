//
//  CloudSyncService.swift
//  CalTrackPro
//
//  CloudKit integration for cross-device data sync and backup
//

import Foundation
import CloudKit
import SwiftData

// MARK: - Sync Status
enum SyncStatus {
    case idle
    case syncing
    case success
    case failed(String)
}

// MARK: - Cloud Sync Service
@MainActor
class CloudSyncService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable = false
    
    // MARK: - Private Properties
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    // Record types
    private let foodEntryRecordType = "FoodEntry"
    private let userProfileRecordType = "UserProfile"
    private let recipeRecordType = "Recipe"
    
    // MARK: - Initialization
    init() {
        // Use your app's container identifier
        container = CKContainer(identifier: "iCloud.com.yourcompany.CalTrackPro")
        privateDatabase = container.privateCloudDatabase
        
        Task {
            await checkiCloudStatus()
        }
    }
    
    // MARK: - iCloud Status
    func checkiCloudStatus() async {
        do {
            let status = try await container.accountStatus()
            iCloudAvailable = status == .available
        } catch {
            iCloudAvailable = false
        }
    }
    
    // MARK: - Save Food Entry
    func saveFoodEntry(_ entry: FoodEntryData) async throws {
        guard iCloudAvailable else { return }
        
        syncStatus = .syncing
        
        let record = CKRecord(recordType: foodEntryRecordType)
        record["id"] = entry.id.uuidString
        record["name"] = entry.name
        record["calories"] = entry.calories
        record["protein"] = entry.protein
        record["carbs"] = entry.carbs
        record["fat"] = entry.fat
        record["servingSize"] = entry.servingSize
        record["mealType"] = entry.mealType
        record["date"] = entry.date
        record["notes"] = entry.notes
        
        do {
            try await privateDatabase.save(record)
            syncStatus = .success
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Fetch Food Entries
    func fetchFoodEntries(for date: Date) async throws -> [FoodEntryData] {
        guard iCloudAvailable else { return [] }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        let query = CKQuery(recordType: foodEntryRecordType, predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        
        let (results, _) = try await privateDatabase.records(matching: query)
        
        return results.compactMap { _, result in
            guard case .success(let record) = result else { return nil }
            return FoodEntryData(from: record)
        }
    }
    
    // MARK: - Delete Food Entry
    func deleteFoodEntry(id: UUID) async throws {
        guard iCloudAvailable else { return }
        
        let predicate = NSPredicate(format: "id == %@", id.uuidString)
        let query = CKQuery(recordType: foodEntryRecordType, predicate: predicate)
        
        let (results, _) = try await privateDatabase.records(matching: query)
        
        for (recordID, _) in results {
            try await privateDatabase.deleteRecord(withID: recordID)
        }
    }
    
    // MARK: - Sync All Data
    func syncAll() async {
        guard iCloudAvailable else {
            syncStatus = .failed("iCloud not available")
            return
        }
        
        syncStatus = .syncing
        
        do {
            // Subscribe to changes for real-time sync
            try await setupSubscriptions()
            
            syncStatus = .success
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error.localizedDescription)
        }
    }
    
    // MARK: - Subscriptions for Real-time Sync
    private func setupSubscriptions() async throws {
        let subscriptionID = "food-entry-changes"
        
        // Check if subscription already exists
        do {
            _ = try await privateDatabase.subscription(for: subscriptionID)
            return // Already subscribed
        } catch {
            // Subscription doesn't exist, create it
        }
        
        let subscription = CKQuerySubscription(
            recordType: foodEntryRecordType,
            predicate: NSPredicate(value: true),
            subscriptionID: subscriptionID,
            options: [.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        try await privateDatabase.save(subscription)
    }
    
    // MARK: - Handle Remote Changes
    func handleRemoteNotification() async {
        syncStatus = .syncing
        
        // Fetch changes
        // In production, use CKFetchRecordZoneChangesOperation for efficient delta sync
        
        syncStatus = .success
        lastSyncDate = Date()
    }
}

// MARK: - Food Entry Data (for CloudKit transfer)
struct FoodEntryData: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fat: Double
    var servingSize: String
    var mealType: String // breakfast, lunch, dinner, snack
    var date: Date
    var notes: String?
    var imageData: Data?
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fat: Double,
        servingSize: String = "1 serving",
        mealType: String = "snack",
        date: Date = Date(),
        notes: String? = nil,
        imageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.servingSize = servingSize
        self.mealType = mealType
        self.date = date
        self.notes = notes
        self.imageData = imageData
    }
    
    init?(from record: CKRecord) {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let calories = record["calories"] as? Int,
              let date = record["date"] as? Date else {
            return nil
        }
        
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = record["protein"] as? Double ?? 0
        self.carbs = record["carbs"] as? Double ?? 0
        self.fat = record["fat"] as? Double ?? 0
        self.servingSize = record["servingSize"] as? String ?? "1 serving"
        self.mealType = record["mealType"] as? String ?? "snack"
        self.date = date
        self.notes = record["notes"] as? String
        self.imageData = nil
    }
}
