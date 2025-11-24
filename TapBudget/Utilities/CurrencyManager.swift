import Foundation

/// Manages currency settings and conversions
class CurrencyManager {
    static let shared = CurrencyManager()
    
    private let currencyKey = "selected_currency"
    private let exchangeRateKey = "exchange_rates"
    
    private init() {}
    
    /// Supported currencies
    static let supportedCurrencies: [(code: String, symbol: String, name: String)] = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("JPY", "¥", "Japanese Yen"),
        ("CAD", "C$", "Canadian Dollar"),
        ("AUD", "A$", "Australian Dollar"),
        ("INR", "₹", "Indian Rupee"),
        ("CNY", "¥", "Chinese Yuan"),
        ("CHF", "CHF", "Swiss Franc"),
        ("MXN", "$", "Mexican Peso")
    ]
    
    /// Gets the currently selected currency
    var selectedCurrency: (code: String, symbol: String, name: String) {
        if let code = UserDefaults.standard.string(forKey: currencyKey),
           let currency = Self.supportedCurrencies.first(where: { $0.code == code }) {
            return currency
        }
        return Self.supportedCurrencies[0] // Default to USD
    }
    
    /// Sets the selected currency
    func setCurrency(_ code: String) {
        UserDefaults.standard.set(code, forKey: currencyKey)
        UserDefaults.standard.synchronize()
    }
    
    /// Formats amount with selected currency
    func formatAmount(_ amount: Double) -> String {
        let currency = selectedCurrency
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = AppConstants.currencyDecimalPlaces
        formatter.maximumFractionDigits = AppConstants.currencyDecimalPlaces
        
        let formatted = formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.\(AppConstants.currencyDecimalPlaces)f", amount)
        return "\(currency.symbol)\(formatted)"
    }
    
    /// Converts amount from one currency to another (simplified - would need real API in production)
    func convertAmount(_ amount: Double, from: String, to: String) -> Double {
        // In a real app, this would fetch exchange rates from an API
        // For now, return the same amount (1:1 conversion)
        // This is a placeholder for future implementation
        return amount
    }
    
    /// Gets exchange rate (placeholder - would fetch from API)
    func getExchangeRate(from: String, to: String) -> Double {
        // Placeholder - would fetch from exchange rate API
        return 1.0
    }
}

