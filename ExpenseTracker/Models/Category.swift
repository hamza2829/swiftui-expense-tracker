import Foundation

/// The fixed list of expense categories.
/// The raw value ("food", "transport", ...) is what the API sends and receives.
enum Category: String, Codable, CaseIterable, Identifiable {
    case food
    case transport
    case shopping
    case bills
    case entertainment
    case other

    var id: String { rawValue }

    /// Name shown in the UI, e.g. "Food".
    var displayName: String { rawValue.capitalized }

    /// SF Symbol used next to the category.
    var iconName: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car"
        case .shopping: return "bag"
        case .bills: return "doc.text"
        case .entertainment: return "film"
        case .other: return "ellipsis.circle"
        }
    }
}
