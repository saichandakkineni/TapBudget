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
    @State private var showingSuccess = false
    @State private var successMessage = ""
    @State private var isSaving = false
    @FocusState private var amountFieldIsFocused: Bool
    
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
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: AppConstants.categoryGridColumns),
                            spacing: AppConstants.categoryGridSpacing
                        ) {
                            ForEach(categories) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory?.id == category.id,
                                    action: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                            selectedCategory = category
                                        }
                                        // Haptic feedback for selection
                                        let generator = UISelectionFeedbackGenerator()
                                        generator.selectionChanged()
                                        // Dismiss keyboard when category is selected
                                        amountFieldIsFocused = false
                                    }
                                )
                            }
                        }
                        
                        // Save button
                        Button(action: saveQuickExpense) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                                Text(isSaving ? "Saving..." : "Save Expense")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(canSave ? Color.accentColor : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!canSave)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(AppConstants.cardCornerRadius)
                    .shadow(radius: AppConstants.cardShadowRadius)
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
            .toast(isPresented: $showingSuccess, message: successMessage, icon: "checkmark.circle.fill")
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
                
                await MainActor.run {
                    // Show success feedback with toast
                    successMessage = "\(amount.formattedAsCurrency()) added to \(category.name)"
                    showingSuccess = true
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    
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
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .symbolEffect(.bounce, value: isSelected)
                Text(category.name)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
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
                    .stroke(isSelected ? Color(hex: category.color) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(.plain)
    }
} 