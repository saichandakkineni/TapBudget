import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingExportSheet = false
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            if expenses.isEmpty {
                EmptyStateView(
                    icon: "tray",
                    title: "No Expenses Yet",
                    message: "Start tracking your expenses by adding your first expense from the home screen.",
                    actionTitle: nil,
                    action: nil
                )
                .navigationTitle("Expenses")
            } else {
                List {
                    ForEach(groupedExpenses.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                            ForEach(groupedExpenses[date] ?? []) { expense in
                                ExpenseRow(expense: expense)
                            }
                            .onDelete { indexSet in
                                if let firstIndex = indexSet.first,
                                   let expensesForDate = groupedExpenses[date],
                                   firstIndex < expensesForDate.count {
                                    expenseToDelete = expensesForDate[firstIndex]
                                    showingDeleteConfirmation = true
                                }
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
                .alert("Delete Expense", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {
                        expenseToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let expense = expenseToDelete {
                            deleteExpense(expense)
                        }
                    }
                } message: {
                    if let expense = expenseToDelete {
                        Text("Are you sure you want to delete this expense of \(expense.amount.formattedAsCurrency())?")
                    }
                }
            }
        }
    }
    
    private var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        modelContext.delete(expense)
        
        do {
            try modelContext.save()
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } catch {
            print("Error deleting expense: \(error.localizedDescription)")
        }
        
        expenseToDelete = nil
    }
}

struct ExpenseRow: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            if let category = expense.category {
                Image(systemName: category.icon)
                    .foregroundColor(Color(hex: category.color))
                    .frame(width: AppConstants.categoryIconFrameWidth)
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
            
            Text(expense.amount.formattedAsCurrency())
                .fontWeight(.semibold)
        }
    }
} 