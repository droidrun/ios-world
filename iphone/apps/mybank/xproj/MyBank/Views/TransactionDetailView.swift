import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let account: Account?
    var onDispute: (() -> Void)? = nil
    @State private var showDisputeAlert = false
    @State private var showShareSheet = false
    @State private var didDispute = false

    private var effectiveStatus: TransactionStatus {
        didDispute ? .disputed : transaction.status
    }

    private var categoryIcon: String {
        switch transaction.category.lowercased() {
        case "food", "food & drink": return "fork.knife"
        case "groceries": return "cart"
        case "coffee": return "cup.and.saucer"
        case "transport", "rideshare": return "car"
        case "gas", "auto & gas": return "fuelpump"
        case "shopping": return "bag"
        case "entertainment": return "ticket"
        case "subscription", "subscriptions": return "tv"
        case "utilities": return "bolt"
        case "rent", "housing": return "house"
        case "health", "fitness": return "heart"
        case "travel": return "airplane"
        case "zelle": return "bolt.horizontal"
        case "deposit", "income": return "arrow.down.circle"
        case "transfer": return "arrow.left.arrow.right"
        case "payment": return "creditcard"
        default: return "dollarsign.circle"
        }
    }

    private var statusColor: Color {
        switch effectiveStatus {
        case .pending: return Color.orange
        case .disputed: return Color.red
        case .posted: return Color.green
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Merchant header
                VStack(spacing: 12) {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: categoryIcon)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(BankPalette.chaseBlue)
                        )

                    Text(transaction.vendor)
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("detail_vendor_label")

                    Text(Formatters.signedCurrencyString(amount: transaction.amount, currencyCode: transaction.currency))
                        .font(.system(size: 34, weight: .bold))
                        .accessibilityIdentifier("detail_amount_label")

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)
                        Text(effectiveStatus.displayName)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("detail_status_label")
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .padding(.bottom, 24)

                // Transaction details section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Details")
                        .font(.headline)
                        .padding(.bottom, 12)

                    DetailRow(label: "Date", value: Formatters.dateTime.string(from: transaction.timestamp), identifier: "detail_timestamp_label")
                    Divider().padding(.vertical, 8)
                    DetailRow(label: "Category", value: transaction.category, identifier: "detail_category_label")
                    Divider().padding(.vertical, 8)
                    DetailRow(label: "Account", value: account?.name ?? "Account", identifier: "detail_account_label")

                    if let note = transaction.note, !note.isEmpty {
                        Divider().padding(.vertical, 8)
                        DetailRow(label: "Memo", value: note, identifier: "detail_note_label")
                    }

                    Divider().padding(.vertical, 8)
                    DetailRow(label: "Transaction type", value: transaction.amount < 0 ? "Purchase" : "Credit", identifier: "detail_type_label")
                }
                .padding(16)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.bottom, 16)

                // Actions section
                VStack(spacing: 0) {
                    Button(action: {
                        didDispute = true
                        onDispute?()
                        showDisputeAlert = true
                    }) {
                        HStack {
                            Image(systemName: didDispute ? "checkmark.seal.fill" : "exclamationmark.triangle")
                                .foregroundColor(didDispute ? BankPalette.accentRed : BankPalette.chaseBlue)
                            Text(didDispute ? "Dispute submitted" : "Dispute this transaction")
                                .foregroundColor(didDispute ? BankPalette.accentRed : BankPalette.chaseBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                    .disabled(didDispute)
                    .accessibilityIdentifier("detail_dispute_button")
                    .alert("Dispute Transaction", isPresented: $showDisputeAlert) {
                        Button("OK", role: .cancel) {}
                    } message: {
                        Text("A dispute for \(String(format: "$%.2f", abs(transaction.amount))) at \(transaction.vendor) has been submitted for review. You'll receive a confirmation email.")
                    }

                    Divider().padding(.leading, 16)

                    Button(action: { showShareSheet = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(BankPalette.chaseBlue)
                            Text("Share transaction details")
                                .foregroundColor(BankPalette.chaseBlue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("detail_share_button")
                    .sheet(isPresented: $showShareSheet) {
                        let text = "Transaction: \(transaction.vendor) - \(String(format: "$%.2f", abs(transaction.amount))) on \(transaction.timestamp.formatted(date: .abbreviated, time: .omitted))"
                        ShareLink(item: text) { Text("Share") }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 16)
        }
        .background(BankPalette.pageBackground)
        .navigationTitle("Transaction")
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    let identifier: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .accessibilityIdentifier(identifier)
        }
    }
}
