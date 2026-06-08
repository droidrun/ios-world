import SwiftUI

private enum TicketsSheet: Identifiable {
    case selling
    case add
    case accounts
    case order(Order)
    case pastTicket(TicketArchiveItem)

    var id: String {
        switch self {
        case .selling:
            return "selling"
        case .add:
            return "add"
        case .accounts:
            return "accounts"
        case .order(let order):
            return "order-\(order.id.uuidString)"
        case .pastTicket(let item):
            return "past-\(item.id.uuidString)"
        }
    }
}

struct TicketsView: View {
    @Environment(MockTicketBoxStore.self) private var store
    @State private var ordersViewModel = OrdersViewModel()
    @State private var activeSheet: TicketsSheet?
    @State private var ticketMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Tickets")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .padding(.horizontal, 18)
                    .padding(.top, 22)

                actionRow
                    .padding(.horizontal, 18)

                if !store.orders.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Mobile Tickets")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.horizontal, 18)

                        VStack(spacing: 14) {
                            ForEach(store.orders) { order in
                                Button {
                                    activeSheet = .order(order)
                                } label: {
                                    PurchasedTicketCard(
                                        order: order,
                                        status: ordersViewModel.status(for: order),
                                        etaText: ordersViewModel.etaText(for: order),
                                        saleListing: store.saleListing(for: order.id)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 18)
                    }
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Past Events")
                        .font(.system(size: 28, weight: .bold))
                        .padding(.horizontal, 18)

                    VStack(spacing: 16) {
                        ForEach(store.pastTickets) { item in
                            Button {
                                activeSheet = .pastTicket(item)
                            } label: {
                                PastEventTicketCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 18)
                }
            }
            .padding(.bottom, 40)
        }
        .background(MockSeatGeekTheme.background.ignoresSafeArea())
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .selling:
                SellingTicketsSheet()
                    .environment(store)
            case .add:
                AddTicketsSheet(message: $ticketMessage)
                    .environment(store)
            case .accounts:
                ConnectedAccountsSheet(message: $ticketMessage)
                    .environment(store)
            case .order(let order):
                TicketOrderDetailSheet(order: order)
                    .environment(store)
            case .pastTicket(let item):
                PastTicketDetailSheet(item: item)
            }
        }
        .alert("Tickets", isPresented: Binding(
            get: { ticketMessage != nil },
            set: { newValue in
                if !newValue {
                    ticketMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(ticketMessage ?? "")
        }
        .onAppear {
            ordersViewModel.startTimer()
        }
        .onDisappear {
            ordersViewModel.stopTimer()
        }
    }

    private var actionRow: some View {
        HStack {
            Button("Selling") {
                activeSheet = .selling
            }
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(MockSeatGeekTheme.textPrimary)
            .buttonStyle(.plain)

            Spacer()

            Button("Add") {
                activeSheet = .add
            }
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(MockSeatGeekTheme.textPrimary)
            .buttonStyle(.plain)

            Spacer()

            Menu {
                Button("Refresh payment accounts") {
                    store.refreshPaymentAccounts()
                    ticketMessage = "TicketBox refreshed your saved payment methods."
                }
                Button("Import MLB tickets") {
                    ticketMessage = store.importMLBTickets()
                        ? "Tickets from your linked MLB account were added."
                        : "No new MLB tickets were available to import."
                }
                Button("Manage connected accounts") {
                    activeSheet = .accounts
                }
                Button("Reset account", role: .destructive) {
                    store.resetState()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
    }
}

private struct PurchasedTicketCard: View {
    let order: Order
    let status: OrderStatus
    let etaText: String
    let saleListing: SaleListing?

    var body: some View {
        CardBackground()
            .overlay {
            if let item = order.items.first {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            statusPill

                            Text(item.eventTitle)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(MockSeatGeekTheme.textPrimary)
                                .lineLimit(2)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 6) {
                            if let saleListing {
                                Text("Listed")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(MockSeatGeekTheme.accent)
                                Text(Formatters.price(saleListing.askingPrice))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(MockSeatGeekTheme.accent)
                                Text("ask price")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                            } else {
                                Text(totalPaidText)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(MockSeatGeekTheme.accent)
                            }
                        }
                    }

                    Text("\(Formatters.seatGeekListDate(item.eventDate)) · \(item.venueName)")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)

                    HStack(spacing: 12) {
                        Label("Section \(item.section)", systemImage: "ticket.fill")
                        Label("Row \(item.row)", systemImage: "rectangle.grid.1x2")
                        Label("\(item.quantity)x", systemImage: "person.2.fill")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                }
                .padding(22)
            }
            }
            .frame(minHeight: 186)
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            Text(status.rawValue)
            Text("· \(etaText)")
        }
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(statusColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.12))
        )
    }

    private var statusColor: Color {
        switch status {
        case .processing:
            return MockSeatGeekTheme.accent
        case .confirmed:
            return MockSeatGeekTheme.blue
        case .delivered:
            return MockSeatGeekTheme.green
        }
    }

    private var totalPaidText: String {
        if let totalPaid = order.totalPaid {
            return Formatters.price(totalPaid)
        }

        let total = order.items.reduce(0.0) { partialResult, item in
            partialResult + ((item.pricePerTicket + item.feesPerTicket) * Double(item.quantity))
        }
        return Formatters.price(total)
    }
}

private struct PastEventTicketCard: View {
    let item: TicketArchiveItem

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                splitBackground

                HStack(spacing: 18) {
                    TeamBadgeView(token: leftToken, size: 64)
                    TeamBadgeView(token: rightToken, size: 64)
                }
            }
            .frame(width: 124)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(item.venueName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                Text(Formatters.ticketArchiveDate(item.date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                Text("Sec \(item.section) \u{2022} Row \(item.row) \u{2022} Seats \(item.seatRange)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
                Text(Formatters.price(item.pricePaid))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.accent)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 20)

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(CardBackground())
    }

    private var leftToken: String {
        switch item.style {
        case .padresAtBraves:
            return "padres"
        case .giantsAtDodgers, .giantsVsDodgers, .giantsVsPadres, .giantsVsRockies:
            return "giants"
        case .warriorsVsSuns, .warriorsVsNuggets, .warriorsVsClippers:
            return "warriors"
        case .concertChaseCenter, .concertFillmore:
            return "concert"
        case .comedyMasonic:
            return "comedy"
        case .theaterOrpheum:
            return "theater"
        }
    }

    private var rightToken: String {
        switch item.style {
        case .padresAtBraves:
            return "braves"
        case .giantsAtDodgers, .giantsVsDodgers:
            return "dodgers"
        case .giantsVsPadres:
            return "padres"
        case .giantsVsRockies:
            return "rockies"
        case .warriorsVsSuns:
            return "suns"
        case .warriorsVsNuggets:
            return "nuggets"
        case .warriorsVsClippers:
            return "clippers"
        case .concertChaseCenter, .concertFillmore:
            return "music"
        case .comedyMasonic:
            return "laughs"
        case .theaterOrpheum:
            return "stage"
        }
    }

    private var splitBackground: some View {
        LinearGradient(
            colors: splitColors,
            startPoint: .leading,
            endPoint: .trailing
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private var splitColors: [Color] {
        switch item.style {
        case .padresAtBraves:
            return [
                Color(red: 0.93, green: 0.77, blue: 0.29),
                Color(red: 0.93, green: 0.77, blue: 0.29),
                Color(red: 0.07, green: 0.16, blue: 0.34),
                Color(red: 0.07, green: 0.16, blue: 0.34)
            ]
        case .giantsAtDodgers, .giantsVsDodgers:
            return [
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.1, green: 0.23, blue: 0.58),
                Color(red: 0.1, green: 0.23, blue: 0.58)
            ]
        case .warriorsVsSuns:
            return [
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.91, green: 0.34, blue: 0.13),
                Color(red: 0.91, green: 0.34, blue: 0.13)
            ]
        case .warriorsVsNuggets:
            return [
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.06, green: 0.18, blue: 0.42),
                Color(red: 0.06, green: 0.18, blue: 0.42)
            ]
        case .warriorsVsClippers:
            return [
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.11, green: 0.29, blue: 0.68),
                Color(red: 0.78, green: 0.12, blue: 0.22),
                Color(red: 0.78, green: 0.12, blue: 0.22)
            ]
        case .giantsVsPadres:
            return [
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.89, green: 0.74, blue: 0.28),
                Color(red: 0.89, green: 0.74, blue: 0.28)
            ]
        case .giantsVsRockies:
            return [
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.94, green: 0.46, blue: 0.19),
                Color(red: 0.2, green: 0.12, blue: 0.38),
                Color(red: 0.2, green: 0.12, blue: 0.38)
            ]
        case .concertChaseCenter:
            return [
                Color(red: 0.58, green: 0.22, blue: 0.72),
                Color(red: 0.58, green: 0.22, blue: 0.72),
                Color(red: 0.18, green: 0.14, blue: 0.36),
                Color(red: 0.18, green: 0.14, blue: 0.36)
            ]
        case .concertFillmore:
            return [
                Color(red: 0.82, green: 0.26, blue: 0.36),
                Color(red: 0.82, green: 0.26, blue: 0.36),
                Color(red: 0.22, green: 0.1, blue: 0.14),
                Color(red: 0.22, green: 0.1, blue: 0.14)
            ]
        case .comedyMasonic:
            return [
                Color(red: 0.92, green: 0.72, blue: 0.18),
                Color(red: 0.92, green: 0.72, blue: 0.18),
                Color(red: 0.14, green: 0.12, blue: 0.1),
                Color(red: 0.14, green: 0.12, blue: 0.1)
            ]
        case .theaterOrpheum:
            return [
                Color(red: 0.72, green: 0.14, blue: 0.22),
                Color(red: 0.72, green: 0.14, blue: 0.22),
                Color(red: 0.12, green: 0.08, blue: 0.16),
                Color(red: 0.12, green: 0.08, blue: 0.16)
            ]
        }
    }
}

private struct SellingTicketsSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOrder: Order?

    var body: some View {
        NavigationStack {
            List {
                if store.orders.isEmpty {
                    Text("No upcoming tickets are available to sell.")
                } else {
                    ForEach(store.orders) { order in
                        if let item = order.items.first {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.eventTitle)
                                        .font(.system(size: 18, weight: .bold))
                                    Text("Section \(item.section) · Row \(item.row)")
                                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    if let saleListing = store.saleListing(for: order.id) {
                                        Text(Formatters.price(saleListing.askingPrice))
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(MockSeatGeekTheme.accent)

                                        HStack(spacing: 8) {
                                            Button("Edit") {
                                                selectedOrder = order
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .tint(MockSeatGeekTheme.accent)

                                            Button("Remove", role: .destructive) {
                                                store.removeSaleListing(orderID: order.id)
                                            }
                                            .buttonStyle(.bordered)
                                        }
                                    } else {
                                        Button("List") {
                                            selectedOrder = order
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .tint(MockSeatGeekTheme.accent)
                                    }
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
            }
            .navigationTitle("Selling")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(item: $selectedOrder) { order in
            ResaleListingEditorSheet(
                order: order,
                initialPrice: store.saleListing(for: order.id)?.askingPrice ?? store.recommendedSalePrice(for: order)
            )
            .environment(store)
        }
    }
}

private struct ResaleListingEditorSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let order: Order
    let initialPrice: Double

    @State private var askingPriceText: String

    init(order: Order, initialPrice: Double) {
        self.order = order
        self.initialPrice = initialPrice
        _askingPriceText = State(initialValue: Self.initialPriceText(for: initialPrice))
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                if let item = order.items.first {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.eventTitle)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(MockSeatGeekTheme.textPrimary)
                        Text("Section \(item.section) · Row \(item.row) · Seats \(item.seatRange)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Ask price")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MockSeatGeekTheme.textPrimary)

                    TextField("0", text: $askingPriceText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 34, weight: .bold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(CardBackground(cornerRadius: 18))

                    Text("Suggested price: \(Formatters.price(store.recommendedSalePrice(for: order))) based on what you paid.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(MockSeatGeekTheme.textSecondary)
                }

                Spacer()
            }
            .padding(20)
            .background(MockSeatGeekTheme.background.ignoresSafeArea())
            .navigationTitle("Edit Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        guard let askingPrice else { return }
                        store.upsertSaleListing(orderID: order.id, askingPrice: askingPrice)
                        dismiss()
                    }
                    .disabled(askingPrice == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var askingPrice: Double? {
        let sanitized = askingPriceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = Double(sanitized), parsed > 0 else { return nil }
        return parsed
    }

    private static func initialPriceText(for price: Double) -> String {
        if price.rounded() == price {
            return String(Int(price))
        }
        return String(format: "%.2f", price)
    }
}

private struct AddTicketsSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var message: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Import") {
                    Button("Import MLB tickets") {
                        message = store.importMLBTickets()
                            ? "Imported MLB tickets into your account."
                            : "No new MLB tickets were available to import."
                        dismiss()
                    }
                    .disabled(!store.settings.hasMLBAccountLinked)
                }

                Section("Recent purchases") {
                    Button("Recover recent concert order") {
                        message = store.recoverConcertOrder()
                            ? "A concert order was recovered to Mobile Tickets."
                            : "That order is already in your account."
                        dismiss()
                    }
                }

                Section("Connected accounts") {
                    Button("Manage connected accounts in Me") {
                        store.selectedTab = .me
                        message = nil
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Tickets")
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
}

private struct ConnectedAccountsSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @Binding var message: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("MLB account") {
                    Toggle("Linked", isOn: Binding(
                        get: { store.settings.hasMLBAccountLinked },
                        set: { store.settings.hasMLBAccountLinked = $0 }
                    ))
                }

                Section("Payments") {
                    if let selectedPaymentAccount = store.selectedPaymentAccount {
                        LabeledContent("Card", value: selectedPaymentAccount.displayName)
                        Button("Refresh payment accounts") {
                            store.refreshPaymentAccounts()
                            message = "Saved payment methods refreshed."
                            dismiss()
                        }
                    } else {
                        Text("No saved payment account.")
                    }
                }
            }
            .navigationTitle("Connected Accounts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct TicketOrderDetailSheet: View {
    @Environment(MockTicketBoxStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var ordersViewModel = OrdersViewModel()
    @State private var showingSaleEditor = false
    @State private var showingWalletAlert = false

    let order: Order

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let item = order.items.first {
                        barcodeCard

                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.eventTitle)
                                .font(.system(size: 28, weight: .bold))
                            Text("\(Formatters.seatGeekListDate(item.eventDate)) · \(item.venueName)")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(MockSeatGeekTheme.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            detailRow(title: "Section", value: item.section)
                            detailRow(title: "Row", value: item.row)
                            detailRow(title: "Seats", value: item.seatRange)
                            detailRow(title: "Delivery", value: order.deliveryMethod.rawValue)
                            detailRow(title: "Order number", value: order.orderNumber)
                            if let promo = order.appliedPromoCode {
                                detailRow(title: "Promo", value: promo)
                            }
                            detailRow(title: "Total paid", value: totalPaidText)
                        }
                        .padding(18)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(MockSeatGeekTheme.surfaceMuted)
                        )

                        if let saleListing {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Active listing")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(MockSeatGeekTheme.textPrimary)
                                        Text("Updated \(saleUpdatedText)")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(Formatters.price(saleListing.askingPrice))
                                            .font(.system(size: 28, weight: .bold))
                                            .foregroundStyle(MockSeatGeekTheme.accent)
                                        Text("ask price")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(MockSeatGeekTheme.textSecondary)
                                    }
                                }

                                Button("Edit listing") {
                                    showingSaleEditor = true
                                }
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(MockSeatGeekTheme.accent)
                                )

                                Button("Remove listing", role: .destructive) {
                                    store.removeSaleListing(orderID: order.id)
                                }
                                .font(.system(size: 18, weight: .semibold))
                                .frame(maxWidth: .infinity)
                            }
                            .padding(18)
                            .background(CardBackground(cornerRadius: 20))
                        } else {
                            Button("List for sale") {
                                showingSaleEditor = true
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(MockSeatGeekTheme.accent)
                            )
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("Mobile Ticket")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .sheet(isPresented: $showingSaleEditor) {
            ResaleListingEditorSheet(
                order: order,
                initialPrice: saleListing?.askingPrice ?? store.recommendedSalePrice(for: order)
            )
            .environment(store)
        }
        .onAppear {
            ordersViewModel.startTimer()
        }
        .onDisappear {
            ordersViewModel.stopTimer()
        }
    }

    private var barcodeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(ordersViewModel.status(for: order).rawValue)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(MockSeatGeekTheme.accent)
                Spacer()
                Text(ordersViewModel.etaText(for: order))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)
            }

            TicketBarcodeView(seed: order.orderNumber.hashValue)
                .frame(height: 160)

            Text("Present this mobile ticket at entry.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)

            Button {
                showingWalletAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "wallet.pass")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Add to Apple Wallet")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(CardBackground())
        .alert("Apple Wallet", isPresented: $showingWalletAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Ticket added to Apple Wallet.")
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
        }
        .font(.system(size: 17, weight: .medium))
    }

    private var totalPaidText: String {
        if let totalPaid = order.totalPaid {
            return Formatters.price(totalPaid)
        }
        let total = order.items.reduce(0.0) { partialResult, item in
            partialResult + ((item.pricePerTicket + item.feesPerTicket) * Double(item.quantity))
        }
        return Formatters.price(total)
    }

    private var saleListing: SaleListing? {
        store.saleListing(for: order.id)
    }

    private var saleUpdatedText: String {
        guard let date = saleListing?.lastUpdated else { return "today" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

private struct PastTicketDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let item: TicketArchiveItem

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                PastEventTicketCard(item: item)

                VStack(spacing: 12) {
                    detailRow("Venue", item.venueName)
                    detailRow("Section", item.section)
                    detailRow("Row", item.row)
                    detailRow("Seats", item.seatRange)
                    detailRow("Price Paid", Formatters.price(item.pricePaid))
                }
                .padding(.horizontal, 4)

                Text("This archived ticket remains in your TicketBox history for quick reorders and price lookups.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(MockSeatGeekTheme.textSecondary)

                Spacer()
            }
            .padding(18)
            .navigationTitle("Past Ticket")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MockSeatGeekTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockSeatGeekTheme.textPrimary)
        }
    }
}

private struct TicketBarcodeView: View {
    var seed: Int = 42

    private let gridSize = 8

    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<gridSize, id: \.self) { row in
                HStack(spacing: 3) {
                    ForEach(0..<gridSize, id: \.self) { col in
                        Rectangle()
                            .fill(isFilled(row: row, col: col) ? MockSeatGeekTheme.textPrimary : MockSeatGeekTheme.surfaceMuted)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .frame(maxWidth: 160)
        .frame(maxWidth: .infinity)
    }

    private func isFilled(row: Int, col: Int) -> Bool {
        // Corner finder patterns (always filled)
        if (row < 2 && col < 2) || (row < 2 && col >= gridSize - 2) || (row >= gridSize - 2 && col < 2) {
            return true
        }
        // Seeded pseudo-random fill for the rest
        let hash = (row &* 31 &+ col &* 17 &+ seed &* 7) & 0xFF
        return hash % 3 != 0
    }
}
