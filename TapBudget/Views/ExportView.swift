import SwiftUI
import UniformTypeIdentifiers

struct ExportView: View {
    let expenses: [Expense]
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var showingShareSheet = false
    @State private var exportedFileURL: URL?
    
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
                    Button("Export") {
                        exportData()
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
        }
    }
    
    private func exportData() {
        let fileName = "expenses_\(Date().formatted(date: .numeric, time: .omitted))"
        let fileManager = FileManager.default
        let tempDirectory = fileManager.temporaryDirectory
        
        switch exportFormat {
        case .csv:
            let csvString = generateCSV()
            let fileURL = tempDirectory.appendingPathComponent("\(fileName).csv")
            try? csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedFileURL = fileURL
            
        case .pdf:
            let pdfData = generatePDF()
            let fileURL = tempDirectory.appendingPathComponent("\(fileName).pdf")
            try? pdfData.write(to: fileURL)
            exportedFileURL = fileURL
        }
        
        showingShareSheet = true
    }
    
    private func generateCSV() -> String {
        var csv = "Date,Category,Amount,Notes\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        expenses.forEach { expense in
            let date = dateFormatter.string(from: expense.date)
            let category = expense.category?.name ?? "Uncategorized"
            let amount = String(format: "%.2f", expense.amount)
            let notes = expense.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
            
            csv += "\(date),\(category),\(amount),\(notes)\n"
        }
        
        return csv
    }
    
    private func generatePDF() -> Data {
        // Implementation for PDF generation
        // This would require additional setup with PDFKit or other PDF generation libraries
        return Data()
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
} 