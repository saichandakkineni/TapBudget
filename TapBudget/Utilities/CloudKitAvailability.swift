import Foundation
import CloudKit

/// Safely checks if CloudKit is available without causing crashes
struct CloudKitAvailability {
    /// Checks if CloudKit is configured and available
    /// Returns false if CloudKit capability isn't enabled in Xcode
    /// This is a safe check that won't crash if CloudKit isn't configured
    static var isAvailable: Bool {
        // The most reliable way to check if CloudKit is configured is to try
        // to access the default container and check its identifier.
        // If CloudKit isn't configured in entitlements, the container identifier
        // will be empty or won't match our expected format.
        
        // Try to get the default container
        let container = CKContainer.default()
        
        // Check if container has a valid identifier (this means CloudKit is configured)
        // If CloudKit isn't configured, the container identifier will be empty or invalid
        let containerIdentifier = container.containerIdentifier
        
        // Debug: Print container identifier to help diagnose issues
        print("🔍 CloudKitAvailability check - Container ID: \(containerIdentifier ?? "nil")")
        
        // If container identifier exists and is not empty, CloudKit is configured
        // The identifier should match what's in entitlements: iCloud.com.cmobautomation.TapBudget
        if let identifier = containerIdentifier, !identifier.isEmpty {
            // If identifier exists and is not empty, CloudKit is configured
            // We don't need to check the exact format - if it exists, CloudKit is available
            print("✅ CloudKit is available - Container ID: \(identifier)")
            return true
        } else {
            print("❌ CloudKit container identifier is nil or empty - CloudKit not configured")
        }
        
        // Fallback: If identifier check fails, return false
        return false
    }
}

