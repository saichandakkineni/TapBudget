import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var selectedTab = 0
    @State private var showingSiriResult = false
    @State private var siriResultMessage = ""
    @State private var showOnboarding = !UserDefaults.hasCompletedOnboarding
    @State private var isInitialLoad = true
    
    // Simplified: Use simple query without complex date calculations in init()
    // Date filtering can be done in computed properties if needed
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    
    // Computed property for today's expenses - calculated lazily after view loads
    private var todayExpenses: [Expense] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        return allExpenses.filter { expense in
            expense.date >= startOfDay && expense.date < endOfDay
        }
    }
    
    var body: some View {
        // CRITICAL: Always show TabView immediately, even if data isn't loaded
        // This prevents blank screen - views will handle their own empty states
        // Use ZStack to ensure something always renders
        ZStack {
            // Background color to ensure something is visible
            Color(.systemBackground)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(0)
                
                ExpenseListView()
                    .tabItem {
                        Label("Expenses", systemImage: "list.bullet")
                    }
                    .tag(1)
                
                CategoriesView()
                    .tabItem {
                        Label("Categories", systemImage: "folder")
                    }
                    .tag(2)
                
                InsightsView()
                    .tabItem {
                        Label("Insights", systemImage: "chart.bar")
                    }
                    .tag(3)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(4)
            }
        }
        .task {
            // Mark initial load as complete after a brief moment
            // This ensures views have time to render
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            isInitialLoad = false
            
            // Delay Siri intent processing until data is ready
            try? await Task.sleep(nanoseconds: 200_000_000) // Additional 0.2 seconds
            processSiriIntent()
        }
        .alert("Siri Expense Added", isPresented: $showingSiriResult) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(siriResultMessage)
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
    
    private func processSiriIntent() {
        // Only process if categories are loaded to prevent crashes
        guard !categories.isEmpty else {
            return
        }
        
        let result = SiriIntentHandler.shared.processPendingExpense(
            modelContext: modelContext,
            categories: categories
        )
        
        if result.success {
            siriResultMessage = result.message
            showingSiriResult = true
        }
    }
} 