import SwiftUI
import SwiftData

struct CategoriesView: View {
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
                .navigationTitle("Categories")
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
                    
                    Section {
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
                .navigationTitle("Categories")
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

