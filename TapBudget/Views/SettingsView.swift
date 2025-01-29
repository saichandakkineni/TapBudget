import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showingAddCategory = false
    @State private var editingCategory: Category?
    
    var body: some View {
        NavigationStack {
            List {
                Section("Categories") {
                    ForEach(categories) { category in
                        CategoryRow(category: category) {
                            editingCategory = category
                        }
                    }
                    .onDelete(perform: deleteCategories)
                }
                
                Section {
                    Button(action: { showingAddCategory = true }) {
                        Label("Add Category", systemImage: "plus.circle.fill")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddCategory) {
                CategoryFormView(mode: .add)
            }
            .sheet(item: $editingCategory) { category in
                CategoryFormView(mode: .edit(category))
            }
        }
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(categories[index])
        }
    }
}

struct CategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: category.icon ?? "questionmark.circle")
                .foregroundColor(Color(hex: category.color ?? "#FF0000"))
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(category.name ?? "Unnamed Category")
                Text("Budget: \(category.budget, format: .currency(code: "USD"))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onEdit) {
                Image(systemName: "pencil.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct CategoryFormView: View {
    enum FormMode {
        case add
        case edit(Category)
    }
    
    let mode: FormMode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var icon = "tag"
    @State private var budget = 0.0
    @State private var color = "#FF0000"
    
    private let icons = ["tag", "cart", "fork.knife", "car", "house", "film", "gamecontroller", "gift", "medical", "airplane"]
    private let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEEAD", "#D4A5A5", "#9B6B6B", "#A2D5F2", "#07689F", "#40514E"]
    
    private var navigationTitle: String {
        switch mode {
        case .add:
            return "New Category"
        case .edit:
            return "Edit Category"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Category Name", text: $name)
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(icons, id: \.self) { iconName in
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
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(colors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: color == colorHex ? 2 : 0)
                                    )
                                    .onTapGesture {
                                        color = colorHex
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Section("Budget") {
                    TextField("Monthly Budget", value: $budget, format: .currency(code: "USD"))
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCategory()
                        dismiss()
                    }
                }
            }
            .onAppear {
                if case .edit(let category) = mode {
                    name = category.name ?? ""
                    icon = category.icon ?? "tag"
                    budget = category.budget
                    color = category.color ?? "#FF0000"
                }
            }
        }
    }
    
    private func saveCategory() {
        switch mode {
        case .add:
            let category = Category(name: name, icon: icon, budget: budget, color: color)
            modelContext.insert(category)
            
        case .edit(let category):
            category.name = name
            category.icon = icon
            category.budget = budget
            category.color = color
        }
    }
} 