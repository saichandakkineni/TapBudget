import SwiftUI
import SwiftData

/// Settings view for configuring budget alerts
struct BudgetAlertSettingsView: View {
    @State private var alertsEnabled: Bool = BudgetAlertManager.shared.alertsEnabled
    @State private var thresholds: [BudgetAlertManager.AlertThreshold] = BudgetAlertManager.shared.alertThresholds
    @State private var showingAddThreshold = false
    @State private var newThresholdPercentage: String = ""
    @State private var showingAlertHistory = false
    @State private var showingClearConfirmation = false
    @State private var showingClearSuccess = false
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Budget Alerts", isOn: $alertsEnabled)
                    .onChange(of: alertsEnabled) { _, newValue in
                        BudgetAlertManager.shared.alertsEnabled = newValue
                    }
            } footer: {
                Text("Receive notifications when you approach or exceed your budget limits")
            }
            
            if alertsEnabled {
                Section {
                    ForEach(thresholds.indices, id: \.self) { index in
                        ThresholdRow(
                            threshold: $thresholds[index],
                            onToggle: {
                                saveThresholds()
                            },
                            onDelete: {
                                BudgetAlertManager.shared.removeThreshold(at: index)
                                thresholds = BudgetAlertManager.shared.alertThresholds
                            }
                        )
                    }
                    
                    Button {
                        showingAddThreshold = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Custom Threshold")
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Alert Thresholds")
                } footer: {
                    Text("You'll receive alerts when spending reaches these percentages of your budget. Tap to enable/disable, swipe to delete.")
                }
                
                Section {
                    Button {
                        showingAlertHistory = true
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                            Text("View Alert History")
                        }
                        .foregroundColor(.blue)
                    }
                    
                    Button("Clear Alert History", role: .destructive) {
                        showingClearConfirmation = true
                    }
                } footer: {
                    Text("View alerts that have been sent or clear the history to allow alerts to be sent again for thresholds you've already reached today.")
                }
            }
        }
        .navigationTitle("Budget Alerts")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddThreshold) {
            AddThresholdView(
                onSave: { percentage in
                    BudgetAlertManager.shared.addThreshold(percentage: percentage)
                    thresholds = BudgetAlertManager.shared.alertThresholds
                    showingAddThreshold = false
                },
                onCancel: {
                    showingAddThreshold = false
                }
            )
        }
        .sheet(isPresented: $showingAlertHistory) {
            AlertHistoryView()
        }
        .alert("Clear Alert History", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearAlertHistory()
            }
        } message: {
            Text("Are you sure you want to clear all alert history? This will allow alerts to be sent again for thresholds you've already reached today.")
        }
        .toast(isPresented: $showingClearSuccess, message: "Alert history cleared successfully", icon: "checkmark.circle.fill")
    }
    
    private func clearAlertHistory() {
        BudgetAlertManager.shared.clearSentAlerts()
        showingClearSuccess = true
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func saveThresholds() {
        BudgetAlertManager.shared.alertThresholds = thresholds
    }
}

struct ThresholdRow: View {
    @Binding var threshold: BudgetAlertManager.AlertThreshold
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Toggle(isOn: Binding(
                get: { threshold.enabled },
                set: { newValue in
                    threshold = BudgetAlertManager.AlertThreshold(
                        percentage: threshold.percentage,
                        enabled: newValue
                    )
                    onToggle()
                }
            )) {
                Text("\(Int(threshold.percentage * 100))%")
                    .font(.body)
            }
            
            Spacer()
            
            if threshold.percentage >= 1.0 {
                Label("Exceeded", systemImage: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if threshold.percentage >= 0.9 {
                Label("Critical", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
            } else {
                Label("Warning", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

struct AddThresholdView: View {
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    @State private var percentageString = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("%")
                            .foregroundColor(.secondary)
                        TextField("Percentage", text: $percentageString)
                            .keyboardType(.decimalPad)
                            .focused($isFocused)
                    }
                } header: {
                    Text("Threshold Percentage")
                } footer: {
                    Text("Enter a value between 1 and 100. For example, 75 for 75% of budget.")
                }
                
                Section {
                    if let percentage = Double(percentageString), percentage >= 1 && percentage <= 100 {
                        Text("Alert will trigger at \(Int(percentage))% of budget")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if !percentageString.isEmpty {
                        Text("Please enter a value between 1 and 100")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Threshold")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let percentage = Double(percentageString),
                           percentage >= 1 && percentage <= 100 {
                            onSave(percentage / 100.0)
                        }
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }
    
    private var isValid: Bool {
        guard let percentage = Double(percentageString) else { return false }
        return percentage >= 1 && percentage <= 100
    }
}

struct AlertHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var alertHistory: [BudgetAlertManager.AlertHistoryItem] = []
    @State private var categoryMap: [String: Category] = [:]
    
    var body: some View {
        NavigationStack {
            Group {
                if alertHistory.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("No Alerts Sent")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Budget alerts that have been sent will appear here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(alertHistory) { item in
                            AlertHistoryRow(
                                item: item,
                                category: categoryMap[item.categoryId]
                            )
                        }
                    }
                }
            }
            .navigationTitle("Alert History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                loadAlertHistory()
            }
        }
    }
    
    private func loadAlertHistory() {
        alertHistory = BudgetAlertManager.shared.getAlertHistory()
        
        // Load categories
        let categoryFetch = FetchDescriptor<Category>()
        if let categories = try? modelContext.fetch(categoryFetch) {
            categoryMap = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
        }
    }
}

struct AlertHistoryRow: View {
    let item: BudgetAlertManager.AlertHistoryItem
    let category: Category?
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category?.name ?? "Unknown Category")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("Threshold: \(Int(item.threshold * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(item.sentDate, style: .date)
                    .font(.caption)
                Text(item.sentDate, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

