import SwiftUI

struct CategoryPickerView: View {
    let categories: [Category]
    let filteredCategories: [Category]
    @Binding var selectedCategory: Category?
    @Binding var searchText: String
    let budgetStatuses: [String: BudgetAlertManager.BudgetStatus]
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search categories", text: $searchText)
                        .focused($isSearchFocused)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()
                
                // Category list
                if filteredCategories.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No categories found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try a different search term")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(filteredCategories) { category in
                            CategoryPickerRow(
                                category: category,
                                isSelected: selectedCategory?.id == category.id,
                                budgetStatus: budgetStatuses[category.id]
                            ) {
                                selectedCategory = category
                                dismiss()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isSearchFocused = true
            }
        }
    }
}

struct CategoryPickerRow: View {
    let category: Category
    let isSelected: Bool
    let budgetStatus: BudgetAlertManager.BudgetStatus?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: category.color).opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: category.icon)
                        .foregroundColor(Color(hex: category.color))
                        .font(.title3)
                }
                
                // Category info
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    if category.budget > 0 {
                        HStack(spacing: 4) {
                            Text("Budget: \(category.budget.formattedAsCurrency())")
                            if let status = budgetStatus {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("\(Int(status.percentage * 100))% used")
                                    .foregroundColor(status.statusColor)
                            }
                        }
                        .font(.caption)
                    } else {
                        Text("No budget set")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

