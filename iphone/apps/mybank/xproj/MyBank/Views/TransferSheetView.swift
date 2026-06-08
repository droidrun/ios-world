import SwiftUI

struct TransferSheetView: View {
    let accounts: [Account]
    let onTransfer: (UUID, UUID, Double, String?) -> Bool

    @State private var fromAccountId: UUID?
    @State private var toAccountId: UUID?
    @State private var amountText = ""
    @State private var noteText = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("From") {
                    Picker("Account", selection: $fromAccountId) {
                        ForEach(accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    .accessibilityIdentifier("transfer_from_picker_sheet")
                }

                Section("To") {
                    Picker("Account", selection: $toAccountId) {
                        ForEach(accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    .accessibilityIdentifier("transfer_to_picker_sheet")
                }

                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("transfer_amount_field_sheet")
                }

                Section("Note") {
                    TextField("Optional note", text: $noteText)
                        .accessibilityIdentifier("transfer_note_field_sheet")
                }
            }
            .navigationTitle("Transfer")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("transfer_cancel_button")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        submit()
                    }
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("transfer_submit_button")
                }
            }
            .onAppear {
                if fromAccountId == nil {
                    fromAccountId = accounts.first?.id
                }
                if toAccountId == nil {
                    toAccountId = accounts.dropFirst().first?.id
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText)
    }

    private var canSubmit: Bool {
        guard let fromId = fromAccountId,
              let toId = toAccountId,
              fromId != toId,
              let fromAccount = accounts.first(where: { $0.id == fromId }) else { return false }
        guard let amount = parsedAmount else { return false }
        return amount > 0 && fromAccount.availableBalance >= amount
    }

    private func submit() {
        guard canSubmit, let fromId = fromAccountId, let toId = toAccountId, let amount = parsedAmount else { return }
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if onTransfer(fromId, toId, amount, trimmedNote.isEmpty ? nil : trimmedNote) {
            dismiss()
        }
    }
}
