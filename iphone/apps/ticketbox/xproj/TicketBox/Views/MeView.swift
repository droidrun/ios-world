import SwiftUI

private enum MeSheet: String, Identifiable {
    case profile
    case promoCodes
    case mlb
    case location
    case sort
    case payment
    case address
    case helpCenter
    case contactUs
    case termsOfUse
    case privacyPolicy

    var id: String { rawValue }
}

struct MeView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(TicketBoxDeviceLocationResolver.self) private var locationResolver
    @State private var activeSheet: MeSheet?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("More")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .padding(.top, 20)

                VStack(spacing: 1) {
                    profileRow
                }
                .background(CardBackground())
                .padding(.horizontal, 18)

                sectionBlock(title: "Account") {
                    VStack(spacing: 1) {
                        simpleMenuRow(
                            title: "Credit card",
                            value: store.selectedPaymentAccount?.maskedNumber ?? "No card",
                            leading: AnyView(MasterCardMarkView())
                        ) {
                            activeSheet = .payment
                        }
                        simpleMenuRow(title: "Delivery email", value: store.settings.deliveryAddress) {
                            activeSheet = .address
                        }
                        simpleMenuRow(
                            title: "Promo codes",
                            value: store.activePromoCodes.isEmpty ? "None" : "\(store.activePromoCodes.count) available"
                        ) {
                            activeSheet = .promoCodes
                        }
                    }
                }

                sectionBlock(title: "Preferences") {
                    VStack(spacing: 1) {
                        simpleMenuRow(title: "Location", value: store.settings.selectedCity) {
                            activeSheet = .location
                        }
                        simpleMenuRow(title: "Sort deals by", value: store.settings.preferredSort.shortLabel) {
                            activeSheet = .sort
                        }
                    }
                }

                sectionBlock(title: "Connected Accounts") {
                    VStack(spacing: 1) {
                        simpleMenuRow(title: "Manage MLB account", leading: AnyView(MLBAccountBadgeView())) {
                            activeSheet = .mlb
                        }
                        favoriteServiceRow(.appleMusic)
                        favoriteServiceRow(.spotify)
                    }
                }

                sectionBlock(title: "Support") {
                    VStack(spacing: 1) {
                        simpleMenuRow(title: "Help Center") {
                            activeSheet = .helpCenter
                        }
                        simpleMenuRow(title: "Contact Us") {
                            activeSheet = .contactUs
                        }
                    }
                }

                sectionBlock(title: "Legal") {
                    VStack(spacing: 1) {
                        simpleMenuRow(title: "Terms of Use") {
                            activeSheet = .termsOfUse
                        }
                        simpleMenuRow(title: "Privacy Policy") {
                            activeSheet = .privacyPolicy
                        }
                    }
                }

                Text("TicketBox v4.2.1")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textTertiary)
                    .padding(.top, 8)
            }
            .padding(.bottom, 36)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            MeDetailSheet(sheet: sheet)
                .environment(store)
                .environment(locationResolver)
        }
    }

    private var profileRow: some View {
        Button {
            activeSheet = .profile
        } label: {
            HStack(spacing: 16) {
                Circle()
                    .fill(MockSeatGeekTheme.surfaceMuted)
                    .frame(width: 74, height: 74)
                    .overlay(
                        Image(systemName: "person")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.settings.profileName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    Text(store.settings.profileEmail)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 20)
        }
        .buttonStyle(.plain)
    }

    private func favoriteServiceRow(_ service: MusicServiceKind) -> some View {
        Button {
            store.toggleMusicService(service)
        } label: {
            HStack(spacing: 16) {
                ServiceIconView(service: service, size: 62)

                Text(service.displayName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)

                Spacer()

                Image(systemName: store.settings.connectedMusicServices.contains(service) ? "checkmark" : "plus")
                    .font(.system(size: 28, weight: .regular))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }

    private func sectionBlock<Content: View>(title: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Text(title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .padding(.horizontal, 18)
            }

            VStack(spacing: 1) {
                content()
            }
            .background(CardBackground())
            .padding(.horizontal, 18)
        }
    }

    private func simpleMenuRow(title: String, value: String? = nil, leading: AnyView? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let leading {
                    leading
                }

                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)

                Spacer()

                if let value {
                    Text(value)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        .lineLimit(1)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
        }
        .buttonStyle(.plain)
    }
}

private struct MeDetailSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(TicketBoxDeviceLocationResolver.self) private var locationResolver
    @Environment(\.dismiss) private var dismiss
    let sheet: MeSheet

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(title)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private var content: some View {
        switch sheet {
        case .profile:
            ProfileEditorSheet()
        case .promoCodes:
            PromoWalletSheet()
        case .mlb:
            Form {
                Section("Connected") {
                    Toggle("MLB account linked", isOn: Binding(
                        get: { store.settings.hasMLBAccountLinked },
                        set: { store.settings.hasMLBAccountLinked = $0 }
                    ))
                }
            }
        case .location:
            List {
                Section {
                    Button {
                        store.revertToDeviceLocation()
                        locationResolver.requestCurrentLocation(promptIfNeeded: true)
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundStyle(MockSeatGeekTheme.accent)
                            Text("Use Current iPhone Location")
                            Spacer()
                            if !store.settings.hasManualLocationOverride {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(MockSeatGeekTheme.accent)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Cities") {
                    ForEach(store.cities, id: \.self) { city in
                        Button {
                            store.updateLocation(city)
                            dismiss()
                        } label: {
                            HStack {
                                Text(city)
                                Spacer()
                                if store.settings.selectedCity == city && store.settings.hasManualLocationOverride {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(MockSeatGeekTheme.accent)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        case .sort:
            List(SortOption.allCases) { option in
                Button {
                    store.updatePreferredSort(option)
                } label: {
                    HStack {
                        Text(option.shortLabel)
                        Spacer()
                        if store.settings.preferredSort == option {
                            Image(systemName: "checkmark")
                                .foregroundStyle(MockSeatGeekTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        case .payment:
            List(store.paymentAccounts) { account in
                Button {
                    store.selectedPaymentAccountID = account.id
                } label: {
                    HStack(spacing: 14) {
                        MasterCardMarkView()
                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.displayName)
                            Text(account.name)
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        }
                        Spacer()
                        if store.selectedPaymentAccountID == account.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(MockSeatGeekTheme.accent)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        case .address:
            AddressEditorSheet()
        case .helpCenter:
            HelpCenterSheet()
        case .contactUs:
            ContactUsSheet()
        case .termsOfUse:
            TermsOfUseSheet()
        case .privacyPolicy:
            PrivacyPolicySheet()
        }
    }

    private var title: String {
        switch sheet {
        case .profile:
            return "Profile"
        case .promoCodes:
            return "Promo codes"
        case .mlb:
            return "Connected Accounts"
        case .location:
            return "Location"
        case .sort:
            return "Sort deals by"
        case .payment:
            return "Credit card"
        case .address:
            return "Delivery email"
        case .helpCenter:
            return "Help Center"
        case .contactUs:
            return "Contact Us"
        case .termsOfUse:
            return "Terms of Use"
        case .privacyPolicy:
            return "Privacy Policy"
        }
    }
}

private struct ProfileEditorSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""

    var body: some View {
        Form {
            Section("Account") {
                TextField("Full name", text: $name)
                TextField("Email", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                TextField("Phone", text: $phone)
                    .keyboardType(.phonePad)
            }

            Section("Preferences") {
                Toggle("Show prices with fees", isOn: Binding(
                    get: { store.settings.showFeesUpfront },
                    set: { store.settings.showFeesUpfront = $0 }
                ))
                Toggle("Use 24-hour time", isOn: Binding(
                    get: { store.settings.use24HourTime },
                    set: { store.settings.use24HourTime = $0 }
                ))
            }

            Section {
                Button("Save changes") {
                    store.updateProfile(name: name, email: email, phone: phone)
                    dismiss()
                }
            }

            Section {
                Button("Reset account", role: .destructive) {
                    store.resetState()
                    dismiss()
                }
            }
        }
        .onAppear {
            name = store.settings.profileName
            email = store.settings.profileEmail
            phone = store.settings.profilePhone ?? ""
        }
    }
}

private struct PromoWalletSheet: View {
    @Environment(MockTicketBoxStore.self) private var store

    @State private var promoCode = ""
    @State private var message: String?

    var body: some View {
        List {
            Section("Available offers") {
                if store.activePromoCodes.isEmpty {
                    Text("No active promo codes right now.")
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                } else {
                    ForEach(store.activePromoCodes) { promo in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(promo.code)
                                .font(.system(size: 18, weight: .bold))
                            Text(promo.title)
                            Text(promo.detail)
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                            Text("Expires \(Formatters.compactMonthDay(promo.expiresAt)) · min \(Formatters.price(promo.minimumSpend))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            if !store.usedPromoCodes.isEmpty {
                Section("Used offers") {
                    ForEach(store.usedPromoCodes) { promo in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(promo.code)
                                .font(.system(size: 18, weight: .bold))
                            Text(promo.title)
                            Text("Used on a previous order")
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Redeem a code") {
                TextField("Enter promo code", text: $promoCode)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)

                Button("Redeem") {
                    switch store.redeemPromoCode(promoCode) {
                    case .success(let promo):
                        promoCode = ""
                        message = "\(promo.code) added to your wallet."
                    case .failure(let error):
                        message = error.localizedDescription
                    }
                }
            }
        }
        .alert("Promo Codes", isPresented: Binding(
            get: { message != nil },
            set: { newValue in
                if !newValue {
                    message = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}

private struct AddressEditorSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""

    var body: some View {
        Form {
            Section {
                Text("Tickets are delivered electronically. Enter the email address where you'd like to receive your tickets.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            Section("Delivery email") {
                TextField("Email address", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Section {
                Button("Save delivery email") {
                    store.updateDeliveryAddress(email)
                    dismiss()
                }
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            email = store.settings.deliveryAddress
        }
    }
}

private struct HelpCenterSheet: View {
    var body: some View {
        List {
            Section("Popular topics") {
                HelpTopicRow(icon: "ticket", question: "How do I get my tickets?", answer: "After purchase, your tickets are delivered directly to the TicketBox app. Go to Tickets to view your mobile tickets. Most tickets are delivered within minutes; some transfers may take up to 24 hours.")
                HelpTopicRow(icon: "arrow.uturn.left.circle", question: "Can I get a refund?", answer: "TicketBox does not typically offer refunds since all sales are final. However, if your event is canceled and not rescheduled, you will receive a full refund automatically within 5–7 business days.")
                HelpTopicRow(icon: "calendar.badge.exclamationmark", question: "My event was canceled", answer: "If the event organizer cancels and does not reschedule, your refund will be processed automatically. You will receive an email confirmation. If the event is rescheduled, your tickets remain valid for the new date.")
                HelpTopicRow(icon: "dollarsign.circle", question: "Sell tickets on TicketBox", answer: "Go to Tickets, tap Selling, and choose the order you want to list. Set your asking price and your listing goes live immediately. When your tickets sell, payout is sent within 5 business days.")
                HelpTopicRow(icon: "arrow.right.arrow.left", question: "Transfer my tickets", answer: "Open your ticket in the Tickets tab, then tap Transfer. Enter the recipient's email address and they will receive a link to accept the tickets into their TicketBox account.")
                HelpTopicRow(icon: "creditcard", question: "Update my payment method", answer: "Go to More > Credit card to view and select your saved payment methods. You can also update your card during checkout.")
            }

            Section("Account") {
                HelpTopicRow(icon: "lock.rotation", question: "Reset my password", answer: "Tap 'Forgot password' on the sign-in screen and enter your email. You will receive a reset link within a few minutes. Check your spam folder if you don't see it.")
                HelpTopicRow(icon: "envelope", question: "Update email address", answer: "Go to More > tap your profile at the top > update the Email field > Save changes. A verification email will be sent to your new address.")
                HelpTopicRow(icon: "person.crop.circle.badge.minus", question: "Delete my account", answer: "Contact support at support@ticketbox.com with the subject 'Account Deletion Request'. Include your registered email address. Account deletion is processed within 30 days.")
            }

            Section("Buying") {
                HelpTopicRow(icon: "tag", question: "How pricing works", answer: "Prices on TicketBox are set by sellers and may be above or below face value. Service fees are added at checkout. Toggle 'Show prices with fees' in your profile to see all-in pricing upfront.")
                HelpTopicRow(icon: "checkmark.shield", question: "TicketBox Buyer Guarantee", answer: "Every purchase is backed by our guarantee: you will get valid tickets in time for your event, or receive comparable replacement tickets or a full refund. This applies to every order on TicketBox.")
                HelpTopicRow(icon: "chart.bar", question: "Deal Score explained", answer: "Deal Score rates ticket value from 0–100 based on price relative to similar seats, historical pricing, and demand. Scores 90+ earn a 'TicketBox Pick' badge indicating exceptional value.")
                HelpTopicRow(icon: "percent", question: "Promo codes and discounts", answer: "Enter promo codes at checkout or redeem them in More > Promo codes. Discounts are applied to the subtotal before fees. Only one promo code can be used per order.")
            }
        }
    }
}

private struct HelpTopicRow: View {
    let icon: String
    let question: String
    let answer: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.accent)
                        .frame(width: 28)
                    Text(question)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MockSeatGeekTheme.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(answer)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.leading, 42)
            }
        }
    }
}

private struct ContactUsSheet: View {
    @State private var selectedTopic = "Order issue"
    @State private var messageText = ""
    @State private var showConfirmation = false

    private let topics = ["Order issue", "Refund request", "Account question", "Event canceled", "Technical problem", "Other"]

    var body: some View {
        Form {
            Section("Topic") {
                Picker("Select a topic", selection: $selectedTopic) {
                    ForEach(topics, id: \.self) { topic in
                        Text(topic).tag(topic)
                    }
                }
            }

            Section("Message") {
                TextField("Describe your issue...", text: $messageText, axis: .vertical)
                    .lineLimit(4...8)
            }

            Section("Other ways to reach us") {
                Label("support@ticketbox.com", systemImage: "envelope")
                Label("1-888-506-4101", systemImage: "phone")
                Label("@TicketBox on X", systemImage: "bubble.left")
            }

            Section {
                Button("Send message") {
                    showConfirmation = true
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .alert("Message sent", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) {
                messageText = ""
            }
        } message: {
            Text("We've received your message and will respond within 24 hours.")
        }
    }
}

private struct TermsOfUseSheet: View {
    private var lastUpdated: String {
        let date = Calendar.current.date(byAdding: .day, value: -38, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Last updated: \(lastUpdated)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)

                Group {
                    sectionText(title: "1. Acceptance of Terms", body: "By accessing or using the TicketBox platform, you agree to be bound by these Terms of Use. If you do not agree, do not use the platform.")

                    sectionText(title: "2. Ticket Purchases", body: "All ticket purchases are final. TicketBox acts as a marketplace connecting buyers and sellers. Prices are set by sellers and may exceed face value. Service fees and delivery fees may apply.")

                    sectionText(title: "3. Buyer Guarantee", body: "Every order on TicketBox is backed by our Buyer Guarantee. If your event is canceled and not rescheduled, you will receive a full refund. If your tickets are not delivered in time, we will find you comparable or better tickets, or issue a full refund.")

                    sectionText(title: "4. Selling on TicketBox", body: "When you list tickets for sale, you agree to deliver valid tickets within the stated timeframe. Failure to deliver may result in charges to your payment method and suspension of your account.")

                    sectionText(title: "5. Account Responsibilities", body: "You are responsible for maintaining the confidentiality of your account credentials. You agree to notify TicketBox immediately of any unauthorized use of your account.")

                    sectionText(title: "6. Prohibited Conduct", body: "You agree not to use the platform for any unlawful purpose, to interfere with the platform's operation, to scrape or harvest data, or to impersonate any person or entity.")

                    sectionText(title: "7. Limitation of Liability", body: "TicketBox shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the platform.")
                }
            }
            .padding(20)
        }
    }

    private func sectionText(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
            Text(body)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
        }
    }
}

private struct PrivacyPolicySheet: View {
    private var effectiveDate: String {
        let date = Calendar.current.date(byAdding: .day, value: -38, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Effective: \(effectiveDate)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)

                Group {
                    sectionText(title: "Information We Collect", body: "We collect information you provide directly, such as your name, email address, phone number, and payment information. We also collect usage data including search queries, viewed events, and purchase history.")

                    sectionText(title: "How We Use Your Information", body: "We use your information to process transactions, personalize your experience, send order confirmations and updates, improve our services, and provide customer support.")

                    sectionText(title: "Information Sharing", body: "We may share your information with ticket sellers to fulfill orders, payment processors to complete transactions, and service providers who assist our operations. We do not sell your personal information to third parties.")

                    sectionText(title: "Data Security", body: "We implement industry-standard security measures to protect your personal information. Payment information is encrypted and processed through secure payment gateways.")

                    sectionText(title: "Your Choices", body: "You can update your account information at any time. You may opt out of promotional emails by following the unsubscribe link. You can request deletion of your account by contacting support.")

                    sectionText(title: "Cookies and Tracking", body: "We use cookies and similar technologies to improve your experience, analyze usage patterns, and deliver personalized content and recommendations.")

                    sectionText(title: "Contact Us", body: "If you have questions about this Privacy Policy, contact us at privacy@ticketbox.com or write to TicketBox, Inc., 902 Broadway, Floor 10, New York, NY 10010.")
                }
            }
            .padding(20)
        }
    }

    private func sectionText(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
            Text(body)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
        }
    }
}
