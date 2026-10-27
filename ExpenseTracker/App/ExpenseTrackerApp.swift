import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @StateObject private var viewModel: TransactionListViewModel

    init() {
        _viewModel = StateObject(wrappedValue: TransactionListViewModel(api: Self.makeAPI()))
    }

    var body: some Scene {
        WindowGroup {
            TransactionListView(viewModel: viewModel)
        }
    }

    /// Dependency injection happens here: pick which `TransactionAPI` the app uses.
    /// - The UI test launches the app with `-useMockAPI` so it never needs a server.
    /// - Otherwise the real URLSession client talks to the local mock server (see mock-server/).
    private static func makeAPI() -> TransactionAPI {
        if ProcessInfo.processInfo.arguments.contains("-useMockAPI") {
            return MockTransactionAPI()
        }
        return URLSessionTransactionAPI(baseURL: URL(string: "http://localhost:3000")!)
    }
}
