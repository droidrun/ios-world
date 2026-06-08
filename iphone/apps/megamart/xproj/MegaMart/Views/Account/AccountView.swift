import SwiftUI

struct AccountView: View {
    @EnvironmentObject private var store: MegaMartStore

    private var firstName: String {
        store.state.userProfile.name.split(separator: " ").first.map(String.init) ?? "there"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                accountTopRow

                if store.isAuthenticated {
                    signedInSummary
                    signedInActions
                } else {
                    signInCard
                    helpfulRow(
                        title: "Check order status and track,\nchange or return items",
                        systemImage: "shippingbox.fill"
                    ) {
                        OrdersView()
                    }
                    helpfulRow(
                        title: "Shop past purchases and\neveryday essentials",
                        systemImage: "bag.fill"
                    ) {
                        SavedItemsListView()
                    }
                    helpfulRow(
                        title: "Create lists with items you\nwant, now or later",
                        systemImage: "list.bullet.rectangle.portrait.fill"
                    ) {
                        SavedItemsListView()
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Helpful Tips")
                        .font(.system(size: 26, weight: .bold))
                    tipCard(
                        title: "Saved items",
                        subtitle: "\(store.state.savedItems.count) products ready to move back into cart"
                    )
                    tipCard(
                        title: "Payment methods",
                        subtitle: store.selectedPaymentMethod?.label ?? "No default payment method"
                    )
                    tipCard(
                        title: "Delivery address",
                        subtitle: store.selectedAddress?.formattedLines.joined(separator: ", ") ?? "No delivery address"
                    )
                }
                .padding(.horizontal, 18)
            }
            .padding(.bottom, 80)
        }
        .background(MegaMartTheme.background)
        .safeAreaInset(edge: .top, spacing: 0) {
            MegaMartScreenHeader(
                destination: SearchView(initialRequest: SearchNavigationRequest(query: "", departmentID: nil, categoryID: nil)),
                text: "Search MegaMart"
            )
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var accountTopRow: some View {
        HStack {
            Text(store.isAuthenticated ? "Hello, \(firstName)" : "Hello")
                .font(.system(size: 28, weight: .medium))

            Spacer()

            NavigationLink {
                MegaMartSettingsView()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.black)
            }
            .buttonStyle(.plain)

            HStack(spacing: 8) {
                Text("🇺🇸")
                    .font(.system(size: 20))
                Text("EN")
                    .font(.system(size: 20, weight: .medium))
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
    }

    private var signedInSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.state.userProfile.name)
                .font(.system(size: 28, weight: .bold))
            Text(store.state.userProfile.email)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            Text(store.state.userProfile.membershipLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MegaMartTheme.linkBlue)
            Text(store.state.userProfile.profileNote)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)

            Button("Sign out") {
                store.signOut()
            }
            .buttonStyle(.plain)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(MegaMartTheme.linkBlue)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.white)
        )
        .padding(.horizontal, 18)
    }

    private var signedInActions: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your account")
                .font(.system(size: 26, weight: .bold))
                .padding(.horizontal, 18)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                actionTile(title: "Your orders", subtitle: "\(store.state.orders.count) orders", systemImage: "shippingbox.fill") {
                    OrdersView()
                }
                .accessibilityIdentifier("account_action_your_orders")
                actionTile(title: "Your lists", subtitle: "\(store.state.savedItems.count) saved items", systemImage: "list.bullet.rectangle.portrait.fill") {
                    SavedItemsListView()
                }
                .accessibilityIdentifier("account_action_your_lists")
                actionTile(title: "Addresses", subtitle: store.selectedAddress?.shortLine ?? "No address", systemImage: "location.fill") {
                    ManageAddressesView()
                }
                .accessibilityIdentifier("account_action_addresses")
                actionTile(title: "Payments", subtitle: store.selectedPaymentMethod?.label ?? "No default card", systemImage: "creditcard.fill") {
                    ManagePaymentMethodsView()
                }
                .accessibilityIdentifier("account_action_payments")
            }
            .padding(.horizontal, 18)
        }
    }

    private var signInCard: some View {
        VStack(spacing: 20) {
            Text("Sign in for the best\nexperience")
                .font(.system(size: 26, weight: .medium))
                .multilineTextAlignment(.center)

            Button("Sign in") {
                store.navigateToAccount(.auth(.signIn))
            }
            .font(.system(size: 20, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(MegaMartTheme.amazonYellow)
            )
            .foregroundStyle(.black)

            Button("Create account") {
                store.navigateToAccount(.auth(.createAccount))
            }
            .font(.system(size: 20, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
                    .overlay(
                        Capsule()
                            .stroke(Color(.systemGray3), lineWidth: 1.5)
                    )
            )
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 18)
    }

    private func helpfulRow<Destination: View>(title: String, systemImage: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color.white.opacity(0.7))
                        .frame(width: 86, height: 86)
                    Image(systemName: systemImage)
                        .font(.system(size: 32))
                        .foregroundStyle(Color(red: 102 / 255, green: 128 / 255, blue: 120 / 255))
                }

                Text(title)
                    .font(.system(size: 22, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()
            }
            .padding(.horizontal, 18)
        }
        .buttonStyle(.plain)
    }

    private func actionTile<Destination: View>(title: String, subtitle: String, systemImage: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink {
            destination()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 30))
                    .foregroundStyle(MegaMartTheme.linkBlue)

                Text(title)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.white)
            )
        }
        .buttonStyle(.plain)
    }

    private func tipCard(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.white)
        )
    }
}

struct AccountAuthView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore

    let mode: AuthEntryMode

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    private var canSubmit: Bool {
        switch mode {
        case .signIn:
            return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !password.isEmpty
        case .createAccount:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                !password.isEmpty
        }
    }

    var body: some View {
        Form {
            Section {
                if mode == .createAccount {
                    TextField("Full name", text: $name)
                        .textContentType(.name)
                        .accessibilityIdentifier("create_account_name_field")
                }

                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    .accessibilityIdentifier(mode == .signIn ? "sign_in_email_field" : "create_account_email_field")

                SecureField("Password", text: $password)
                    .textContentType(mode == .signIn ? .password : .newPassword)
                    .accessibilityIdentifier(mode == .signIn ? "sign_in_password_field" : "create_account_password_field")
            } header: {
                Text(mode == .signIn ? "Sign in to your account" : "Create an account")
            } footer: {
                Text("This app stays on-device. Credentials are stored only in local app state.")
            }

            if mode == .signIn {
                Section("Saved account") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.state.userProfile.name)
                            .font(.subheadline.weight(.semibold))
                        Text(store.state.userProfile.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button("Use saved account") {
                        email = store.state.userProfile.email
                        password = "password1"
                    }
                    .accessibilityIdentifier("use_demo_account_button")
                }
            }

            Section {
                Button(mode == .signIn ? "Continue" : "Create account") {
                    submit()
                }
                .disabled(!canSubmit)
                .accessibilityIdentifier(mode == .signIn ? "sign_in_submit_button" : "create_account_submit_button")
            }
        }
        .navigationTitle(mode.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if mode == .signIn {
                email = store.state.userProfile.email
            }
        }
    }

    private func submit() {
        switch mode {
        case .signIn:
            store.signIn(email: email)
        case .createAccount:
            store.createAccount(name: name, email: email)
        }
        dismiss()
    }
}

struct ManageAddressesView: View {
    @EnvironmentObject private var store: MegaMartStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    private var previewAddress: Address? {
        deviceLocationManager.latestResolvedAddress
    }

    var body: some View {
        List {
            Section("Current iPhone location") {
                Button {
                    deviceLocationManager.requestCurrentLocation(recipientName: store.state.userProfile.name)
                } label: {
                    HStack(spacing: 12) {
                        if deviceLocationManager.isRequestInFlight {
                            ProgressView()
                                .progressViewStyle(.circular)
                        } else {
                            Image(systemName: "location.fill")
                                .foregroundStyle(MegaMartTheme.linkBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use Current Location")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("Reads your current location and updates delivery defaults.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
                .disabled(deviceLocationManager.isRequestInFlight)
                .accessibilityIdentifier("use_current_location_button")

                if let message = deviceLocationManager.statusMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    store.upsertCurrentLocationAddress(
                        SeedData.benchmarkCurrentLocationAddress(recipientName: store.state.userProfile.name)
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Use San Francisco Default Address")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text("Fallback address when live location is unavailable.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("use_sf_benchmark_location_button")

                if let previewAddress {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Latest resolved location")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(previewAddress.formattedLines.joined(separator: "\n"))
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("Delivery locations") {
                ForEach(store.state.addresses) { address in
                    Button {
                        store.selectAddress(address.id)
                    } label: {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(address.label)
                                    .font(.subheadline.weight(.semibold))
                                ForEach(address.formattedLines, id: \.self) { line in
                                    Text(line)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if store.selectedAddress?.id == address.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MegaMartTheme.linkBlue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Your Addresses")
        .onChange(of: deviceLocationManager.resolutionToken) { _, _ in
            guard let address = deviceLocationManager.latestResolvedAddress else { return }
            store.upsertCurrentLocationAddress(address)
        }
    }
}

struct ManagePaymentMethodsView: View {
    @EnvironmentObject private var store: MegaMartStore

    var body: some View {
        List {
            Section("Wallet") {
                ForEach(store.state.paymentMethods) { method in
                    Button {
                        store.selectPaymentMethod(method.id)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(method.label)
                                    .font(.subheadline.weight(.semibold))
                                Text(method.details)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.selectedPaymentMethod?.id == method.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MegaMartTheme.linkBlue)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Payment Methods")
    }
}

struct SavedItemsListView: View {
    @EnvironmentObject private var store: MegaMartStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if store.state.savedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Saved list empty")
                            .font(.headline)
                        Text("Save products from Search or product detail screens.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(.white)
                    )
                    .accessibilityIdentifier("saved_items_empty_state")
                } else {
                    ForEach(store.state.savedItems) { item in
                        VStack(alignment: .leading, spacing: 10) {
                            if let product = store.product(for: item.productID) {
                                NavigationLink {
                                    ProductDetailView(productID: product.id)
                                } label: {
                                    HStack(spacing: 12) {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                            .frame(width: 72, height: 72)
                                            .overlay {
                                                MegaMartProductArtwork(product: product)
                                                    .padding(10)
                                            }

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(item.productName)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.primary)
                                            Text(Formatters.currency(item.unitPrice))
                                                .font(.headline)
                                                .accessibilityIdentifier("saved_list_price_\(item.productID)")
                                            Text(item.deliveryEstimate)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }

                            HStack {
                                Button("Move to Cart") {
                                    store.moveSavedItemToCart(savedItemID: item.id)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .accessibilityIdentifier("saved_move_to_cart_\(item.productID)")

                                Button("Remove") {
                                    store.removeSavedItem(savedItemID: item.id)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("saved_remove_\(item.productID)")
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(.white)
                        )
                    }
                }
            }
            .padding()
            .padding(.bottom, 60)
        }
        .background(MegaMartTheme.background)
        .navigationTitle("Saved Items")
    }
}
