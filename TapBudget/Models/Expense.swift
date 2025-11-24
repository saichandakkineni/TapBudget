import Foundation
import SwiftData

@Model final class Expense {
    var id: String = UUID().uuidString
    var amount: Double = 0
    var date: Date = Date()
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