import Foundation

struct DateFilterHelper {
    static let calendar = Calendar.current
    
    /// Returns the start date of the current month
    static func startOfCurrentMonth() -> Date? {
        let now = Date()
        var components = calendar.dateComponents([.year, .month], from: now)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }
    
    /// Returns the start date of the next month
    static func startOfNextMonth(from date: Date = Date()) -> Date? {
        guard let startOfMonth = startOfMonth(for: date) else { return nil }
        return calendar.date(byAdding: .month, value: 1, to: startOfMonth)
    }
    
    /// Returns the start date of a specific month for a given date
    static func startOfMonth(for date: Date) -> Date? {
        var components = calendar.dateComponents([.year, .month], from: date)
        components.day = 1
        components.hour = 0
        components.minute = 0
        components.second = 0
        return calendar.date(from: components)
    }
    
    /// Returns the date range for the current month
    static func currentMonthRange() -> (start: Date, end: Date)? {
        guard let start = startOfCurrentMonth(),
              let end = startOfNextMonth(from: start) else {
            return nil
        }
        return (start, end)
    }
    
    /// Returns the date range for a specific month
    static func monthRange(for date: Date) -> (start: Date, end: Date)? {
        guard let start = startOfMonth(for: date),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else {
            return nil
        }
        return (start, end)
    }
    
    /// Checks if a date is in the current month
    static func isInCurrentMonth(_ date: Date) -> Bool {
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    /// Checks if a date is in a specific month
    static func isInMonth(_ date: Date, equalTo otherDate: Date) -> Bool {
        return calendar.isDate(date, equalTo: otherDate, toGranularity: .month)
    }
    
    /// Returns the start of day for a given date
    static func startOfDay(for date: Date) -> Date {
        return calendar.startOfDay(for: date)
    }
    
    /// Returns date range for today
    static func todayRange() -> (start: Date, end: Date)? {
        let start = startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return nil
        }
        return (start, end)
    }
}

