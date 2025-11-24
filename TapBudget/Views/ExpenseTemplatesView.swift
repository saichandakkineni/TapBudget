import SwiftUI
import SwiftData

/// View for managing expense templates
struct ExpenseTemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<ExpenseTemplate> { $0.isActive == true }) private var templates: [ExpenseTemplate]
    @Query private var categories: [Category]
    @State private var showingAddTemplate = false
    @State private var editingTemplate: ExpenseTemplate?
    
    var body: some View {
        NavigationStack {
            if templates.isEmpty {
                EmptyStateView(
                    icon: "doc.text",
                    title: "No Templates",
                    message: "Create expense templates for quick expense entry.",
                    actionTitle: "Add Template",
                    action: { showingAddTemplate = true }
                )
                .navigationTitle("Templates")
            } else {
                List {
                    ForEach(templates) { template in
                        TemplateRow(template: template) {
                            editingTemplate = template
                        }
                    }
                    .onDelete { indexSet in
                        deleteTemplates(at: indexSet)
                    }
                }
                .navigationTitle("Templates")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { showingAddTemplate = true }) {
                            Label("Add Template", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddTemplate) {
            TemplateFormView(mode: .add, categories: categories) { result in
                showingAddTemplate = false
                handleResult(result)
            }
        }
        .sheet(item: $editingTemplate) { template in
            TemplateFormView(mode: .edit(template), categories: categories) { result in
                editingTemplate = nil
                handleResult(result)
            }
        }
    }
    
    private func deleteTemplates(at indexSet: IndexSet) {
        for index in indexSet {
            if index < templates.count {
                modelContext.delete(templates[index])
            }
        }
        try? modelContext.save()
    }
    
    private func handleResult(_ result: Result<Void, Error>) {
        // Handle result if needed
        if case .failure(let error) = result {
            print("Error: \(error.localizedDescription)")
        }
    }
}

struct TemplateRow: View {
    let template: ExpenseTemplate
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: template.icon)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.body)
                if let category = template.category {
                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text(template.amount.formattedAsCurrency())
                .fontWeight(.semibold)
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .accessibleButton(label: "\(template.name) template, \(template.amount.formattedAsCurrency())", hint: "Double tap to edit")
    }
}

struct TemplateFormView: View {
    enum Mode {
        case add
        case edit(ExpenseTemplate)
    }
    
    let mode: Mode
    let categories: [Category]
    let onSave: (Result<Void, Error>) -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amountString = ""
    @State private var selectedCategory: Category?
    @State private var notes = ""
    @State private var icon = "tag"
    
    private var navigationTitle: String {
        switch mode {
        case .add:
            return "New Template"
        case .edit:
            return "Edit Template"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $name)
                    TextField("Amount", text: $amountString)
                        .keyboardType(.decimalPad)
                    
                    Picker("Category", selection: $selectedCategory) {
                        Text("None").tag(nil as Category?)
                        ForEach(categories) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundColor(Color(hex: category.color))
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    
                    TextField("Notes (Optional)", text: $notes)
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(AppConstants.availableIcons, id: \.self) { iconName in
                                Image(systemName: iconName)
                                    .font(.title2)
                                    .foregroundColor(icon == iconName ? .accentColor : .primary)
                                    .onTapGesture {
                                        icon = iconName
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || amountString.isEmpty || Double(amountString) == nil)
                }
            }
            .onAppear {
                if case .edit(let template) = mode {
                    name = template.name
                    amountString = String(template.amount)
                    selectedCategory = template.category
                    notes = template.notes ?? ""
                    icon = template.icon
                }
            }
        }
    }
    
    private func saveTemplate() {
        guard let amount = Double(amountString), amount > 0 else {
            onSave(.failure(NSError(domain: "TemplateError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid amount"])))
            return
        }
        
        do {
            switch mode {
            case .add:
                let template = ExpenseTemplate(
                    name: name,
                    amount: amount,
                    category: selectedCategory,
                    notes: notes.isEmpty ? nil : notes,
                    icon: icon
                )
                modelContext.insert(template)
                
            case .edit(let template):
                template.name = name
                template.amount = amount
                template.category = selectedCategory
                template.notes = notes.isEmpty ? nil : notes
                template.icon = icon
            }
            
            try modelContext.save()
            onSave(.success(()))
        } catch {
            onSave(.failure(error))
        }
    }
}

