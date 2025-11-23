import XCTest
@testable import TapBudget

/// Unit tests for DataValidator utility
final class DataValidatorTests: XCTestCase {
    
    // MARK: - Expense Amount Validation Tests
    
    func testValidateExpenseAmount_ValidAmount() {
        let result = DataValidator.validateExpenseAmount(100.50)
        XCTAssertTrue(result.isValid, "Valid amount should pass validation")
        XCTAssertNil(result.errorMessage)
    }
    
    func testValidateExpenseAmount_BelowMinimum() {
        let result = DataValidator.validateExpenseAmount(0.005)
        XCTAssertFalse(result.isValid, "Amount below minimum should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateExpenseAmount_AboveMaximum() {
        let result = DataValidator.validateExpenseAmount(2_000_000)
        XCTAssertFalse(result.isValid, "Amount above maximum should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateExpenseAmount_NaN() {
        let result = DataValidator.validateExpenseAmount(Double.nan)
        XCTAssertFalse(result.isValid, "NaN amount should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateExpenseAmount_Infinite() {
        let result = DataValidator.validateExpenseAmount(Double.infinity)
        XCTAssertFalse(result.isValid, "Infinite amount should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    // MARK: - Expense Notes Validation Tests
    
    func testValidateExpenseNotes_Nil() {
        let result = DataValidator.validateExpenseNotes(nil)
        XCTAssertTrue(result.isValid, "Nil notes should be valid (optional)")
    }
    
    func testValidateExpenseNotes_Valid() {
        let result = DataValidator.validateExpenseNotes("Valid notes")
        XCTAssertTrue(result.isValid, "Valid notes should pass validation")
    }
    
    func testValidateExpenseNotes_TooLong() {
        let longNotes = String(repeating: "a", count: 501)
        let result = DataValidator.validateExpenseNotes(longNotes)
        XCTAssertFalse(result.isValid, "Notes exceeding 500 characters should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    // MARK: - Category Name Validation Tests
    
    func testValidateCategoryName_Valid() {
        let result = DataValidator.validateCategoryName("Food")
        XCTAssertTrue(result.isValid, "Valid category name should pass validation")
    }
    
    func testValidateCategoryName_Empty() {
        let result = DataValidator.validateCategoryName("")
        XCTAssertFalse(result.isValid, "Empty category name should fail validation")
        XCTAssertNotNil(result.errorMessage)
    }
    
    func testValidateCategoryName_WhitespaceOnly() {
        let result = DataValidator.validateCategoryName("   ")
        XCTAssertFalse(result.isValid, "Whitespace-only name should fail validation")
    }
    
    func testValidateCategoryName_TooShort() {
        let result = DataValidator.validateCategoryName("")
        XCTAssertFalse(result.isValid, "Name shorter than minimum should fail validation")
    }
    
    func testValidateCategoryName_TooLong() {
        let longName = String(repeating: "a", count: 51)
        let result = DataValidator.validateCategoryName(longName)
        XCTAssertFalse(result.isValid, "Name longer than maximum should fail validation")
    }
    
    func testValidateCategoryName_InvalidCharacters() {
        let result = DataValidator.validateCategoryName("Food<Category>")
        XCTAssertFalse(result.isValid, "Name with invalid characters should fail validation")
    }
    
    // MARK: - Category Budget Validation Tests
    
    func testValidateCategoryBudget_Valid() {
        let result = DataValidator.validateCategoryBudget(1000.0)
        XCTAssertTrue(result.isValid, "Valid budget should pass validation")
    }
    
    func testValidateCategoryBudget_Negative() {
        let result = DataValidator.validateCategoryBudget(-100)
        XCTAssertFalse(result.isValid, "Negative budget should fail validation")
    }
    
    func testValidateCategoryBudget_Zero() {
        let result = DataValidator.validateCategoryBudget(0)
        XCTAssertTrue(result.isValid, "Zero budget should be valid")
    }
    
    func testValidateCategoryBudget_TooLarge() {
        let result = DataValidator.validateCategoryBudget(2_000_000)
        XCTAssertFalse(result.isValid, "Budget exceeding maximum should fail validation")
    }
    
    // MARK: - Category Icon Validation Tests
    
    func testValidateCategoryIcon_Valid() {
        let result = DataValidator.validateCategoryIcon("cart")
        XCTAssertTrue(result.isValid, "Valid icon should pass validation")
    }
    
    func testValidateCategoryIcon_Empty() {
        let result = DataValidator.validateCategoryIcon("")
        XCTAssertFalse(result.isValid, "Empty icon should fail validation")
    }
    
    func testValidateCategoryIcon_Invalid() {
        let result = DataValidator.validateCategoryIcon("invalid-icon")
        XCTAssertFalse(result.isValid, "Invalid icon should fail validation")
    }
    
    // MARK: - Category Color Validation Tests
    
    func testValidateCategoryColor_Valid() {
        let result = DataValidator.validateCategoryColor("#FF6B6B")
        XCTAssertTrue(result.isValid, "Valid color should pass validation")
    }
    
    func testValidateCategoryColor_Empty() {
        let result = DataValidator.validateCategoryColor("")
        XCTAssertFalse(result.isValid, "Empty color should fail validation")
    }
    
    func testValidateCategoryColor_InvalidFormat() {
        let result = DataValidator.validateCategoryColor("FF6B6B")
        XCTAssertFalse(result.isValid, "Color without # should fail validation")
    }
    
    func testValidateCategoryColor_InvalidHex() {
        let result = DataValidator.validateCategoryColor("#GGGGGG")
        XCTAssertFalse(result.isValid, "Invalid hex color should fail validation")
    }
    
    // MARK: - Expense Date Validation Tests
    
    func testValidateExpenseDate_Valid() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let result = DataValidator.validateExpenseDate(yesterday)
        XCTAssertTrue(result.isValid, "Past date should be valid")
    }
    
    func testValidateExpenseDate_Future() {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let result = DataValidator.validateExpenseDate(tomorrow)
        XCTAssertFalse(result.isValid, "Future date should fail validation")
    }
    
    func testValidateExpenseDate_TooFarPast() {
        let elevenYearsAgo = Calendar.current.date(byAdding: .year, value: -11, to: Date())!
        let result = DataValidator.validateExpenseDate(elevenYearsAgo)
        XCTAssertFalse(result.isValid, "Date too far in past should fail validation")
    }
}

