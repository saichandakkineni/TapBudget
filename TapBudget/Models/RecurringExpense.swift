import Foundation
import SwiftData

/// Model representing a recurring expense that auto-creates monthly expenses
@Model final class RecurringExpense {
    var id: String = UUID().uuidString
    var amount: Double = 0
    var name: String = ""
    var notes: String?
    @Relationship(inverse: \Category.recurringExpenses)
    var category: Category?
    var startDate: Date = Date()
    var endDate: Date? // nil means recurring indefinitely
    var isActive: Bool = true
    var lastProcessedDate: Date?
    
    init(
        amount: Double,
        name: String,
        notes: String? = nil,
        category: Category? = nil,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.amount = amount
        self.name = name
        self.notes = notes
        self.category = category
        self.startDate = startDate
        self.endDate = endDate
        self.isActive = isActive
        self.lastProcessedDate = nil
    }
    
    /// Checks if this recurring expense should create an expense for the current month
    var shouldCreateExpenseThisMonth: Bool {
        guard isActive else { return false }
        
        let now = Date()
        
        // Check if we're past the start date
        guard now >= startDate else { return false }
        
        // Check if we're before the end date (if set)
        if let endDate = endDate, now > endDate {
            return false
        }
        
        // Check if we've already processed this month
        if let lastProcessed = lastProcessedDate {
            let calendar = Calendar.current
            if calendar.isDate(lastProcessed, equalTo: now, toGranularity: .month) {
                return false
            }
        }
        
        return true
    }
}

