import Foundation
import UserNotifications

/// Manages local notifications for budget alerts and other app notifications
/// Uses UNUserNotificationCenter to send notifications when budget thresholds are reached
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    /// Shared singleton instance
    static let shared = NotificationManager()
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        super.init()
        // Set this instance as the delegate
        UNUserNotificationCenter.current().delegate = self
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    /// Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification tap if needed
        completionHandler()
    }
    
    /// Request notification permissions
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification authorization: \(error.localizedDescription)")
            return false
        }
    }
    
    /// Check if notifications are authorized
    func checkAuthorizationStatus() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .authorized
    }
    
    /// Send a budget alert notification
    func sendBudgetAlert(categoryName: String, budgetPercentage: Double, title: String? = nil, body: String? = nil) async {
        // Check if authorized, if not request permission
        var isAuthorized = await checkAuthorizationStatus()
        print("   🔔 Notification authorization check: \(isAuthorized)")
        
        if !isAuthorized {
            print("   📝 Requesting notification permission...")
            isAuthorized = await requestAuthorization()
            print("   📝 Permission request result: \(isAuthorized)")
        }
        
        guard isAuthorized else {
            print("   ❌ Notification permission not granted - cannot send notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title ?? "Budget Alert"
        content.body = body ?? "You've reached \(Int(budgetPercentage * 100))% of your budget for \(categoryName)"
        content.sound = .default
        content.badge = 1
        
        // Add category info to userInfo for potential deep linking
        content.userInfo = [
            "type": "budget_alert",
            "category": categoryName,
            "percentage": budgetPercentage
        ]
        
        // Create a trigger for immediate delivery
        // iOS requires at least 1 second for time interval triggers, or use nil for immediate
        // Using 1 second to ensure it fires reliably
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        
        // Create the request with unique identifier
        let uniqueID = "budget_alert_\(categoryName)_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: uniqueID,
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("   ✅ Notification scheduled successfully: \(uniqueID)")
            print("      Title: \(content.title)")
            print("      Body: \(content.body)")
            print("      Will appear in 1 second")
        } catch {
            print("   ❌ Error scheduling notification: \(error.localizedDescription)")
            print("      Error details: \(error)")
        }
    }
    
    /// Send a daily/weekly spending summary notification
    func sendSpendingSummary(totalSpent: Double, expenseCount: Int, period: String = "today") {
        Task {
            guard await checkAuthorizationStatus() else { return }
            
            let content = UNMutableNotificationContent()
            content.title = "Daily Spending Summary"
            content.body = "You spent \(totalSpent.formattedAsCurrency()) across \(expenseCount) expense\(expenseCount == 1 ? "" : "s") \(period)"
            content.sound = .default
            content.badge = 1
            
            // Schedule for next day at 9 AM
            var dateComponents = DateComponents()
            dateComponents.hour = 9
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "spending_summary_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Error scheduling spending summary: \(error.localizedDescription)")
            }
        }
    }
}

