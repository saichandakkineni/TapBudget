//
//  TapBudgetApp.swift
//  TapBudget
//
//  Created by SAICHAND AKKINENI on 2025-01-28.
//

import SwiftUI
import SwiftData

@main
struct TapBudgetApp: App {
    let modelContainer: ModelContainer
    
    init() {
        do {
            modelContainer = try ModelContainer(
                for: Category.self, Expense.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
            
            // Add default categories if none exist
            let context = modelContainer.mainContext
            let categoryFetch = FetchDescriptor<Category>()
            
            do {
                let existingCategories = try context.fetch(categoryFetch)
                
                if existingCategories.isEmpty {
                    let defaultCategories = [
                        Category(name: "Food", icon: "fork.knife", budget: 500, color: "#FF6B6B"),
                        Category(name: "Bills", icon: "doc.text", budget: 1000, color: "#4ECDC4"),
                        Category(name: "Shopping", icon: "cart", budget: 300, color: "#45B7D1"),
                        Category(name: "Transport", icon: "car", budget: 200, color: "#96CEB4"),
                        Category(name: "Entertainment", icon: "film", budget: 150, color: "#FFEEAD")
                    ]
                    defaultCategories.forEach { context.insert($0) }
                    try context.save()
                }
            } catch {
                print("Error fetching categories: \(error)")
            }
        } catch {
            fatalError("Could not initialize ModelContainer: \(error.localizedDescription)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.modelContext, modelContainer.mainContext)
        }
        .modelContainer(modelContainer)
    }
}
