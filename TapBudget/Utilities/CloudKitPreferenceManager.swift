import Foundation

/// Manages CloudKit sync preference (opt-in/opt-out)
/// Stores user's choice to enable or disable iCloud sync
@Observable
class CloudKitPreferenceManager {
    static let shared = CloudKitPreferenceManager()
    
    private let cloudKitEnabledKey = "cloudkit_sync_enabled"
    
    private init() {
        // Default: CloudKit is disabled unless user explicitly enables it
        // Only set default if key doesn't exist (first launch)
        if UserDefaults.standard.object(forKey: cloudKitEnabledKey) == nil {
            UserDefaults.standard.set(false, forKey: cloudKitEnabledKey)
        }
    }
    
    /// Whether CloudKit sync is enabled (user preference)
    /// Default: false (disabled)
    var isCloudKitEnabled: Bool {
        get {
            // Default to false if not set
            UserDefaults.standard.object(forKey: cloudKitEnabledKey) as? Bool ?? false
        }
        set {
            UserDefaults.standard.set(newValue, forKey: cloudKitEnabledKey)
            UserDefaults.standard.synchronize()
            print("CloudKit sync preference updated: \(newValue ? "Enabled" : "Disabled")")
        }
    }
    
    /// Checks if CloudKit should be enabled for ModelContainer
    /// Returns true only if:
    /// 1. User has opted in (isCloudKitEnabled == true)
    /// 2. CloudKit is available (entitlements configured)
    var shouldEnableCloudKit: Bool {
        return isCloudKitEnabled && CloudKitAvailability.isAvailable
    }
}

