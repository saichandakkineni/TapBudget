import Foundation
import UserNotifications

/// Manages local notifications for budget alerts and other app notifications
/// Uses UNUserNotificationCenter to send notifications when budget thresholds are reached
class NotificationManager {
    /// Shared singleton instance
    static let shared = NotificationManager()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
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
    func sendBudgetAlert(categoryName: String, budgetPercentage: Double) {
        Task {
            // Check if authorized, if not request permission
            var isAuthorized = await checkAuthorizationStatus()
            if !isAuthorized {
                isAuthorized = await requestAuthorization()
            }
            
            guard isAuthorized else {
                print("Notification permission not granted")
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = "Budget Alert"
            content.body = "You've reached \(Int(budgetPercentage * 100))% of your budget for \(categoryName)"
            content.sound = .default
            content.badge = 1
            
            // Create a trigger for immediate delivery
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
            
            // Create the request
            let request = UNNotificationRequest(
                identifier: "budget_alert_\(categoryName)_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            // Schedule the notification
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Error scheduling notification: \(error.localizedDescription)")
            }
        }
    }
}

