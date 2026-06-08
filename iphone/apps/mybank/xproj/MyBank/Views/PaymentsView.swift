import SwiftUI

enum BillPayMode: String, CaseIterable, Identifiable {
    case payNow = "Pay now"
    case schedule = "Schedule"

    var id: Self { self }
}

struct ZelleComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let payees: [Payee]
    let availableBalance: Double?
    let onSend: (UUID, Double, String?) -> Bool

    @State private var selectedPayeeId: UUID?
    @State private var amountText = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Recipient") {
                    Picker("Send to", selection: $selectedPayeeId) {
                        ForEach(payees) { payee in
                            Text(payee.name).tag(Optional(payee.id))
                        }
                    }
                    .accessibilityIdentifier("zelle_recipient_picker")
                }

                Section("Payment") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("zelle_amount_field")

                    TextField("Memo (optional)", text: $memo)
                        .accessibilityIdentifier("zelle_memo_field")

                    if let availableBalance {
                        LabeledContent("Available") {
                            Text(Formatters.currencyString(amount: availableBalance, currencyCode: "USD"))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button("Send now") {
                        guard canSubmit, let selectedPayeeId, let amount = parsedAmount else { return }
                        if onSend(selectedPayeeId, amount, memo.isEmpty ? nil : memo) {
                            dismiss()
                        }
                    }
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("zelle_send_button")
                }
            }
            .navigationTitle("Send with Zelle")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedPayeeId == nil {
                    selectedPayeeId = payees.first?.id
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText)
    }

    private var canSubmit: Bool {
        guard selectedPayeeId != nil else { return false }
        guard let amount = parsedAmount else { return false }
        if let availableBalance {
            return amount > 0 && amount <= availableBalance
        }
        return amount > 0
    }
}

struct BillPayComposerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let payees: [Payee]
    let defaultPayeeId: UUID?
    let defaultMode: BillPayMode
    let availableBalance: Double?
    let onPay: (UUID, Double, String?) -> Bool
    let onSchedule: (UUID, Double, Date, String?) -> Bool

    @State private var selectedPayeeId: UUID?
    @State private var amountText = ""
    @State private var memo = ""
    @State private var selectedMode: BillPayMode
    @State private var scheduleDate: Date

    init(
        payees: [Payee],
        defaultPayeeId: UUID? = nil,
        defaultMode: BillPayMode = .payNow,
        availableBalance: Double? = nil,
        onPay: @escaping (UUID, Double, String?) -> Bool,
        onSchedule: @escaping (UUID, Double, Date, String?) -> Bool
    ) {
        self.payees = payees
        self.defaultPayeeId = defaultPayeeId
        self.defaultMode = defaultMode
        self.availableBalance = availableBalance
        self.onPay = onPay
        self.onSchedule = onSchedule
        _selectedMode = State(initialValue: defaultMode)
        _scheduleDate = State(initialValue: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Payee") {
                    Picker("Pay bill", selection: $selectedPayeeId) {
                        ForEach(payees) { payee in
                            Text(payee.name).tag(Optional(payee.id))
                        }
                    }
                    .accessibilityIdentifier("bill_payee_picker")
                }

                Section("Payment") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                        .accessibilityIdentifier("bill_amount_field")

                    TextField("Memo (optional)", text: $memo)
                        .accessibilityIdentifier("bill_memo_field")

                    if let availableBalance {
                        LabeledContent("Checking available") {
                            Text(Formatters.currencyString(amount: availableBalance, currencyCode: "USD"))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section("Timing") {
                    Picker("When", selection: $selectedMode) {
                        ForEach(BillPayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("bill_mode_picker")

                    if selectedMode == .schedule {
                        DatePicker(
                            "Send on",
                            selection: $scheduleDate,
                            in: Date()...,
                            displayedComponents: [.date]
                        )
                        .accessibilityIdentifier("bill_schedule_date_picker")
                    }
                }

                Section {
                    Button(submitLabel) {
                        guard canSubmit, let selectedPayeeId, let amount = parsedAmount else { return }
                        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
                        if selectedMode == .schedule {
                            if onSchedule(selectedPayeeId, amount, scheduleDate, trimmedMemo.isEmpty ? nil : trimmedMemo) {
                                dismiss()
                            }
                        } else {
                            if onPay(selectedPayeeId, amount, trimmedMemo.isEmpty ? nil : trimmedMemo) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(!canSubmit)
                    .accessibilityIdentifier("bill_submit_button")
                }
            }
            .navigationTitle("Pay bills")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                if selectedPayeeId == nil {
                    selectedPayeeId = defaultPayeeId ?? payees.first?.id
                }
            }
        }
    }

    private var parsedAmount: Double? {
        Double(amountText)
    }

    private var canSubmit: Bool {
        guard selectedPayeeId != nil else { return false }
        guard let amount = parsedAmount else { return false }
        if selectedMode == .payNow, let availableBalance {
            return amount > 0 && amount <= availableBalance
        }
        return amount > 0
    }

    private var submitLabel: String {
        selectedMode == .schedule ? "Schedule payment" : "Submit payment"
    }
}
