import Foundation
import SwiftData

/// Model for customizable budget periods
@Model final class BudgetPeriod {
    var id: String = UUID().uuidString
    @Relationship(inverse: \Category.budgetPeriods)
    var category: Category?
    var periodTypeRawValue: String = PeriodType.monthly.rawValue
    var startDate: Date = Date()
    var endDate: Date?
    var budgetAmount: Double = 0
    var isActive: Bool = true
    
    var periodType: PeriodType {
        get { PeriodType(rawValue: periodTypeRawValue) ?? .monthly }
        set { periodTypeRawValue = newValue.rawValue }
    }
    
    init(
        category: Category? = nil,
        periodType: PeriodType = .monthly,
        startDate: Date = Date(),
        endDate: Date? = nil,
        budgetAmount: Double,
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.category = category
        self.periodTypeRawValue = periodType.rawValue
        self.startDate = startDate
        self.endDate = endDate
        self.budgetAmount = budgetAmount
        self.isActive = isActive
    }
    
    /// Calculates the end date based on period type
    func calculateEndDate() -> Date {
        let calendar = Calendar.current
        
        switch periodType {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate
        case .biWeekly:
            return calendar.date(byAdding: .weekOfYear, value: 2, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        case .custom:
            return endDate ?? calendar.date(byAdding: .month, value: 1, to: startDate) ?? startDate
        }
    }
}

enum PeriodType: String, Codable, CaseIterable {
    case weekly = "Weekly"
    case biWeekly = "Bi-Weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    
    var description: String {
        return rawValue
    }
}

