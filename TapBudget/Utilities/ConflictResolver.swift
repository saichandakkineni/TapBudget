import Foundation
import SwiftData

/// Handles conflict resolution for CloudKit sync
class ConflictResolver {
    static let shared = ConflictResolver()
    
    private init() {}
    
    /// Resolves conflicts between local and remote data
    /// Strategy: Last-write-wins with timestamp comparison
    func resolveConflict<T: PersistentModel>(
        local: T,
        remote: T,
        localTimestamp: Date,
        remoteTimestamp: Date
    ) -> T {
        // Last-write-wins strategy
        if remoteTimestamp > localTimestamp {
            return remote
        } else {
            return local
        }
    }
    
    /// Merges two expense records, preferring non-nil values
    func mergeExpenses(local: Expense, remote: Expense) -> Expense {
        // Prefer the most recent update
        let localModified = local.date // Using date as proxy for modification time
        let remoteModified = remote.date
        
        if remoteModified > localModified {
            // Remote is newer, use remote values but keep local ID
            let merged = Expense(
                amount: remote.amount,
                date: remote.date,
                notes: remote.notes ?? local.notes,
                category: remote.category ?? local.category
            )
            merged.id = local.id // Keep local ID for consistency
            return merged
        } else {
            // Local is newer or same, keep local
            return local
        }
    }
    
    /// Merges two category records
    func mergeCategories(local: Category, remote: Category) -> Category {
        // For categories, prefer the one with more expenses (more complete)
        let localExpenseCount = local.expenses?.count ?? 0
        let remoteExpenseCount = remote.expenses?.count ?? 0
        
        if remoteExpenseCount > localExpenseCount {
            let merged = Category(
                name: remote.name,
                icon: remote.icon,
                budget: remote.budget,
                color: remote.color
            )
            merged.id = local.id
            return merged
        } else {
            return local
        }
    }
    
    /// Resolves conflicts for shared budgets
    func resolveSharedBudgetConflict(
        local: SharedBudget,
        remote: SharedBudget
    ) -> SharedBudget {
        // Merge members from both
        var mergedMembers = Set(local.getMembers())
        mergedMembers.formUnion(remote.getMembers())
        
        let merged = SharedBudget(
            name: local.name, // Prefer local name
            createdBy: local.createdBy, // Keep original creator
            periodType: remote.periodType, // Prefer remote period type
            budgetAmount: max(local.budgetAmount, remote.budgetAmount), // Use higher budget
            startDate: min(local.startDate, remote.startDate), // Use earlier start date
            endDate: local.endDate ?? remote.endDate
        )
        merged.id = local.id
        
        // Merge members
        for memberId in mergedMembers {
            merged.addMember(memberId)
        }
        
        return merged
    }
}

