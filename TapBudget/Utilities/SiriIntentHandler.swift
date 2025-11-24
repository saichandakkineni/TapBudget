import Foundation
import SwiftData

/// Handles Siri Intent data when app opens from a Siri shortcut
class SiriIntentHandler {
    static let shared = SiriIntentHandler()
    
    private let pendingExpenseKey = "pendingSiriExpense"
    
    private init() {}
    
    /// Checks for pending Siri expense and processes it
    /// - Parameters:
    ///   - modelContext: The SwiftData model context
    ///   - categories: Available categories to match against
    /// - Returns: Result indicating success or failure with message
    func processPendingExpense(
        modelContext: ModelContext,
        categories: [Category]
    ) -> (success: Bool, message: String) {
        guard let intentData = UserDefaults.standard.dictionary(forKey: pendingExpenseKey) else {
            return (false, "")
        }
        
        // Clear the pending intent
        UserDefaults.standard.removeObject(forKey: pendingExpenseKey)
        UserDefaults.standard.synchronize()
        
        guard let amount = intentData["amount"] as? Double,
              amount > 0 else {
            return (false, "Invalid amount")
        }
        
        let categoryName = intentData["categoryName"] as? String ?? ""
        let notes = intentData["notes"] as? String
        
        // Find matching category
        let category: Category?
        if !categoryName.isEmpty {
            category = categories.first { $0.name.lowercased() == categoryName.lowercased() }
        } else {
            // If no category specified, use first category or return error
            category = categories.first
        }
        
        guard let selectedCategory = category else {
            return (false, "Category '\(categoryName)' not found")
        }
        
        // Create expense
        do {
            let viewModel = ExpenseViewModel(modelContext: modelContext)
            try viewModel.addExpense(amount: amount, category: selectedCategory, notes: notes)
            return (true, "Added \(amount.formattedAsCurrency()) to \(selectedCategory.name)")
        } catch {
            return (false, "Failed to add expense: \(error.localizedDescription)")
        }
    }
}

