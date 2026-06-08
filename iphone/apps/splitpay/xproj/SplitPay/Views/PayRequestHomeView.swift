import SwiftUI

struct PayRequestHomeView: View {
    @EnvironmentObject private var store: SplitPayStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var searchModel = UserSearchViewModel()
    @State private var selectedUser: User?
    @State private var amountText = "0"
    @State private var memo = ""
    @State private var errorMessage: String?
    @State private var confirmationText: String?
    @State private var shouldReplaceAmount = false
    @State private var infoAlert: InfoAlert?
    @State private var paymentConfirmation: PaymentConfirmationState?
    @State private var requestConfirmation: RequestConfirmationState?

    var body: some View {
        ZStack {
            SplitPayTheme.background.ignoresSafeArea()

            if let selectedUser {
                amountEntryView(for: selectedUser)
            } else {
                recipientPickerView
            }

            if let confirmationText {
                VStack {
                    Spacer()
                    Text(confirmationText)
                        .font(SplitPayTheme.titleFont(size: 15))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 34)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: selectedUser?.id) {
            resetAmountState()
            memo = ""
            errorMessage = nil
        }
        .alert(item: $infoAlert) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(item: $paymentConfirmation) { confirmation in
            PaymentConfirmationSheet(confirmation: confirmation) {
                performPay(with: confirmation)
            }
        }
        .sheet(item: $requestConfirmation) { confirmation in
            RequestConfirmationSheet(confirmation: confirmation) {
                performConfirmedRequest(with: confirmation)
            }
        }
    }

    private var recipientPickerView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.accent)

                    TextField("Phone, name or @username", text: $searchModel.query)
                        .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .accessibilityIdentifier("recipient_search_field")
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(SplitPayTheme.accent, lineWidth: 2)
                )

                Button {
                    infoAlert = InfoAlert(
                        title: "Scan a code",
                        message: "Camera-based SplitPay code scanning is coming soon."
                    )
                } label: {
                    Circle()
                        .fill(SplitPayTheme.cardSecondary)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.horizontal, 16)

            Button {
                infoAlert = InfoAlert(
                    title: "Multiple People",
                    message: "Group payments and requests are coming soon."
                )
            } label: {
                HStack(spacing: 14) {
                    Circle()
                        .fill(SplitPayTheme.cardSecondary)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        )

                    Text("Select multiple people")
                        .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textSecondary)
                }
                .padding(14)
                .background(CardSurface(radius: 20))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)

            Text("Top people")
                .font(SplitPayTheme.titleFont(size: 22))
                .foregroundStyle(SplitPayTheme.textPrimary)
                .padding(.horizontal, 16)

            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 18) {
                    if displayedUsers.isEmpty {
                        EmptyStateView(
                            title: "No matches found",
                            subtitle: "Try a different phone number, name, or @username."
                        )
                        .padding(.horizontal, 16)
                    } else {
                        ForEach(displayedUsers) { user in
                            let rowID = "recipient_row_\(user.displayName.lowercased().replacingOccurrences(of: " ", with: "_"))"
                            Button {
                                selectedUser = user
                            } label: {
                                UserRowView(user: user)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .padding(.horizontal, 16)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier(rowID)
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }

    private func amountEntryView(for user: User) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    selectedUser = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(SplitPayTheme.iconSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    SplitPayAvatarView(user: user, size: 64)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(SplitPayTheme.accent, lineWidth: 1.5)
                        )
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.accent)
                        )
                }
                .padding(.top, 8)

                Text(user.displayName)
                    .font(SplitPayTheme.titleFont(size: 20))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                HStack(alignment: .center, spacing: 6) {
                    Text("$")
                        .font(SplitPayTheme.titleFont(size: 26, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)

                    Text(amountText)
                        .font(.system(size: 52, weight: .regular))
                        .foregroundStyle(SplitPayTheme.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)

                    Rectangle()
                        .fill(SplitPayTheme.accent.opacity(0.18))
                        .frame(width: 3, height: 54)

                    if amountText != "0" {
                        Button {
                            resetAmountState()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.iconSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }

            Spacer(minLength: 16)

            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    amountTag(title: "Gift", systemImage: "gift")
                    amountTag(title: "Schedule", systemImage: "calendar")
                }
            }
            .padding(.horizontal, 16)

            HStack(spacing: 10) {
                TextField("What's this for?", text: $memo)
                    .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                    .foregroundStyle(SplitPayTheme.textPrimary)
                    .textInputAutocapitalization(.sentences)
                    .accessibilityIdentifier("memo_field")

                Button {
                    infoAlert = InfoAlert(title: "Emoji", message: "Emoji picker is coming soon.")
                } label: {
                    Image(systemName: "moon.circle")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundStyle(SplitPayTheme.accent)
                }
                .buttonStyle(.plain)

                Button {
                    infoAlert = InfoAlert(title: "GIF", message: "GIF picker is coming soon.")
                } label: {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(SplitPayTheme.accent, lineWidth: 1.5)
                        .frame(width: 44, height: 32)
                        .overlay(
                            Text("GIF")
                                .font(SplitPayTheme.titleFont(size: 14, weight: .semibold))
                                .foregroundStyle(SplitPayTheme.accent)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(SplitPayTheme.border, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white)
                    )
            )
            .padding(.horizontal, 16)

            if let errorMessage {
                Text(errorMessage)
                    .font(SplitPayTheme.bodyFont(size: 13))
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }

            HStack(spacing: 14) {
                SplitPayPrimaryButton(title: "Request") {
                    submit(.request, for: user)
                }
                .accessibilityIdentifier("request_button")

                SplitPayPrimaryButton(title: "Pay") {
                    submit(.pay, for: user)
                }
                .accessibilityIdentifier("send_button")
            }
            .accessibilityElement(children: .contain)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 6)

            NumberPadView(
                appendDigit: appendDigit,
                appendDecimal: appendDecimal,
                deleteLastCharacter: deleteLastCharacter
            )
        }
    }

    private var displayedUsers: [User] {
        let results = searchModel.results(store: store)
        if searchModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return Array(results.prefix(12))
        }
        return results
    }

    private func amountTag(title: String, systemImage: String) -> some View {
        Button {
            infoAlert = InfoAlert(
                title: title,
                message: "\(title) is coming soon."
            )
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(SplitPayTheme.titleFont(size: 15))
                    .foregroundStyle(SplitPayTheme.textPrimary)

                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(SplitPayTheme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(SplitPayTheme.cardSecondary)
            )
        }
        .buttonStyle(.plain)
    }

    private func appendDigit(_ digit: String) {
        if shouldReplaceAmount {
            amountText = digit
            shouldReplaceAmount = false
            return
        }

        if amountText == "0" {
            amountText = digit
        } else {
            amountText.append(digit)
        }
    }

    private func appendDecimal() {
        if shouldReplaceAmount {
            amountText = "0."
            shouldReplaceAmount = false
            return
        }
        guard !amountText.contains(".") else { return }
        amountText.append(".")
    }

    private func deleteLastCharacter() {
        guard !amountText.isEmpty else { return }
        amountText.removeLast()
        if amountText.isEmpty {
            amountText = "0"
        }
    }

    private func submit(_ action: SubmissionAction, for user: User) {
        guard let amount = resolvedAmountValue() else { return }
        guard amount > 0 else {
            errorMessage = "Enter an amount greater than $0."
            return
        }

        errorMessage = nil
        let memoText = memo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "payment" : memo

        switch action {
        case .pay:
            let confirmation = PaymentConfirmationState(
                user: user,
                amount: amount,
                memo: memoText,
                privacy: store.settings.defaultPrivacy,
                fundingSource: store.preferredPaymentSource(for: amount)
            )

            if store.settings.requireConfirmation {
                paymentConfirmation = confirmation
            } else {
                performPay(with: confirmation)
            }
        case .request:
            if store.settings.requireConfirmation {
                let confirmation = RequestConfirmationState(
                    user: user,
                    amount: amount,
                    memo: memoText,
                    privacy: store.settings.defaultPrivacy
                )
                requestConfirmation = confirmation
            } else {
                performRequest(for: user, amount: amount, memo: memoText)
            }
        }
    }

    private func performConfirmedRequest(with confirmation: RequestConfirmationState) {
        requestConfirmation = nil
        performRequest(for: confirmation.user, amount: confirmation.amount, memo: confirmation.memo)
    }

    private func performPay(with confirmation: PaymentConfirmationState) {
        paymentConfirmation = nil

        let result = store.pay(
            recipientID: confirmation.user.id,
            amount: confirmation.amount,
            memo: confirmation.memo,
            privacy: confirmation.privacy,
            fundingSourceID: confirmation.fundingSource.id
        )
        guard result != nil else {
            errorMessage = "Payment couldn't be completed right now."
            return
        }
        showConfirmation("Paid \(confirmation.user.displayName)")
    }

    private func performRequest(for user: User, amount: Double, memo: String) {
        let result = store.createRequest(
            to: user.id,
            amount: amount,
            memo: memo,
            privacy: store.settings.defaultPrivacy
        )
        guard result != nil else {
            errorMessage = "Unable to create request."
            return
        }
        showConfirmation("Requested \(user.displayName)")
    }

    private func showConfirmation(_ text: String) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
            confirmationText = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            dismiss()
        }
    }

    private func resetAmountState() {
        amountText = "0"
        shouldReplaceAmount = false
    }

    private func currentAmountValue() -> Double? {
        let normalized = amountText.hasSuffix(".") ? String(amountText.dropLast()) : amountText
        let candidate = normalized.isEmpty ? "0" : normalized
        return Double(candidate)
    }

    private func resolvedAmountValue() -> Double? {
        guard let currentAmount = currentAmountValue() else {
            errorMessage = "Enter a valid amount."
            return nil
        }
        return currentAmount
    }

    private func formattedAmount(_ amount: Double) -> String {
        AmountDisplayFormatter.string(from: amount)
    }
}

private enum SubmissionAction {
    case pay
    case request
}

private struct PaymentConfirmationState: Identifiable {
    let id = UUID()
    let user: User
    let amount: Double
    let memo: String
    let privacy: TransactionPrivacy
    let fundingSource: FundingSource
}

private struct PaymentConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let confirmation: PaymentConfirmationState
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        SplitPayAvatarView(user: confirmation.user, size: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Pay \(confirmation.user.displayName)")
                                .font(SplitPayTheme.titleFont(size: 20))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                            Text("@\(confirmation.user.username)")
                                .font(SplitPayTheme.bodyFont(size: 15))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        }
                    }

                    Text(String(format: "$%.2f", confirmation.amount))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(SplitPayTheme.textPrimary)

                    if !confirmation.memo.isEmpty {
                        Text(confirmation.memo)
                            .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 10) {
                        confirmationRow(title: "Privacy", value: confirmation.privacy.rawValue)
                        confirmationRow(title: "Funding", value: confirmation.fundingSource.name)
                        confirmationRow(title: "Details", value: confirmation.fundingSource.subtitle)
                    }

                    HStack(spacing: 12) {
                        SplitPaySecondaryButton(title: "Cancel") {
                            dismiss()
                        }
                        .accessibilityIdentifier("pay_confirm_cancel_button")

                        SplitPayPrimaryButton(title: String(format: "Pay $%.2f", confirmation.amount)) {
                            onConfirm()
                            dismiss()
                        }
                        .accessibilityIdentifier("pay_confirm_button")
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(SplitPayTheme.background.ignoresSafeArea())
            .navigationTitle("Confirm Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func confirmationRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                .foregroundStyle(SplitPayTheme.textSecondary)
            Spacer()
            Text(value)
                .font(SplitPayTheme.bodyFont(size: 15))
                .foregroundStyle(SplitPayTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct RequestConfirmationState: Identifiable {
    let id = UUID()
    let user: User
    let amount: Double
    let memo: String
    let privacy: TransactionPrivacy
}

private struct RequestConfirmationSheet: View {
    @Environment(\.dismiss) private var dismiss

    let confirmation: RequestConfirmationState
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        SplitPayAvatarView(user: confirmation.user, size: 44)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Request from \(confirmation.user.displayName)")
                                .font(SplitPayTheme.titleFont(size: 20))
                                .foregroundStyle(SplitPayTheme.textPrimary)
                            Text("@\(confirmation.user.username)")
                                .font(SplitPayTheme.bodyFont(size: 15))
                                .foregroundStyle(SplitPayTheme.textSecondary)
                        }
                    }

                    Text(String(format: "$%.2f", confirmation.amount))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(SplitPayTheme.textPrimary)

                    if !confirmation.memo.isEmpty {
                        Text(confirmation.memo)
                            .font(SplitPayTheme.titleFont(size: 17, weight: .regular))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                    }

                    Divider()

                    HStack {
                        Text("Privacy")
                            .font(SplitPayTheme.bodyFont(size: 15, weight: .semibold))
                            .foregroundStyle(SplitPayTheme.textSecondary)
                        Spacer()
                        Text(confirmation.privacy.rawValue)
                            .font(SplitPayTheme.bodyFont(size: 15))
                            .foregroundStyle(SplitPayTheme.textPrimary)
                    }

                    HStack(spacing: 12) {
                        SplitPaySecondaryButton(title: "Cancel") {
                            dismiss()
                        }

                        SplitPayPrimaryButton(title: String(format: "Request $%.2f", confirmation.amount)) {
                            onConfirm()
                            dismiss()
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(SplitPayTheme.background.ignoresSafeArea())
            .navigationTitle("Confirm Request")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct NumberPadView: View {
    let appendDigit: (String) -> Void
    let appendDecimal: () -> Void
    let deleteLastCharacter: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            keypadRow([.digit("1"), .digit("2"), .digit("3")])
            keypadRow([.digit("4"), .digit("5"), .digit("6")])
            keypadRow([.digit("7"), .digit("8"), .digit("9")])
            keypadRow([.decimal, .digit("0"), .delete])
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color(red: 0.79, green: 0.80, blue: 0.84).opacity(0.55))
    }

    private func keypadRow(_ keys: [PadKey]) -> some View {
        HStack(spacing: 8) {
            ForEach(Array(keys.enumerated()), id: \.offset) { _, key in
                button(for: key)
            }
        }
    }

    @ViewBuilder
    private func button(for key: PadKey) -> some View {
        Button {
            switch key {
            case .digit(let value):
                appendDigit(value)
            case .decimal:
                appendDecimal()
            case .delete:
                deleteLastCharacter()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(key.backgroundColor)
                key.label
                    .foregroundStyle(key.foregroundColor)
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(key.accessibilityID)
    }
}

private enum PadKey {
    case digit(String)
    case decimal
    case delete

    var accessibilityID: String {
        switch self {
        case .digit(let v): return "amount_digit_\(v)"
        case .decimal:      return "amount_decimal"
        case .delete:       return "amount_delete"
        }
    }

    @ViewBuilder
    var label: some View {
        switch self {
        case .digit(let value):
            Text(value)
                .font(.system(size: 24, weight: .regular))
        case .decimal:
            Text(".")
                .font(.system(size: 28, weight: .regular))
        case .delete:
            Image(systemName: "delete.left")
                .font(.system(size: 22, weight: .regular))
        }
    }

    var backgroundColor: Color {
        switch self {
        case .digit, .decimal:
            return Color.white.opacity(0.95)
        case .delete:
            return Color(red: 0.68, green: 0.71, blue: 0.76)
        }
    }

    var foregroundColor: Color {
        SplitPayTheme.textPrimary
    }
}

private enum AmountDisplayFormatter {
    static func string(from amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }
}

private struct InfoAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    PayRequestHomeView()
        .environmentObject(SplitPayStore())
}
