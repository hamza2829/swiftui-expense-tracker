import Foundation

/// Everything the app needs from the backend.
/// The view model only knows this protocol, so tests can pass in a mock.
protocol TransactionAPI {
    func fetchTransactions() async throws -> [Transaction]
    func addTransaction(_ newTransaction: NewTransaction) async throws -> Transaction
}

/// Errors thrown by `URLSessionTransactionAPI`.
enum APIError: LocalizedError, Equatable {
    case invalidResponse
    case badStatusCode(Int)
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server sent an invalid response."
        case .badStatusCode(let code):
            return "The server returned an error (status \(code))."
        case .decodingFailed:
            return "The server data could not be read."
        }
    }
}
