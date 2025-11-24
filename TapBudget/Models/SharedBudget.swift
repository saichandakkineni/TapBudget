import Foundation
import SwiftData

/// Model representing a shared budget group for family/collaborative budgeting
@Model final class SharedBudget {
    var id: String = UUID().uuidString
    var name: String = ""
    var createdBy: String = "" // User ID or name
    var createdAt: Date = Date()
    var isActive: Bool = true
    
    // CloudKit sharing
    var shareURL: String? // CloudKit share URL
    var shareToken: String? // CloudKit share token
    
    // Members (stored as JSON string for simplicity, or could be separate model)
    var memberIds: String = "[]" // JSON array of member user IDs
    
    // Budget period
    var periodTypeRawValue: String = PeriodType.monthly.rawValue
    var budgetAmount: Double = 0
    var startDate: Date = Date()
    var endDate: Date?
    
    var periodType: PeriodType {
        get { PeriodType(rawValue: periodTypeRawValue) ?? .monthly }
        set { periodTypeRawValue = newValue.rawValue }
    }
    
    // Associated categories (many-to-many relationship)
    @Relationship(inverse: \Category.sharedBudgets)
    var categories: [Category]?
    
    init(
        name: String,
        createdBy: String,
        periodType: PeriodType = .monthly,
        budgetAmount: Double,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.createdBy = createdBy
        self.createdAt = Date()
        self.isActive = isActive
        self.periodTypeRawValue = periodType.rawValue
        self.budgetAmount = budgetAmount
        self.startDate = startDate
        self.endDate = endDate
        self.memberIds = "[]"
        self.categories = []
    }
    
    /// Adds a member to the shared budget
    func addMember(_ userId: String) {
        var members = getMembers()
        if !members.contains(userId) {
            members.append(userId)
            if let jsonData = try? JSONEncoder().encode(members),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                memberIds = jsonString
            }
        }
    }
    
    /// Removes a member from the shared budget
    func removeMember(_ userId: String) {
        var members = getMembers()
        members.removeAll { $0 == userId }
        if let jsonData = try? JSONEncoder().encode(members),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            memberIds = jsonString
        }
    }
    
    /// Gets list of member IDs
    func getMembers() -> [String] {
        guard let data = memberIds.data(using: .utf8),
              let members = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return members
    }
    
    /// Checks if a user is a member
    func isMember(_ userId: String) -> Bool {
        return getMembers().contains(userId)
    }
}

