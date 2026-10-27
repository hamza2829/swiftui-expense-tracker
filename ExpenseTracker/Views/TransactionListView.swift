import SwiftUI

/// The main screen: loading / error / empty states, the category filter, search and the list.
struct TransactionListView: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @State private var isShowingAddForm = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Expenses")
                .navigationDestination(for: Transaction.self) { transaction in
                    TransactionDetailView(transaction: transaction)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            isShowingAddForm = true
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isShowingAddForm) {
                    AddTransactionView(viewModel: viewModel)
                }
        }
        .task {
            // Load once when the screen first appears.
            if viewModel.state == .idle {
                await viewModel.loadTransactions()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading…")

        case .failed(let message):
            ContentUnavailableView {
                Label("Could not load expenses", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task { await viewModel.loadTransactions() }
                }
                .buttonStyle(.borderedProminent)
            }

        case .loaded:
            if viewModel.transactions.isEmpty {
                ContentUnavailableView(
                    "No expenses yet",
                    systemImage: "tray",
                    description: Text("Tap + to add your first expense.")
                )
            } else {
                transactionList
            }
        }
    }

    private var transactionList: some View {
        List {
            Picker("Category", selection: $viewModel.selectedCategory) {
                Text("All").tag(Category?.none)
                ForEach(Category.allCases) { category in
                    Text(category.displayName).tag(Category?.some(category))
                }
            }

            if viewModel.filteredTransactions.isEmpty {
                Text("No expenses match your filter.")
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.filteredTransactions) { transaction in
                NavigationLink(value: transaction) {
                    TransactionRowView(transaction: transaction)
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search by title")
        .accessibilityIdentifier("transactionList")
    }
}

#Preview {
    TransactionListView(viewModel: TransactionListViewModel(api: MockTransactionAPI()))
}
