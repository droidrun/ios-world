import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var store: MegaMartStore
    @StateObject private var viewModel = OrdersViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                segmentPicker

                if displayedOrders.isEmpty {
                    emptyState
                } else {
                    ForEach(displayedOrders) { order in
                        NavigationLink {
                            OrderDetailView(orderID: order.id)
                        } label: {
                            OrderRowCard(order: order)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("order_row_\(order.orderNumber)")
                    }
                }
            }
            .padding()
            .padding(.bottom, 60)
        }
        .navigationTitle("Orders")
    }

    private var displayedOrders: [Order] {
        switch viewModel.selectedSegment {
        case .active:
            return store.activeOrders
        case .delivered:
            return store.deliveredOrders
        case .canceled:
            return store.canceledOrders
        }
    }

    private var segmentPicker: some View {
        HStack(spacing: 10) {
            ForEach(OrdersSegment.allCases) { segment in
                Button {
                    viewModel.selectedSegment = segment
                } label: {
                    Text(segment.title)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedSegment == segment ? Color.orange.opacity(0.2) : Color(.secondarySystemBackground))
                        )
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedSegment == segment ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
                .accessibilityIdentifier("orders_segment_\(segment.rawValue)")
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(emptyTitle)
                .font(.headline)
            Text("Advance orders in Settings or place a new order from the Cart.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
        .accessibilityIdentifier(emptyIdentifier)
    }

    private var emptyTitle: String {
        switch viewModel.selectedSegment {
        case .active:
            return "No active orders"
        case .delivered:
            return "No past orders"
        case .canceled:
            return "No canceled orders"
        }
    }

    private var emptyIdentifier: String {
        switch viewModel.selectedSegment {
        case .active:
            return "orders_no_active_state"
        case .delivered:
            return "orders_no_past_state"
        case .canceled:
            return "orders_no_canceled_state"
        }
    }
}

private struct OrderRowCard: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.orderNumber)
                        .font(.headline)
                    Text(Formatters.shortDate(order.createdAt))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                StatusChipView(status: order.status)
            }

            Text(order.items.map(\.productName).joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(2)

            HStack {
                Text(Formatters.currency(order.estimatedTotal))
                    .font(.subheadline.weight(.bold))
                    .accessibilityIdentifier("order_total_\(order.orderNumber)")
                Spacer()
                Text(order.deliveryOption.estimatedArrival)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

struct OrderDetailView: View {
    @EnvironmentObject private var store: MegaMartStore
    let orderID: String

    var body: some View {
        Group {
            if let order = currentOrder {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.orderNumber)
                                        .font(.title3.weight(.bold))
                                    Text("Placed \(Formatters.detailDate(order.createdAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                StatusChipView(status: order.status)
                            }

                            Text("Total: \(Formatters.currency(order.estimatedTotal))")
                                .font(.headline)
                                .accessibilityIdentifier("order_detail_total_\(order.orderNumber)")
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color(.secondarySystemBackground))
                        )

                        section(title: "Items") {
                            VStack(spacing: 12) {
                                ForEach(order.items) { item in
                                    if let product = store.product(for: item.productID) {
                                        NavigationLink {
                                            ProductDetailView(productID: product.id)
                                        } label: {
                                            HStack {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(item.productName)
                                                        .font(.subheadline.weight(.semibold))
                                                    if !item.selectedVariantValues.isEmpty {
                                                        Text(Formatters.variantSummary(item.selectedVariantValues))
                                                            .font(.caption)
                                                            .foregroundStyle(.secondary)
                                                    }
                                                    Text("Qty \(item.quantity)")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                                Spacer()
                                                Text(Formatters.currency(item.unitPrice * Double(item.quantity)))
                                                    .font(.subheadline.weight(.semibold))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }

                        section(title: "Tracking timeline") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(order.statusEvents) { event in
                                    HStack(alignment: .top, spacing: 12) {
                                        Circle()
                                            .fill(event.status == order.status ? Color.orange : Color.gray.opacity(0.3))
                                            .frame(width: 10, height: 10)
                                            .padding(.top, 4)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.summary)
                                                .font(.subheadline.weight(.semibold))
                                            Text(Formatters.detailDate(event.timestamp))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }

                        section(title: "Delivery and payment") {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(order.deliveryOption.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(order.deliveryOption.estimatedArrival)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Divider()
                                Text(order.shippingAddress.formattedLines.joined(separator: "\n"))
                                    .font(.subheadline)
                                Divider()
                                Text(order.paymentMethod.label)
                                    .font(.subheadline.weight(.semibold))
                                Text(order.paymentMethod.details)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        section(title: "Price summary") {
                            VStack(spacing: 10) {
                                row("Item subtotal", value: Formatters.currency(order.itemSubtotal))
                                row("Shipping", value: order.shippingCost == 0 ? "Free" : Formatters.currency(order.shippingCost))
                                row("Tax", value: Formatters.currency(order.tax))
                                row("Discount", value: "-\(Formatters.currency(order.discount))")
                                row("Estimated total", value: Formatters.currency(order.estimatedTotal), bold: true)
                            }
                        }

                        VStack(spacing: 10) {
                            Button("Buy Again") {
                                store.reorder(orderID: order.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                            .accessibilityIdentifier("order_buy_again_\(order.orderNumber)")

                            if order.canCancel {
                                Button("Cancel Order") {
                                    store.cancelOrder(orderID: order.id)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityIdentifier("order_cancel_\(order.orderNumber)")
                            }

                            NavigationLink {
                                ReturnOrderRequestView(orderID: order.id)
                            } label: {
                                Text(order.status == .returned ? "View Return" : "Return or Replace")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .disabled(order.status != .delivered && order.status != .returned)
                            .accessibilityIdentifier("order_return_replace_\(order.orderNumber)")

                            NavigationLink {
                                CustomerServiceView(orderID: order.id)
                            } label: {
                                Text("Customer Service")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityIdentifier("order_help_\(order.orderNumber)")
                        }
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
                .navigationTitle("Order Details")
                .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Order not found")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentOrder: Order? {
        store.state.orders.first(where: { $0.id == orderID })
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func row(_ title: String, value: String, bold: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(bold ? .subheadline.weight(.bold) : .subheadline)
            Spacer()
            Text(value)
                .font(bold ? .headline.weight(.bold) : .subheadline)
        }
    }
}

private struct ReturnOrderRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    let orderID: String

    @State private var reason = "Damaged item"
    @State private var notes = ""

    private let reasonOptions = [
        "Damaged item",
        "Wrong item",
        "No longer needed",
        "Missing parts"
    ]

    private var order: Order? {
        store.state.orders.first(where: { $0.id == orderID })
    }

    var body: some View {
        Form {
            if let order {
                Section("Order") {
                    Text(order.orderNumber)
                    Text(order.items.map(\.productName).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }

                if order.status == .returned {
                    Section("Return status") {
                        Text("A return has already been started for this order.")
                        Text(order.statusEvents.last?.summary ?? "Return requested")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Section("Return reason") {
                        Picker("Reason", selection: $reason) {
                            ForEach(reasonOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }

                        TextField("Additional notes", text: $notes)
                    }

                    Section {
                        Button("Start return") {
                            let detail = notes.trimmingCharacters(in: .whitespacesAndNewlines)
                            let summary = detail.isEmpty ? reason : "\(reason) - \(detail)"
                            store.requestReturn(orderID: orderID, reason: summary)
                            dismiss()
                        }
                    }
                }
            }
        }
        .navigationTitle("Return or Replace")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CustomerServiceView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: MegaMartStore
    let orderID: String

    @State private var topic = "Delivery issue"
    @State private var message = ""
    @State private var didSubmit = false

    private let topics = [
        "Delivery issue",
        "Billing question",
        "Product support",
        "Return follow-up"
    ]

    private var order: Order? {
        store.state.orders.first(where: { $0.id == orderID })
    }

    var body: some View {
        Form {
            if let order {
                Section("Order") {
                    Text(order.orderNumber)
                    Text(order.items.map(\.productName).joined(separator: ", "))
                        .foregroundStyle(.secondary)
                }
            }

            if didSubmit {
                Section("Request sent") {
                    Text("Customer service has been notified and a local case note was created for this order.")
                    Button("Done") {
                        dismiss()
                    }
                }
            } else {
                Section("Help topic") {
                    Picker("Topic", selection: $topic) {
                        ForEach(topics, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }

                    TextField("Describe the issue", text: $message, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button("Send message") {
                        let detail = message.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.inlineStatusMessage = detail.isEmpty ? "Customer service request sent" : "Customer service noted: \(topic)"
                        didSubmit = true
                    }
                }
            }
        }
        .navigationTitle("Customer Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}
