import Foundation
import WidgetKit

/// Manages data sharing between the main app and widget extension
/// Uses UserDefaults with App Group for data sharing
class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    // App Group identifier - needs to be configured in Xcode
    // Format: group.com.yourcompany.TapBudget
    private let appGroupIdentifier = "group.com.tapbudget.app"
    private let monthlyTotalKey = "widget_monthly_total"
    private let expenseCountKey = "widget_expense_count"
    private let lastUpdateKey = "widget_last_update"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    private init() {}
    
    /// Updates widget data with current monthly summary
    /// - Parameters:
    ///   - monthlyTotal: Total expenses for the current month
    ///   - expenseCount: Number of expenses in the current month
    func updateMonthlySummary(monthlyTotal: Double, expenseCount: Int) {
        guard let defaults = sharedDefaults else {
            print("Warning: App Group not configured. Widget data won't be shared.")
            return
        }
        
        defaults.set(monthlyTotal, forKey: monthlyTotalKey)
        defaults.set(expenseCount, forKey: expenseCountKey)
        defaults.set(Date(), forKey: lastUpdateKey)
        
        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "TapBudgetWidget")
    }
    
    /// Retrieves monthly summary data for widget
    func getMonthlySummary() -> (total: Double, count: Int)? {
        guard let defaults = sharedDefaults else { return nil }
        
        let total = defaults.double(forKey: monthlyTotalKey)
        let count = defaults.integer(forKey: expenseCountKey)
        
        return (total, count)
    }
    
    /// Reloads all widget timelines
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

