import SwiftUI
import SwiftData

struct MonthlySummaryCard: View {
    @Query private var expenses: [Expense]
    
    private var monthlyTotal: Double {
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            return 0
        }
        
        return expenses.filter { expense in
            expense.date >= monthRange.start && expense.date < monthRange.end
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var expenseCount: Int {
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            return 0
        }
        
        return expenses.filter { expense in
            expense.date >= monthRange.start && expense.date < monthRange.end
        }.count
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
            // Update widget data when expenses change (non-blocking)
            // Use Task to avoid blocking main thread
            Task { @MainActor in
                WidgetDataManager.shared.updateMonthlySummary(
                    monthlyTotal: monthlyTotal,
                    expenseCount: expenseCount
                )
            }
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
