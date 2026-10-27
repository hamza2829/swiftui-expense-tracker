import SwiftUI

/// Shows every field of one transaction.
struct TransactionDetailView: View {
    let transaction: Transaction

    var body: some View {
        List {
            LabeledContent("Title", value: transaction.title)
            LabeledContent("Amount", value: transaction.formattedAmount)
            LabeledContent("Category") {
                Label(transaction.category.displayName, systemImage: transaction.category.iconName)
            }
            LabeledContent("Date") {
                Text(transaction.date, format: .dateTime.day().month(.wide).year())
            }
            LabeledContent("ID", value: String(transaction.id))
        }
        .navigationTitle(transaction.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TransactionDetailView(transaction: MockTransactionAPI.sampleTransactions[0])
    }
}
