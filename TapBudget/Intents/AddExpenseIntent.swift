//
//  AddExpenseIntent.swift
//  TapBudget
//
//  Intent definition for Siri Shortcuts to add expenses
//  Note: Requires Intent Extension target for full Siri integration
//

import Foundation
import AppIntents

/// Intent for adding expenses via Siri Shortcuts
/// Note: AppIntents has limitations with parameter types. This is a simplified version.
/// For full Siri integration, consider using Intents Extension instead.
@available(iOS 16.0, *)
struct AddExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Expense"
    static var description = IntentDescription("Add an expense to TapBudget using voice commands.")
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // Store intent data - amount will be entered in app
        let intentData: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(intentData, forKey: "pendingSiriExpense")
        UserDefaults.standard.synchronize()
        
        return .result()
    }
}

/// App Shortcuts provider for Siri integration
@available(iOS 16.0, *)
struct TapBudgetShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add expense in \(.applicationName)",
                "Log expense in \(.applicationName)",
                "Record expense in \(.applicationName)"
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor {
        .blue
    }
}

