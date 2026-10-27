import SwiftUI

/// Form for a new transaction. "Save" validates the input and sends a POST through the view model.
struct AddTransactionView: View {
    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var amountText = ""
    @State private var category: Category = .food
    @State private var date = Date()
    @State private var errorMessage: String?
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                    Picker("Category", selection: $category) {
                        ForEach(Category.allCases) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        errorMessage = nil
        do {
            try await viewModel.addTransaction(title: title, amountText: amountText, category: category, date: date)
            dismiss()
        } catch {
            // Shows either a validation message or the network error.
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

#Preview {
    AddTransactionView(viewModel: TransactionListViewModel(api: MockTransactionAPI()))
}
