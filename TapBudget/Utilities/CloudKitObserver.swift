import Foundation
import CloudKit
import SwiftData

/// Observes CloudKit changes and syncs with local SwiftData
@Observable
class CloudKitObserver {
    static let shared = CloudKitObserver()
    
    private var container: CKContainer?
    private var subscriptionID: CKSubscription.ID?
    private var isInitialized = false
    
    private init() {
        // Lazy initialization - don't initialize CloudKit until needed
    }
    
    /// Initializes CloudKit container (lazy initialization)
    /// Uses a safe approach that won't crash if CloudKit isn't configured
    private func initializeIfNeeded() {
        guard !isInitialized else { return }
        isInitialized = true
        
        // Use safe CloudKit availability check
        if CloudKitAvailability.isAvailable {
            container = CKContainer.default()
        } else {
            // CloudKit not configured - this is fine
            print("CloudKit not configured")
            container = nil
        }
    }
    
    /// Sets up CloudKit subscription for real-time updates
    func setupSubscription() async throws {
        initializeIfNeeded()
        
        guard let container = container else {
            // CloudKit not available, skip subscription setup
            return
        }
        
        let database = container.privateCloudDatabase
        
        let subscription = CKQuerySubscription(
            recordType: "Expense",
            predicate: NSPredicate(value: true),
            subscriptionID: "expense-updates",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        // Save subscription - this can throw, so we handle errors
        do {
            _ = try await database.save(subscription)
            subscriptionID = subscription.subscriptionID
        } catch let error as CKError {
            // Subscription might already exist, that's okay
            if error.code != .serverRecordChanged {
                throw error
            }
        } catch {
            // Re-throw other errors
            throw error
        }
    }
    
    /// Handles remote CloudKit notifications
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard let notification = notification else {
            return false
        }
        
        switch notification.notificationType {
        case .query:
            // Handle query notification
            Task {
                await syncChanges()
            }
            return true
        default:
            return false
        }
    }
    
    /// Syncs changes from CloudKit
    private func syncChanges() async {
        // In a real implementation, this would:
        // 1. Fetch changes from CloudKit
        // 2. Merge with local SwiftData
        // 3. Handle conflicts
        // 4. Update UI
        
        print("Syncing changes from CloudKit...")
    }
}

