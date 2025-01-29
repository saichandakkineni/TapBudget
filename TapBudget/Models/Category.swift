import Foundation
import SwiftData

@Model final class Category {
    @Attribute(.unique) var id: String
    var name: String
    var icon: String
    var budget: Double
    var color: String
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.category)
    var expenses: [Expense]?
    
    init(name: String, icon: String, budget: Double = 0, color: String = "#FF0000") {
        self.id = UUID().uuidString
        self.name = name
        self.icon = icon
        self.budget = budget
        self.color = color
        self.expenses = []
    }
} 