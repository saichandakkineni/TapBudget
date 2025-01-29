import SwiftUI
import SwiftData

@Observable class ExpenseViewModel {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func addExpense(amount: Double, category: Category, notes: String? = nil) {
        let expense = Expense(amount: amount, notes: notes, category: category)
        modelContext.insert(expense)
        checkBudgetLimit(for: category)
    }
    
    func checkBudgetLimit(for category: Category) {
        let now = Date()
        let calendar = Calendar.current
        
        // Get start of current month
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let startOfMonth = calendar.date(from: components),
              let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { 
            return 
        }
        
        // Create a simple predicate for the date range
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startOfMonth &&
                expense.date < startOfNextMonth
            }
        )
        
        do {
            // Fetch all expenses in the date range and filter by category in memory
            let expenses = try modelContext.fetch(descriptor)
            let categoryExpenses = expenses.filter { $0.category?.id == category.id }
            let totalSpent = categoryExpenses.reduce(0) { $0 + $1.amount }
            
            if totalSpent >= category.budget * 0.9 {
                print("Budget alert: You've reached 90% of your budget for \(category.name)")
            }
        } catch {
            print("Error fetching expenses: \(error.localizedDescription)")
        }
    }
} 