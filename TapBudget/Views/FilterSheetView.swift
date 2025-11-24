import SwiftUI

/// Filter sheet for expense list
struct FilterSheetView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]
    @Binding var minAmount: String
    @Binding var maxAmount: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isFilteringByDate: Bool
    let onClear: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All Categories").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                }
                
                Section("Amount Range") {
                    HStack {
                        Text("Min")
                        TextField("0.00", text: $minAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Max")
                        TextField("0.00", text: $maxAmount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Date Range") {
                    Toggle("Filter by Date", isOn: $isFilteringByDate)
                    
                    if isFilteringByDate {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear All") {
                        onClear()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

