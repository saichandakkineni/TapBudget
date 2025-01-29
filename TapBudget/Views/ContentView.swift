import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    
    @Query private var todayExpenses: [Expense]
    
    init() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startOfDay && expense.date < endOfDay
            },
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        
        _todayExpenses = Query(descriptor)
    }
    
    var body: some View {
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
            
            InsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.bar")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
} 