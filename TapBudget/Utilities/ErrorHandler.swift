import Foundation
import SwiftUI

/// Centralized error handling with user-friendly messages
class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    /// Converts technical errors to user-friendly messages
    func userFriendlyMessage(for error: Error) -> String {
        if let expenseError = error as? ExpenseError {
            return expenseError.userFriendlyMessage
        }
        
        if let categoryError = error as? CategoryError {
            return categoryError.userFriendlyMessage
        }
        
        let nsError = error as NSError
        
        // Handle common SwiftData errors
        if nsError.domain == "NSCocoaErrorDomain" {
            switch nsError.code {
            case 134030: // NSValidationErrorMinimum
                return "The entered value is too small. Please check your input."
            case 134040: // NSValidationErrorMaximum
                return "The entered value is too large. Please check your input."
            case 134020: // NSValidationErrorMultipleErrors
                return "Please check all fields and try again."
            default:
                break
            }
        }
        
        // Handle network errors if applicable
        if nsError.domain == NSURLErrorDomain {
            return "Unable to connect. Please check your internet connection."
        }
        
        // Generic fallback
        return "An unexpected error occurred. Please try again."
    }
    
    /// Shows an error alert
    func showError(_ error: Error, in view: some View) -> some View {
        // This would typically be used with a state variable
        // For now, return the view as-is
        return view
    }
}

/// Extension for ExpenseError to provide user-friendly messages
extension ExpenseError {
    var userFriendlyMessage: String {
        switch self {
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Unable to save expense. \(message)"
        case .invalidAmount:
            return "Please enter a valid amount greater than zero."
        case .invalidCategory:
            return "Please select a valid category."
        case .invalidDate:
            return "Please select a valid date."
        }
    }
}

/// Extension for CategoryError to provide user-friendly messages
extension CategoryError {
    var userFriendlyMessage: String {
        switch self {
        case .invalidInput:
            return "Please check all fields and try again."
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Unable to save category. \(message)"
        }
    }
}

