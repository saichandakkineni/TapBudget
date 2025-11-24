import SwiftUI
import SwiftData

/// Advanced analytics card showing spending trends and comparisons
struct AdvancedAnalyticsCard: View {
    let expenses: [Expense]
    let categories: [Category]
    let timeRange: InsightsView.TimeRange
    
    private var monthlyAmounts: [Double] {
        let calendar = Calendar.current
        let endDate = Date()
        let monthsToShow: Int
        
        switch timeRange {
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
                return 0.0
            }
            
            return expenses.filter { expense in
                expense.date >= monthRange.start && expense.date < monthRange.end
            }.reduce(0) { $0 + $1.amount }
        }
    }
    
    private var spendingTrend: SpendingTrend {
        AnalyticsHelper.calculateTrend(monthlyAmounts)
    }
    
    private var averageSpending: Double {
        AnalyticsHelper.averageSpending(monthlyAmounts)
    }
    
    private var categoryComparison: CategoryComparison {
        let categorySpending = categories.map { category in
            let categoryExpenses = expenses.filter { $0.category?.id == category.id }
            let amount = categoryExpenses.reduce(0) { $0 + $1.amount }
            return (category: category.name, amount: amount)
        }
        return AnalyticsHelper.categoryComparison(categorySpending)
    }
    
    private var monthComparison: MonthComparison? {
        guard monthlyAmounts.count >= 2 else { return nil }
        let current = monthlyAmounts.last ?? 0
        let previous = monthlyAmounts[monthlyAmounts.count - 2]
        return AnalyticsHelper.monthOverMonthComparison(current: current, previous: previous)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analytics Summary")
                .font(DynamicTypeHelper.headlineFont)
            
            // Spending Trend
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trend")
                        .font(DynamicTypeHelper.captionFont)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(spendingTrend.description)
                            .font(DynamicTypeHelper.bodyFont)
                            .fontWeight(.semibold)
                            .foregroundColor(spendingTrend.color)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Average")
                        .font(DynamicTypeHelper.captionFont)
                        .foregroundColor(.secondary)
                    Text(averageSpending.formattedAsCurrency())
                        .font(DynamicTypeHelper.bodyFont)
                        .fontWeight(.semibold)
                }
            }
            
            Divider()
            
            // Month-over-Month Comparison
            if let comparison = monthComparison {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Month-over-Month")
                        .font(DynamicTypeHelper.captionFont)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("This Month")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(comparison.currentAmount.formattedAsCurrency())
                                .font(DynamicTypeHelper.bodyFont)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text("Change")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                Image(systemName: comparison.isIncrease ? "arrow.up" : "arrow.down")
                                    .font(.caption)
                                Text("\(String(format: "%.1f", abs(comparison.percentChange)))%")
                                    .font(DynamicTypeHelper.captionFont)
                            }
                            .foregroundColor(comparison.isIncrease ? .red : .green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Last Month")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(comparison.previousAmount.formattedAsCurrency())
                                .font(DynamicTypeHelper.bodyFont)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                Divider()
            }
            
            // Category Comparison
            if let topCategory = categoryComparison.topCategory {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Top Category")
                        .font(DynamicTypeHelper.captionFont)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(topCategory.name)
                            .font(DynamicTypeHelper.bodyFont)
                            .fontWeight(.semibold)
                        Spacer()
                        Text(topCategory.amount.formattedAsCurrency())
                            .font(DynamicTypeHelper.bodyFont)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: AppConstants.cardShadowRadius, x: 0, y: 2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analytics summary, \(spendingTrend.description), average spending \(averageSpending.formattedAsCurrency())")
    }
}

