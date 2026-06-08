import SwiftUI

struct WalletView: View {
    @ObservedObject var viewModel: WalletViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    paymentMethodsSection
                    promotionsSection
                    balancesSection
                    receiptsSection
                }
                .padding(16)
            }
            .background(CityRideTheme.background)
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if let message = viewModel.message {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(CityRideTheme.muted)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .uberCard(radius: 999)
                        .padding(.bottom, 10)
                        .accessibilityIdentifier("wallet_status_message")
                }
            }
        }
    }

    private func paymentMethodID(_ method: PaymentMethod) -> String {
        let provider = method.providerName.accessibilitySafe
        let last4 = method.last4.isEmpty ? "na" : method.last4
        return "wallet_payment_method_row_\(provider)_\(last4)"
    }

    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Payment methods")
                .font(.title3.weight(.bold))

            ForEach(viewModel.walletState.paymentMethods) { method in
                Button {
                    viewModel.setPaymentMethod(id: method.id)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: icon(for: method.type))
                            .font(.title3)
                            .frame(width: 40, height: 40)
                            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                        VStack(alignment: .leading, spacing: 3) {
                            Text(method.cardLabel)
                                .font(.headline)
                            Text(method.type.label)
                                .font(.caption)
                                .foregroundStyle(CityRideTheme.muted)
                        }

                        Spacer()

                        if !method.isAvailable {
                            Text("Unavailable")
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.10), in: Capsule())
                        }

                        if method.id == viewModel.selectedPaymentMethodID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CityRideTheme.accent)
                        }
                    }
                    .padding(12)
                    .uberCard(radius: 14)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(paymentMethodID(method))
            }
        }
    }

    private var promotionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Promotions")
                .font(.title3.weight(.bold))

            if viewModel.walletState.promotions.isEmpty {
                Text("No promos available")
                    .foregroundStyle(CityRideTheme.muted)
                    .padding(12)
                    .uberCard(radius: 14)
                    .accessibilityIdentifier("wallet_no_promotions")
            } else {
                ForEach(viewModel.walletState.promotions) { promo in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(promo.title)
                            .font(.headline)
                        Text(promo.detail)
                            .font(.subheadline)
                            .foregroundStyle(CityRideTheme.muted)
                        Text(promo.valueLabel)
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .uberCard(radius: 14)
                    .accessibilityIdentifier("wallet_promo_row_\(promo.id)")
                }
            }
        }
    }

    private var balancesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CityRide Cash")
                .font(.title3.weight(.bold))

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Balance")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(AppFormatters.price(viewModel.walletState.giftCardBalance))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Divider().overlay(Color.white.opacity(0.15))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ride credits")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(AppFormatters.price(viewModel.walletState.rideCredits))
                            .font(.headline)
                            .accessibilityIdentifier("wallet_ride_credits_value")
                    }
                    .accessibilityIdentifier("wallet_ride_credits_row")
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Business profile")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                        Text(viewModel.walletState.businessProfileEnabled ? "Enabled" : "Disabled")
                            .font(.headline)
                            .accessibilityIdentifier("wallet_business_profile_value")
                    }
                    .accessibilityIdentifier("wallet_business_profile_row")
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.0, green: 0.45, blue: 0.35), Color(red: 0.0, green: 0.3, blue: 0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityIdentifier("wallet_gift_card_row")
        }
    }

    private var receiptsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Receipts")
                .font(.title3.weight(.bold))

            NavigationLink {
                ReceiptListView(receipts: viewModel.receipts, trips: viewModel.store.state.trips)
            } label: {
                HStack {
                    Text("Trip receipts history")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(CityRideTheme.muted)
                }
                .padding(12)
                .uberCard(radius: 14)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("wallet_receipts_entry")
        }
    }

    private func detailRow(label: String, value: String, rowID: String, valueID: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(CityRideTheme.muted)
                .accessibilityIdentifier(valueID)
        }
        .font(.subheadline)
        .accessibilityIdentifier(rowID)
    }

    private func icon(for type: PaymentMethodType) -> String {
        switch type {
        case .card:
            return "creditcard"
        case .applePay:
            return "applelogo"
        case .cash:
            return "banknote"
        case .business:
            return "briefcase"
        }
    }
}

private struct ReceiptListView: View {
    let receipts: [RideReceipt]
    let trips: [Trip]

    private func trip(for receipt: RideReceipt) -> Trip? {
        trips.first(where: { $0.id == receipt.tripId })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                if receipts.isEmpty {
                    Text("No receipts yet")
                        .foregroundStyle(CityRideTheme.muted)
                        .padding(12)
                        .uberCard(radius: 14)
                        .accessibilityIdentifier("wallet_receipts_empty")
                } else {
                    ForEach(receipts) { receipt in
                        receiptCard(receipt)
                            .accessibilityIdentifier("wallet_receipt_row_\(receipt.id)")
                    }
                }
            }
            .padding(16)
        }
        .background(CityRideTheme.background)
        .navigationTitle("Receipts")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func receiptCard(_ receipt: RideReceipt) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let trip = trip(for: receipt) {
                HStack(spacing: 10) {
                    Image(systemName: "car.fill")
                        .font(.headline)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(trip.pickupName) → \(trip.destinationName)")
                            .font(.headline)
                            .lineLimit(1)
                        Text("\(trip.rideType) \u{00B7} \(AppFormatters.shortDateTime.string(from: receipt.generatedAt))")
                            .font(.caption)
                            .foregroundStyle(CityRideTheme.muted)
                    }
                    Spacer()
                }

                if let driver = trip.driver {
                    HStack {
                        Text("Driver")
                            .foregroundStyle(CityRideTheme.muted)
                        Spacer()
                        Text(driver.driverName)
                    }
                    .font(.caption)
                }
            } else {
                Text("Trip \(receipt.tripId)")
                    .font(.headline)
                Text(AppFormatters.shortDateTime.string(from: receipt.generatedAt))
                    .font(.caption)
                    .foregroundStyle(CityRideTheme.muted)
            }

            Divider().overlay(Color.white.opacity(0.1))

            VStack(spacing: 4) {
                receiptRow(label: "Base fare", value: receipt.baseFare, currency: receipt.currency)
                receiptRow(label: "Fees", value: receipt.fees, currency: receipt.currency)
                receiptRow(label: "Taxes", value: receipt.taxes, currency: receipt.currency)
            }

            Divider().overlay(Color.white.opacity(0.1))

            HStack {
                Text("Total")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(AppFormatters.price(receipt.receiptTotal, currencyCode: receipt.currency))
                    .font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .uberCard(radius: 14)
    }

    private func receiptRow(label: String, value: Double, currency: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(CityRideTheme.muted)
            Spacer()
            Text(AppFormatters.price(value, currencyCode: currency))
                .font(.caption)
                .foregroundStyle(CityRideTheme.muted)
        }
    }
}
