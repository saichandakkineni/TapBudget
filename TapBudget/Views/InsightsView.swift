import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var expenses: [Expense]
    @Query private var categories: [Category]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly spending chart
                    ChartCard(title: "Monthly Spending") {
                        Chart(monthlySpending) { spending in
                            BarMark(
                                x: .value("Month", spending.month),
                                y: .value("Amount", spending.amount)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                        }
                        .chartXAxis {
                            AxisMarks(values: .automatic) { value in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                    }
                    
                    // Category breakdown
                    ChartCard(title: "Spending by Category") {
                        Chart(categorySpending) { spending in
                            SectorMark(
                                angle: .value("Amount", spending.amount),
                                innerRadius: .ratio(0.618),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color(hex: spending.category.color ?? "#FF0000"))
                        }
                    }
                    
                    // Budget progress
                    VStack(spacing: 15) {
                        ForEach(categories) { category in
                            BudgetProgressView(category: category, expenses: expenses)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
        }
    }
    
    private var monthlySpending: [MonthlySpending] {
        // Calculate monthly totals for the last 6 months
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -5, to: endDate)!
        
        return calendar.generateDates(
            inside: DateInterval(start: startDate, end: endDate),
            matching: DateComponents(day: 1)
        ).map { date in
            let monthExpenses = expenses.filter {
                calendar.isDate($0.date, equalTo: date, toGranularity: .month)
            }
            return MonthlySpending(
                month: date,
                amount: monthExpenses.reduce(0) { $0 + $1.amount }
            )
        }
    }
    
    private var categorySpending: [CategorySpending] {
        categories.map { category in
            let amount = expenses.filter { $0.category?.id == category.id }
                .reduce(0) { $0 + $1.amount }
            return CategorySpending(category: category, amount: amount)
        }
    }
}

struct ChartCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            content()
                .frame(height: 200)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}

struct BudgetProgressView: View {
    let category: Category
    let expenses: [Expense]
    
    private var totalSpent: Double {
        expenses.filter { $0.category?.id == category.id }
            .reduce(0) { $0 + $1.amount }
    }
    
    private var progress: Double {
        category.budget > 0 ? min(totalSpent / category.budget, 1.0) : 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: category.icon ?? "questionmark.circle")
                    .foregroundColor(Color(hex: category.color ?? "#FF0000"))
                Text(category.name ?? "Unnamed Category")
                Spacer()
                Text(totalSpent, format: .currency(code: "USD"))
                    .fontWeight(.semibold)
            }
            
            ProgressView(value: progress)
                .tint(Color(hex: category.color ?? "#FF0000"))
        }
    }
}

struct MonthlySpending: Identifiable {
    let month: Date
    let amount: Double
    var id: Date { month }
}

struct CategorySpending: Identifiable {
    let category: Category
    let amount: Double
    var id: String { category.id }
} 