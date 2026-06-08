import SwiftUI

struct DepositSheetView: View {
    let accounts: [Account]
    let defaultAccountId: UUID?
    let onDeposit: (UUID, Double, String?) -> Bool

    @State private var selectedAccountId: UUID?
    @State private var amountText = ""
    @State private var noteText = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Deposit To") {
                    Picker("Account", selection: $selectedAccountId) {
                        ForEach(accounts) { account in
                            Text(account.name).tag(Optional(account.id))
                        }
                    }
                    .accessibilityIdentifier("deposit_account_picker")
                }

                Section("Amount") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("deposit_amount_field")
                }

                Section("Note") {
                    TextField("Optional note", text: $noteText)
                        .accessibilityIdentifier("deposit_note_field")
                }
            }
            .navigationTitle("Deposit")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("deposit_cancel_button")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        submit()
                    }
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("deposit_submit_button")
                }
            }
            .onAppear {
                if selectedAccountId == nil {
                    selectedAccountId = defaultAccountId ?? accounts.first?.id
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText)
    }

    private var canSubmit: Bool {
        guard selectedAccountId != nil else { return false }
        guard let amount = parsedAmount else { return false }
        return amount > 0
    }

    private func submit() {
        guard canSubmit, let accountId = selectedAccountId, let amount = parsedAmount else { return }
        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if onDeposit(accountId, amount, trimmedNote.isEmpty ? nil : trimmedNote) {
            dismiss()
        }
    }
}
