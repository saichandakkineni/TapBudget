import Foundation
import SwiftUI

/// Global manager for CloudKit sync notifications and alerts
/// Allows any view to show sync completion messages
@Observable
class CloudKitSyncNotificationManager {
    static let shared = CloudKitSyncNotificationManager()
    
    var showingSyncAlert = false
    var syncAlertMessage = ""
    var syncAlertIsError = false
    
    private init() {}
    
    /// Show sync completion message globally
    func showSyncMessage(_ message: String, isError: Bool = false) {
        syncAlertMessage = message
        syncAlertIsError = isError
        showingSyncAlert = true
    }
}

