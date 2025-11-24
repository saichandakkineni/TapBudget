import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Query private var expenses: [Expense]
    @Query private var categories: [Category]
    @State private var selectedTimeRange: TimeRange = .sixMonths
    
    enum TimeRange: String, CaseIterable {
        case threeMonths = "3 Months"
        case sixMonths = "6 Months"
        case oneYear = "1 Year"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Advanced Analytics Summary
                    AdvancedAnalyticsCard(expenses: expenses, categories: categories, timeRange: selectedTimeRange)
                    
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
                                innerRadius: .ratio(AppConstants.pieChartInnerRadius),
                                angularInset: AppConstants.pieChartAngularInset
                            )
                            .foregroundStyle(Color(hex: spending.category.color))
                        }
                    }
                    
                    // Budget progress
                    if categories.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar.doc.horizontal",
                            title: "No Categories",
                            message: "Create categories in Settings to track your budget progress.",
                            actionTitle: nil,
                            action: nil
                        )
                    } else {
                        VStack(spacing: 15) {
                            ForEach(categories) { category in
                                BudgetProgressView(category: category, expenses: expenses)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Insights")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
    
    private var monthlySpending: [MonthlySpending] {
        // Calculate monthly totals based on selected time range
        let calendar = Calendar.current
        let endDate = Date()
        let monthsToShow: Int
        
        switch selectedTimeRange {
        case .threeMonths:
            monthsToShow = 3
        case .sixMonths:
            monthsToShow = 6
        case .oneYear:
            monthsToShow = 12
        }
        
        guard let startDate = calendar.date(byAdding: .month, value: -(monthsToShow - 1), to: endDate) else {
            return []
        }
        
        return calendar.generateDates(
            inside: DateInterval(start: startDate, end: endDate),
            matching: DateComponents(day: 1)
        ).map { date in
            guard let monthRange = DateFilterHelper.monthRange(for: date) else {
                return MonthlySpending(month: date, amount: 0)
            }
            
            let monthExpenses = expenses.filter { expense in
                expense.date >= monthRange.start && expense.date < monthRange.end
            }
            return MonthlySpending(
                month: date,
                amount: monthExpenses.reduce(0) { $0 + $1.amount }
            )
        }
    }
    
    private var categorySpending: [CategorySpending] {
        // Optimize by grouping expenses by category first
        // Filter expenses to current month only for better performance
        guard let monthRange = DateFilterHelper.currentMonthRange() else {
            return []
        }
        
        let currentMonthExpenses = expenses.filter { expense in
            expense.date >= monthRange.start && expense.date < monthRange.end
        }
        
        let expensesByCategory = Dictionary(grouping: currentMonthExpenses) { $0.category?.id ?? "" }
        
        return categories.map { category in
            let categoryExpenses = expensesByCategory[category.id] ?? []
            let amount = categoryExpenses.reduce(0) { $0 + $1.amount }
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
                .font(DynamicTypeHelper.headlineFont)
            
            content()
                .frame(height: AppConstants.chartHeight)
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: AppConstants.cardShadowRadius, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
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
    
    private var percentage: Int {
        category.budget > 0 ? Int((totalSpent / category.budget) * 100) : 0
    }
    
    private var remainingBudget: Double {
        max(0, category.budget - totalSpent)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))
                Text(category.name)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(totalSpent.formattedAsCurrency())
                        .fontWeight(.semibold)
                    if category.budget > 0 {
                        Text("\(percentage)%")
                            .font(.caption2)
                            .foregroundColor(percentage >= 90 ? .red : percentage >= 75 ? .orange : .secondary)
                    }
                }
            }
            
            if category.budget > 0 {
                ProgressView(value: progress)
                    .tint(Color(hex: category.color))
                
                HStack {
                    Text("Remaining: \(remainingBudget.formattedAsCurrency())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    if remainingBudget < category.budget * 0.1 {
                        Text("⚠️ Low budget")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            } else {
                Text("No budget set")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: AppConstants.cardShadowRadius, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(AccessibilityHelper.categoryLabel(name: category.name, budget: category.budget, spent: totalSpent))
        .accessibilityValue(AccessibilityHelper.progressValue(current: totalSpent, total: category.budget))
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