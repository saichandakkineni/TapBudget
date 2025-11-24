import SwiftUI

/// Helper utilities for accessibility features
struct AccessibilityHelper {
    /// Creates an accessibility label for an expense
    static func expenseLabel(amount: Double, category: String, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return "Expense of \(amount.formattedAsCurrency()) in \(category) category on \(dateFormatter.string(from: date))"
    }
    
    /// Creates an accessibility label for a category
    static func categoryLabel(name: String, budget: Double, spent: Double) -> String {
        if budget > 0 {
            let percentage = Int((spent / budget) * 100)
            return "\(name) category, budget \(budget.formattedAsCurrency()), spent \(spent.formattedAsCurrency()), \(percentage) percent"
        } else {
            return "\(name) category, spent \(spent.formattedAsCurrency())"
        }
    }
    
    /// Creates an accessibility hint for buttons
    static func buttonHint(action: String) -> String {
        return "Double tap to \(action)"
    }
    
    /// Creates an accessibility value for progress indicators
    static func progressValue(current: Double, total: Double) -> String {
        let percentage = Int((current / total) * 100)
        return "\(percentage) percent"
    }
}

/// Accessibility modifiers extension
extension View {
    /// Adds comprehensive accessibility support
    func accessibleExpense(amount: Double, category: String, date: Date, notes: String? = nil) -> some View {
        self
            .accessibilityLabel(AccessibilityHelper.expenseLabel(amount: amount, category: category, date: date))
            .accessibilityValue(notes ?? "")
            .accessibilityHint("Expense entry")
    }
    
    /// Adds accessibility support for category buttons
    func accessibleCategory(name: String, budget: Double, spent: Double, isSelected: Bool) -> some View {
        self
            .accessibilityLabel(AccessibilityHelper.categoryLabel(name: name, budget: budget, spent: spent))
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityHint(AccessibilityHelper.buttonHint(action: "select \(name) category"))
            .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    /// Adds accessibility support for action buttons
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? AccessibilityHelper.buttonHint(action: label.lowercased()))
            .accessibilityAddTraits(.isButton)
    }
}

