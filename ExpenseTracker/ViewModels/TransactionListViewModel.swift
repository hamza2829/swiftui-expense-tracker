import Foundation

/// Holds the state for the transaction screens and talks to the API.
///
/// - `@MainActor`: all state changes happen on the main thread, which SwiftUI needs.
/// - The API comes in through `init`, so the app passes the real client and tests pass a mock.
@MainActor
final class TransactionListViewModel: ObservableObject {
    /// What the list screen should show.
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(message: String)
    }

    /// Problems with the user's input in the add form.
    enum ValidationError: LocalizedError, Equatable {
        case emptyTitle
        case invalidAmount

        var errorDescription: String? {
            switch self {
            case .emptyTitle: return "Please enter a title."
            case .invalidAmount: return "The amount must be a number greater than 0."
            }
        }
    }

    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var state: LoadState = .idle

    /// `nil` means "All categories".
    @Published var selectedCategory: Category?
    @Published var searchText = ""

    private let api: TransactionAPI

    init(api: TransactionAPI) {
        self.api = api
    }

    /// The transactions after applying the category filter and the title search, newest first.
    var filteredTransactions: [Transaction] {
        let search = searchText.trimmingCharacters(in: .whitespaces)
        return transactions
            .filter { selectedCategory == nil || $0.category == selectedCategory }
            .filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }
            .sorted { $0.date > $1.date }
    }

    /// Loads the transactions. Also used by the "Retry" button.
    func loadTransactions() async {
        state = .loading
        do {
            transactions = try await api.fetchTransactions()
            state = .loaded
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    /// Validates the form input, sends it to the API and adds the result to the list.
    /// Throws a `ValidationError` for bad input or the API's error if the request fails.
    func addTransaction(title: String, amountText: String, category: Category, date: Date) async throws {
        let (validTitle, amount) = try Self.validate(title: title, amountText: amountText)
        let newTransaction = NewTransaction(title: validTitle, amount: amount, category: category, date: date)
        let created = try await api.addTransaction(newTransaction)
        transactions.append(created)
    }

    /// Checks the raw form input and returns the cleaned-up title and the amount as a number.
    static func validate(title: String, amountText: String) throws -> (title: String, amount: Double) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw ValidationError.emptyTitle
        }

        // Accept both "12.50" and "12,50".
        let normalizedAmount = amountText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(normalizedAmount), amount > 0 else {
            throw ValidationError.invalidAmount
        }

        return (trimmedTitle, amount)
    }
}
