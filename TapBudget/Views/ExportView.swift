import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isExporting = false
    
    enum ExportFormat: String, CaseIterable {
        case csv = "CSV"
        case pdf = "PDF"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue)
                        }
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
                    .disabled(isExporting || expenses.isEmpty)
                    
                    if expenses.isEmpty {
                        Text("No expenses to export")
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
    
    private func exportData() {
        guard !expenses.isEmpty else {
            errorMessage = "No expenses to export"
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
                    let csvString = generateCSV()
                    let fileURL = tempDirectory.appendingPathComponent("\(fileName).csv")
                    try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
                    await MainActor.run {
                        exportedFileURL = fileURL
                        showingShareSheet = true
                        isExporting = false
                    }
                    
                case .pdf:
                    let pdfData = generatePDF()
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
                    errorMessage = "Failed to export expenses: \(error.localizedDescription)"
                    showingError = true
                    isExporting = false
                }
            }
        }
    }
    
    private func generateCSV() -> String {
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
    
    private func generatePDF() -> Data {
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