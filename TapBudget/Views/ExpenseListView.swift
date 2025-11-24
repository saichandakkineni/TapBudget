import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var queryVersion = 0 // Force query refresh by changing this
    
    // Dynamic queries that re-evaluate when queryVersion changes
    private var expenses: [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\Expense.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    private var categories: [Category] {
        let descriptor = FetchDescriptor<Category>()
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
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
    
    // Pagination state
    @State private var displayedExpenseCount: Int = 50 // Initial batch size
    private let paginationBatchSize: Int = 50 // Load 50 more at a time
    @State private var refreshTrigger = UUID() // Force refresh when sync completes
    
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
                    ForEach(Array(paginatedGroupedExpenses.keys.sorted(by: >).enumerated()), id: \.element) { index, date in
                        Section(header: Text(date.formatted(date: .complete, time: .omitted))) {
                            ForEach(paginatedGroupedExpenses[date] ?? []) { expense in
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
                                   let expensesForDate = paginatedGroupedExpenses[date],
                                   firstIndex < expensesForDate.count {
                                    expenseToDelete = expensesForDate[firstIndex]
                                    showingDeleteConfirmation = true
                                }
                            }
                            
                            // Show "Load More" button at the last section if there are more expenses
                            if index == paginatedGroupedExpenses.keys.sorted(by: >).count - 1 && hasMoreExpenses {
                                Button {
                                    loadMoreExpenses()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("Load More Expenses (\(remainingExpenseCount) remaining)")
                                            .font(.subheadline)
                                            .foregroundColor(.accentColor)
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search expenses...")
                .onChange(of: searchText) { _, _ in
                    // Reset pagination when search changes
                    displayedExpenseCount = paginationBatchSize
                }
                .onChange(of: selectedCategory?.id) { _, _ in
                    // Reset pagination when category filter changes
                    displayedExpenseCount = paginationBatchSize
                }
                .onChange(of: isFilteringByDate) { _, _ in
                    // Reset pagination when date filter changes
                    displayedExpenseCount = paginationBatchSize
                }
                .onChange(of: minAmount) { _, _ in
                    // Reset pagination when amount filter changes
                    displayedExpenseCount = paginationBatchSize
                }
                .onChange(of: maxAmount) { _, _ in
                    // Reset pagination when amount filter changes
                    displayedExpenseCount = paginationBatchSize
                }
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
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("CloudKitSyncCompleted"))) { _ in
                    // Force query refresh by incrementing queryVersion
                    // This makes the computed properties re-fetch data
                    modelContext.processPendingChanges()
                    queryVersion += 1
                    refreshTrigger = UUID()
                    
                    // Process again after delays to catch any delayed CloudKit changes
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await MainActor.run {
                            modelContext.processPendingChanges()
                            queryVersion += 1 // Force query re-evaluation
                            refreshTrigger = UUID()
                        }
                        
                        // One more time after another delay
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                        await MainActor.run {
                            modelContext.processPendingChanges()
                            queryVersion += 1 // Force query re-evaluation
                            refreshTrigger = UUID()
                        }
                    }
                }
                .id(refreshTrigger) // Force refresh when trigger changes
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
    
    // Paginated expenses - only show up to displayedExpenseCount
    private var paginatedExpenses: [Expense] {
        Array(filteredExpenses.prefix(displayedExpenseCount))
    }
    
    // Paginated grouped expenses
    private var paginatedGroupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: paginatedExpenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    // Check if there are more expenses to load
    private var hasMoreExpenses: Bool {
        filteredExpenses.count > displayedExpenseCount
    }
    
    // Calculate remaining expense count (cached to avoid repeated computation)
    private var remainingExpenseCount: Int {
        max(0, filteredExpenses.count - displayedExpenseCount)
    }
    
    private var groupedExpenses: [Date: [Expense]] {
        Dictionary(grouping: expenses) { expense in
            Calendar.current.startOfDay(for: expense.date)
        }
    }
    
    // Load more expenses (increase displayed count)
    private func loadMoreExpenses() {
        let totalCount = filteredExpenses.count
        let newCount = min(displayedExpenseCount + paginationBatchSize, totalCount)
        
        withAnimation {
            displayedExpenseCount = newCount
        }
    }
    
    private func clearFilters() {
        selectedCategory = nil
        minAmount = ""
        maxAmount = ""
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        endDate = Date()
        isFilteringByDate = false
        // Reset pagination when filters are cleared
        displayedExpenseCount = paginationBatchSize
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