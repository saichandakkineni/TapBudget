import SwiftUI
import SwiftData

/// Quick button for adding expenses from templates
struct TemplateQuickButton: View {
    let template: ExpenseTemplate
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: template.icon)
                    .font(.title3)
                Text(template.name)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(template.amount.formattedAsCurrency())
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(Color(.systemGray6))
            .foregroundColor(.primary)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibleButton(label: "\(template.name) template, \(template.amount.formattedAsCurrency())", hint: "Double tap to add this expense")
    }
}

