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
                    let defaultCategories = AppConstants.defaultCategories.map {
                        Category(name: $0.name, icon: $0.icon, budget: $0.budget, color: $0.color)
                    }
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
                .task {
                    // Request notification permissions on app launch
                    _ = await NotificationManager.shared.requestAuthorization()
                }
        }
        .modelContainer(modelContainer)
    }
}
