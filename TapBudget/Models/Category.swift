import Foundation
import SwiftData

@Model final class Category {
    var id: String = UUID().uuidString
    var name: String = ""
    var icon: String = "tag"
    var budget: Double = 0
    var color: String = "#FF0000"
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense]?
    
    var recurringExpenses: [RecurringExpense]?
    
    var expenseTemplates: [ExpenseTemplate]?
    
    var budgetPeriods: [BudgetPeriod]?
    
    var sharedBudgets: [SharedBudget]?
    
    init(name: String, icon: String, budget: Double = 0, color: String = "#FF0000") {
        self.id = UUID().uuidString
        self.name = name
        self.icon = icon
        self.budget = budget
        self.color = color
        self.expenses = []
        self.recurringExpenses = []
        self.expenseTemplates = []
        self.budgetPeriods = []
        self.sharedBudgets = []
    }
} 