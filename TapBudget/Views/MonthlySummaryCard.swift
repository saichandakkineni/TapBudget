import SwiftUI
import SwiftData

struct MonthlySummaryCard: View {
    @Query private var expenses: [Expense]
    
    private var monthlyTotal: Double {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        
        return expenses.filter { expense in
            let expenseMonth = Calendar.current.component(.month, from: expense.date)
            let expenseYear = Calendar.current.component(.year, from: expense.date)
            return expenseMonth == currentMonth && expenseYear == currentYear
        }.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Month")
                .font(.headline)
            
            Text("$\(monthlyTotal, format: .currency(code: ""))")
                .font(.system(size: 36, weight: .bold))
            
            HStack {
                Spacer()
                Text(Date(), format: .dateTime.month(.wide))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
} 