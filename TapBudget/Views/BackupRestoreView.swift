import SwiftUI
import SwiftData

/// View for backup and restore functionality
struct BackupRestoreView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @Query private var categories: [Category]
    @Query private var templates: [ExpenseTemplate]
    @Query private var recurringExpenses: [RecurringExpense]
    
    @State private var showingShareSheet = false
    @State private var backupURL: URL?
    @State private var showingRestoreAlert = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isBackingUp = false
    @State private var isRestoring = false
    
    var body: some View {
        List {
            Section {
                Button(action: createBackup) {
                    HStack {
                        if isBackingUp {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                        Text(isBackingUp ? "Creating Backup..." : "Create Backup")
                    }
                }
                .disabled(isBackingUp || isRestoring)
                
                if !expenses.isEmpty || !categories.isEmpty {
                    Text("\(expenses.count) expenses, \(categories.count) categories")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("Create a backup file containing all your expenses, categories, templates, and recurring expenses.")
            }
            
            Section {
                Button(action: { showingRestoreAlert = true }) {
                    HStack {
                        if isRestoring {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text(isRestoring ? "Restoring..." : "Restore from Backup")
                    }
                }
                .disabled(isBackingUp || isRestoring)
            } header: {
                Text("Restore")
            } footer: {
                Text("Restore your data from a previously created backup file. This will replace all current data.")
            }
        }
        .navigationTitle("Backup & Restore")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if let url = backupURL {
                ShareSheet(items: [url])
            }
        }
        .fileImporter(
            isPresented: $showingRestoreAlert,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    restoreBackup(from: url)
                }
            case .failure(let error):
                errorMessage = "Failed to select file: \(error.localizedDescription)"
                showingError = true
            }
        }
        .alert("Restore Error", isPresented: $showingError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func createBackup() {
        isBackingUp = true
        
        Task {
            guard let backupData = BackupManager.shared.createBackup(
                expenses: expenses,
                categories: categories,
                templates: templates,
                recurringExpenses: recurringExpenses
            ) else {
                await MainActor.run {
                    errorMessage = "Failed to create backup"
                    showingError = true
                    isBackingUp = false
                }
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let fileName = "TapBudget_Backup_\(dateFormatter.string(from: Date())).json"
            
            let fileManager = FileManager.default
            let tempDirectory = fileManager.temporaryDirectory
            let fileURL = tempDirectory.appendingPathComponent(fileName)
            
            do {
                try backupData.write(to: fileURL)
                await MainActor.run {
                    backupURL = fileURL
                    showingShareSheet = true
                    isBackingUp = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save backup: \(error.localizedDescription)"
                    showingError = true
                    isBackingUp = false
                }
            }
        }
    }
    
    private func restoreBackup(from url: URL) {
        isRestoring = true
        
        Task {
            do {
                let data = try Data(contentsOf: url)
                
                // Clear existing data
                await MainActor.run {
                    // Delete all existing data
                    expenses.forEach { modelContext.delete($0) }
                    categories.forEach { modelContext.delete($0) }
                    templates.forEach { modelContext.delete($0) }
                    recurringExpenses.forEach { modelContext.delete($0) }
                    
                    try? modelContext.save()
                }
                
                // Restore from backup
                try BackupManager.shared.restoreBackup(data: data, modelContext: modelContext)
                
                await MainActor.run {
                    isRestoring = false
                    // Show success message
                    errorMessage = "Backup restored successfully!"
                    showingError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to restore backup: \(error.localizedDescription)"
                    showingError = true
                    isRestoring = false
                }
            }
        }
    }
}

