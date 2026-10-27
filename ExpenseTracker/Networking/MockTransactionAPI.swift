import Foundation

/// An in-memory fake of `TransactionAPI`. No network is used.
///
/// It is used by the unit tests, by the UI test (launch argument `-useMockAPI`)
/// and by SwiftUI previews.
final class MockTransactionAPI: TransactionAPI {
    /// The data that `fetchTransactions()` returns.
    var transactions: [Transaction]
    /// If set, every call throws this error (to simulate a network failure).
    var error: Error?
    /// Every transaction passed to `addTransaction(_:)`, so tests can check it.
    private(set) var addedTransactions: [NewTransaction] = []

    init(transactions: [Transaction] = MockTransactionAPI.sampleTransactions, error: Error? = nil) {
        self.transactions = transactions
        self.error = error
    }

    func fetchTransactions() async throws -> [Transaction] {
        if let error { throw error }
        return transactions
    }

    func addTransaction(_ newTransaction: NewTransaction) async throws -> Transaction {
        if let error { throw error }
        addedTransactions.append(newTransaction)

        // Like a real server: give the new transaction the next free id.
        let nextId = (transactions.map(\.id).max() ?? 0) + 1
        let created = Transaction(
            id: nextId,
            title: newTransaction.title,
            amount: newTransaction.amount,
            category: newTransaction.category,
            date: newTransaction.date
        )
        transactions.append(created)
        return created
    }
}

extension MockTransactionAPI {
    static let sampleTransactions: [Transaction] = [
        Transaction(id: 1, title: "Groceries", amount: 54.20, category: .food, date: day("2026-10-20")),
        Transaction(id: 2, title: "Bus ticket", amount: 2.80, category: .transport, date: day("2026-10-19")),
        Transaction(id: 3, title: "Electricity bill", amount: 75.00, category: .bills, date: day("2026-10-15")),
        Transaction(id: 4, title: "Cinema", amount: 12.50, category: .entertainment, date: day("2026-10-12")),
        Transaction(id: 5, title: "Running shoes", amount: 89.99, category: .shopping, date: day("2026-10-10")),
        Transaction(id: 6, title: "Pizza night", amount: 23.40, category: .food, date: day("2026-10-08"))
    ]

    /// Turns "2026-10-20" into a Date at 12:00 UTC on that day.
    private static func day(_ text: String) -> Date {
        ISO8601DateFormatter().date(from: text + "T12:00:00Z")!
    }
}
