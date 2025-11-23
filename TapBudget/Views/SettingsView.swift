import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @Query private var expenses: [Expense]
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isDeleting = false
    @State private var categoryToDelete: Category?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            if categories.isEmpty {
                EmptyStateView.noCategories {
                    showingAddCategory = true
                }
                .navigationTitle("Settings")
                .sheet(isPresented: $showingAddCategory) {
                    CategoryFormView(mode: .add) { result in
                        showingAddCategory = false
                        handleCategoryResult(result)
                    }
                }
            } else {
                List {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(totalCategories)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Categories")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(totalExpenses)")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("Total Expenses")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section("Categories") {
                        ForEach(categories) { category in
                            CategoryRow(category: category, expenseCount: getExpenseCount(for: category)) {
                                editingCategory = category
                            }
                        }
                        .onDelete { indexSet in
                            if let firstIndex = indexSet.first, firstIndex < categories.count {
                                categoryToDelete = categories[firstIndex]
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                    
                }
                .navigationTitle("Settings")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddCategory = true }) {
                            Label("Add Category", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .sheet(isPresented: $showingAddCategory) {
                    CategoryFormView(mode: .add) { result in
                        showingAddCategory = false
                        handleCategoryResult(result)
                    }
                }
                .sheet(item: $editingCategory) { category in
                    CategoryFormView(mode: .edit(category)) { result in
                        editingCategory = nil
                        handleCategoryResult(result)
                    }
                }
                .alert("Error", isPresented: $showingAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
                .toast(isPresented: $showingSuccess, message: successMessage, icon: "checkmark.circle.fill")
                .alert("Delete Category", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) {
                        categoryToDelete = nil
                    }
                    Button("Delete", role: .destructive) {
                        if let category = categoryToDelete {
                            deleteCategory(category)
                        }
                    }
                } message: {
                    if let category = categoryToDelete {
                        let expenseCount = getExpenseCount(for: category)
                        if expenseCount > 0 {
                            Text("This will delete '\(category.name)' and all \(expenseCount) associated expense\(expenseCount == 1 ? "" : "s"). This action cannot be undone.")
                        } else {
                            Text("Are you sure you want to delete '\(category.name)'?")
                        }
                    }
                }
            }
        }
    }
    
    private func getExpenseCount(for category: Category) -> Int {
        return expenses.filter { $0.category?.id == category.id }.count
    }
    
    private func deleteCategory(_ category: Category) {
        isDeleting = true
        
        Task {
            do {
                await MainActor.run {
                    modelContext.delete(category)
                }
                
                try await MainActor.run {
                    try modelContext.save()
                }
                
                await MainActor.run {
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    isDeleting = false
                    categoryToDelete = nil
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to delete category: \(error.localizedDescription)"
                    showingAlert = true
                    isDeleting = false
                    categoryToDelete = nil
                }
            }
        }
    }
    
    private func handleCategoryResult(_ result: Result<Void, CategoryError>) {
        switch result {
        case .success:
            successMessage = "Category saved successfully"
            showingSuccess = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .failure(let error):
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private var totalExpenses: Int {
        expenses.count
    }
    
    private var totalCategories: Int {
        categories.count
    }
}

struct CategoryRow: View {
    let category: Category
    let expenseCount: Int
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: category.icon ?? "questionmark.circle")
                .foregroundColor(Color(hex: category.color ?? "#FF0000"))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name ?? "Unnamed Category")
                HStack(spacing: 8) {
                    Text("Budget: \(category.budget.formattedAsCurrency())")
                    if expenseCount > 0 {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text("\(expenseCount) expense\(expenseCount == 1 ? "" : "s")")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct CategoryFormView: View {
    enum FormMode {
        case add
        case edit(Category)
    }
    
    let mode: FormMode
    let onSave: (Result<Void, CategoryError>) -> Void
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon: String? = nil
    @State private var budgetString = ""
    @State private var color: String? = nil
    @State private var nameError: String?
    @State private var isSaving = false
    @FocusState private var budgetFieldIsFocused: Bool
    
    private var budget: Double? {
        if budgetString.isEmpty {
            return nil
        }
        return Double(budgetString)
    }
    
    private let icons = AppConstants.availableIcons
    private let colors = AppConstants.availableColors
    
    private var navigationTitle: String {
        switch mode {
        case .add:
            return "New Category"
        case .edit:
            return "Edit Category"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Category Name", text: $name)
                        .onChange(of: name) { _, newValue in
                            validateName(newValue)
                        }
                    
                    if let error = nameError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section("Icon") {
                    if icon == nil {
                        Text("Please select an icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(icons, id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(icon == iconName ? .accentColor : .primary)
                                    .onTapGesture {
                                        icon = iconName
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Section("Color") {
                    if color == nil {
                        Text("Please select a color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: (color == colorHex) ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        color = colorHex
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Section("Budget") {
                    HStack {
                        Text("$")
                        TextField("Monthly Budget", text: $budgetString)
                            .keyboardType(.decimalPad)
                            .focused($budgetFieldIsFocused)
                            .onChange(of: budgetFieldIsFocused) { _, isFocused in
                                if isFocused && budgetString == "0" {
                                    budgetString = ""
                                }
                            }
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                    }
                    .disabled(!isFormValid || isSaving)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        budgetFieldIsFocused = false
                    }
                }
            }
            .onAppear {
                if case .edit(let category) = mode {
                    name = category.name ?? ""
                    icon = category.icon ?? AppConstants.defaultCategoryIcon
                    budgetString = category.budget > 0 ? String(format: "%.2f", category.budget).replacingOccurrences(of: ".00", with: "") : ""
                    color = category.color ?? AppConstants.defaultCategoryColor
                } else {
                    // For new category, start with empty values - user must select everything
                    name = ""
                    icon = nil
                    budgetString = ""
                    color = nil
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let hasValidName = !trimmedName.isEmpty &&
                          trimmedName.count >= AppConstants.minCategoryNameLength &&
                          trimmedName.count <= AppConstants.maxCategoryNameLength &&
                          nameError == nil
        
        // Check if budget is entered and valid
        let hasValidBudget: Bool
        if let budgetValue = budget {
            hasValidBudget = budgetValue > 0
        } else {
            hasValidBudget = false
        }
        
        // Require icon and color to be selected
        let hasSelectedIcon = icon != nil
        let hasSelectedColor = color != nil
        
        return hasValidName && hasValidBudget && hasSelectedIcon && hasSelectedColor
    }
    
    private func validateName(_ name: String) {
        let validation = DataValidator.validateCategoryName(name)
        nameError = validation.errorMessage
    }
    
    private func saveCategory() {
        // Comprehensive validation
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard let budgetValue = budget, budgetValue >= 0 else {
            onSave(.failure(.validationFailed("Please enter a valid budget amount")))
            return
        }
        
        guard let selectedIcon = icon else {
            onSave(.failure(.validationFailed("Please select an icon")))
            return
        }
        
        guard let selectedColor = color else {
            onSave(.failure(.validationFailed("Please select a color")))
            return
        }
        
        let validation = DataValidator.validateCategory(
            name: trimmedName,
            icon: selectedIcon,
            budget: budgetValue,
            color: selectedColor
        )
        
        guard validation.isValid else {
            onSave(.failure(.validationFailed(validation.errorMessage ?? "Invalid input")))
            return
        }
        
        isSaving = true
        
        Task {
            let finalBudget = max(0, budgetValue)
            
            do {
                await MainActor.run {
                    switch mode {
                    case .add:
                        let category = Category(name: trimmedName, icon: selectedIcon, budget: finalBudget, color: selectedColor)
                        modelContext.insert(category)
                        
                    case .edit(let category):
                        category.name = trimmedName
                        category.icon = selectedIcon
                        category.budget = finalBudget
                        category.color = selectedColor
                    }
                }
                
                try await MainActor.run {
                    try modelContext.save()
                }
                
                await MainActor.run {
                    isSaving = false
                    onSave(.success(()))
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    onSave(.failure(.saveFailed(error.localizedDescription)))
                }
            }
        }
    }
}

// MARK: - Category Errors
enum CategoryError: LocalizedError {
    case invalidInput
    case validationFailed(String)
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "Please enter a valid category name and budget"
        case .validationFailed(let message):
            return message
        case .saveFailed(let message):
            return "Failed to save category: \(message)"
        }
    }
} 