import Foundation
import SwiftData

/// Simple caching utility for performance optimization
class PerformanceCache {
    static let shared = PerformanceCache()
    
    private var monthlyTotalCache: [String: (total: Double, count: Int, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 60 // 1 minute
    
    private init() {}
    
    /// Gets cached monthly total or calculates and caches it
    func getMonthlyTotal(for monthKey: String, calculator: () -> (total: Double, count: Int)) -> (total: Double, count: Int) {
        if let cached = monthlyTotalCache[monthKey],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return (cached.total, cached.count)
        }
        
        let result = calculator()
        monthlyTotalCache[monthKey] = (result.total, result.count, Date())
        return result
    }
    
    /// Clears the cache
    func clearCache() {
        monthlyTotalCache.removeAll()
    }
    
    /// Clears cache for a specific month
    func clearCache(for monthKey: String) {
        monthlyTotalCache.removeValue(forKey: monthKey)
    }
    
    /// Generates a cache key for a month
    static func monthKey(for date: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return "\(components.year ?? 0)-\(components.month ?? 0)"
    }
}

