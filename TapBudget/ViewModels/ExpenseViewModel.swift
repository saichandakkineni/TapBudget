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
            checkBudgetLimit(for: category)
        } catch {
            throw ExpenseError.saveFailed(error.localizedDescription)
        }
    }
    
    /// Checks if the category has reached budget threshold and sends notification if needed
    /// This method calculates the total spent for the current month and sends a notification
    /// if the spending reaches 90% of the budget limit
    /// - Parameter category: The category to check budget limits for
    private func checkBudgetLimit(for category: Category) {
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            print("Error: Could not calculate current month range")
            return
        }
        
        // Extract tuple values to use in predicate (SwiftData predicates can't access tuple members directly)
        let startOfMonth = monthRange.start
        let endOfMonth = monthRange.end
        
        // Create a simple predicate for the date range
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startOfMonth &&
                expense.date < endOfMonth
            }
        )
        
        do {
            // Fetch all expenses in the date range and filter by category in memory
            let expenses = try modelContext.fetch(descriptor)
            let categoryExpenses = expenses.filter { $0.category?.id == category.id }
            let totalSpent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            // Check if budget threshold is reached
            if category.budget > 0 && totalSpent >= category.budget * AppConstants.budgetAlertThreshold {
                let percentage = totalSpent / category.budget
                NotificationManager.shared.sendBudgetAlert(
                    categoryName: category.name,
                    budgetPercentage: percentage
                )
            }
        } catch {
            print("Error fetching expenses for budget check: \(error.localizedDescription)")
        }
    }
}

// MARK: - Expense Errors
enum ExpenseError: LocalizedError {
    case invalidAmount
    case invalidCategory
    case validationFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Please enter a valid amount greater than zero"
        case .invalidCategory:
            return "Please select a valid category"
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Failed to save expense: \(message)"
        }
    }
} 