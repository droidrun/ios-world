import SwiftUI

struct MyBankDepositChecksView: View {
    @ObservedObject var store: BankStore
    @State private var showDepositSheet = false
    @State private var showInboxSheet = false
    @State private var selectedTransaction: Transaction?

    private var depositAccounts: [Account] {
        store.accounts.filter { $0.type != .credit }
    }

    private var recentDeposits: [Transaction] {
        store.transactions
            .filter { $0.category == "Deposit" }
            .sorted(by: { $0.timestamp > $1.timestamp })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                MyBankHomeToolbar(onInboxTap: {
                    showInboxSheet = true
                })

                Text("Deposit checks")
                    .font(.system(size: 34, weight: .bold))

                Text("Capture the front and back of a check, confirm the amount, and post it into your MyBank account.")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Mobile deposit")
                            .font(.system(size: 24, weight: .bold))

                        HStack(spacing: 14) {
                            DepositPlaceholder(title: "Front")
                            DepositPlaceholder(title: "Back")
                        }

                        Button("Deposit a check") {
                            showDepositSheet = true
                        }
                        .buttonStyle(FilledPillButtonStyle(tint: BankPalette.chaseBlue))
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent deposits")
                            .font(.system(size: 22, weight: .bold))

                        if recentDeposits.isEmpty {
                            Text("No recent mobile deposits.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(recentDeposits.prefix(3)) { deposit in
                                Button {
                                    selectedTransaction = deposit
                                } label: {
                                    MyBankActivityRow(
                                        transaction: deposit,
                                        accountName: store.accounts.first(where: { $0.id == deposit.accountId })?.name ?? "MyBank account"
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(BankPalette.pageBackground)
        .sheet(isPresented: $showDepositSheet) {
            DepositSheetView(
                accounts: depositAccounts,
                defaultAccountId: depositAccounts.first(where: { $0.type == .checking })?.id,
                onDeposit: { accountId, amount, note in
                    store.createDeposit(to: accountId, amount: amount, note: note)
                }
            )
        }
        .sheet(isPresented: $showInboxSheet) {
            MyBankInboxSheet(store: store)
        }
        .sheet(item: $selectedTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(
                    transaction: transaction,
                    account: store.accounts.first(where: { $0.id == transaction.accountId })
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { selectedTransaction = nil }
                    }
                }
            }
        }
    }
}

private struct DepositPlaceholder: View {
    let title: String

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black.opacity(0.05))
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .overlay(
                VStack(spacing: 10) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 28))
                        .foregroundColor(BankPalette.chaseBlue)
                    Text(title)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.secondary)
                }
            )
    }
}
