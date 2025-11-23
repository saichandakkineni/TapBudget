import Foundation

enum AppConstants {
    // Budget thresholds
    static let budgetAlertThreshold: Double = 0.9 // 90% of budget
    static let budgetAlertPercentage: Int = 90
    
    // UI Constants
    static let categoryGridColumns = 3
    static let categoryGridSpacing: CGFloat = 15
    static let cardCornerRadius: CGFloat = 15
    static let cardShadowRadius: CGFloat = 2
    static let categoryButtonVerticalPadding: CGFloat = 10
    static let categoryIconFrameWidth: CGFloat = 30
    
    // Chart Constants
    static let chartHeight: CGFloat = 200
    static let pieChartInnerRadius: Double = 0.618
    static let pieChartAngularInset: Double = 1.5
    static let monthlySpendingMonthsToShow = 6
    
    // Number Formatting
    static let currencyDecimalPlaces = 2
    static let defaultCurrencySymbol = "$"
    
    // Default Category Values
    static let defaultCategoryColor = "#FF0000"
    static let defaultCategoryIcon = "tag"
    
    // Default Categories
    struct DefaultCategory {
        let name: String
        let icon: String
        let budget: Double
        let color: String
    }
    
    static let defaultCategories: [DefaultCategory] = [
        DefaultCategory(name: "Food", icon: "fork.knife", budget: 500, color: "#FF6B6B"),
        DefaultCategory(name: "Bills", icon: "doc.text", budget: 1000, color: "#4ECDC4"),
        DefaultCategory(name: "Shopping", icon: "cart", budget: 300, color: "#45B7D1"),
        DefaultCategory(name: "Transport", icon: "car", budget: 200, color: "#96CEB4"),
        DefaultCategory(name: "Entertainment", icon: "film", budget: 150, color: "#FFEEAD")
    ]
    
    // Category Icons
    static let availableIcons = [
        "tag", "cart", "fork.knife", "car", "house", "film",
        "gamecontroller", "gift", "medical", "airplane"
    ]
    
    // Category Colors
    static let availableColors = [
        "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEEAD",
        "#D4A5A5", "#9B6B6B", "#A2D5F2", "#07689F", "#40514E"
    ]
    
    // Validation
    static let minExpenseAmount: Double = 0.01
    static let maxExpenseAmount: Double = 1_000_000
    static let minCategoryNameLength = 1
    static let maxCategoryNameLength = 30
}

