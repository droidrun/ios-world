import Foundation

struct AmountFormatter {
    static func format(_ amount: Double, showSigned: Bool, isIncoming: Bool) -> String {
        if showSigned {
            let sign = isIncoming ? "+" : "-"
            return String(format: "%@$%.2f", sign, amount)
        }
        let label = isIncoming ? "Received" : "Sent"
        return String(format: "%@ $%.2f", label, amount)
    }
}

final class PayFlowViewModel: ObservableObject {
    @Published var draft: PaymentDraft
    @Published var errorMessage: String?

    init(defaultPrivacy: TransactionPrivacy, fundingSourceID: String) {
        draft = PaymentDraft.empty(defaultPrivacy: defaultPrivacy, fundingSourceID: fundingSourceID)
    }

    func amountValue() -> Double {
        Double(draft.amountText.replacingOccurrences(of: ",", with: "")) ?? 0
    }

    func validate(balance: Double, isBalance: Bool) -> Bool {
        let amount = amountValue()
        guard amount > 0 else {
            errorMessage = "Enter an amount greater than 0."
            return false
        }
        if isBalance && amount > balance {
            errorMessage = "Insufficient SplitPay balance."
            return false
        }
        errorMessage = nil
        return true
    }
}
