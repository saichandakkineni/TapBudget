import Foundation
import CloudKit
import SwiftData

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

