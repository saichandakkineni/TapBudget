//
//  TapBudgetApp.swift
//  TapBudget
//
//  Created by SAICHAND AKKINENI on 2025-01-28.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct TapBudgetApp: App {
    let modelContainer: ModelContainer
    
    init() {
        // CRITICAL: Robust ModelContainer initialization with multiple fallback strategies
        // This ensures the app ALWAYS launches, even if there are schema issues
        
        var container: ModelContainer?
        var lastError: Error?
        
        // Strategy 1: Try normal initialization
        do {
            let schema = Schema([
                Category.self,
                Expense.self,
                RecurringExpense.self,
                ExpenseTemplate.self,
                BudgetPeriod.self,
                SharedBudget.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(
                for: Category.self, Expense.self, RecurringExpense.self, ExpenseTemplate.self, BudgetPeriod.self, SharedBudget.self,
                configurations: configuration
            )
            print("SUCCESS: ModelContainer initialized normally")
        } catch {
            lastError = error
            print("WARNING: Normal initialization failed: \(error.localizedDescription)")
            
            // Strategy 2: Delete old database and retry
            do {
                print("Attempting to reset database...")
                let fileManager = FileManager.default
                let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                let storeURL = appSupportURL.appendingPathComponent("default.store")
                
                // Delete all possible database files
                try? fileManager.removeItem(at: storeURL)
                try? fileManager.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? fileManager.removeItem(at: storeURL.appendingPathExtension("shm"))
                
                // Also check for any other store files
                if let files = try? fileManager.contentsOfDirectory(at: appSupportURL, includingPropertiesForKeys: nil) {
                    for file in files where file.pathExtension == "store" || file.pathExtension == "wal" || file.pathExtension == "shm" {
                        try? fileManager.removeItem(at: file)
                    }
                }
                
                print("Deleted old database files")
                
                // Retry with fresh database
                let schema = Schema([
                    Category.self,
                    Expense.self,
                    RecurringExpense.self,
                    ExpenseTemplate.self,
                    BudgetPeriod.self,
                    SharedBudget.self
                ])
                
                let freshConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                container = try ModelContainer(
                    for: Category.self, Expense.self, RecurringExpense.self, ExpenseTemplate.self, BudgetPeriod.self, SharedBudget.self,
                    configurations: freshConfig
                )
                print("SUCCESS: Database reset and recreated")
            } catch {
                lastError = error
                print("WARNING: Database reset failed: \(error.localizedDescription)")
                
                // Strategy 3: Try in-memory storage with full schema
                do {
                    print("Attempting in-memory storage with full schema...")
                    let schema = Schema([
                        Category.self,
                        Expense.self,
                        RecurringExpense.self,
                        ExpenseTemplate.self,
                        BudgetPeriod.self,
                        SharedBudget.self
                    ])
                    let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                    container = try ModelContainer(
                        for: Category.self, Expense.self, RecurringExpense.self, ExpenseTemplate.self, BudgetPeriod.self, SharedBudget.self,
                        configurations: inMemoryConfig
                    )
                    print("SUCCESS: Using in-memory storage")
                } catch {
                    lastError = error
                    print("WARNING: In-memory full schema failed: \(error.localizedDescription)")
                    
                    // Strategy 4: Minimal schema (only core models)
                    do {
                        print("Attempting minimal schema (Category + Expense only)...")
                        let minimalSchema = Schema([Category.self, Expense.self])
                        let minimalConfig = ModelConfiguration(schema: minimalSchema, isStoredInMemoryOnly: true)
                        container = try ModelContainer(
                            for: Category.self, Expense.self,
                            configurations: minimalConfig
                        )
                        print("SUCCESS: Using minimal schema")
                    } catch {
                        lastError = error
                        print("CRITICAL: All initialization strategies failed")
                        fatalError("Could not initialize ModelContainer with any strategy. Last error: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Ensure we have a container
        guard let finalContainer = container else {
            fatalError("ModelContainer is nil after all initialization attempts. Last error: \(lastError?.localizedDescription ?? "unknown")")
        }
        
        modelContainer = finalContainer
    }
    
    var body: some Scene {
        WindowGroup {
            // CRITICAL: Show ContentView immediately - ensure it renders something
            // Even if @Query properties are empty, views should still render
            Group {
                ContentView()
            }
            .environment(\.modelContext, modelContainer.mainContext)
            .task {
                // ALL initialization happens here - completely non-blocking
                await initializeAppInBackground()
            }
            .onOpenURL { url in
                handleAppURL(url)
            }
        }
        .modelContainer(modelContainer)
    }
    
    /// All app initialization - completely async and non-blocking
    /// This ensures the app launches immediately without any blocking operations
    private func initializeAppInBackground() async {
        // Initialize default categories in background (non-blocking)
        Task.detached(priority: .utility) {
            await MainActor.run {
                let context = modelContainer.mainContext
                let categoryFetch = FetchDescriptor<Category>()
                
                do {
                    let existingCategories = try context.fetch(categoryFetch)
                    let existingCategoryNames = Set(existingCategories.map { $0.name.lowercased() })
                    
                    // Only add default categories that don't already exist (by name, case-insensitive)
                    let categoriesToAdd = AppConstants.defaultCategories.filter { defaultCat in
                        !existingCategoryNames.contains(defaultCat.name.lowercased())
                    }
                    
                    if !categoriesToAdd.isEmpty {
                        let newCategories = categoriesToAdd.map {
                            Category(name: $0.name, icon: $0.icon, budget: $0.budget, color: $0.color)
                        }
                        newCategories.forEach { context.insert($0) }
                        try context.save()
                        print("✅ Added \(newCategories.count) default categories")
                    }
                } catch {
                    print("Error initializing default categories: \(error.localizedDescription)")
                    // Don't crash - app can still function
                }
            }
        }
        
        // Request notification permissions (non-blocking)
        Task.detached(priority: .utility) {
            _ = await NotificationManager.shared.requestAuthorization()
        }
        
        // Process recurring expenses (non-blocking)
        Task.detached(priority: .utility) {
            await MainActor.run {
                let processor = RecurringExpenseProcessor(modelContext: modelContainer.mainContext)
                do {
                    try processor.processRecurringExpenses()
                } catch {
                    print("Error processing recurring expenses: \(error.localizedDescription)")
                }
            }
        }
        
        // Check budget alerts periodically (non-blocking)
        Task.detached(priority: .utility) {
            // Wait a bit for data to load
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                // Fetch expenses for budget checking
                let expenseFetch = FetchDescriptor<Expense>()
                if let expenses = try? modelContainer.mainContext.fetch(expenseFetch) {
                    Task {
                        await BudgetAlertManager.shared.checkBudgetsAndSendAlerts(
                            modelContext: modelContainer.mainContext,
                            expenses: expenses
                        )
                    }
                }
            }
        }
    }
    
    private func handleAppURL(_ url: URL) {
        // Handle Siri shortcut URLs if needed
        // The SiriIntentHandler will process pending expenses when ContentView appears
        
        // Handle CloudKit share URLs if needed
        // CloudKit share handling is done through the CloudKit framework
    }
}
