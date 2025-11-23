import Foundation

/// Comprehensive data validation utilities for the app
struct DataValidator {
    
    // MARK: - Expense Validation
    
    /// Validates an expense amount
    /// - Parameter amount: The amount to validate
    /// - Returns: Validation result with error message if invalid
    static func validateExpenseAmount(_ amount: Double) -> ValidationResult {
        if amount < AppConstants.minExpenseAmount {
            return .invalid("Amount must be at least \(AppConstants.minExpenseAmount.formattedAsCurrency())")
        }
        
        if amount > AppConstants.maxExpenseAmount {
            return .invalid("Amount cannot exceed \(AppConstants.maxExpenseAmount.formattedAsCurrency())")
        }
        
        if amount.isNaN || amount.isInfinite {
            return .invalid("Amount must be a valid number")
        }
        
        return .valid
    }
    
    /// Validates expense notes
    /// - Parameter notes: The notes to validate
    /// - Returns: Validation result with error message if invalid
    static func validateExpenseNotes(_ notes: String?) -> ValidationResult {
        guard let notes = notes else {
            return .valid // Notes are optional
        }
        
        let trimmed = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.count > 500 {
            return .invalid("Notes cannot exceed 500 characters")
        }
        
        return .valid
    }
    
    /// Validates a complete expense before saving
    /// - Parameters:
    ///   - amount: The expense amount
    ///   - category: The expense category
    ///   - notes: Optional notes
    /// - Returns: Validation result with error message if invalid
    static func validateExpense(amount: Double, category: Category?, notes: String? = nil) -> ValidationResult {
        // Validate amount
        let amountValidation = validateExpenseAmount(amount)
        if case .invalid(let message) = amountValidation {
            return .invalid(message)
        }
        
        // Validate category
        guard let category = category else {
            return .invalid("Please select a category")
        }
        
        if category.id.isEmpty {
            return .invalid("Invalid category selected")
        }
        
        // Validate notes
        let notesValidation = validateExpenseNotes(notes)
        if case .invalid(let message) = notesValidation {
            return .invalid(message)
        }
        
        return .valid
    }
    
    // MARK: - Category Validation
    
    /// Validates a category name
    /// - Parameter name: The category name to validate
    /// - Returns: Validation result with error message if invalid
    static func validateCategoryName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            return .invalid("Category name cannot be empty")
        }
        
        if trimmed.count < AppConstants.minCategoryNameLength {
            return .invalid("Category name must be at least \(AppConstants.minCategoryNameLength) character")
        }
        
        if trimmed.count > AppConstants.maxCategoryNameLength {
            return .invalid("Category name cannot exceed \(AppConstants.maxCategoryNameLength) characters")
        }
        
        // Check for invalid characters
        let invalidCharacters = CharacterSet(charactersIn: "<>\"'&")
        if trimmed.rangeOfCharacter(from: invalidCharacters) != nil {
            return .invalid("Category name contains invalid characters")
        }
        
        return .valid
    }
    
    /// Validates a category budget
    /// - Parameter budget: The budget amount to validate
    /// - Returns: Validation result with error message if invalid
    static func validateCategoryBudget(_ budget: Double) -> ValidationResult {
        if budget < 0 {
            return .invalid("Budget cannot be negative")
        }
        
        if budget > AppConstants.maxExpenseAmount {
            return .invalid("Budget cannot exceed \(AppConstants.maxExpenseAmount.formattedAsCurrency())")
        }
        
        if budget.isNaN || budget.isInfinite {
            return .invalid("Budget must be a valid number")
        }
        
        return .valid
    }
    
    /// Validates a category icon
    /// - Parameter icon: The icon name to validate
    /// - Returns: Validation result with error message if invalid
    static func validateCategoryIcon(_ icon: String) -> ValidationResult {
        if icon.isEmpty {
            return .invalid("Please select an icon")
        }
        
        if !AppConstants.availableIcons.contains(icon) {
            return .invalid("Invalid icon selected")
        }
        
        return .valid
    }
    
    /// Validates a category color
    /// - Parameter color: The color hex string to validate
    /// - Returns: Validation result with error message if invalid
    static func validateCategoryColor(_ color: String) -> ValidationResult {
        if color.isEmpty {
            return .invalid("Please select a color")
        }
        
        // Validate hex color format
        let hexPattern = "^#[0-9A-Fa-f]{6}$"
        let regex = try? NSRegularExpression(pattern: hexPattern)
        let range = NSRange(location: 0, length: color.utf16.count)
        
        if regex?.firstMatch(in: color, options: [], range: range) == nil {
            return .invalid("Invalid color format")
        }
        
        if !AppConstants.availableColors.contains(color) {
            return .invalid("Invalid color selected")
        }
        
        return .valid
    }
    
    /// Validates a complete category before saving
    /// - Parameters:
    ///   - name: The category name
    ///   - icon: The category icon
    ///   - budget: The category budget
    ///   - color: The category color
    /// - Returns: Validation result with error message if invalid
    static func validateCategory(name: String, icon: String, budget: Double, color: String) -> ValidationResult {
        // Validate name
        let nameValidation = validateCategoryName(name)
        if case .invalid(let message) = nameValidation {
            return .invalid(message)
        }
        
        // Validate icon
        let iconValidation = validateCategoryIcon(icon)
        if case .invalid(let message) = iconValidation {
            return .invalid(message)
        }
        
        // Validate budget
        let budgetValidation = validateCategoryBudget(budget)
        if case .invalid(let message) = budgetValidation {
            return .invalid(message)
        }
        
        // Validate color
        let colorValidation = validateCategoryColor(color)
        if case .invalid(let message) = colorValidation {
            return .invalid(message)
        }
        
        return .valid
    }
    
    // MARK: - Date Validation
    
    /// Validates that a date is not in the future
    /// - Parameter date: The date to validate
    /// - Returns: Validation result with error message if invalid
    static func validateExpenseDate(_ date: Date) -> ValidationResult {
        if date > Date() {
            return .invalid("Expense date cannot be in the future")
        }
        
        // Check if date is too far in the past (more than 10 years)
        let tenYearsAgo = Calendar.current.date(byAdding: .year, value: -10, to: Date()) ?? Date()
        if date < tenYearsAgo {
            return .invalid("Expense date is too far in the past")
        }
        
        return .valid
    }
}

// MARK: - Validation Result

/// Represents the result of a validation operation
enum ValidationResult {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        if case .valid = self {
            return true
        }
        return false
    }
    
    var errorMessage: String? {
        if case .invalid(let message) = self {
            return message
        }
        return nil
    }
}

