import SwiftUI
import SwiftData

/// ViewModel responsible for managing expense-related business logic
/// Handles expense creation, validation, and budget limit checking
@Observable class ExpenseViewModel {
    /// The SwiftData model context for database operations
    let modelContext: ModelContext
    
    /// Initializes the ExpenseViewModel with a model context
    /// - Parameter modelContext: The SwiftData model context to use for database operations
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Adds an expense and checks budget limits
    /// - Parameters:
    ///   - amount: The expense amount
    ///   - category: The expense category
    ///   - notes: Optional notes for the expense
    ///   - date: Optional date for the expense (defaults to current date)
    /// - Throws: ExpenseError if validation or save fails
    func addExpense(amount: Double, category: Category, notes: String? = nil, date: Date = Date()) throws {
        // Comprehensive validation
        let validation = DataValidator.validateExpense(amount: amount, category: category, notes: notes)
        if case .invalid(let message) = validation {
            throw ExpenseError.validationFailed(message)
        }
        
        // Validate date
        let dateValidation = DataValidator.validateExpenseDate(date)
        if case .invalid(let message) = dateValidation {
            throw ExpenseError.validationFailed(message)
        }
        
        let expense = Expense(amount: amount, date: date, notes: notes, category: category)
        modelContext.insert(expense)
        
        do {
            try modelContext.save()
            // Budget alerts are now handled by BudgetAlertManager when expenses are added
            // This ensures alerts respect the user's toggle setting
        } catch {
            throw ExpenseError.saveFailed(error.localizedDescription)
        }
    }
}

// MARK: - Expense Errors
enum ExpenseError: LocalizedError {
    case invalidAmount
    case invalidCategory
    case invalidDate
    case validationFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount greater than zero"
        case .invalidCategory:
            return "Please select a valid category"
        case .invalidDate:
            return "Please select a valid date"
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Failed to save expense: \(message)"
        }
    }
} 