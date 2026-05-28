import SwiftUI

struct AccountListView: View {
    @ObservedObject var viewModel: AccountsViewModel

    var body: some View {
        List(viewModel.filteredAccounts, selection: $viewModel.selectedAccountId) { account in
            HStack {
                Image(systemName: "key.fill")
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading) {
                    Text(account.issuer)
                        .lineLimit(1)
                    Text(account.accountName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .tag(account.id)
        }
        .listStyle(.sidebar)
    }
}
