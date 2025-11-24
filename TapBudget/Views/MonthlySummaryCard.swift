import SwiftUI
import SwiftData

struct MonthlySummaryCard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var queryVersion = 0 // Force query refresh by changing this
    
    // Dynamic query that re-evaluates when queryVersion changes
    private var expenses: [Expense] {
        let monthRange = DateFilterHelper.currentMonthRange()
        if let start = monthRange?.start, let end = monthRange?.end {
            let descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    expense.date >= start && expense.date < end
                },
                sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        } else {
            let descriptor = FetchDescriptor<Expense>(
                sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
            )
            return (try? modelContext.fetch(descriptor)) ?? []
        }
    }
    
    init() {
        // No initialization needed for computed property
    }
    
    private var monthlyTotal: Double {
        let monthKey = PerformanceCache.monthKey(for: Date())
        
        // Use PerformanceCache to avoid recalculating on every render
        let result = PerformanceCache.shared.getMonthlyTotal(for: monthKey) {
            let total = expenses.reduce(0) { $0 + $1.amount }
            let count = expenses.count
            return (total, count)
        }
        
        return result.total
    }
    
    private var expenseCount: Int {
        let monthKey = PerformanceCache.monthKey(for: Date())
        
        // Use PerformanceCache to avoid recalculating on every render
        let result = PerformanceCache.shared.getMonthlyTotal(for: monthKey) {
            let total = expenses.reduce(0) { $0 + $1.amount }
            let count = expenses.count
            return (total, count)
        }
        
        return result.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("This Month")
                    .font(DynamicTypeHelper.headlineFont)
                Spacer()
                Text(Date(), format: .dateTime.month(.wide))
                    .font(DynamicTypeHelper.captionFont)
                    .foregroundColor(.secondary)
            }
            
            Text(monthlyTotal.formattedAsCurrency())
                .font(DynamicTypeHelper.amountFont())
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            
            HStack {
                Label("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")", systemImage: "list.bullet")
                    .font(DynamicTypeHelper.captionFont)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: AppConstants.cardShadowRadius, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Monthly summary, \(monthlyTotal.formattedAsCurrency()), \(expenseCount) expense\(expenseCount == 1 ? "" : "s")")
        .onChange(of: expenses.count) { _, _ in
            // Clear cache when expenses change to ensure fresh data
            let monthKey = PerformanceCache.monthKey(for: Date())
            PerformanceCache.shared.clearCache(for: monthKey)
            
            // Update widget data when expenses change (non-blocking)
            // Use Task to avoid blocking main thread
            Task { @MainActor in
                WidgetDataManager.shared.updateMonthlySummary(
                    monthlyTotal: monthlyTotal,
                    expenseCount: expenseCount
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitSyncCompleted"))) { _ in
            // Force query refresh when sync completes
            modelContext.processPendingChanges()
            queryVersion += 1
            // Clear cache to ensure fresh data
            let monthKey = PerformanceCache.monthKey(for: Date())
            PerformanceCache.shared.clearCache(for: monthKey)
        }
        .task {
            // Update widget data on appear (non-blocking, delayed)
            // Small delay ensures view is fully rendered before updating widget
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            await MainActor.run {
                WidgetDataManager.shared.updateMonthlySummary(
                    monthlyTotal: monthlyTotal,
                    expenseCount: expenseCount
                )
            }
        }
    }
}
