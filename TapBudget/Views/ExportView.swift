import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ExportView: View {
    let expenses: [Expense]
    @Query private var categories: [Category]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isExporting = false
    @State private var selectedCategory: Category?
    @State private var useDateRange = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate: Date = Date()
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                        }
                    }
                }
                
                Section("Filter Options") {
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
                    
                    Toggle("Filter by Date Range", isOn: $useDateRange)
                    
                    if useDateRange {
                        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
                
                Section {
                    Button(action: exportData) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            }
                            Text(isExporting ? "Exporting..." : "Export")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isExporting || filteredExpenses.isEmpty)
                    .accessibleButton(label: isExporting ? "Exporting" : "Export expenses", hint: filteredExpenses.isEmpty ? "No expenses to export" : "Double tap to export")
                    
                    if filteredExpenses.isEmpty {
                        Text("No expenses match the selected filters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s") will be exported")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Export Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingShareSheet, content: {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            })
            .alert("Export Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var filteredExpenses: [Expense] {
        var filtered = expenses
        
        // Filter by category
        if let selectedCategory = selectedCategory {
            filtered = filtered.filter { $0.category?.id == selectedCategory.id }
        }
        
        // Filter by date range
        if useDateRange {
            filtered = filtered.filter { expense in
                expense.date >= startDate && expense.date <= endDate
            }
        }
        
        return filtered
    }
    
    private func exportData() {
        let expensesToExport = filteredExpenses
        
        guard !expensesToExport.isEmpty else {
            errorMessage = ErrorHandler.shared.userFriendlyMessage(for: NSError(domain: "ExportError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No expenses match the selected filters"]))
            showingError = true
            return
        }
        
        isExporting = true
        
        Task {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let fileName = "expenses_\(dateFormatter.string(from: Date()))"
            let fileManager = FileManager.default
            let tempDirectory = fileManager.temporaryDirectory
            
            do {
                switch exportFormat {
                case .csv:
                    let csvString = generateCSV(from: expensesToExport)
                    let fileURL = tempDirectory.appendingPathComponent("\(fileName).csv")
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                    await MainActor.run {
                        exportedFileURL = fileURL
                        showingShareSheet = true
                        isExporting = false
                    }
                    
                case .pdf:
                    let pdfData = generatePDF(from: expensesToExport)
                    let fileURL = tempDirectory.appendingPathComponent("\(fileName).pdf")
                    try pdfData.write(to: fileURL)
                    await MainActor.run {
                        exportedFileURL = fileURL
                        showingShareSheet = true
                        isExporting = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = ErrorHandler.shared.userFriendlyMessage(for: error)
                    showingError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func generateCSV(from expenses: [Expense]) -> String {
        var csv = "Date,Category,Amount,Notes\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        expenses.forEach { expense in
            let date = dateFormatter.string(from: expense.date)
            let category = expense.category?.name ?? "Uncategorized"
            let amount = expense.amount.formattedAsCurrency()
            let notes = expense.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(date),\(category),\(amount),\(notes)\n"
        }
        
        return csv
    }
    
    private func generatePDF(from expenses: [Expense]) -> Data {
        return PDFGenerator.generatePDF(from: expenses)
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 