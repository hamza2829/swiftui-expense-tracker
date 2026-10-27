import Foundation

/// One expense as returned by the API.
struct Transaction: Codable, Identifiable, Hashable {
    let id: Int
    let title: String
    let amount: Double
    let category: Category
    let date: Date

    /// Amount formatted as money, e.g. "$12.50".
    var formattedAmount: String {
        amount.formatted(.currency(code: "USD"))
    }
}

/// The body sent with POST /transactions.
/// It has no `id` because the server creates the id.
struct NewTransaction: Codable, Equatable {
    let title: String
    let amount: Double
    let category: Category
    let date: Date
}
