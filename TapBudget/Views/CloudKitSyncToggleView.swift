import SwiftUI
import SwiftData

/// Settings view for CloudKit sync toggle
struct CloudKitSyncToggleView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isCloudKitEnabled: Bool = CloudKitPreferenceManager.shared.isCloudKitEnabled
    @State private var showingDisableWarning = false
    @State private var showingEnableInfo = false
    @State private var isSyncing = false
    
    var body: some View {
        HStack {
            Image(systemName: "icloud.fill")
                .foregroundColor(.cyan)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("iCloud Sync")
                    .font(.body)
                
                if isSyncing {
                    Text("Syncing...")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text(isCloudKitEnabled ? "Syncing across devices" : "Local storage only")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { isCloudKitEnabled },
                set: { newValue in
                    if newValue {
                        // Enabling CloudKit - trigger sync
                        isCloudKitEnabled = true
                        CloudKitPreferenceManager.shared.isCloudKitEnabled = true
                        print("✅ CloudKit sync enabled by user")
                        
                        // Trigger sync after enabling
                        Task {
                            await triggerCloudKitSync()
                        }
                    } else {
                        // Disabling CloudKit - show warning
                        showingDisableWarning = true
                    }
                }
            ))
            .toggleStyle(.switch)
        }
        .alert("Disable iCloud Sync?", isPresented: $showingDisableWarning) {
            Button("Cancel", role: .cancel) {
                // Reset toggle to enabled
                isCloudKitEnabled = true
            }
            Button("Disable", role: .destructive) {
                isCloudKitEnabled = false
                CloudKitPreferenceManager.shared.isCloudKitEnabled = false
                print("⚠️ CloudKit sync disabled by user")
            }
        } message: {
            Text("Your data will remain on this device only. You can enable iCloud sync again anytime. Note: You'll need to restart the app for this change to take effect.")
        }
    }
    
    /// Trigger CloudKit sync when enabled
    private func triggerCloudKitSync() async {
        guard CloudKitPreferenceManager.shared.shouldEnableCloudKit else {
            return
        }
        
        isSyncing = true
        
        do {
            // Trigger sync
            try await CloudKitSyncManager.shared.triggerSwiftDataCloudKitSync(modelContext: modelContext)
            
            // Wait for sync to complete
            _ = await CloudKitSyncManager.shared.waitForCloudKitSync(
                modelContext: modelContext,
                timeoutSeconds: 30
            )
            
            // Post notification to refresh all views
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("CloudKitSyncCompleted"),
                    object: nil
                )
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                isSyncing = false
                print("Error triggering CloudKit sync: \(error.localizedDescription)")
            }
        }
    }
}

