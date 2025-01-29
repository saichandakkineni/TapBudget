import Foundation
import SwiftData

@Model final class Expense {
    @Attribute(.unique) var id: String
    var amount: Double
    var date: Date
    var notes: String?
    
    var category: Category?
    
    init(amount: Double, date: Date = Date(), notes: String? = nil, category: Category? = nil) {
        self.id = UUID().uuidString
        self.amount = amount
        self.date = date
        self.notes = notes
        self.category = category
    }
} 