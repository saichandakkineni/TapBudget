import Foundation

/// Safely checks if CloudKit is available without causing crashes
/// This avoids importing CloudKit at the top level to prevent initialization issues
struct CloudKitAvailability {
    /// Checks if CloudKit is configured and available
    /// Returns false if CloudKit capability isn't enabled in Xcode
    static var isAvailable: Bool {
        // Check if CloudKit container identifier exists in Info.plist
        // This is a safe check that won't crash if CloudKit isn't configured
        return Bundle.main.object(forInfoDictionaryKey: "CKContainerIdentifier") != nil
    }
}

