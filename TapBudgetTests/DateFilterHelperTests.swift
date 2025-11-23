import XCTest
@testable import TapBudget

/// Unit tests for DateFilterHelper utility
final class DateFilterHelperTests: XCTestCase {
    
    func testStartOfCurrentMonth() {
        let startOfMonth = DateFilterHelper.startOfCurrentMonth()
        XCTAssertNotNil(startOfMonth, "Start of current month should not be nil")
        
        if let start = startOfMonth {
            let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: start)
            XCTAssertEqual(components.day, 1, "Start of month should be day 1")
            XCTAssertEqual(components.hour, 0, "Start of month should be hour 0")
            XCTAssertEqual(components.minute, 0, "Start of month should be minute 0")
            XCTAssertEqual(components.second, 0, "Start of month should be second 0")
        }
    }
    
    func testCurrentMonthRange() {
        let range = DateFilterHelper.currentMonthRange()
        XCTAssertNotNil(range, "Current month range should not be nil")
        
        if let (start, end) = range {
            XCTAssertTrue(start < end, "Start date should be before end date")
            XCTAssertTrue(end > Date(), "End date should be in the future")
        }
    }
    
    func testIsInCurrentMonth() {
        let today = Date()
        let result = DateFilterHelper.isInCurrentMonth(today)
        XCTAssertTrue(result, "Today should be in current month")
        
        let nextMonth = Calendar.current.date(byAdding: .month, value: 1, to: today)!
        let result2 = DateFilterHelper.isInCurrentMonth(nextMonth)
        XCTAssertFalse(result2, "Next month date should not be in current month")
    }
    
    func testStartOfDay() {
        let now = Date()
        let startOfDay = DateFilterHelper.startOfDay(for: now)
        
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: startOfDay)
        XCTAssertEqual(components.hour, 0, "Start of day should be hour 0")
        XCTAssertEqual(components.minute, 0, "Start of day should be minute 0")
        XCTAssertEqual(components.second, 0, "Start of day should be second 0")
    }
    
    func testTodayRange() {
        let (start, end) = DateFilterHelper.todayRange()
        XCTAssertTrue(start < end, "Start should be before end")
        
        let now = Date()
        XCTAssertTrue(start <= now, "Start should be before or equal to now")
        XCTAssertTrue(end > now, "End should be after now")
    }
}

