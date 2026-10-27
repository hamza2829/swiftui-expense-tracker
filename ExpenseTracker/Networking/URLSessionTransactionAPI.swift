import Foundation

/// The real API client. It talks to the REST backend with URLSession and async/await.
///
/// Endpoints (relative to `baseURL`):
/// - GET  /transactions  -> [Transaction]
/// - POST /transactions  -> Transaction (the created one, with its new id)
final class URLSessionTransactionAPI: TransactionAPI {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    /// `session` can be replaced in tests with one that uses a stub URLProtocol.
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
        // Dates are sent as ISO 8601 strings, e.g. "2026-10-01T12:00:00Z".
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
    }

    func fetchTransactions() async throws -> [Transaction] {
        let url = baseURL.appendingPathComponent("transactions")
        let (data, response) = try await session.data(from: url)
        try checkStatusCode(of: response)
        return try decode([Transaction].self, from: data)
    }

    func addTransaction(_ newTransaction: NewTransaction) async throws -> Transaction {
        var request = URLRequest(url: baseURL.appendingPathComponent("transactions"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(newTransaction)

        let (data, response) = try await session.data(for: request)
        try checkStatusCode(of: response)
        return try decode(Transaction.self, from: data)
    }

    // MARK: - Helpers

    /// Throws unless the response is HTTP with a 2xx status code.
    private func checkStatusCode(of response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.badStatusCode(httpResponse.statusCode)
        }
    }

    /// Decodes JSON and turns any decoding problem into `APIError.decodingFailed`.
    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingFailed
        }
    }
}
