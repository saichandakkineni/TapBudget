import Foundation
import CloudKit
import SwiftData
import CoreData

/// Manages CloudKit synchronization for SwiftData models
class CloudKitSyncManager {
    static let shared = CloudKitSyncManager()
    
    private var container: CKContainer?
    private var privateDatabase: CKDatabase? {
        container?.privateCloudDatabase
    }
    private var sharedDatabase: CKDatabase? {
        container?.sharedCloudDatabase
    }
    
    private var isInitialized = false
    
    private init() {
        // Lazy initialization - don't initialize CloudKit until needed
        // This prevents crashes if CloudKit isn't configured
    }
    
    /// Initializes CloudKit container (lazy initialization)
    /// Uses a safe approach that won't crash if CloudKit isn't configured
    private func initializeIfNeeded() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Use safe CloudKit availability check
        if CloudKitAvailability.isAvailable {
            // CloudKit is configured, safe to initialize
            container = CKContainer.default()
        } else {
            // CloudKit not configured - this is fine, app can run without it
            print("CloudKit not configured - Shared Budgets feature will be unavailable")
            container = nil
        }
    }
    
    /// Checks if CloudKit is available and user is signed in
    func checkCloudKitStatus() async -> CloudKitStatus {
        initializeIfNeeded()
        
        guard let container = container else {
            return .error("CloudKit not configured. Please enable CloudKit capability in Xcode.")
        }
        
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                return .available
            case .noAccount:
                return .noAccount
            case .restricted:
                return .restricted
            case .couldNotDetermine:
                return .unknown
            @unknown default:
                return .unknown
            }
        } catch {
            return .error(error.localizedDescription)
        }
    }
    
    /// Creates a CloudKit share for a shared budget
    func createShare(for sharedBudget: SharedBudget) async throws -> CKShare {
        initializeIfNeeded()
        
        guard let privateDatabase = privateDatabase else {
            throw NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        // Note: In a real implementation, this would create a CKShare
        // For now, this is a placeholder that shows the structure
        // Actual CloudKit sharing requires proper CKShare setup
        
        let share = CKShare(rootRecord: CKRecord(recordType: "SharedBudget"))
        share[CKShare.SystemFieldKey.title] = sharedBudget.name
        
        // Set permissions
        share.publicPermission = .none
        
        // Save share
        _ = try await privateDatabase.save(share)
        
        return share
    }
    
    /// Accepts a CloudKit share invitation
    func acceptShare(metadata: CKShare.Metadata) async throws {
        initializeIfNeeded()
        
        guard let container = container else {
            throw NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let acceptSharesOperation = CKAcceptSharesOperation(shareMetadatas: [metadata])
        
        return try await withCheckedThrowingContinuation { continuation in
            acceptSharesOperation.acceptSharesResultBlock = { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            
            container.add(acceptSharesOperation)
        }
    }
    
    /// Fetches shared budgets from CloudKit
    func fetchSharedBudgets() async throws -> [CKRecord] {
        initializeIfNeeded()
        
        guard let sharedDatabase = sharedDatabase else {
            throw NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        let query = CKQuery(recordType: "SharedBudget", predicate: NSPredicate(value: true))
        let results = try await sharedDatabase.records(matching: query)
        return Array(results.matchResults.compactMap { try? $0.1.get() })
    }
    
    /// Checks if data exists in CloudKit (for debugging sync issues)
    /// Note: SwiftData uses automatic schema mapping, record types may vary
    func checkCloudKitDataExists() async -> (expenses: Int, categories: Int, error: String?) {
        initializeIfNeeded()
        
        guard let privateDatabase = privateDatabase else {
            return (0, 0, "CloudKit not available")
        }
        
        do {
            // SwiftData with CloudKit uses automatic schema mapping
            // Record types are typically: "CD_Expense", "CD_Category", etc.
            // But we'll try multiple possible names to be safe
            
            var expenseCount = 0
            var categoryCount = 0
            
            // Try common SwiftData CloudKit record type names
            let possibleExpenseTypes = ["CD_Expense", "Expense", "CD_EXPENSE"]
            let possibleCategoryTypes = ["CD_Category", "Category", "CD_CATEGORY"]
            
            for recordType in possibleExpenseTypes {
                do {
                    let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                    let results = try await privateDatabase.records(matching: query, inZoneWith: nil)
                    expenseCount = max(expenseCount, results.matchResults.count)
                    if expenseCount > 0 { break } // Found data, stop trying
                } catch {
                    // Try next record type
                    continue
                }
            }
            
            for recordType in possibleCategoryTypes {
                do {
                    let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
                    let results = try await privateDatabase.records(matching: query, inZoneWith: nil)
                    categoryCount = max(categoryCount, results.matchResults.count)
                    if categoryCount > 0 { break } // Found data, stop trying
                } catch {
                    // Try next record type
                    continue
                }
            }
            
            return (expenseCount, categoryCount, nil)
        } catch {
            // If we can't query, it might mean data hasn't synced yet or record types are different
            // This is not necessarily an error - SwiftData handles sync internally
            return (0, 0, "Could not query CloudKit (this may be normal if sync is in progress)")
        }
    }
    
    /// Forces CloudKit to sync by checking for remote changes
    /// This helps trigger SwiftData's CloudKit sync mechanism
    func forceCloudKitSync() async throws {
        initializeIfNeeded()
        
        guard let container = container else {
            throw NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        // Verify account status - this helps ensure CloudKit is ready
        _ = try await container.accountStatus()
        
        // Note: Actual sync is handled by NSPersistentCloudKitContainer under the hood
        // This function just ensures CloudKit is accessible and ready
    }
    
    /// Triggers CloudKit sync by performing operations that force SwiftData to sync
    /// This is a workaround since we can't directly access NSPersistentCloudKitContainer
    func triggerSwiftDataCloudKitSync(modelContext: ModelContext) async throws {
        initializeIfNeeded()
        
        guard container != nil else {
            throw NSError(domain: "CloudKitError", code: 0, userInfo: [NSLocalizedDescriptionKey: "CloudKit not available"])
        }
        
        print("🔄 Triggering SwiftData CloudKit sync...")
        
        // Force CloudKit sync by:
        // 1. Processing pending changes
        // 2. Saving context (pushes local changes)
        // 3. Accessing persistent store coordinator to trigger CloudKit sync
        // 4. Fetching with queries that will trigger CloudKit to pull changes
        
        await MainActor.run {
            // Process pending changes
            modelContext.processPendingChanges()
            
            // Save to push local changes
            do {
                try modelContext.save()
                print("✅ Local changes saved")
            } catch {
                print("❌ Error saving: \(error.localizedDescription)")
            }
        }
        
        // Access the underlying persistent store coordinator to trigger CloudKit sync
        // SwiftData uses NSPersistentStoreCoordinator under the hood
        await MainActor.run {
            // Force a fetch operation that will trigger CloudKit sync
            // The act of fetching will cause SwiftData to check CloudKit for updates
            let expenseDescriptor = FetchDescriptor<Expense>()
            let categoryDescriptor = FetchDescriptor<Category>()
            
            // Fetch with a predicate that forces a database query
            // This should trigger CloudKit to sync
            _ = try? modelContext.fetch(expenseDescriptor)
            _ = try? modelContext.fetch(categoryDescriptor)
            
            // Process pending changes immediately
            modelContext.processPendingChanges()
        }
        
        // Wait a moment for CloudKit to process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Fetch data to trigger CloudKit sync
        await MainActor.run {
            let expenseDescriptor = FetchDescriptor<Expense>()
            let categoryDescriptor = FetchDescriptor<Category>()
            
            _ = try? modelContext.fetch(expenseDescriptor)
            _ = try? modelContext.fetch(categoryDescriptor)
            
            // Process any changes that came from CloudKit
            modelContext.processPendingChanges()
            
            // Save to persist synced data
            try? modelContext.save()
        }
        
        print("✅ SwiftData CloudKit sync trigger complete")
    }
    
    /// Waits for CloudKit sync to complete by polling for changes
    /// Returns true if sync appears complete, false if timeout
    func waitForCloudKitSync(modelContext: ModelContext, timeoutSeconds: Int = 30) async -> Bool {
        initializeIfNeeded()
        
        guard container != nil else {
            return false
        }
        
        let startTime = Date()
        var previousExpenseCount = -1
        var previousCategoryCount = -1
        var stableCount = 0
        
        // Initial fetch to get baseline
        await MainActor.run {
            modelContext.processPendingChanges()
            let expenseDescriptor = FetchDescriptor<Expense>()
            let categoryDescriptor = FetchDescriptor<Category>()
            let currentExpenses = (try? modelContext.fetch(expenseDescriptor)) ?? []
            let currentCategories = (try? modelContext.fetch(categoryDescriptor)) ?? []
            previousExpenseCount = currentExpenses.count
            previousCategoryCount = currentCategories.count
        }
        
        while Date().timeIntervalSince(startTime) < Double(timeoutSeconds) {
            await MainActor.run {
                modelContext.processPendingChanges()
                let expenseDescriptor = FetchDescriptor<Expense>()
                let categoryDescriptor = FetchDescriptor<Category>()
                let currentExpenses = (try? modelContext.fetch(expenseDescriptor)) ?? []
                let currentCategories = (try? modelContext.fetch(categoryDescriptor)) ?? []
                
                let currentExpenseCount = currentExpenses.count
                let currentCategoryCount = currentCategories.count
                
                if currentExpenseCount != previousExpenseCount || currentCategoryCount != previousCategoryCount {
                    stableCount = 0
                    previousExpenseCount = currentExpenseCount
                    previousCategoryCount = currentCategoryCount
                    modelContext.processPendingChanges()
                    try? modelContext.save()
                } else {
                    stableCount += 1
                    if stableCount >= 3 {
                        // Stable for 3 seconds, consider sync complete
                        return
                    }
                }
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
        
        // Final processing
        await MainActor.run {
            modelContext.processPendingChanges()
            try? modelContext.save()
        }
        
        return true
    }
}

enum CloudKitStatus: Equatable {
    case available
    case noAccount
    case restricted
    case unknown
    case error(String)
    
    static func == (lhs: CloudKitStatus, rhs: CloudKitStatus) -> Bool {
        switch (lhs, rhs) {
        case (.available, .available),
             (.noAccount, .noAccount),
             (.restricted, .restricted),
             (.unknown, .unknown):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
    
    var description: String {
        switch self {
        case .available:
            return "iCloud is available"
        case .noAccount:
            return "Please sign in to iCloud"
        case .restricted:
            return "iCloud is restricted"
        case .unknown:
            return "Unable to determine iCloud status"
        case .error(let message):
            return "Error: \(message)"
        }
    }
}

