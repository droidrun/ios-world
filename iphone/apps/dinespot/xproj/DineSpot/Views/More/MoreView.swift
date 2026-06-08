import SwiftUI

struct UpdatesView: View {
    @EnvironmentObject private var store: DiningStore

    private var unreadAlerts: [DiningAlert] {
        store.diningAlerts.filter { !$0.isRead }
    }

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Updates")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .accessibilityIdentifier("updates_title")

                    Spacer()

                    NavigationLink {
                        ProfileView()
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(DiningTheme.textPrimary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("updates_settings_button")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                if store.diningAlerts.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            if unreadAlerts.isEmpty {
                                emptyCaughtUpState
                            }

                            ForEach(store.diningAlerts) { alert in
                                updateCard(alert)
                            }

                            supportLinks
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 110)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityIdentifier("updates_screen")
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bell")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(DiningTheme.textSecondary)
            Text("Nothing to see here, you're all caught up!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("updates_empty_state")
    }

    private var emptyCaughtUpState: some View {
        VStack(spacing: 14) {
            Image(systemName: "bell")
                .font(.system(size: 52, weight: .regular))
                .foregroundStyle(DiningTheme.textSecondary)
            Text("Nothing to see here, you're all caught up!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .accessibilityIdentifier("updates_caught_up_state")
    }

    private func updateCard(_ alert: DiningAlert) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(alert.title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .accessibilityIdentifier("updates_alert_title_\(alert.id)")

                Spacer()

                Text(DateFormatters.weekdayDate.string(from: alert.date))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(DiningTheme.muted)
                    .accessibilityIdentifier("updates_alert_date_\(alert.id)")
            }

            Text(alert.message)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DiningTheme.textSecondary)
                .accessibilityIdentifier("updates_alert_message_\(alert.id)")

            HStack {
                if let restaurantID = alert.restaurantID,
                   let restaurant = store.restaurant(for: restaurantID) {
                    NavigationLink {
                        RestaurantDetailView(restaurantID: restaurant.id)
                    } label: {
                        Text("View restaurant")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(DiningTheme.accentRed)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("updates_view_restaurant_\(alert.id)")
                }

                Spacer()

                if !alert.isRead {
                    Button("Mark read") {
                        store.markAlertRead(alertID: alert.id)
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(DiningTheme.textPrimary)
                    .accessibilityIdentifier("updates_mark_read_\(alert.id)")
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alert.isRead ? DiningTheme.surface.opacity(0.75) : DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(DiningTheme.border, lineWidth: 1)
        )
        .accessibilityIdentifier("updates_alert_row_\(alert.id)")
    }

    private var supportLinks: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Support")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(DiningTheme.textPrimary)

            NavigationLink {
                HelpCenterView()
            } label: {
                supportLinkLabel("Help Center")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("updates_help_center_row")

            NavigationLink {
                ContactSupportView()
            } label: {
                supportLinkLabel("Contact Support")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("updates_contact_support_row")

            NavigationLink {
                ReservationPoliciesView()
            } label: {
                supportLinkLabel("Reservation Policies")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("updates_policies_row")
        }
        .padding(.top, 8)
    }

    private func supportLinkLabel(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(DiningTheme.textPrimary)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(DiningTheme.textSecondary)
        }
        .padding(12)
        .background(DiningTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct HelpCenterView: View {
    private let faqs: [(question: String, answer: String)] = [
        ("How do I make a reservation?", "Search for a restaurant, select your party size, date, and time, then confirm your booking."),
        ("Can I modify my reservation?", "Yes, tap your reservation and select 'Modify' to change the date, time, or party size."),
        ("What is the cancellation policy?", "Policies vary by restaurant. Most allow free cancellation up to 1 hour before your reservation."),
        ("How do points work?", "Earn 100 points per reservation honored. Redeem 2,000 points for a $20 reward."),
        ("What if I'm running late?", "Contact the restaurant directly. Most hold tables for 15 minutes past reservation time."),
        ("How do I leave a review?", "After dining, you'll receive a prompt to rate your experience. You can also find past reservations in your profile.")
    ]

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(faqs.enumerated()), id: \.offset) { index, faq in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(DiningTheme.accentRed)

                                Text(faq.question)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(DiningTheme.textPrimary)
                            }

                            Text(faq.answer)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DiningTheme.textSecondary)
                                .padding(.leading, 30)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DiningTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DiningTheme.border, lineWidth: 1)
                        )
                        .accessibilityIdentifier("help_center_faq_\(index)")
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("help_center_screen")
    }
}

// MARK: - Support Chat LLM Service

private final class SupportLLMService {
    static let shared = SupportLLMService()
    private let session = URLSession.shared

    private func resolveAPIKey() -> String? {
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
           !plistKey.isEmpty, !plistKey.contains("$(") {
            return plistKey
        }
        var dir = Bundle.main.bundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let envFile = dir.appendingPathComponent(".env")
            if let contents = try? String(contentsOf: envFile, encoding: .utf8) {
                for line in contents.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard trimmed.hasPrefix("OPENAI_API_KEY"), let eqIdx = trimmed.firstIndex(of: "=") else { continue }
                    var val = String(trimmed[trimmed.index(after: eqIdx)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                        val = String(val.dropFirst().dropLast())
                    }
                    if !val.isEmpty { return val }
                }
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }
        if let udKey = UserDefaults.standard.string(forKey: "openai_api_key"), !udKey.isEmpty {
            return udKey
        }
        return nil
    }

    var isAvailable: Bool { resolveAPIKey() != nil }

    func generateReply(
        conversationHistory: [(role: String, text: String)],
        userMessage: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let apiKey = resolveAPIKey() else {
            completion(nil)
            return
        }

        let systemPrompt = """
        You are a DineSpot restaurant reservation app support agent. \
        Be helpful, concise, and friendly. Reply in 1-3 sentences. \
        You can help with: reservation issues, account help, restaurant recommendations, \
        payment questions, and general app questions. \
        If asked about a specific reservation, ask for a confirmation code. \
        Do not use emojis. Do not mention being an AI or assistant.
        """

        var transcript = conversationHistory.suffix(10).map { entry in
            let name = entry.role == "agent" ? "Support Agent" : "Customer"
            return "\(name): \(entry.text)"
        }.joined(separator: "\n")
        if !transcript.isEmpty { transcript += "\n" }
        transcript += "Customer: \(userMessage)"

        let messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt],
            ["role": "user", "content": "Conversation:\n\(transcript)\n\nReply as Support Agent:"]
        ]

        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": 200
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body),
              let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        session.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data,
                  let raw = try? JSONSerialization.jsonObject(with: data),
                  let json = raw as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let first = choices.first,
                  let message = first["message"] as? [String: Any],
                  let text = message["content"] as? String else {
                completion(nil)
                return
            }
            completion(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }.resume()
    }
}

// MARK: - Contact Support View

private struct SupportMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let isTyping: Bool

    init(text: String, isUser: Bool, isTyping: Bool = false) {
        self.text = text
        self.isUser = isUser
        self.isTyping = isTyping
    }
}

private struct ContactSupportView: View {
    private let quickReplies = ["Reservation issue", "Account help", "Report a problem", "Other"]

    private let fallbackResponses: [String: String] = [
        "Reservation issue": "I can help with that! Please share your reservation confirmation code and I'll look into it right away.",
        "Account help": "Sure! What do you need help with — updating your profile, resetting your password, or something else?",
        "Report a problem": "I'm sorry to hear that. Please describe the issue and we'll work to resolve it as quickly as possible.",
        "Other": "No problem! Please describe what you need help with and I'll do my best to assist."
    ]

    @State private var messages: [SupportMessage] = [
        SupportMessage(text: "Hi there! How can we help you today?", isUser: false)
    ]
    @State private var showQuickReplies = true
    @State private var userMessage = ""
    @State private var scrollTarget: UUID?
    @FocusState private var isComposerFocused: Bool

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                // Support header
                HStack(spacing: 12) {
                    Image(systemName: "headset.circle.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(DiningTheme.accentRed)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("DineSpot Support")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(DiningTheme.textPrimary)
                        Text("Typically replies within minutes")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(DiningTheme.textSecondary)
                    }

                    Spacer()
                }
                .padding(16)
                .background(DiningTheme.surface)
                .accessibilityIdentifier("contact_support_header")

                Divider().overlay(DiningTheme.border)

                // Chat area
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                                if message.isUser {
                                    userBubble(text: message.text)
                                        .id(message.id)
                                        .accessibilityIdentifier("contact_support_user_msg_\(String(format: "%03d", index))")
                                } else {
                                    supportBubble(text: message.text, isTyping: message.isTyping)
                                        .id(message.id)
                                        .accessibilityIdentifier("contact_support_agent_msg_\(String(format: "%03d", index))")
                                }
                            }

                            if showQuickReplies {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Quick replies")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(DiningTheme.textSecondary)

                                    FlowLayout(spacing: 8) {
                                        ForEach(quickReplies, id: \.self) { reply in
                                            Button {
                                                sendMessage(reply)
                                            } label: {
                                                Text(reply)
                                                    .font(.system(size: 16, weight: .bold))
                                                    .foregroundStyle(DiningTheme.accentRed)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(DiningTheme.accentRed.opacity(0.1))
                                                    .clipShape(Capsule())
                                                    .overlay(
                                                        Capsule().stroke(DiningTheme.accentRed.opacity(0.3), lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                            .accessibilityIdentifier("contact_support_chip_\(reply.lowercased().replacingOccurrences(of: " ", with: "_"))")
                                        }
                                    }
                                }
                                .accessibilityIdentifier("contact_support_quick_replies")
                            }
                        }
                        .padding(16)
                        .padding(.top, 12)
                    }
                    .onChange(of: scrollTarget) { _, target in
                        if let target {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(target, anchor: .bottom)
                            }
                        }
                    }
                }

                // Composer bar
                HStack(spacing: 10) {
                    TextField("Type a message...", text: $userMessage)
                        .textFieldStyle(.roundedBorder)
                        .focused($isComposerFocused)
                        .onSubmit { sendComposerMessage() }
                        .accessibilityIdentifier("contact_support_composer_field")

                    Button {
                        sendComposerMessage()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? DiningTheme.textSecondary.opacity(0.4) : DiningTheme.accentRed)
                    }
                    .buttonStyle(.plain)
                    .disabled(userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("contact_support_send_button")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DiningTheme.surface)
            }
        }
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("contact_support_screen")
    }

    private func sendComposerMessage() {
        let text = userMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        userMessage = ""
        sendMessage(text)
    }

    private func sendMessage(_ text: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            showQuickReplies = false
        }
        let userMsg = SupportMessage(text: text, isUser: true)
        messages.append(userMsg)
        scrollTarget = userMsg.id

        // Add typing indicator
        let typingMsg = SupportMessage(text: "...", isUser: false, isTyping: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            messages.append(typingMsg)
            scrollTarget = typingMsg.id
        }

        let history = messages.filter { !$0.isTyping }.map {
            (role: $0.isUser ? "customer" : "agent", text: $0.text)
        }

        let llm = SupportLLMService.shared
        if llm.isAvailable {
            llm.generateReply(conversationHistory: history, userMessage: text) { reply in
                DispatchQueue.main.async {
                    replaceTypingIndicator(typingID: typingMsg.id, text: reply ?? fallbackReply(for: text))
                }
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                replaceTypingIndicator(typingID: typingMsg.id, text: fallbackReply(for: text))
            }
        }
    }

    private func replaceTypingIndicator(typingID: UUID, text: String) {
        if let idx = messages.firstIndex(where: { $0.id == typingID }) {
            let replyMsg = SupportMessage(text: text, isUser: false)
            messages[idx] = replyMsg
            scrollTarget = replyMsg.id
        }
    }

    private func fallbackReply(for text: String) -> String {
        let lower = text.lowercased()
        if let matched = fallbackResponses[text] {
            return matched
        }
        if lower.contains("reserv") || lower.contains("booking") || lower.contains("cancel") {
            return "I can help with your reservation. Could you share your confirmation code so I can pull up the details?"
        }
        if lower.contains("account") || lower.contains("password") || lower.contains("login") || lower.contains("profile") {
            return "For account-related issues, please go to Profile > Settings to update your information. If you're locked out, I can help with a password reset."
        }
        if lower.contains("refund") || lower.contains("charge") || lower.contains("payment") {
            return "I understand your concern about the charge. Could you share the reservation confirmation code and the amount in question?"
        }
        if lower.contains("recommend") || lower.contains("suggest") || lower.contains("good restaurant") {
            return "I'd love to help you find a great spot! What cuisine are you in the mood for, and what area are you looking in?"
        }
        if lower.contains("thank") || lower.contains("thx") {
            return "You're welcome! Is there anything else I can help you with?"
        }
        return "Thanks for reaching out. Let me look into that for you. Could you provide a bit more detail so I can assist you better?"
    }

    private func userBubble(text: String) -> some View {
        HStack {
            Spacer()
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .padding(12)
                .background(DiningTheme.accentRed)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private func supportBubble(text: String, isTyping: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DiningTheme.accentRed)

            VStack(alignment: .leading, spacing: 4) {
                Text("Support Agent")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DiningTheme.textSecondary)

                if isTyping {
                    Text("...")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(DiningTheme.textSecondary)
                        .padding(12)
                        .background(DiningTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DiningTheme.border, lineWidth: 1)
                        )
                } else {
                    Text(text)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(DiningTheme.textPrimary)
                        .padding(12)
                        .background(DiningTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DiningTheme.border, lineWidth: 1)
                        )
                }
            }

            Spacer()
        }
    }
}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > maxWidth, currentX > 0 {
                currentY += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }

        return CGSize(width: maxWidth, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX, currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

private struct ReservationPoliciesView: View {
    private let policies: [(icon: String, title: String, description: String)] = [
        ("xmark.circle", "Cancellation Policy", "Free cancellation is available up to 1 hour before your reservation time. Late cancellations may result in a fee determined by the restaurant. Repeated late cancellations may affect your account standing."),
        ("exclamationmark.triangle", "No-Show Policy", "Failing to honor a reservation without canceling will be recorded on your account. Accumulating four no-shows within a 12-month period may result in temporary suspension of online booking privileges."),
        ("clock.badge.exclamationmark", "Late Arrival", "Tables are typically held for 15 minutes past the reservation time. After that, the table may be released to other diners. If you are running late, contact the restaurant directly to let them know."),
        ("creditcard", "Payment Holds", "Some restaurants require a credit card to hold your reservation. A temporary authorization may appear on your statement but will not be charged unless you cancel late or fail to show up. Hold amounts vary by restaurant.")
    ]

    var body: some View {
        ZStack {
            DiningTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(policies.enumerated()), id: \.offset) { index, policy in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 10) {
                                Image(systemName: policy.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(DiningTheme.accentRed)
                                    .frame(width: 28)

                                Text(policy.title)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(DiningTheme.textPrimary)
                            }

                            Text(policy.description)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(DiningTheme.textSecondary)
                                .padding(.leading, 38)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DiningTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(DiningTheme.border, lineWidth: 1)
                        )
                        .accessibilityIdentifier("reservation_policy_\(index)")
                    }
                }
                .padding(16)
                .padding(.bottom, 20)
            }
        }
        .navigationTitle("Reservation Policies")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("reservation_policies_screen")
    }
}

// Backward-compatible alias for older navigation references.
struct MoreView: View {
    var body: some View {
        UpdatesView()
    }
}
