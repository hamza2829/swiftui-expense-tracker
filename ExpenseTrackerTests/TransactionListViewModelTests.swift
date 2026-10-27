import XCTest
@testable import ExpenseTracker

@MainActor
final class TransactionListViewModelTests: XCTestCase {
    private struct TestError: LocalizedError {
        var errorDescription: String? { "No internet connection" }
    }

    // MARK: - Loading

    func testInitialStateIsIdle() {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(viewModel.transactions.isEmpty)
    }

    func testLoadSuccessSetsTransactionsAndLoadedState() async {
        let api = MockTransactionAPI()
        let viewModel = TransactionListViewModel(api: api)

        await viewModel.loadTransactions()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.transactions, api.transactions)
    }

    func testLoadSuccessWithNoDataGivesEmptyList() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI(transactions: []))

        await viewModel.loadTransactions()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertTrue(viewModel.filteredTransactions.isEmpty)
    }

    func testLoadFailureSetsFailedStateWithMessage() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI(error: TestError()))

        await viewModel.loadTransactions()

        XCTAssertEqual(viewModel.state, .failed(message: "No internet connection"))
        XCTAssertTrue(viewModel.transactions.isEmpty)
    }

    func testRetryAfterFailureLoadsTransactions() async {
        let api = MockTransactionAPI(error: TestError())
        let viewModel = TransactionListViewModel(api: api)
        await viewModel.loadTransactions()

        api.error = nil // the "network" works again
        await viewModel.loadTransactions()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.transactions.count, api.transactions.count)
    }

    // MARK: - Filter and search

    func testFilterByCategoryShowsOnlyThatCategory() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())
        await viewModel.loadTransactions()

        viewModel.selectedCategory = .food

        XCTAssertEqual(Set(viewModel.filteredTransactions.map(\.title)), ["Groceries", "Pizza night"])
    }

    func testNoCategorySelectedShowsAllTransactionsNewestFirst() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())
        await viewModel.loadTransactions()

        viewModel.selectedCategory = nil

        let dates = viewModel.filteredTransactions.map(\.date)
        XCTAssertEqual(dates.count, MockTransactionAPI.sampleTransactions.count)
        XCTAssertEqual(dates, dates.sorted(by: >))
    }

    func testSearchByTitleIsCaseInsensitive() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())
        await viewModel.loadTransactions()

        viewModel.searchText = "CINE"

        XCTAssertEqual(viewModel.filteredTransactions.map(\.title), ["Cinema"])
    }

    func testSearchAndCategoryFilterAreCombined() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())
        await viewModel.loadTransactions()

        viewModel.selectedCategory = .food
        viewModel.searchText = "pizza"
        XCTAssertEqual(viewModel.filteredTransactions.map(\.title), ["Pizza night"])

        viewModel.selectedCategory = .bills
        XCTAssertTrue(viewModel.filteredTransactions.isEmpty)
    }

    // MARK: - Adding

    func testAddTransactionSendsItToAPIAndAddsItToList() async throws {
        let api = MockTransactionAPI()
        let viewModel = TransactionListViewModel(api: api)
        await viewModel.loadTransactions()
        let countBefore = viewModel.transactions.count
        let date = Date()

        try await viewModel.addTransaction(title: "  Coffee  ", amountText: "3,50", category: .food, date: date)

        XCTAssertEqual(api.addedTransactions, [NewTransaction(title: "Coffee", amount: 3.5, category: .food, date: date)])
        XCTAssertEqual(viewModel.transactions.count, countBefore + 1)
        XCTAssertEqual(viewModel.transactions.last?.title, "Coffee")
    }

    func testAddTransactionWithEmptyTitleThrowsAndDoesNotCallAPI() async {
        let api = MockTransactionAPI()
        let viewModel = TransactionListViewModel(api: api)

        do {
            try await viewModel.addTransaction(title: "   ", amountText: "10", category: .food, date: Date())
            XCTFail("Expected a validation error")
        } catch {
            XCTAssertEqual(error as? TransactionListViewModel.ValidationError, .emptyTitle)
        }
        XCTAssertTrue(api.addedTransactions.isEmpty)
    }

    func testAddTransactionWithZeroAmountThrows() async {
        let viewModel = TransactionListViewModel(api: MockTransactionAPI())

        do {
            try await viewModel.addTransaction(title: "Coffee", amountText: "0", category: .food, date: Date())
            XCTFail("Expected a validation error")
        } catch {
            XCTAssertEqual(error as? TransactionListViewModel.ValidationError, .invalidAmount)
        }
    }

    func testValidationRejectsNegativeAndNonNumericAmounts() {
        for amountText in ["-5", "abc", ""] {
            XCTAssertThrowsError(try TransactionListViewModel.validate(title: "Coffee", amountText: amountText)) { error in
                XCTAssertEqual(error as? TransactionListViewModel.ValidationError, .invalidAmount, "for input '\(amountText)'")
            }
        }
    }

    func testValidationErrorsHaveUserFacingMessages() {
        XCTAssertEqual(TransactionListViewModel.ValidationError.emptyTitle.localizedDescription, "Please enter a title.")
        XCTAssertEqual(
            TransactionListViewModel.ValidationError.invalidAmount.localizedDescription,
            "The amount must be a number greater than 0."
        )
    }

    func testAddTransactionAPIFailureKeepsListUnchanged() async {
        let api = MockTransactionAPI()
        let viewModel = TransactionListViewModel(api: api)
        await viewModel.loadTransactions()
        let before = viewModel.transactions

        api.error = TestError()
        do {
            try await viewModel.addTransaction(title: "Coffee", amountText: "3.5", category: .food, date: Date())
            XCTFail("Expected an error")
        } catch {
            XCTAssertTrue(error is TestError)
        }
        XCTAssertEqual(viewModel.transactions, before)
    }
}
