import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [Category]
    @State private var showingExportSheet = false
    @State private var expenseToDelete: Expense?
    @State private var showingDeleteConfirmation = false
    @State private var searchText = ""
    @State private var selectedCategory: Category?
    @State private var showingFilters = false
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    @State private var isFilteringByDate = false
    
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
                    ForEach(filteredGroupedExpenses.keys.sorted(by: >), id: \.self) { date in
                        Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                            ForEach(filteredGroupedExpenses[date] ?? []) { expense in
                                ExpenseRow(expense: expense)
                                    .accessibleExpense(
                                        amount: expense.amount,
                                        category: expense.category?.name ?? "Uncategorized",
                                        date: expense.date,
                                        notes: expense.notes
                                    )
                            }
                            .onDelete { indexSet in
                                if let firstIndex = indexSet.first,
                                   let expensesForDate = filteredGroupedExpenses[date],
                                   firstIndex < expensesForDate.count {
                                    expenseToDelete = expensesForDate[firstIndex]
                                    showingDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search expenses...")
                .navigationTitle("Expenses")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                        .accessibleButton(label: "Filters", hint: "Double tap to show filter options")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingExportSheet = true }) {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .accessibleButton(label: "Export expenses", hint: "Double tap to export expenses")
                    }
                }
                .sheet(isPresented: $showingFilters) {
                    FilterSheetView(
                        selectedCategory: $selectedCategory,
                        categories: categories,
                        minAmount: $minAmount,
                        maxAmount: $maxAmount,
                        startDate: $startDate,
                        endDate: $endDate,
                        isFilteringByDate: $isFilteringByDate,
                        onClear: {
                            clearFilters()
                        }
                    )
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
    
    private var filteredExpenses: [Expense] {
        var filtered = expenses
        
        // Search text filter
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.category?.name.localizedCaseInsensitiveContains(searchText) == true ||
                expense.notes?.localizedCaseInsensitiveContains(searchText) == true ||
                expense.amount.formattedAsCurrency().localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Amount range filter
        if let min = Double(minAmount), min > 0 {
            filtered = filtered.filter { $0.amount >= min }
        }
        if let max = Double(maxAmount), max > 0 {
            filtered = filtered.filter { $0.amount <= max }
        }
        
        // Date range filter
        if isFilteringByDate {
            filtered = filtered.filter { expense in
                expense.date >= startDate && expense.date <= endDate
            }
        }
        
        return filtered
    }
    
    private var filteredGroupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: filteredExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    private var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        minAmount = ""
        maxAmount = ""
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
        isFilteringByDate = false
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