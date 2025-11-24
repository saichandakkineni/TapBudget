import Foundation
import SwiftUI

/// Helper for advanced analytics calculations
struct AnalyticsHelper {
    /// Calculates spending trend (increasing, decreasing, stable)
    static func calculateTrend(_ amounts: [Double]) -> SpendingTrend {
        guard amounts.count >= 2 else { return .stable }
        
        let recent = Array(amounts.suffix(3))
        let previous = Array(amounts.prefix(max(1, amounts.count - 3)))
        
        let recentAvg = recent.reduce(0, +) / Double(recent.count)
        let previousAvg = previous.reduce(0, +) / Double(previous.count)
        
        let change = recentAvg - previousAvg
        let percentChange = previousAvg > 0 ? (change / previousAvg) * 100 : 0
        
        if abs(percentChange) < 5 {
            return .stable
        } else if percentChange > 0 {
            return .increasing(percentChange)
        } else {
            return .decreasing(abs(percentChange))
        }
    }
    
    /// Calculates average spending per period
    static func averageSpending(_ amounts: [Double]) -> Double {
        guard !amounts.isEmpty else { return 0 }
        return amounts.reduce(0, +) / Double(amounts.count)
    }
    
    /// Finds the highest spending period
    static func highestSpending(_ periods: [(date: Date, amount: Double)]) -> (date: Date, amount: Double)? {
        return periods.max(by: { $0.amount < $1.amount })
    }
    
    /// Finds the lowest spending period
    static func lowestSpending(_ periods: [(date: Date, amount: Double)]) -> (date: Date, amount: Double)? {
        return periods.min(by: { $0.amount < $1.amount })
    }
    
    /// Calculates category comparison statistics
    static func categoryComparison(_ categorySpending: [(category: String, amount: Double)]) -> CategoryComparison {
        guard !categorySpending.isEmpty else {
            return CategoryComparison(
                topCategory: nil,
                bottomCategory: nil,
                averageSpending: 0,
                totalSpending: 0
            )
        }
        
        let sorted = categorySpending.sorted { $0.amount > $1.amount }
        let total = categorySpending.reduce(0) { $0 + $1.amount }
        let average = total / Double(categorySpending.count)
        
        return CategoryComparison(
            topCategory: sorted.first.map { ($0.category, $0.amount) },
            bottomCategory: sorted.last.map { ($0.category, $0.amount) },
            averageSpending: average,
            totalSpending: total
        )
    }
    
    /// Calculates month-over-month comparison
    static func monthOverMonthComparison(current: Double, previous: Double) -> MonthComparison {
        let change = current - previous
        let percentChange = previous > 0 ? (change / previous) * 100 : 0
        
        return MonthComparison(
            currentAmount: current,
            previousAmount: previous,
            change: change,
            percentChange: percentChange
        )
    }
}

enum SpendingTrend {
    case increasing(Double) // percentage increase
    case decreasing(Double) // percentage decrease
    case stable
    
    var description: String {
        switch self {
        case .increasing(let percent):
            return "↑ Up \(String(format: "%.1f", percent))%"
        case .decreasing(let percent):
            return "↓ Down \(String(format: "%.1f", percent))%"
        case .stable:
            return "→ Stable"
        }
    }
    
    var color: Color {
        switch self {
        case .increasing:
            return .red
        case .decreasing:
            return .green
        case .stable:
            return .secondary
        }
    }
}

struct CategoryComparison {
    let topCategory: (name: String, amount: Double)?
    let bottomCategory: (name: String, amount: Double)?
    let averageSpending: Double
    let totalSpending: Double
}

struct MonthComparison {
    let currentAmount: Double
    let previousAmount: Double
    let change: Double
    let percentChange: Double
    
    var isIncrease: Bool {
        change > 0
    }
}

