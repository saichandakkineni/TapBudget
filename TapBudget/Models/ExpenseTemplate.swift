import Foundation
import SwiftData

/// Model for expense templates (quick-add templates)
@Model final class ExpenseTemplate {
    var id: String = UUID().uuidString
    var name: String = ""
    var amount: Double = 0
    @Relationship(inverse: \Category.expenseTemplates)
    var category: Category?
    var notes: String?
    var icon: String = "tag"
    var isActive: Bool = true
    
    init(
        name: String,
        amount: Double,
        category: Category? = nil,
        notes: String? = nil,
        icon: String = "tag",
        isActive: Bool = true
    ) {
        self.id = UUID().uuidString
        self.name = name
        self.amount = amount
        self.category = category
        self.notes = notes
        self.icon = icon
        self.isActive = isActive
    }
}

