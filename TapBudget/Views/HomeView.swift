import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showingQuickEntry = false
    @State private var selectedAmount = ""
    @State private var selectedCategory: Category?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @FocusState private var amountFieldIsFocused: Bool
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Monthly summary card
                    MonthlySummaryCard()
                    
                    // Quick expense entry
                    VStack(alignment: .leading) {
                        Text("Quick Add")
                            .font(.headline)
                        
                        // Amount input
                        HStack {
                            Text("$")
                            TextField("Amount", text: $selectedAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .focused($amountFieldIsFocused)
                        }
                        
                        // Category grid
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 15) {
                            ForEach(categories) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id,
                                    action: { 
                                        selectedCategory = category
                                        // Optionally dismiss keyboard when category is selected
                                        amountFieldIsFocused = false
                                    }
                                )
                            }
                        }
                        
                        // Save button
                        Button(action: saveQuickExpense) {
                            Text("Save Expense")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(15)
                    .shadow(radius: 2)
                }
                .padding()
            }
            .navigationTitle("TapBudget")
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    Button("Done") {
                        amountFieldIsFocused = false
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveQuickExpense() {
        guard let category = selectedCategory,
              let amount = Double(selectedAmount),
              amount > 0 else {
            alertMessage = "Please enter a valid amount and select a category"
            showingAlert = true
            return
        }
        
        let viewModel = ExpenseViewModel(modelContext: modelContext)
        viewModel.addExpense(amount: amount, category: category)
        
        // Reset form
        selectedAmount = ""
        selectedCategory = nil
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: category.icon)
                    .font(.title2)
                Text(category.name)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
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
            .cornerRadius(10)
        }
    }
} 