import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingExportSheet = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { date in
                    Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                        ForEach(groupedExpenses[date] ?? []) { expense in
                            ExpenseRow(expense: expense)
                        }
                        .onDelete { indexSet in
                            deleteExpenses(for: date, at: indexSet)
                        }
                    }
                }
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportView(expenses: expenses)
            }
        }
    }
    
    private var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    private func deleteExpenses(for date: Date, at offsets: IndexSet) {
        guard let expensesToDelete = groupedExpenses[date] else { return }
        offsets.forEach { index in
            modelContext.delete(expensesToDelete[index])
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            if let category = expense.category {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))
                    .frame(width: 30)
            }
            
            VStack(alignment: .leading) {
                Text(expense.category?.name ?? "Uncategorized")
                if let notes = expense.notes {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("$\(expense.amount, format: .currency(code: ""))")
                .fontWeight(.semibold)
        }
    }
} 