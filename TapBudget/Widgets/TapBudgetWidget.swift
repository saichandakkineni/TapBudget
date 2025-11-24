//
//  TapBudgetWidget.swift
//  TapBudget Widget Extension
//
//  Note: This file requires a Widget Extension target to be added in Xcode
//  Steps to add widget:
//  1. File > New > Target > Widget Extension
//  2. Name it "TapBudgetWidget"
//  3. Add this file to the widget extension target
//

import WidgetKit
import SwiftUI

/// Widget configuration for TapBudget
struct TapBudgetWidget: Widget {
    let kind: String = "TapBudgetWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthlySummaryProvider()) { entry in
            MonthlySummaryWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Monthly Spending")
        .description("View your current month's spending at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Widget entry containing the data to display
struct MonthlySummaryEntry: TimelineEntry {
    let date: Date
    let monthlyTotal: Double
    let expenseCount: Int
    let budgetProgress: Double?
    let categoryName: String?
}

/// Provider that fetches data for the widget
struct MonthlySummaryProvider: TimelineProvider {
    typealias Entry = MonthlySummaryEntry
    
    func placeholder(in context: Context) -> MonthlySummaryEntry {
        MonthlySummaryEntry(
            date: Date(),
            monthlyTotal: 1250.50,
            expenseCount: 15,
            budgetProgress: 0.65,
            categoryName: "Food"
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (MonthlySummaryEntry) -> Void) {
        let entry = fetchMonthlySummary()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthlySummaryEntry>) -> Void) {
        let entry = fetchMonthlySummary()
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchMonthlySummary() -> MonthlySummaryEntry {
        // Widgets run in a separate process and need App Groups to share data
        // Fetch from shared UserDefaults via App Group
        let appGroupIdentifier = "group.com.tapbudget.app"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return MonthlySummaryEntry(
                date: Date(),
                monthlyTotal: 0,
                expenseCount: 0,
                budgetProgress: nil,
                categoryName: nil
            )
        }
        
        let monthlyTotal = sharedDefaults.double(forKey: "widget_monthly_total")
        let expenseCount = sharedDefaults.integer(forKey: "widget_expense_count")
        
        return MonthlySummaryEntry(
            date: Date(),
            monthlyTotal: monthlyTotal,
            expenseCount: expenseCount,
            budgetProgress: nil,
            categoryName: nil
        )
    }
}

/// Widget view that adapts to widget family size
struct MonthlySummaryWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: MonthlySummaryProvider.Entry
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }
    
    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("This Month")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            Text(entry.monthlyTotal.formattedAsCurrency())
                .font(.title2)
                .fontWeight(.bold)
            
            if entry.expenseCount > 0 {
                Text("\(entry.expenseCount) expense\(entry.expenseCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private var mediumWidgetView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("This Month")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.accentColor)
                }
                
                Text(entry.monthlyTotal.formattedAsCurrency())
                    .font(.system(size: 32, weight: .bold))
                
                if entry.expenseCount > 0 {
                    Label("\(entry.expenseCount) expense\(entry.expenseCount == 1 ? "" : "s")", systemImage: "list.bullet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let progress = entry.budgetProgress, let categoryName = entry.categoryName {
                VStack(alignment: .leading, spacing: 8) {
                    Text(categoryName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progress)
                        .tint(.accentColor)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
    }
}


#Preview(as: .systemSmall) {
    TapBudgetWidget()
} timeline: {
    MonthlySummaryEntry(
        date: Date(),
        monthlyTotal: 1250.50,
        expenseCount: 15,
        budgetProgress: nil,
        categoryName: nil
    )
}

#Preview(as: .systemMedium) {
    TapBudgetWidget()
} timeline: {
    MonthlySummaryEntry(
        date: Date(),
        monthlyTotal: 1250.50,
        expenseCount: 15,
        budgetProgress: 0.65,
        categoryName: "Food"
    )
}

