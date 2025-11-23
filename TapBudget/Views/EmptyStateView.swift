import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// Predefined empty states
extension EmptyStateView {
    static func noExpenses(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: "No Expenses Yet",
            message: "Start tracking your expenses by adding your first expense from the home screen.",
            actionTitle: "Add Expense",
            action: action
        )
    }
    
    static func noCategories(action: @escaping () -> Void) -> EmptyStateView {
        EmptyStateView(
            icon: "folder.badge.plus",
            title: "No Categories",
            message: "Create your first category to start organizing your expenses.",
            actionTitle: "Add Category",
            action: action
        )
    }
    
    static func noExpensesForCategory(categoryName: String) -> EmptyStateView {
        EmptyStateView(
            icon: "chart.bar.doc.horizontal",
            title: "No Expenses",
            message: "You haven't added any expenses for \(categoryName) yet.",
            actionTitle: nil,
            action: nil
        )
    }
}

