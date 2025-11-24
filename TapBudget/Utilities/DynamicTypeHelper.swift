import SwiftUI

/// Helper for Dynamic Type support
struct DynamicTypeHelper {
    /// Scaled font sizes that adapt to user's accessibility settings
    static let titleFont = Font.system(.title, design: .rounded)
    static let headlineFont = Font.system(.headline, design: .rounded)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)
    
    /// Scaled font for large amounts
    static func amountFont(size: CGFloat = 36) -> Font {
        return .system(size: size, weight: .bold, design: .rounded)
    }
}

/// View modifier for Dynamic Type support
extension View {
    /// Ensures text scales properly with accessibility settings
    func scalableFont(_ font: Font) -> some View {
        self.font(font)
    }
}

