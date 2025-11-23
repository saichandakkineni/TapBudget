import Foundation

/// Extension providing currency formatting utilities for Double values
extension Double {
    /// Formats the double value as currency with default $ symbol
    /// - Returns: A formatted string with currency symbol and proper decimal formatting
    /// - Example: 100.5.formattedAsCurrency() returns "$100.50"
    func formattedAsCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "$\(formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self))"
    }
    
    /// Formats the double value as currency with a custom symbol
    /// - Parameter symbol: The currency symbol to use (e.g., "€", "£", "¥")
    /// - Returns: A formatted string with custom currency symbol and proper decimal formatting
    /// - Example: 100.5.formattedAsCurrency(symbol: "€") returns "€100.50"
    func formattedAsCurrency(symbol: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return "\(symbol)\(formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self))"
    }
}

