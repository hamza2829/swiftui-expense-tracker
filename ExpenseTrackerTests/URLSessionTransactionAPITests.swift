import XCTest
@testable import ExpenseTracker

final class URLSessionTransactionAPITests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/api")!

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        super.tearDown()
    }

    private func makeAPI() -> URLSessionTransactionAPI {
        URLSessionTransactionAPI(baseURL: baseURL, session: StubURLProtocol.makeSession())
    }

    /// Makes the stub answer every request with this status code and body.
    private func stubResponse(statusCode: Int, body: String) {
        StubURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
            return (response, Data(body.utf8))
        }
    }

    func testFetchTransactionsDecodesValidJSON() async throws {
        stubResponse(statusCode: 200, body: """
        [
          { "id": 1, "title": "Groceries", "amount": 54.2, "category": "food", "date": "2026-10-20T12:00:00Z" },
          { "id": 2, "title": "Bus ticket", "amount": 2.8, "category": "transport", "date": "2026-10-19T12:00:00Z" }
        ]
        """)

        let transactions = try await makeAPI().fetchTransactions()

        XCTAssertEqual(transactions.count, 2)
        XCTAssertEqual(transactions[0].id, 1)
        XCTAssertEqual(transactions[0].title, "Groceries")
        XCTAssertEqual(transactions[0].amount, 54.2)
        XCTAssertEqual(transactions[0].category, .food)
        XCTAssertEqual(transactions[0].date, ISO8601DateFormatter().date(from: "2026-10-20T12:00:00Z"))
        XCTAssertEqual(transactions[1].category, .transport)
    }

    func testFetchTransactionsWithInvalidJSONThrowsDecodingFailed() async {
        // "amount" is a string and "category" is unknown, so decoding must fail.
        stubResponse(statusCode: 200, body: """
        [ { "id": 1, "title": "Broken", "amount": "lots", "category": "unknown", "date": "yesterday" } ]
        """)

        do {
            _ = try await makeAPI().fetchTransactions()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .decodingFailed)
        }
    }

    func testFetchTransactionsWithServerErrorThrowsBadStatusCode() async {
        stubResponse(statusCode: 500, body: "Internal Server Error")

        do {
            _ = try await makeAPI().fetchTransactions()
            XCTFail("Expected an error")
        } catch {
            XCTAssertEqual(error as? APIError, .badStatusCode(500))
        }
    }

    func testAddTransactionSendsPOSTWithJSONBody() async throws {
        var sentRequest: URLRequest?
        StubURLProtocol.requestHandler = { request in
            sentRequest = request
            let response = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            let body = """
            { "id": 9, "title": "Coffee", "amount": 3.5, "category": "food", "date": "2026-10-21T12:00:00Z" }
            """
            return (response, Data(body.utf8))
        }
        let date = ISO8601DateFormatter().date(from: "2026-10-21T12:00:00Z")!
        let newTransaction = NewTransaction(title: "Coffee", amount: 3.5, category: .food, date: date)

        let created = try await makeAPI().addTransaction(newTransaction)

        // The response is decoded into the created transaction.
        XCTAssertEqual(created.id, 9)
        XCTAssertEqual(created.title, "Coffee")

        // The request is a JSON POST to /transactions with the new transaction as body.
        let request = try XCTUnwrap(sentRequest)
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/api/transactions")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let sentBody = try decoder.decode(NewTransaction.self, from: XCTUnwrap(request.bodyData()))
        XCTAssertEqual(sentBody, newTransaction)
    }
}
