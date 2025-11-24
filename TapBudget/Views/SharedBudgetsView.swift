import SwiftUI
import SwiftData
import CloudKit

/// View for managing shared budgets
struct SharedBudgetsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sharedBudgets: [SharedBudget]
    @Query private var categories: [Category]
    @State private var showingCreateBudget = false
    @State private var showingCloudKitStatus = false
    @State private var cloudKitStatus: CloudKitStatus = .unknown
    @State private var isCheckingStatus = false
    
    var body: some View {
        NavigationStack {
            List {
                // CloudKit Status Section
                Section {
                    HStack {
                        if isCheckingStatus {
                            ProgressView()
                        } else {
                            Image(systemName: cloudKitStatusIcon)
                                .foregroundColor(cloudKitStatusColor)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("iCloud Sync")
                                .font(.headline)
                            Text(cloudKitStatus.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button("Check") {
                            checkCloudKitStatus()
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Sync Status")
                }
                
                // Shared Budgets Section
                Section {
                    if sharedBudgets.isEmpty {
                        Text("No shared budgets yet")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(sharedBudgets) { budget in
                            SharedBudgetRow(budget: budget)
                        }
                    }
                } header: {
                    Text("Shared Budgets")
                }
            }
            .navigationTitle("Shared Budgets")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingCreateBudget = true }) {
                        Label("Create Shared Budget", systemImage: "plus.circle.fill")
                    }
                    .disabled(cloudKitStatus != .available)
                }
            }
            .sheet(isPresented: $showingCreateBudget) {
                CreateSharedBudgetView(categories: categories) { result in
                    showingCreateBudget = false
                    handleResult(result)
                }
            }
            .onAppear {
                checkCloudKitStatus()
            }
        }
    }
    
    private var cloudKitStatusIcon: String {
        switch cloudKitStatus {
        case .available:
            return "checkmark.circle.fill"
        case .noAccount:
            return "person.crop.circle.badge.exclamationmark"
        case .restricted:
            return "lock.circle.fill"
        case .unknown, .error:
            return "questionmark.circle.fill"
        }
    }
    
    private var cloudKitStatusColor: Color {
        switch cloudKitStatus {
        case .available:
            return .green
        case .noAccount, .restricted:
            return .orange
        case .unknown, .error:
            return .red
        }
    }
    
    private func checkCloudKitStatus() {
        // Don't check CloudKit status if it's not available
        guard CloudKitAvailability.isAvailable else {
            cloudKitStatus = .error("CloudKit not configured. Please enable CloudKit capability in Xcode.")
            return
        }
        
        isCheckingStatus = true
        Task {
            // Check CloudKit status asynchronously with error handling
            let status = await CloudKitSyncManager.shared.checkCloudKitStatus()
            
            await MainActor.run {
                cloudKitStatus = status
                isCheckingStatus = false
            }
        }
    }
    
    private func handleResult(_ result: Result<Void, Error>) {
        if case .failure(let error) = result {
            print("Error creating shared budget: \(error.localizedDescription)")
        }
    }
}

struct SharedBudgetRow: View {
    let budget: SharedBudget
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(budget.name)
                    .font(.headline)
                Spacer()
                Text(budget.budgetAmount.formattedAsCurrency())
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            HStack {
                Label("\(budget.getMembers().count) member\(budget.getMembers().count == 1 ? "" : "s")", systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(budget.periodType.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateSharedBudgetView: View {
    let categories: [Category]
    let onSave: (Result<Void, Error>) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var budgetAmountString = ""
    @State private var selectedPeriodType: PeriodType = .monthly
    @State private var selectedCategories: Set<Category> = []
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Budget Details") {
                    TextField("Budget Name", text: $name)
                    TextField("Budget Amount", text: $budgetAmountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Period", selection: $selectedPeriodType) {
                        ForEach(PeriodType.allCases, id: \.self) { period in
                            Text(period.description).tag(period)
                        }
                    }
                }
                
                Section("Categories") {
                    if categories.isEmpty {
                        Text("No categories available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                Text(category.name)
                                Spacer()
                                if selectedCategories.contains(category) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedCategories.contains(category) {
                                    selectedCategories.remove(category)
                                } else {
                                    selectedCategories.insert(category)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Shared Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSharedBudget()
                    }
                    .disabled(name.isEmpty || budgetAmountString.isEmpty || Double(budgetAmountString) == nil || isCreating)
                }
            }
        }
    }
    
    private func createSharedBudget() {
        guard let budgetAmount = Double(budgetAmountString), budgetAmount > 0 else {
            onSave(.failure(NSError(domain: "SharedBudgetError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid budget amount"])))
            return
        }
        
        isCreating = true
        
        Task {
            do {
                // Get current user ID (simplified - in production would get from CloudKit)
                let userId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
                
                await MainActor.run {
                    let sharedBudget = SharedBudget(
                        name: name,
                        createdBy: userId,
                        periodType: selectedPeriodType,
                        budgetAmount: budgetAmount
                    )
                    sharedBudget.categories = Array(selectedCategories)
                    modelContext.insert(sharedBudget)
                }
                
                try await MainActor.run {
                    try modelContext.save()
                }
                
                // Create CloudKit share (async)
                await MainActor.run {
                    isCreating = false
                    onSave(.success(()))
                }
                
                // Create CloudKit share in background
                let sharedBudget = await MainActor.run {
                    let descriptor = FetchDescriptor<SharedBudget>(
                        predicate: #Predicate<SharedBudget> { $0.name == name }
                    )
                    return try? modelContext.fetch(descriptor).first
                }
                
                if let sharedBudget = sharedBudget {
                    do {
                        _ = try await CloudKitSyncManager.shared.createShare(for: sharedBudget)
                    } catch {
                        print("Error creating CloudKit share: \(error.localizedDescription)")
                    }
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    onSave(.failure(error))
                }
            }
        }
    }
}

