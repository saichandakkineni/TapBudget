import Foundation
import SwiftData

/// Manages backup and restore functionality
class BackupManager {
    static let shared = BackupManager()
    
    private init() {}
    
    /// Creates a backup of all app data
    func createBackup(
        expenses: [Expense],
        categories: [Category],
        templates: [ExpenseTemplate],
        recurringExpenses: [RecurringExpense]
    ) -> Data? {
        let backup = BackupData(
            expenses: expenses.map { ExpenseData(from: $0) },
            categories: categories.map { CategoryData(from: $0) },
            templates: templates.map { TemplateData(from: $0) },
            recurringExpenses: recurringExpenses.map { RecurringExpenseData(from: $0) },
            version: "1.0",
            createdAt: Date()
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(backup)
        } catch {
            print("Error creating backup: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Restores data from backup
    func restoreBackup(
        data: Data,
        modelContext: ModelContext
    ) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let backup = try decoder.decode(BackupData.self, from: data)
        
        // Restore categories first (expenses depend on them)
        var categoryMap: [String: Category] = [:]
        
        for categoryData in backup.categories {
            let category = Category(
                name: categoryData.name,
                icon: categoryData.icon,
                budget: categoryData.budget,
                color: categoryData.color
            )
            category.id = categoryData.id
            categoryMap[categoryData.id] = category
            modelContext.insert(category)
        }
        
        // Restore expenses
        for expenseData in backup.expenses {
            let category: Category? = expenseData.categoryId.flatMap { categoryMap[$0] }
            let expense = Expense(
                amount: expenseData.amount,
                date: expenseData.date,
                notes: expenseData.notes,
                category: category
            )
            expense.id = expenseData.id
            modelContext.insert(expense)
        }
        
        // Restore templates
        for templateData in backup.templates {
            let category: Category? = templateData.categoryId.flatMap { categoryMap[$0] }
            let template = ExpenseTemplate(
                name: templateData.name,
                amount: templateData.amount,
                category: category,
                notes: templateData.notes,
                icon: templateData.icon,
                isActive: templateData.isActive
            )
            template.id = templateData.id
            modelContext.insert(template)
        }
        
        // Restore recurring expenses
        for recurringData in backup.recurringExpenses {
            let category: Category? = recurringData.categoryId.flatMap { categoryMap[$0] }
            let recurring = RecurringExpense(
                amount: recurringData.amount,
                name: recurringData.name,
                notes: recurringData.notes,
                category: category,
                startDate: recurringData.startDate,
                endDate: recurringData.endDate,
                isActive: recurringData.isActive
            )
            recurring.id = recurringData.id
            recurring.lastProcessedDate = recurringData.lastProcessedDate
            modelContext.insert(recurring)
        }
        
        try modelContext.save()
    }
}

// MARK: - Backup Data Structures

struct BackupData: Codable {
    let expenses: [ExpenseData]
    let categories: [CategoryData]
    let templates: [TemplateData]
    let recurringExpenses: [RecurringExpenseData]
    let version: String
    let createdAt: Date
}

struct ExpenseData: Codable {
    let id: String
    let amount: Double
    let date: Date
    let notes: String?
    let categoryId: String?
    
    init(from expense: Expense) {
        self.id = expense.id
        self.amount = expense.amount
        self.date = expense.date
        self.notes = expense.notes
        self.categoryId = expense.category?.id
    }
}

struct CategoryData: Codable {
    let id: String
    let name: String
    let icon: String
    let budget: Double
    let color: String
    
    init(from category: Category) {
        self.id = category.id
        self.name = category.name
        self.icon = category.icon
        self.budget = category.budget
        self.color = category.color
    }
}

struct TemplateData: Codable {
    let id: String
    let name: String
    let amount: Double
    let categoryId: String?
    let notes: String?
    let icon: String
    let isActive: Bool
    
    init(from template: ExpenseTemplate) {
        self.id = template.id
        self.name = template.name
        self.amount = template.amount
        self.categoryId = template.category?.id
        self.notes = template.notes
        self.icon = template.icon
        self.isActive = template.isActive
    }
}

struct RecurringExpenseData: Codable {
    let id: String
    let amount: Double
    let name: String
    let notes: String?
    let categoryId: String?
    let startDate: Date
    let endDate: Date?
    let isActive: Bool
    let lastProcessedDate: Date?
    
    init(from recurring: RecurringExpense) {
        self.id = recurring.id
        self.amount = recurring.amount
        self.name = recurring.name
        self.notes = recurring.notes
        self.categoryId = recurring.category?.id
        self.startDate = recurring.startDate
        self.endDate = recurring.endDate
        self.isActive = recurring.isActive
        self.lastProcessedDate = recurring.lastProcessedDate
    }
}

