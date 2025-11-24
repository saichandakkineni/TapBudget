import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    // Optimize: Only fetch expenses from last 6 months for budget calculations
    // This reduces memory usage while still providing enough data for budget alerts
    @Query private var expenses: [Expense]
    @Query(filter: #Predicate<ExpenseTemplate> { $0.isActive == true }) private var templates: [ExpenseTemplate]
    
    // Initialize query with date predicate for recent expenses only
    init() {
        // Fetch expenses from last 6 months (sufficient for budget calculations)
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()
        _expenses = Query(
            filter: #Predicate<Expense> { expense in
                expense.date >= sixMonthsAgo
            },
            sort: \Expense.date,
            order: .reverse
        )
    }
    @State private var showingQuickEntry = false
    @State private var selectedAmount = ""
    @State private var selectedCategory: Category?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isSaving = false
    @FocusState private var amountFieldIsFocused: Bool
    @State private var budgetStatuses: [String: BudgetAlertManager.BudgetStatus] = [:]
    @State private var showingBudgetAlert = false
    @State private var budgetAlertMessage = ""
    
    private var canSave: Bool {
        selectedCategory != nil && 
        !selectedAmount.isEmpty && 
        Double(selectedAmount) != nil &&
        !isSaving
    }
    
    private var expenseViewModel: ExpenseViewModel {
        ExpenseViewModel(modelContext: modelContext)
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    @State private var searchText = ""
    @State private var showingCategoryPicker = false
    
    private var filteredCategories: [Category] {
        if searchText.isEmpty {
            return categories
        }
        return categories.filter { category in
            category.name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 20) {
                        // iCloud Sync Banner (shown if user skipped onboarding and CloudKit is available)
                        CloudKitSyncBanner()
                        
                        // Monthly summary card
                        MonthlySummaryCard()
                        
                        // Quick expense entry
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Quick Add")
                                .font(.headline)
                            
                            // Templates section
                            if !templates.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Templates")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(templates.prefix(5)) { template in
                                                TemplateQuickButton(template: template) {
                                                    addFromTemplate(template)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // Amount input
                            HStack {
                                Text(CurrencyManager.shared.selectedCurrency.symbol)
                                TextField("Amount", text: $selectedAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .focused($amountFieldIsFocused)
                                    .accessibilityLabel("Expense amount")
                                    .accessibilityHint("Enter the amount you spent")
                            }
                            
                            // Category picker button
                            Button {
                                showingCategoryPicker = true
                                amountFieldIsFocused = false
                            } label: {
                                HStack {
                                    if let category = selectedCategory {
                                        HStack(spacing: 8) {
                                            Image(systemName: category.icon)
                                                .foregroundColor(Color(hex: category.color))
                                            Text(category.name)
                                                .foregroundColor(.primary)
                                        }
                                    } else {
                                        HStack(spacing: 8) {
                                            Image(systemName: "folder")
                                                .foregroundColor(.secondary)
                                            Text("Select Category")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                        .font(.caption)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(AppConstants.cardCornerRadius)
                        .shadow(radius: AppConstants.cardShadowRadius)
                    }
                    .padding()
                    .padding(.bottom, 90) // Space for sticky button
                }
                
                // Sticky Save Button
                VStack {
                    Spacer()
                    Button(action: saveQuickExpense) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSaving ? "Saving..." : "Save Expense")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canSave ? Color.accentColor : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canSave)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 100)
                        .allowsHitTesting(false)
                    )
                    .accessibleButton(label: isSaving ? "Saving expense" : "Save expense", hint: canSave ? "Double tap to save the expense" : "Please select a category and enter an amount")
                }
            }
            .navigationTitle("TapBudget")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        amountFieldIsFocused = false
                    }
                }
            }
            .sheet(isPresented: $showingCategoryPicker) {
                CategoryPickerView(
                    categories: categories,
                    filteredCategories: filteredCategories,
                    selectedCategory: $selectedCategory,
                    searchText: $searchText,
                    budgetStatuses: budgetStatuses
                )
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(ErrorHandler.shared.userFriendlyMessage(for: NSError(domain: "ExpenseError", code: 0, userInfo: [NSLocalizedDescriptionKey: alertMessage])))
            }
            .toast(isPresented: $showingSuccess, message: successMessage, icon: "checkmark.circle.fill")
            .task {
                // Calculate budget statuses on appear
                updateBudgetStatuses()
            }
            .onChange(of: expenses.count) { _, _ in
                // Update budget statuses when expenses change
                updateBudgetStatuses()
            }
        }
    }
    
    /// Update budget statuses for all categories
    private func updateBudgetStatuses() {
        guard let monthRange = DateFilterHelper.currentMonthRange() else { return }
        
        var statuses: [String: BudgetAlertManager.BudgetStatus] = [:]
        
        for category in categories {
            let status = BudgetAlertManager.shared.calculateBudgetStatus(
                for: category,
                expenses: expenses,
                monthRange: monthRange
            )
            statuses[category.id] = status
        }
        
        budgetStatuses = statuses
    }
    
    /// Check budgets and show in-app alerts
    private func checkAndShowBudgetAlerts() async {
        // Send push notifications
        await BudgetAlertManager.shared.checkBudgetsAndSendAlerts(
            modelContext: modelContext,
            expenses: expenses
        )
        
        // Show in-app alert for critical/exceeded budgets
        guard let monthRange = DateFilterHelper.currentMonthRange() else { return }
        
        for category in categories {
            guard category.budget > 0 else { continue }
            
            let status = BudgetAlertManager.shared.calculateBudgetStatus(
                for: category,
                expenses: expenses,
                monthRange: monthRange
            )
            
            if status.status == .exceeded {
                budgetAlertMessage = "⚠️ \(category.name) budget exceeded by \((status.spent - status.budget).formattedAsCurrency())"
                showingBudgetAlert = true
                break // Show only one alert at a time
            } else if status.status == .critical && status.percentage >= 0.95 {
                budgetAlertMessage = "🚨 \(category.name) budget at \(Int(status.percentage * 100))% - Only \(status.remaining.formattedAsCurrency()) remaining"
                showingBudgetAlert = true
                break
            }
        }
    }
    
    private func saveQuickExpense() {
        guard let category = selectedCategory else {
            alertMessage = "Please select a category"
            showingAlert = true
            return
        }
        
        guard let amount = Double(selectedAmount) else {
            alertMessage = "Please enter a valid amount"
            showingAlert = true
            return
        }
        
        // Comprehensive validation
        let validation = DataValidator.validateExpense(amount: amount, category: category, notes: nil)
        if case .invalid(let message) = validation {
            alertMessage = message
            showingAlert = true
            return
        }
        
        isSaving = true
        
        Task {
            do {
                try expenseViewModel.addExpense(amount: amount, category: category)
                
                // Check budget alert for this specific category only
                await BudgetAlertManager.shared.checkBudgetAndSendAlert(
                    for: category,
                    modelContext: modelContext,
                    expenses: expenses
                )
                
                await MainActor.run {
                    // Show success feedback with toast
                    successMessage = "\(amount.formattedAsCurrency()) added to \(category.name)"
                    showingSuccess = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    // Update widget data
                    updateWidgetData()
                    
                    // Reset form after a brief delay
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await MainActor.run {
                            selectedAmount = ""
                            selectedCategory = nil
                            amountFieldIsFocused = false
                            isSaving = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    isSaving = false
                }
            }
        }
    }
    
    private func addFromTemplate(_ template: ExpenseTemplate) {
        guard let category = template.category ?? categories.first else {
            alertMessage = "Please create a category first"
            showingAlert = true
            return
        }
        
        Task {
            do {
                try expenseViewModel.addExpense(
                    amount: template.amount,
                    category: category,
                    notes: template.notes
                )
                
                // Check budget alert for this specific category only
                await BudgetAlertManager.shared.checkBudgetAndSendAlert(
                    for: category,
                    modelContext: modelContext,
                    expenses: expenses
                )
                
                await MainActor.run {
                    successMessage = "\(template.name) added: \(template.amount.formattedAsCurrency())"
                    showingSuccess = true
                    
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
                    updateWidgetData()
                }
            } catch {
                await MainActor.run {
                    alertMessage = error.localizedDescription
                    showingAlert = true
                }
            }
        }
    }
    
    private func updateWidgetData() {
        // Calculate monthly total and count for widget
        guard let monthRange = DateFilterHelper.currentMonthRange() else { return }
        
        // Extract tuple values for use in predicate
        let startOfMonth = monthRange.start
        let endOfMonth = monthRange.end
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { expense in
                expense.date >= startOfMonth && expense.date < endOfMonth
            }
        )
        
        do {
            let monthlyExpenses = try modelContext.fetch(descriptor)
            let monthlyTotal = monthlyExpenses.reduce(0) { $0 + $1.amount }
            let expenseCount = monthlyExpenses.count
            
            WidgetDataManager.shared.updateMonthlySummary(
                monthlyTotal: monthlyTotal,
                expenseCount: expenseCount
            )
        } catch {
            print("Error updating widget data: \(error.localizedDescription)")
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let budgetStatus: BudgetAlertManager.BudgetStatus?
    let action: () -> Void
    
    private var alertBadge: some View {
        Group {
            if let status = budgetStatus, category.budget > 0 {
                switch status.status {
                case .warning:
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                case .critical:
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                case .exceeded:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                case .safe:
                    EmptyView()
                }
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Image(systemName: category.icon)
                        .font(.title2)
                        .symbolEffect(.bounce, value: isSelected)
                    
                    // Budget alert badge
                    VStack {
                        HStack {
                            Spacer()
                            alertBadge
                                .padding(4)
                        }
                        Spacer()
                    }
                }
                
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                // Budget progress indicator
                if let status = budgetStatus, category.budget > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color(.systemGray5))
                                .frame(height: 2)
                            
                            Rectangle()
                                .fill(status.statusColor)
                                .frame(width: geometry.size.width * min(1.0, status.percentage), height: 2)
                        }
                    }
                    .frame(height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppConstants.categoryButtonVerticalPadding)
            .background(
                isSelected ? 
                    Color(hex: category.color).opacity(0.2) : 
                    Color(.systemGray6)
            )
            .foregroundColor(
                isSelected ? 
                    Color(hex: category.color) : 
                    .primary
            )
            .cornerRadius(AppConstants.cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.cardCornerRadius)
                    .stroke(
                        isSelected ? Color(hex: category.color) : 
                        (budgetStatus?.status == .critical || budgetStatus?.status == .exceeded) ? 
                        budgetStatus?.statusColor.opacity(0.5) ?? Color.clear : Color.clear,
                        lineWidth: 2
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
} 