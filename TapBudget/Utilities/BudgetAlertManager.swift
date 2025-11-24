import Foundation
import SwiftData
import UserNotifications

/// Manages budget alerts and notifications
/// Checks spending against budget thresholds and sends alerts
@MainActor
class BudgetAlertManager {
    static let shared = BudgetAlertManager()
    
    private let alertThresholdsKey = "budget_alert_thresholds"
    private let alertsEnabledKey = "budget_alerts_enabled"
    private let lastAlertCheckKey = "last_budget_alert_check"
    private let sentAlertsKey = "sent_budget_alerts"
    
    private init() {}
    
    /// Alert threshold configuration
    struct AlertThreshold: Codable {
        let percentage: Double // e.g., 0.8 for 80%
        let enabled: Bool
    }
    
    /// Budget status for a category
    struct BudgetStatus {
        let category: Category
        let spent: Double
        let budget: Double
        let percentage: Double
        let remaining: Double
        let status: Status
        
        enum Status {
            case safe // < 80%
            case warning // 80-90%
            case critical // 90-100%
            case exceeded // > 100%
        }
        
        var statusColor: Color {
            switch status {
            case .safe: return .green
            case .warning: return .orange
            case .critical: return .red
            case .exceeded: return .red
            }
        }
    }
    
    // MARK: - Configuration
    
    /// Default alert thresholds (disabled by default)
    var defaultThresholds: [AlertThreshold] {
        [
            AlertThreshold(percentage: 0.8, enabled: false),  // 80% warning
            AlertThreshold(percentage: 0.9, enabled: false),  // 90% critical
            AlertThreshold(percentage: 1.0, enabled: false)   // 100% exceeded
        ]
    }
    
    /// Get configured alert thresholds
    var alertThresholds: [AlertThreshold] {
        get {
            guard let data = UserDefaults.standard.data(forKey: alertThresholdsKey),
                  let thresholds = try? JSONDecoder().decode([AlertThreshold].self, from: data) else {
                return defaultThresholds
            }
            return thresholds
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: alertThresholdsKey)
            }
        }
    }
    
    /// Add a custom threshold
    func addThreshold(percentage: Double) {
        var thresholds = alertThresholds
        // Check if threshold already exists
        if !thresholds.contains(where: { abs($0.percentage - percentage) < 0.01 }) {
            thresholds.append(AlertThreshold(percentage: percentage, enabled: true))
            // Sort by percentage
            thresholds.sort { $0.percentage < $1.percentage }
            alertThresholds = thresholds
        }
    }
    
    /// Remove a threshold
    func removeThreshold(at index: Int) {
        var thresholds = alertThresholds
        guard index >= 0 && index < thresholds.count else { return }
        thresholds.remove(at: index)
        alertThresholds = thresholds
    }
    
    /// Update a threshold
    func updateThreshold(at index: Int, percentage: Double, enabled: Bool) {
        var thresholds = alertThresholds
        guard index >= 0 && index < thresholds.count else { return }
        thresholds[index] = AlertThreshold(percentage: percentage, enabled: enabled)
        // Re-sort
        thresholds.sort { $0.percentage < $1.percentage }
        alertThresholds = thresholds
    }
    
    /// Check if alerts are enabled (default: false)
    var alertsEnabled: Bool {
        get {
            // Check if key exists - if not, default to false
            if UserDefaults.standard.object(forKey: alertsEnabledKey) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: alertsEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: alertsEnabledKey)
        }
    }
    
    // MARK: - Budget Status Calculation
    
    /// Calculate budget status for a category
    func calculateBudgetStatus(for category: Category, expenses: [Expense], monthRange: (start: Date, end: Date)?) -> BudgetStatus {
        guard let monthRange = monthRange else {
            return BudgetStatus(
                category: category,
                spent: 0,
                budget: category.budget,
                percentage: 0,
                remaining: category.budget,
                status: .safe
            )
        }
        
        // Filter expenses for this category in the current month
        let categoryExpenses = expenses.filter { expense in
            expense.category?.id == category.id &&
            expense.date >= monthRange.start &&
            expense.date < monthRange.end
        }
        
        let spent = categoryExpenses.reduce(0) { $0 + $1.amount }
        let budget = category.budget
        let percentage = budget > 0 ? spent / budget : 0
        let remaining = max(0, budget - spent)
        
        let status: BudgetStatus.Status
        if percentage >= 1.0 {
            status = .exceeded
        } else if percentage >= 0.9 {
            status = .critical
        } else if percentage >= 0.8 {
            status = .warning
        } else {
            status = .safe
        }
        
        return BudgetStatus(
            category: category,
            spent: spent,
            budget: budget,
            percentage: percentage,
            remaining: remaining,
            status: status
        )
    }
    
    // MARK: - Alert Checking
    
    /// Check a specific category and send alert if threshold is reached
    func checkBudgetAndSendAlert(for category: Category, modelContext: ModelContext, expenses: [Expense]) async {
        print("🔔 Budget Alert Check for \(category.name)")
        print("   Alerts Enabled: \(alertsEnabled)")
        
        guard alertsEnabled else {
            print("   ❌ Alerts are disabled - skipping check")
            return
        }
        
        guard category.budget > 0 else {
            print("   ⏭️ Skipping \(category.name) - no budget set")
            return
        }
        
        // Request notification permission if needed
        let isAuthorized = await NotificationManager.shared.checkAuthorizationStatus()
        if !isAuthorized {
            let granted = await NotificationManager.shared.requestAuthorization()
            if !granted {
                print("   ❌ Permission denied - cannot send notifications")
                return
            }
        }
        
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            print("   ❌ Could not get month range")
            return
        }
        
        let thresholds = alertThresholds.filter { $0.enabled }
        if thresholds.isEmpty {
            print("   ⚠️ No thresholds enabled - no alerts will be sent")
            return
        }
        
        let status = calculateBudgetStatus(for: category, expenses: expenses, monthRange: monthRange)
        print("   📊 \(category.name): \(Int(status.percentage * 100))% spent (\(status.spent.formattedAsCurrency()) / \(status.budget.formattedAsCurrency()))")
        
        // Find the highest threshold that has been reached and hasn't been alerted today
        let sortedThresholds = thresholds.sorted { $0.percentage > $1.percentage }
        var highestThresholdToAlert: AlertThreshold? = nil
        
        for threshold in sortedThresholds {
            if status.percentage >= threshold.percentage {
                let alertKey = "\(category.id)_\(Int(threshold.percentage * 100))"
                
                if !hasSentAlert(for: alertKey) {
                    highestThresholdToAlert = threshold
                    print("      Found highest threshold to alert: \(Int(threshold.percentage * 100))%")
                    break
                } else {
                    print("      Threshold \(Int(threshold.percentage * 100))% already alerted today")
                }
            }
        }
        
        // Send alert only for the highest threshold reached
        if let threshold = highestThresholdToAlert {
            let alertKey = "\(category.id)_\(Int(threshold.percentage * 100))"
            print("   ✅ Sending alert for \(category.name) at \(Int(threshold.percentage * 100))% threshold")
            
            await sendAlert(
                category: category,
                percentage: status.percentage,
                threshold: threshold.percentage,
                spent: status.spent,
                budget: status.budget
            )
            
            markAlertSent(for: alertKey)
        } else {
            print("   ⏭️ No new threshold alerts needed for \(category.name)")
        }
    }
    
    /// Check all categories and send alerts if thresholds are reached
    func checkBudgetsAndSendAlerts(modelContext: ModelContext, expenses: [Expense]) async {
        print("🔔 Budget Alert Check Started")
        print("   Alerts Enabled: \(alertsEnabled)")
        
        guard alertsEnabled else {
            print("   ❌ Alerts are disabled - skipping check")
            return
        }
        
        // Request notification permission if needed
        let isAuthorized = await NotificationManager.shared.checkAuthorizationStatus()
        print("   Notification Permission: \(isAuthorized ? "✅ Granted" : "❌ Not Granted")")
        
        if !isAuthorized {
            print("   Requesting notification permission...")
            let granted = await NotificationManager.shared.requestAuthorization()
            if !granted {
                print("   ❌ Permission denied - cannot send notifications")
                return
            }
        }
        
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            print("   ❌ Could not get month range")
            return
        }
        
        // Get all categories
        let categoryFetch = FetchDescriptor<Category>()
        guard let categories = try? modelContext.fetch(categoryFetch) else {
            print("   ❌ Could not fetch categories")
            return
        }
        
        let thresholds = alertThresholds.filter { $0.enabled }
        print("   Enabled Thresholds: \(thresholds.map { "\(Int($0.percentage * 100))%" })")
        
        if thresholds.isEmpty {
            print("   ⚠️ No thresholds enabled - no alerts will be sent")
            return
        }
        
        let today = Calendar.current.startOfDay(for: Date())
        var alertsSent = 0
        
        // Check each category
        for category in categories {
            guard category.budget > 0 else {
                print("   ⏭️ Skipping \(category.name) - no budget set")
                continue
            }
            
            let status = calculateBudgetStatus(for: category, expenses: expenses, monthRange: monthRange)
            print("   📊 \(category.name): \(Int(status.percentage * 100))% spent (\(status.spent.formattedAsCurrency()) / \(status.budget.formattedAsCurrency()))")
            
            // Find the highest threshold that has been reached and hasn't been alerted today
            // Sort thresholds in descending order to check highest first
            let sortedThresholds = thresholds.sorted { $0.percentage > $1.percentage }
            var highestThresholdToAlert: AlertThreshold? = nil
            
            for threshold in sortedThresholds {
                if status.percentage >= threshold.percentage {
                    // Check if we've already sent an alert for this threshold today
                    let alertKey = "\(category.id)_\(Int(threshold.percentage * 100))"
                    
                    if !hasSentAlert(for: alertKey) {
                        // This is the highest threshold reached that hasn't been alerted
                        highestThresholdToAlert = threshold
                        print("      Found highest threshold to alert: \(Int(threshold.percentage * 100))%")
                        break
                    } else {
                        print("      Threshold \(Int(threshold.percentage * 100))% already alerted today")
                    }
                }
            }
            
            // Send alert only for the highest threshold reached
            if let threshold = highestThresholdToAlert {
                let alertKey = "\(category.id)_\(Int(threshold.percentage * 100))"
                print("   ✅ Sending alert for \(category.name) at \(Int(threshold.percentage * 100))% threshold")
                print("      Alert Key: \(alertKey)")
                
                // Send alert
                await sendAlert(
                    category: category,
                    percentage: status.percentage,
                    threshold: threshold.percentage,
                    spent: status.spent,
                    budget: status.budget
                )
                
                // Mark as sent
                markAlertSent(for: alertKey)
                alertsSent += 1
            } else {
                print("   ⏭️ No new threshold alerts needed for \(category.name)")
            }
        }
        
        print("   ✅ Budget Alert Check Complete - \(alertsSent) alert(s) sent")
        
        // Update last check time
        UserDefaults.standard.set(Date(), forKey: lastAlertCheckKey)
    }
    
    /// Send a budget alert notification
    private func sendAlert(category: Category, percentage: Double, threshold: Double, spent: Double, budget: Double) async {
        let thresholdPercent = Int(threshold * 100)
        let currentPercent = Int(percentage * 100)
        
        let title: String
        let body: String
        
        if percentage >= 1.0 {
            title = "Budget Exceeded! ⚠️"
            body = "You've exceeded your \(category.name) budget by \(currentPercent - 100)%. Spent: \(spent.formattedAsCurrency()) of \(budget.formattedAsCurrency())"
        } else if threshold >= 0.9 {
            title = "Budget Critical Alert 🚨"
            body = "You've reached \(currentPercent)% of your \(category.name) budget. Only \((budget - spent).formattedAsCurrency()) remaining!"
        } else {
            title = "Budget Warning ⚡"
            body = "You've reached \(currentPercent)% of your \(category.name) budget. \((budget - spent).formattedAsCurrency()) remaining."
        }
        
        print("   📤 Preparing to send notification:")
        print("      Title: \(title)")
        print("      Body: \(body)")
        
        await NotificationManager.shared.sendBudgetAlert(
            categoryName: category.name,
            budgetPercentage: percentage,
            title: title,
            body: body
        )
    }
    
    // MARK: - Alert Tracking
    
    /// Check if alert has been sent for a key today
    private func hasSentAlert(for key: String) -> Bool {
        guard let data = UserDefaults.standard.data(forKey: sentAlertsKey),
              let sentAlerts = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return false
        }
        
        guard let sentDate = sentAlerts[key] else {
            return false
        }
        
        // Check if alert was sent today
        let today = Calendar.current.startOfDay(for: Date())
        let alertDate = Calendar.current.startOfDay(for: sentDate)
        
        return alertDate == today
    }
    
    /// Mark alert as sent
    private func markAlertSent(for key: String) {
        var sentAlerts: [String: Date] = [:]
        
        if let data = UserDefaults.standard.data(forKey: sentAlertsKey),
           let existing = try? JSONDecoder().decode([String: Date].self, from: data) {
            sentAlerts = existing
        }
        
        sentAlerts[key] = Date()
        
        // Clean up old alerts (older than 7 days)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        sentAlerts = sentAlerts.filter { $0.value >= sevenDaysAgo }
        
        if let data = try? JSONEncoder().encode(sentAlerts) {
            UserDefaults.standard.set(data, forKey: sentAlertsKey)
        }
    }
    
    /// Clear all sent alerts (useful for testing or reset)
    func clearSentAlerts() {
        UserDefaults.standard.removeObject(forKey: sentAlertsKey)
    }
    
    /// Get alert history (recent alerts sent)
    func getAlertHistory() -> [AlertHistoryItem] {
        guard let data = UserDefaults.standard.data(forKey: sentAlertsKey),
              let sentAlerts = try? JSONDecoder().decode([String: Date].self, from: data) else {
            return []
        }
        
        // Convert to array of AlertHistoryItem
        return sentAlerts.map { key, date in
            // Parse key format: "categoryId_percentage" (timestamp removed for daily deduplication)
            let components = key.components(separatedBy: "_")
            let categoryId = components.first ?? "unknown"
            // Get percentage (second component)
            let percentage = components.count >= 2 ? Double(components[1]) ?? 0 : 0
            
            return AlertHistoryItem(
                categoryId: categoryId,
                threshold: percentage / 100.0,
                sentDate: date
            )
        }.sorted { $0.sentDate > $1.sentDate } // Most recent first
    }
    
    /// Alert history item
    struct AlertHistoryItem: Identifiable {
        let id = UUID()
        let categoryId: String
        let threshold: Double
        let sentDate: Date
    }
}

// MARK: - Color Extension
import SwiftUI
extension Color {
    static let budgetSafe = Color.green
    static let budgetWarning = Color.orange
    static let budgetCritical = Color.red
}

