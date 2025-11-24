import Foundation
import SwiftData

/// Processes recurring expenses and creates monthly expense entries
class RecurringExpenseProcessor {
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Processes all active recurring expenses and creates expenses for the current month
    /// Should be called on app launch or monthly
    /// Optimized to only process if needed
    func processRecurringExpenses() throws {
        // Quick check: only fetch if we have active recurring expenses
        let descriptor = FetchDescriptor<RecurringExpense>(
            predicate: #Predicate<RecurringExpense> { recurring in
                recurring.isActive == true
            }
        )
        
        let recurringExpenses = try modelContext.fetch(descriptor)
        
        // Early return if no recurring expenses
        guard !recurringExpenses.isEmpty else { return }
        
        let currentDate = Date()
        var hasChanges = false
        
        for recurring in recurringExpenses {
            guard recurring.shouldCreateExpenseThisMonth else { continue }
            
            // Get the first day of current month for the expense date
            guard let monthStart = DateFilterHelper.startOfCurrentMonth() else { continue }
            
            // Create the expense
            let expense = Expense(
                amount: recurring.amount,
                date: monthStart,
                notes: recurring.notes ?? recurring.name,
                category: recurring.category
            )
            
            modelContext.insert(expense)
            recurring.lastProcessedDate = currentDate
            hasChanges = true
        }
        
        // Only save if we made changes
        if hasChanges {
            try modelContext.save()
        }
    }
    
    /// Checks if any recurring expenses need processing
    func hasPendingRecurringExpenses() -> Bool {
        do {
            let descriptor = FetchDescriptor<RecurringExpense>(
                predicate: #Predicate<RecurringExpense> { recurring in
                    recurring.isActive == true
                }
            )
            
            let recurringExpenses = try modelContext.fetch(descriptor)
            return recurringExpenses.contains { $0.shouldCreateExpenseThisMonth }
        } catch {
            return false
        }
    }
}

