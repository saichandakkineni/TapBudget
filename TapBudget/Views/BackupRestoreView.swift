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
    @State private var isError = true // Track if alert is for error or success
    @State private var isBackingUp = false
    @State private var isRestoring = false
    
    // CloudKit sync refresh state
    @State private var isRefreshingSync = false
    @State private var cloudKitStatus: CloudKitStatus = .unknown
    @State private var lastSyncTime: Date?
    @State private var refreshTrigger = UUID() // Force view refresh after sync
    
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
            
            // iCloud Sync Refresh Section (only show when CloudKit sync is enabled)
            if CloudKitPreferenceManager.shared.shouldEnableCloudKit {
                Section {
                    Button(action: refreshCloudKitSync) {
                        HStack {
                            if isRefreshingSync {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isRefreshingSync ? "Refreshing..." : "Refresh Sync")
                        }
                    }
                    .disabled(isRefreshingSync || isBackingUp || isRestoring)
                    
                    // Show sync status
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Sync Status:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(syncStatusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(syncStatusColor)
                        }
                        
                        if let lastSync = lastSyncTime {
                            Text("Last sync: \(lastSync.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("iCloud Sync")
                } footer: {
                    Text("Manually refresh sync with iCloud. This will sync local changes to iCloud and pull updates from iCloud. Your data syncs automatically, but you can force a refresh if needed.")
                }
            }
        }
        .navigationTitle("Backup & Restore")
        .task {
            // Check CloudKit status on appear
            await checkCloudKitStatus()
        }
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
                isError = true
                showingError = true
            }
        }
        .alert(isError ? "Restore Error" : "Restore Successful", isPresented: $showingError) {
            Button("OK", role: .cancel) {
                // Post notification after alert is dismissed so views can refresh
                let syncInfo: [String: Any] = [
                    "expenseCount": 0,
                    "categoryCount": 0,
                    "error": ""
                ]
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloudKitSyncCompleted"),
                    object: nil,
                    userInfo: syncInfo
                )
                refreshTrigger = UUID()
            }
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
                    isError = true
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
                    isError = true
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
                    isError = false
                    showingError = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to restore backup: \(error.localizedDescription)"
                    isError = true
                    showingError = true
                    isRestoring = false
                }
            }
        }
    }
    
    // MARK: - CloudKit Sync Methods
    
    /// Check CloudKit sync status
    private func checkCloudKitStatus() async {
        cloudKitStatus = await CloudKitSyncManager.shared.checkCloudKitStatus()
    }
    
    /// Perform CloudKit sync with proper waiting for async operations
    private func performCloudKitSync() async {
        do {
            // Step 1: Process and save local changes first (push to iCloud)
            await MainActor.run {
                modelContext.processPendingChanges()
                try? modelContext.save()
            }
            
            // Step 2: Trigger CloudKit sync
            try await CloudKitSyncManager.shared.triggerSwiftDataCloudKitSync(modelContext: modelContext)
            
            // Step 3: Wait for CloudKit sync to complete
            let syncComplete = await CloudKitSyncManager.shared.waitForCloudKitSync(
                modelContext: modelContext,
                timeoutSeconds: 30
            )
            
            // Step 4: Final fetch and process
            await MainActor.run {
                let expenseDescriptor = FetchDescriptor<Expense>()
                let categoryDescriptor = FetchDescriptor<Category>()
                
                _ = try? modelContext.fetch(expenseDescriptor)
                _ = try? modelContext.fetch(categoryDescriptor)
                
                modelContext.processPendingChanges()
                try? modelContext.save()
            }
            
            // Step 5: Check CloudKit to verify data exists
            let cloudKitData = await CloudKitSyncManager.shared.checkCloudKitDataExists()
            
            // Step 6: Show alert first, then post notification
            await MainActor.run {
                // Get updated counts
                let localExpenseCount = expenses.count
                let localCategoryCount = categories.count
                
                var message: String
                var isError = false
                
                if let error = cloudKitData.error {
                    message = "Sync completed, but CloudKit check failed: \(error). Data may still be syncing."
                    isError = false
                } else {
                    if cloudKitData.expenses > 0 || cloudKitData.categories > 0 {
                        message = "Sync refreshed! Found \(cloudKitData.expenses) expenses and \(cloudKitData.categories) categories in iCloud. Local: \(localExpenseCount) expenses, \(localCategoryCount) categories."
                    } else {
                        message = "Sync refreshed! Local changes uploaded. No data found in iCloud yet (this is normal for new installs)."
                    }
                }
                
                // Set alert state first
                errorMessage = message
                self.isError = isError
                isRefreshingSync = false
                
                // Show alert immediately - don't delay
                showingError = true
            }
            
            // Update lastSyncTime
            await MainActor.run {
                lastSyncTime = Date()
            }
            
            // Don't post notification or update refreshTrigger - let user dismiss alert first
            // This prevents the alert from being dismissed automatically
        } catch {
            await MainActor.run {
                errorMessage = "Failed to refresh sync: \(error.localizedDescription)"
                isError = true
                showingError = true
                isRefreshingSync = false
            }
        }
    }
    
    /// Refresh CloudKit sync
    private func refreshCloudKitSync() {
        guard CloudKitPreferenceManager.shared.shouldEnableCloudKit else {
            return
        }
        
        isRefreshingSync = true
        
        Task {
            // Check CloudKit status first
            let status = await CloudKitSyncManager.shared.checkCloudKitStatus()
            
            await MainActor.run {
                cloudKitStatus = status
                
                switch status {
                case .available:
                    // Trigger bidirectional sync with proper waiting for CloudKit
                    // Don't set isRefreshingSync = false here, let performCloudKitSync handle it
                    Task {
                        await performCloudKitSync()
                    }
                    return // Exit early, performCloudKitSync will handle completion
                case .noAccount:
                    errorMessage = "Please sign in to iCloud to sync your data."
                    isError = true
                    showingError = true
                case .restricted:
                    errorMessage = "iCloud is restricted on this device."
                    isError = true
                    showingError = true
                case .unknown:
                    errorMessage = "Unable to determine iCloud status. Please check your iCloud settings."
                    isError = true
                    showingError = true
                case .error(let message):
                    errorMessage = "Sync error: \(message)"
                    isError = true
                    showingError = true
                }
                
                isRefreshingSync = false
            }
        }
    }
    
    /// Get sync status text
    private var syncStatusText: String {
        switch cloudKitStatus {
        case .available:
            return "Synced"
        case .noAccount:
            return "Not Signed In"
        case .restricted:
            return "Restricted"
        case .unknown:
            return "Unknown"
        case .error(let message):
            return "Error"
        }
    }
    
    /// Get sync status color
    private var syncStatusColor: Color {
        switch cloudKitStatus {
        case .available:
            return .green
        case .noAccount, .restricted, .unknown:
            return .orange
        case .error:
            return .red
        }
    }
}

