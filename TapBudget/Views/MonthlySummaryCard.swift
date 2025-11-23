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
                    .font(.headline)
                Spacer()
                Text(Date(), format: .dateTime.month(.wide))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(monthlyTotal.formattedAsCurrency())
                .font(.system(size: 36, weight: .bold))
            
            HStack {
                Label("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(AppConstants.cardCornerRadius)
        .shadow(radius: AppConstants.cardShadowRadius)
    }
} 