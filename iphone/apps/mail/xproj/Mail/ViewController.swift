import UIKit
import UserNotifications
import Contacts

enum MailAppearance {
    private static let key = "mail_app_dark_mode"

    static var isDarkMode: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    static var interfaceStyle: UIUserInterfaceStyle {
        isDarkMode ? .dark : .light
    }

    static func apply(to controller: UIViewController) {
        controller.overrideUserInterfaceStyle = interfaceStyle
    }

    static func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
        NotificationCenter.default.post(name: .mailAppearanceDidChange, object: nil)
    }
}

enum MailFolder: Int, CaseIterable {
    case inbox
    case drafts
    case scheduled
    case sent
    case archive
    case trash

    var title: String {
        switch self {
        case .inbox:
            return "Inbox"
        case .drafts:
            return "Drafts"
        case .scheduled:
            return "Send Later"
        case .sent:
            return "Sent"
        case .archive:
            return "Archive"
        case .trash:
            return "Trash"
        }
    }
}

enum MailCategory: Int, CaseIterable {
    case all
    case transactions
    case updates
    case promotions

    var title: String {
        switch self {
        case .all:
            return "Primary"
        case .transactions:
            return "Transactions"
        case .updates:
            return "Updates"
        case .promotions:
            return "Promotions"
        }
    }
}

enum MailAttachmentTemplate: String, CaseIterable {
    case receipt
    case boardingPass
    case dashboard
    case property
    case whiteboard
    case poster
    case menu
    case product
}

struct MailAttachment {
    let id: UUID
    var filename: String
    var title: String
    var subtitle: String
    var template: MailAttachmentTemplate
}

struct MailItem {
    let id: UUID
    var threadId: String
    var from: String
    var to: String
    var subject: String
    var body: String
    var preview: String
    var date: Date
    var folder: MailFolder
    var category: MailCategory
    var isUnread: Bool
    var scheduledSend: Date?
    var attachments: [MailAttachment]
}

private enum MailTheme {
    static let accountName = "Mail"
    static let accountEmail = "jordan.avery@email.com"

    static let groupedBackground = UIColor.systemGroupedBackground
    static let cardBackground = UIColor.secondarySystemGroupedBackground
    static let elevatedBackground = UIColor.tertiarySystemGroupedBackground
    static let mutedFill = UIColor.tertiarySystemFill

    static func tintedBackground(for tint: UIColor) -> UIColor {
        UIColor { trait in
            tint.resolvedColor(with: trait).withAlphaComponent(trait.userInterfaceStyle == .dark ? 0.22 : 0.12)
        }
    }

    static func folderTint(for folder: MailFolder) -> UIColor {
        switch folder {
        case .inbox:
            return .systemBlue
        case .drafts:
            return .systemOrange
        case .scheduled:
            return .systemTeal
        case .sent:
            return .systemGreen
        case .archive:
            return .systemIndigo
        case .trash:
            return .systemRed
        }
    }
}

private let mailCountFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()

private func formatMailCount(_ count: Int) -> String {
    mailCountFormatter.string(from: NSNumber(value: count)) ?? "\(count)"
}

private func formatMailAttachmentCount(_ count: Int) -> String {
    count == 1 ? "1 image" : "\(count) images"
}

private func mailPreviewText(body: String, attachments: [MailAttachment]) -> String {
    let compact = body.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
    if !compact.isEmpty {
        return compact.count > 80 ? String(compact.prefix(80)) + "..." : compact
    }
    guard let firstAttachment = attachments.first else { return "" }
    let base = attachments.count > 1 ? "Attached \(formatMailAttachmentCount(attachments.count)): \(firstAttachment.title)" : "Attached: \(firstAttachment.title)"
    return base.count > 80 ? String(base.prefix(80)) + "..." : base
}

private func mailFolderDisplayTitle(_ folder: MailFolder) -> String {
    folder == .inbox ? "All Inboxes" : folder.title
}

private func makeAttachment(_ template: MailAttachmentTemplate, filename: String? = nil, title: String? = nil, subtitle: String? = nil) -> MailAttachment {
    switch template {
    case .receipt:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "expense-receipt.png",
            title: title ?? "Expense Receipt",
            subtitle: subtitle ?? "Amount: $184.33",
            template: template
        )
    case .boardingPass:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "boarding-pass.png",
            title: title ?? "Boarding Pass",
            subtitle: subtitle ?? "SFO to JFK • Seat 2A",
            template: template
        )
    case .dashboard:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "growth-dashboard.png",
            title: title ?? "Growth Dashboard",
            subtitle: subtitle ?? "Q1 funnel snapshot",
            template: template
        )
    case .property:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "listing-photo.png",
            title: title ?? "Listing Photo",
            subtitle: subtitle ?? "Open house hero image",
            template: template
        )
    case .whiteboard:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "whiteboard-notes.png",
            title: title ?? "Whiteboard Notes",
            subtitle: subtitle ?? "Product review capture",
            template: template
        )
    case .poster:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "event-poster.png",
            title: title ?? "Event Poster",
            subtitle: subtitle ?? "Creative approval candidate",
            template: template
        )
    case .menu:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "menu-proof.png",
            title: title ?? "Menu Proof",
            subtitle: subtitle ?? "Final print-ready layout",
            template: template
        )
    case .product:
        return MailAttachment(
            id: UUID(),
            filename: filename ?? "product-shot.png",
            title: title ?? "Product Shot",
            subtitle: subtitle ?? "Launch image option",
            template: template
        )
    }
}

private func mailInitials(from value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    let source = trimmed.contains("@") ? String(trimmed.split(separator: "@").first ?? "") : trimmed
    let pieces = source
        .replacingOccurrences(of: "&", with: " ")
        .split(whereSeparator: { $0 == " " || $0 == "." || $0 == "_" || $0 == "-" })
    let initials = pieces.prefix(2).compactMap { $0.first }.map(String.init).joined()
    if !initials.isEmpty {
        return initials.uppercased()
    }
    guard let first = trimmed.first else { return "?" }
    return String(first).uppercased()
}

private func mailAvatarPalette(for sender: String) -> (background: UIColor, foreground: UIColor, symbol: String?) {
    let lowercased = sender.lowercased()
    if lowercased.contains("robinhood") {
        return (UIColor(red: 0.82, green: 0.96, blue: 0.06, alpha: 1), .black, "chart.line.uptrend.xyaxis")
    }
    if lowercased.contains("icloud") {
        return (UIColor(red: 0.84, green: 0.42, blue: 0.81, alpha: 1), .white, "star.fill")
    }
    if lowercased.contains("openai") {
        return (UIColor(red: 0.70, green: 0.80, blue: 0.94, alpha: 1), .white, "sparkles")
    }
    if lowercased.contains("chase") || lowercased.contains("finance") {
        return (UIColor(red: 0.67, green: 0.77, blue: 0.90, alpha: 1), .white, "building.columns.fill")
    }
    if lowercased.contains("seattle mariners") || lowercased.contains("mariners") {
        return (UIColor(red: 0.05, green: 0.38, blue: 0.48, alpha: 1), .white, "sportscourt.fill")
    }
    if lowercased.contains("travel") || lowercased.contains("air") {
        return (.systemTeal, .white, "airplane")
    }
    if lowercased.contains("operations") || lowercased.contains("workspace") {
        return (.systemIndigo, .white, "briefcase.fill")
    }

    let hash = abs(sender.hashValue)
    let hue = CGFloat(hash % 256) / 255.0
    return (UIColor(hue: hue, saturation: 0.42, brightness: 0.82, alpha: 1), .white, nil)
}

final class MailAvatarView: UIView {
    private let initialsLabel = UILabel()
    private let symbolView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true

        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        initialsLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        initialsLabel.textAlignment = .center

        symbolView.translatesAutoresizingMaskIntoConstraints = false
        symbolView.contentMode = .scaleAspectFit
        symbolView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)

        addSubview(initialsLabel)
        addSubview(symbolView)

        NSLayoutConstraint.activate([
            initialsLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            initialsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            symbolView.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: centerYAnchor),
            symbolView.widthAnchor.constraint(equalToConstant: 20),
            symbolView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func configure(sender: String) {
        let palette = mailAvatarPalette(for: sender)
        backgroundColor = palette.background
        initialsLabel.textColor = palette.foreground
        symbolView.tintColor = palette.foreground

        if let symbol = palette.symbol {
            symbolView.image = UIImage(systemName: symbol)
            symbolView.isHidden = false
            initialsLabel.isHidden = true
        } else {
            initialsLabel.text = mailInitials(from: sender)
            initialsLabel.isHidden = false
            symbolView.isHidden = true
        }
    }
}

private enum MailAttachmentRenderer {
    static func image(for attachment: MailAttachment, size: CGSize? = nil) -> UIImage {
        let canvasSize = size ?? preferredCanvasSize(for: attachment.template)
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: canvasSize)
            let cgContext = context.cgContext

            drawBackground(for: attachment.template, in: rect, context: cgContext)
            drawContent(for: attachment, in: rect, context: cgContext)
            drawFooter(for: attachment, in: rect, context: cgContext)
        }
    }

    private static func preferredCanvasSize(for template: MailAttachmentTemplate) -> CGSize {
        switch template {
        case .dashboard, .whiteboard, .menu:
            return CGSize(width: 1200, height: 900)
        case .property, .poster, .product:
            return CGSize(width: 1080, height: 1350)
        case .receipt, .boardingPass:
            return CGSize(width: 1080, height: 1440)
        }
    }

    private static func drawBackground(for template: MailAttachmentTemplate, in rect: CGRect, context: CGContext) {
        let colors: [UIColor]
        switch template {
        case .receipt:
            colors = [UIColor(red: 0.93, green: 0.93, blue: 0.95, alpha: 1), UIColor(red: 0.86, green: 0.87, blue: 0.90, alpha: 1)]
        case .boardingPass:
            colors = [UIColor(red: 0.08, green: 0.46, blue: 0.92, alpha: 1), UIColor(red: 0.14, green: 0.78, blue: 0.89, alpha: 1)]
        case .dashboard:
            colors = [UIColor(red: 0.05, green: 0.11, blue: 0.20, alpha: 1), UIColor(red: 0.10, green: 0.19, blue: 0.33, alpha: 1)]
        case .property:
            colors = [UIColor(red: 0.48, green: 0.79, blue: 0.96, alpha: 1), UIColor(red: 0.94, green: 0.74, blue: 0.53, alpha: 1)]
        case .whiteboard:
            colors = [UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1), UIColor(red: 0.91, green: 0.88, blue: 0.80, alpha: 1)]
        case .poster:
            colors = [UIColor(red: 0.98, green: 0.54, blue: 0.19, alpha: 1), UIColor(red: 0.85, green: 0.18, blue: 0.24, alpha: 1)]
        case .menu:
            colors = [UIColor(red: 0.96, green: 0.92, blue: 0.84, alpha: 1), UIColor(red: 0.89, green: 0.83, blue: 0.72, alpha: 1)]
        case .product:
            colors = [UIColor(red: 0.95, green: 0.87, blue: 0.80, alpha: 1), UIColor(red: 0.84, green: 0.90, blue: 0.96, alpha: 1)]
        }

        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors.map(\.cgColor) as CFArray,
            locations: [0, 1]
        ) else { return }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.minX, y: rect.minY),
            end: CGPoint(x: rect.maxX, y: rect.maxY),
            options: []
        )
    }

    private static func drawContent(for attachment: MailAttachment, in rect: CGRect, context: CGContext) {
        switch attachment.template {
        case .receipt:
            drawReceipt(in: rect, context: context)
        case .boardingPass:
            drawBoardingPass(in: rect, context: context)
        case .dashboard:
            drawDashboard(in: rect, context: context)
        case .property:
            drawProperty(in: rect, context: context)
        case .whiteboard:
            drawWhiteboard(in: rect, context: context)
        case .poster:
            drawPoster(in: rect, context: context)
        case .menu:
            drawMenu(in: rect, context: context)
        case .product:
            drawProduct(in: rect, context: context)
        }
    }

    private static func drawFooter(for attachment: MailAttachment, in rect: CGRect, context: CGContext) {
        let footerRect = CGRect(x: 0, y: rect.height - 220, width: rect.width, height: 220)
        context.saveGState()
        context.setFillColor(UIColor.black.withAlphaComponent(0.28).cgColor)
        context.fill(footerRect)
        context.restoreGState()

        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 56, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 28, weight: .medium),
            .foregroundColor: UIColor.white.withAlphaComponent(0.88)
        ]

        attachment.title.draw(in: CGRect(x: 60, y: rect.height - 182, width: rect.width - 120, height: 72), withAttributes: titleAttributes)
        attachment.subtitle.draw(in: CGRect(x: 60, y: rect.height - 104, width: rect.width - 120, height: 44), withAttributes: subtitleAttributes)
    }

    private static func drawReceipt(in rect: CGRect, context: CGContext) {
        let page = CGRect(x: rect.width * 0.14, y: rect.height * 0.08, width: rect.width * 0.72, height: rect.height * 0.64)
        let pagePath = UIBezierPath(roundedRect: page, cornerRadius: 28)
        UIColor.white.setFill()
        pagePath.fill()

        let mono = UIFont.monospacedSystemFont(ofSize: 28, weight: .regular)
        let bold = UIFont.monospacedSystemFont(ofSize: 36, weight: .bold)
        "RECEIPT".draw(in: CGRect(x: page.minX + 36, y: page.minY + 34, width: page.width - 72, height: 42), withAttributes: [.font: bold, .foregroundColor: UIColor.black])

        let lineColor = UIColor(white: 0.88, alpha: 1).cgColor
        for row in 0..<9 {
            let y = page.minY + 120 + CGFloat(row) * 56
            context.setStrokeColor(lineColor)
            context.setLineWidth(2)
            context.move(to: CGPoint(x: page.minX + 36, y: y))
            context.addLine(to: CGPoint(x: page.maxX - 36, y: y))
            context.strokePath()
        }

        "$184.33".draw(in: CGRect(x: page.minX + 36, y: page.maxY - 120, width: page.width - 72, height: 48), withAttributes: [.font: bold, .foregroundColor: UIColor.black])
        "Total".draw(in: CGRect(x: page.minX + 36, y: page.maxY - 164, width: page.width - 72, height: 40), withAttributes: [.font: mono, .foregroundColor: UIColor.darkGray])
    }

    private static func drawBoardingPass(in rect: CGRect, context: CGContext) {
        let ticket = CGRect(x: rect.width * 0.1, y: rect.height * 0.14, width: rect.width * 0.8, height: rect.height * 0.5)
        let ticketPath = UIBezierPath(roundedRect: ticket, cornerRadius: 38)
        UIColor.white.setFill()
        ticketPath.fill()

        UIColor.systemBlue.setFill()
        UIBezierPath(roundedRect: CGRect(x: ticket.minX, y: ticket.minY, width: ticket.width, height: 140), cornerRadius: 38).fill()

        let topAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 30, weight: .semibold), .foregroundColor: UIColor.white]
        "ALASKA".draw(in: CGRect(x: ticket.minX + 42, y: ticket.minY + 40, width: 220, height: 40), withAttributes: topAttrs)

        let airportAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 72, weight: .bold), .foregroundColor: UIColor.black]
        "SFO".draw(in: CGRect(x: ticket.minX + 54, y: ticket.minY + 190, width: 180, height: 84), withAttributes: airportAttrs)
        "JFK".draw(in: CGRect(x: ticket.maxX - 234, y: ticket.minY + 190, width: 180, height: 84), withAttributes: airportAttrs)

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 46, weight: .bold)
        UIImage(systemName: "airplane", withConfiguration: iconConfig)?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal).draw(in: CGRect(x: ticket.midX - 32, y: ticket.minY + 214, width: 64, height: 64))
    }

    private static func drawDashboard(in rect: CGRect, context: CGContext) {
        let panel = CGRect(x: 56, y: 80, width: rect.width - 112, height: rect.height - 300)
        UIColor.white.withAlphaComponent(0.08).setFill()
        UIBezierPath(roundedRect: panel, cornerRadius: 36).fill()

        let cardWidth = (panel.width - 36 * 4) / 3
        for index in 0..<3 {
            let card = CGRect(x: panel.minX + 36 + CGFloat(index) * (cardWidth + 36), y: panel.minY + 36, width: cardWidth, height: 140)
            UIColor.white.withAlphaComponent(0.09).setFill()
            UIBezierPath(roundedRect: card, cornerRadius: 24).fill()
        }

        let path = UIBezierPath()
        path.move(to: CGPoint(x: panel.minX + 40, y: panel.maxY - 140))
        path.addCurve(to: CGPoint(x: panel.minX + panel.width * 0.4, y: panel.maxY - 260), controlPoint1: CGPoint(x: panel.minX + 120, y: panel.maxY - 220), controlPoint2: CGPoint(x: panel.minX + 240, y: panel.maxY - 320))
        path.addCurve(to: CGPoint(x: panel.maxX - 40, y: panel.minY + 250), controlPoint1: CGPoint(x: panel.minX + panel.width * 0.58, y: panel.maxY - 180), controlPoint2: CGPoint(x: panel.maxX - 180, y: panel.minY + 180))
        UIColor.systemGreen.setStroke()
        path.lineWidth = 14
        path.stroke()
    }

    private static func drawProperty(in rect: CGRect, context: CGContext) {
        UIColor(red: 0.31, green: 0.62, blue: 0.29, alpha: 1).setFill()
        UIBezierPath(rect: CGRect(x: 0, y: rect.height * 0.62, width: rect.width, height: rect.height * 0.38)).fill()

        let house = CGRect(x: rect.width * 0.18, y: rect.height * 0.27, width: rect.width * 0.5, height: rect.height * 0.34)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: house, cornerRadius: 18).fill()

        let roof = UIBezierPath()
        roof.move(to: CGPoint(x: house.minX - 24, y: house.minY + 44))
        roof.addLine(to: CGPoint(x: house.midX, y: house.minY - 72))
        roof.addLine(to: CGPoint(x: house.maxX + 24, y: house.minY + 44))
        roof.close()
        UIColor(red: 0.38, green: 0.27, blue: 0.22, alpha: 1).setFill()
        roof.fill()

        UIColor(red: 0.76, green: 0.86, blue: 0.96, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: house.minX + 42, y: house.minY + 46, width: 120, height: 86), cornerRadius: 12).fill()
        UIBezierPath(roundedRect: CGRect(x: house.minX + 208, y: house.minY + 46, width: 120, height: 86), cornerRadius: 12).fill()
        UIColor(red: 0.58, green: 0.40, blue: 0.27, alpha: 1).setFill()
        UIBezierPath(roundedRect: CGRect(x: house.minX + 176, y: house.maxY - 160, width: 96, height: 160), cornerRadius: 16).fill()
    }

    private static func drawWhiteboard(in rect: CGRect, context: CGContext) {
        let board = CGRect(x: 64, y: 72, width: rect.width - 128, height: rect.height - 300)
        UIColor.white.setFill()
        UIBezierPath(roundedRect: board, cornerRadius: 26).fill()

        let stickyColors = [UIColor.systemPink, UIColor.systemYellow, UIColor.systemTeal]
        for index in 0..<3 {
            let sticky = CGRect(x: board.minX + 54 + CGFloat(index) * 210, y: board.minY + 60, width: 160, height: 144)
            stickyColors[index].withAlphaComponent(0.72).setFill()
            UIBezierPath(roundedRect: sticky, cornerRadius: 16).fill()
        }

        let arrow = UIBezierPath()
        arrow.move(to: CGPoint(x: board.minX + 120, y: board.midY))
        arrow.addCurve(to: CGPoint(x: board.maxX - 150, y: board.midY + 110), controlPoint1: CGPoint(x: board.minX + 260, y: board.midY - 80), controlPoint2: CGPoint(x: board.maxX - 280, y: board.midY + 160))
        UIColor.systemIndigo.setStroke()
        arrow.lineWidth = 12
        arrow.stroke()
    }

    private static func drawPoster(in rect: CGRect, context: CGContext) {
        let circle = UIBezierPath(ovalIn: CGRect(x: rect.width * 0.2, y: rect.height * 0.12, width: rect.width * 0.6, height: rect.width * 0.6))
        UIColor.white.withAlphaComponent(0.12).setFill()
        circle.fill()

        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 220, weight: .bold)
        UIImage(systemName: "music.mic", withConfiguration: symbolConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: CGRect(x: rect.midX - 110, y: rect.height * 0.18, width: 220, height: 220))
    }

    private static func drawMenu(in rect: CGRect, context: CGContext) {
        let page = CGRect(x: 88, y: 72, width: rect.width - 176, height: rect.height - 260)
        UIColor.white.withAlphaComponent(0.94).setFill()
        UIBezierPath(roundedRect: page, cornerRadius: 30).fill()

        let sectionAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 34, weight: .semibold), .foregroundColor: UIColor.black]
        "DINNER".draw(in: CGRect(x: page.minX + 40, y: page.minY + 36, width: 200, height: 44), withAttributes: sectionAttrs)
        for row in 0..<7 {
            let y = page.minY + 124 + CGFloat(row) * 84
            UIColor(white: 0.85, alpha: 1).setFill()
            UIBezierPath(roundedRect: CGRect(x: page.minX + 40, y: y, width: page.width - 80, height: 12), cornerRadius: 6).fill()
            UIBezierPath(roundedRect: CGRect(x: page.minX + 40, y: y + 24, width: page.width * 0.45, height: 10), cornerRadius: 5).fill()
        }
    }

    private static func drawProduct(in rect: CGRect, context: CGContext) {
        let shadowRect = CGRect(x: rect.width * 0.28, y: rect.height * 0.22, width: rect.width * 0.44, height: rect.height * 0.42)
        UIColor.black.withAlphaComponent(0.12).setFill()
        UIBezierPath(roundedRect: shadowRect.offsetBy(dx: 0, dy: 20), cornerRadius: 42).fill()

        let box = UIBezierPath(roundedRect: shadowRect, cornerRadius: 42)
        UIColor.white.setFill()
        box.fill()

        let band = CGRect(x: shadowRect.minX, y: shadowRect.minY + 120, width: shadowRect.width, height: 220)
        UIColor(red: 0.97, green: 0.56, blue: 0.44, alpha: 1).setFill()
        UIBezierPath(roundedRect: band, cornerRadius: 24).fill()

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .medium)
        UIImage(systemName: "shippingbox.fill", withConfiguration: iconConfig)?.withTintColor(.white, renderingMode: .alwaysOriginal).draw(in: CGRect(x: rect.midX - 60, y: band.midY - 60, width: 120, height: 120))
    }
}

extension Notification.Name {
    static let mailStoreDidChange = Notification.Name("MailStoreDidChange")
    static let mailAIReplyFailed = Notification.Name("MailAIReplyFailed")
    static let mailAppearanceDidChange = Notification.Name("MailAppearanceDidChange")
}

struct SharedMailRecord: Codable {
    let id: UUID
    let from: String
    let subject: String
    let body: String
    let category: Int
    let date: Date
}

final class MailSharedInboxService {
    private let fileName = "mail_inbox.json"
    private let appGroupID = "group.com.iosworld.benchmark.personalsuite"

    private var inboxURL: URL? {
        if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            return appGroupURL.appendingPathComponent(fileName)
        }
        return nil
    }

    func loadRecords() -> [SharedMailRecord] {
        guard let url = inboxURL, let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([SharedMailRecord].self, from: data)) ?? []
    }
}

final class MailStore {
    static let shared = MailStore()

    private(set) var items: [MailItem]
    private let sharedInboxService = MailSharedInboxService()
    private let importedKey = "mail_imported_external_ids"
    private let readItemsKey = "mail_read_item_ids"
    private var importedExternalIds: Set<String>
    private var sharedSyncTimer: Timer?
    private let sharedInboxIOQueue = DispatchQueue(label: "mail.sharedinbox.io", qos: .utility)
    private let notificationSenders = [
        "Omar Reyes",
        "Devon Hart",
        "Blair Morgan",
        "Micah Chen",
        "Nimbus Workspace",
        "Finance Team",
        "Skyline Travel",
        "Operations",
        "HR Desk"
    ]
    private let notificationSubjects = [
        "Quick follow-up",
        "Action needed today",
        "Updated timeline",
        "Invoice available",
        "Meeting recap",
        "Logistics update",
        "Travel confirmation",
        "Draft for review"
    ]
    private let notificationBodies = [
        "Hi Jordan,\n\nQuick update on our end. The latest changes are in the shared folder. Let me know if you want a walkthrough.\n\nBest,\n",
        "Jordan,\n\nWe are ready to move forward. Please confirm the timing so we can send the final materials.\n\nThanks,\n",
        "Hello,\n\nHere is the latest status update along with next steps. We are on track for this week.\n\nRegards,\n",
        "Hi,\n\nAttached is the updated document. Please review and share any comments by EOD.\n\nThanks,\n",
        "Jordan,\n\nSharing a quick recap from today. Let me know if anything should be adjusted.\n\nBest,\n"
    ]
    private let notificationCategories: [MailCategory] = [.transactions, .updates, .promotions]

    private init() {
        importedExternalIds = Set(UserDefaults.standard.stringArray(forKey: importedKey) ?? [])
        let readIDs = Set((UserDefaults.standard.stringArray(forKey: readItemsKey) ?? []).compactMap { UUID(uuidString: $0) })
        let now = Date()
        var seeded = MailStore.seedItems(now: now)
        if !readIDs.isEmpty {
            for i in seeded.indices where readIDs.contains(seeded[i].id) {
                seeded[i].isUnread = false
            }
        }
        items = seeded
        importSharedInbox(silent: true)
        startSharedInboxSync()
    }

    private func persistReadState() {
        let readIDs = items.filter { !$0.isUnread }.map { $0.id.uuidString }
        UserDefaults.standard.set(readIDs, forKey: readItemsKey)
    }

    func items(in folder: MailFolder) -> [MailItem] {
        items
            .filter { $0.folder == folder }
            .sorted { $0.date > $1.date }
    }

    func count(in folder: MailFolder) -> Int {
        items.filter { $0.folder == folder }.count
    }

    func unreadCount(in folder: MailFolder) -> Int {
        items.filter { $0.folder == folder && $0.isUnread }.count
    }

    func item(for id: UUID) -> MailItem? {
        items.first { $0.id == id }
    }

    func threadItems(for threadId: String) -> [MailItem] {
        items.filter { $0.threadId == threadId }.sorted { $0.date < $1.date }
    }

    func add(_ item: MailItem) {
        items.insert(item, at: 0)
        notify()
    }

    func addIncomingMail(from: String, subject: String, body: String, category: MailCategory, date: Date) {
        let item = MailStore.makeItem(
            from: from,
            to: "You",
            subject: subject,
            body: body,
            date: date,
            folder: .inbox,
            category: category,
            isUnread: true,
            attachments: []
        )
        add(item)
    }

    func importSharedInbox(silent: Bool = false) {
        sharedInboxIOQueue.async { [weak self] in
            guard let self = self else { return }
            let records = self.sharedInboxService.loadRecords()
            guard !records.isEmpty else { return }
            DispatchQueue.main.async { [weak self] in
                self?.applyImportedRecords(records, silent: silent)
            }
        }
    }

    private func applyImportedRecords(_ records: [SharedMailRecord], silent: Bool) {
        var imported = 0
        for record in records {
            let idString = record.id.uuidString
            if importedExternalIds.contains(idString) || items.contains(where: { $0.id == record.id }) {
                continue
            }
            let category = MailCategory(rawValue: record.category) ?? .transactions
            let item = MailStore.makeItem(
                id: record.id,
                from: record.from,
                to: "You",
                subject: record.subject,
                body: record.body,
                date: record.date,
                folder: .inbox,
                category: category,
                isUnread: true,
                attachments: []
            )
            items.insert(item, at: 0)
            importedExternalIds.insert(idString)
            imported += 1
        }
        if imported > 0 {
            saveImportedIds()
            notify()
        } else if !silent {
            notify()
        }
    }

    func randomNotificationPayload() -> MailNotificationPayload {
        let sender = notificationSenders.randomElement() ?? "Operations"
        let subject = notificationSubjects.randomElement() ?? "Quick update"
        let base = notificationBodies.randomElement() ?? "Hi,\n\nQuick note with a short update.\n\nBest,\n"
        let body = "\(base)\(sender)"
        let category = notificationCategories.randomElement() ?? .updates
        return MailNotificationPayload(from: sender, subject: subject, body: body, category: category)
    }

    func update(_ item: MailItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = item
        notify()
    }

    private func startSharedInboxSync() {
        sharedSyncTimer?.invalidate()
        sharedSyncTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.importSharedInbox(silent: true)
        }
    }

    private func saveImportedIds() {
        UserDefaults.standard.set(Array(importedExternalIds), forKey: importedKey)
    }

    func move(id: UUID, to folder: MailFolder, scheduledSend: Date? = nil) {
        guard var item = item(for: id) else { return }
        item.folder = folder
        item.scheduledSend = scheduledSend
        if folder != .inbox {
            item.isUnread = false
        }
        update(item)
        persistReadState()
    }

    func markRead(id: UUID) {
        guard var item = item(for: id) else { return }
        guard item.isUnread else { return }
        item.isUnread = false
        update(item)
        persistReadState()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        notify()
    }

    func sendMessage(to recipient: String, subject: String, body: String, category: MailCategory, attachments: [MailAttachment], threadId: String? = nil) {
        let trimmedSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let subjectLine = trimmedSubject.isEmpty ? "(no subject)" : trimmedSubject
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        let bodyText = trimmedBody.isEmpty && !attachments.isEmpty ? "Attached \(formatMailAttachmentCount(attachments.count))." : trimmedBody
        let tid = threadId ?? UUID().uuidString
        let sentMail = MailStore.makeItem(
            threadId: tid,
            from: "You",
            to: recipient,
            subject: subjectLine,
            body: bodyText,
            date: Date(),
            folder: .sent,
            category: category,
            isUnread: false,
            attachments: attachments
        )
        add(sentMail)
        simulateResponse(to: recipient, subject: subjectLine, originalBody: bodyText, category: category, threadId: tid)
    }

    func simulateResponse(to recipient: String, subject: String, originalBody: String, category: MailCategory, threadId: String) {
        let subjectLine = subject.lowercased().hasPrefix("re:") ? subject : "Re: \(subject)"
        let sender = recipient.isEmpty ? "Client" : recipient

        let keyResult = OpenAISettings.shared.validatedApiKey()
        guard let apiKey = keyResult.key else {
            deliverFallbackReply(from: sender, subject: subjectLine, originalBody: originalBody, category: category, threadId: threadId)
            return
        }

        OpenAIClient.shared.generateReply(to: sender, subject: subjectLine, body: originalBody, apiKey: apiKey) { [weak self] result in
            switch result {
            case .success(let response):
                let reply = MailStore.makeItem(
                    threadId: threadId,
                    from: sender,
                    to: "You",
                    subject: subjectLine,
                    body: response,
                    date: Date(),
                    folder: .inbox,
                    category: category,
                    isUnread: true
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    self?.add(reply)
                }
            case .failure:
                self?.deliverFallbackReply(from: sender, subject: subjectLine, originalBody: originalBody, category: category, threadId: threadId)
            }
        }
    }

    private func deliverFallbackReply(from sender: String, subject: String, originalBody: String, category: MailCategory, threadId: String) {
        let lower = originalBody.lowercased()
        let body: String
        if lower.contains("meeting") || lower.contains("schedule") || lower.contains("calendar") {
            body = "Thanks for reaching out. Let me check my calendar and get back to you with some available times. I should have an update for you shortly."
        } else if lower.contains("update") || lower.contains("status") || lower.contains("progress") {
            body = "Thanks for checking in. Things are moving along well on my end. I'll put together a more detailed update and send it over soon."
        } else if lower.contains("question") || lower.contains("help") || lower.contains("issue") || lower.contains("problem") {
            body = "Thanks for bringing this up. Let me look into it and I'll follow up with more details. Feel free to send over any additional context in the meantime."
        } else if lower.contains("thank") || lower.contains("appreciate") {
            body = "You're welcome! Happy to help. Don't hesitate to reach out if anything else comes up."
        } else if lower.contains("confirm") || lower.contains("approve") || lower.contains("sign") {
            body = "Received, thank you. I'll review everything and confirm once I've had a chance to go through the details."
        } else {
            body = "Thanks for your email. I've noted everything and will get back to you with a proper response shortly."
        }
        let reply = MailStore.makeItem(
            threadId: threadId,
            from: sender,
            to: "You",
            subject: subject,
            body: body,
            date: Date(),
            folder: .inbox,
            category: category,
            isUnread: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.add(reply)
        }
    }

    private func notifyAIReplyFailed(_ message: String) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .mailAIReplyFailed, object: nil, userInfo: ["message": message])
        }
    }

    private func notify() {
        NotificationCenter.default.post(name: .mailStoreDidChange, object: nil)
    }

    private static func makeItem(id: UUID = UUID(), threadId: String? = nil, from: String, to: String, subject: String, body: String, date: Date, folder: MailFolder, category: MailCategory, isUnread: Bool, attachments: [MailAttachment] = []) -> MailItem {
        return MailItem(
            id: id,
            threadId: threadId ?? UUID().uuidString,
            from: from,
            to: to,
            subject: subject,
            body: body,
            preview: mailPreviewText(body: body, attachments: attachments),
            date: date,
            folder: folder,
            category: category,
            isUnread: isUnread,
            scheduledSend: nil,
            attachments: attachments
        )
    }

    private static func seedItems(now: Date) -> [MailItem] {
        [
            MailStore.makeItem(
                from: "Robinhood",
                to: "You",
                subject: "Discover what Wall Street analysts are buying",
                body: "With the analyst ratings screener, find stocks with analyst buy ratings and price target upside. Explore fresh ideas before the close and compare how sentiment changed across sectors.",
                date: now.addingTimeInterval(-60),
                folder: .inbox,
                category: .promotions,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "iCloud",
                to: "You",
                subject: "Critical security alert for jordan.avery@icloud.com",
                body: "A sign-in attempt on macOS Ventura was blocked until you verified your identity. Review the recent activity and secure the account if this was not you.",
                date: now.addingTimeInterval(-120),
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "Omar Reyes",
                to: "You",
                subject: "Transaction receipt",
                body: "Hi Jordan,\n\nI just submitted this for approval. I attached the signed receipt and the cleaned-up screenshot for finance.\n\nBest,\nOmar",
                date: now.addingTimeInterval(-(21 * 60)),
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "receipt-amy.png", title: "Transaction Receipt", subtitle: "Approved spend • $184.33")]
            ),
            MailStore.makeItem(
                from: "OpenAI",
                to: "You",
                subject: "Introducing GPT-5.4",
                body: "Designed for complex, long-running professional work, GPT-5.4 improves instruction following, agent reliability, and document workflows across research, writing, and operations.",
                date: now.addingTimeInterval(-(28 * 60)),
                folder: .inbox,
                category: .updates,
                isUnread: true,
                attachments: [makeAttachment(.dashboard, filename: "gpt-5-4-brief.png", title: "Launch Brief", subtitle: "Capability summary preview")]
            ),
            MailStore.makeItem(
                from: "Chase",
                to: "You",
                subject: "Chase security alert: You signed in with a new device",
                body: "You signed in with a new device and successfully validated your identity. If this was not you, reset your password immediately and review account activity.",
                date: now.addingTimeInterval(-(31 * 60)),
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "Seattle Mariners",
                to: "You",
                subject: "Watch our guys in the World Baseball Classic",
                body: "Cal, Julio, and more are hitting the global stage on Friday night. I attached the promo creative we are sending to season-ticket holders.",
                date: now.addingTimeInterval(-(51 * 60)),
                folder: .inbox,
                category: .promotions,
                isUnread: true,
                attachments: [makeAttachment(.poster, filename: "wbc-poster.png", title: "World Baseball Classic", subtitle: "Campaign poster concept")]
            ),
            MailStore.makeItem(
                from: "Blair Morgan",
                to: "You",
                subject: "Updated invitation: Blair/Jordan weekly sync",
                body: "The meeting has been updated with a room change and a shorter agenda. Join five minutes early if you want to review the hiring update before the call.",
                date: now.addingTimeInterval(-(62 * 60)),
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Mina Shah",
                to: "You",
                subject: "Invitation: Q2 planning kickoff",
                body: "You're invited to the Q2 planning kickoff meeting on Thursday at 10 AM. We'll be reviewing OKRs, team capacity, and project priorities for the quarter. Please come prepared with your top three goals.",
                date: now.addingTimeInterval(-(75 * 60)),
                folder: .inbox,
                category: .updates,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "Riley Brooks",
                to: "You",
                subject: "Moved: Design review to Wednesday",
                body: "Heads up — the design review meeting has been moved from Tuesday to Wednesday at 2 PM. Same agenda, just a day shift. The conference room is still booked.",
                date: now.addingTimeInterval(-(80 * 60)),
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Alaska Airlines",
                to: "You",
                subject: "Your boarding pass is ready",
                body: "Thanks for checking in. I attached the boarding pass for tomorrow morning's flight.",
                date: now.addingTimeInterval(-(84 * 60)),
                folder: .inbox,
                category: .transactions,
                isUnread: true,
                attachments: [makeAttachment(.boardingPass, filename: "alaska-boarding-pass.png", title: "Boarding Pass", subtitle: "SFO to JFK • Boarding 6:05 AM")]
            ),
            MailStore.makeItem(
                from: "Sora Design Review",
                to: "You",
                subject: "Creative selects for homepage refresh",
                body: "Sharing the latest hero treatment. The first image is strongest for launch, but I included the product shot as a backup.",
                date: now.addingTimeInterval(-(3 * 3600 + 14 * 60)),
                folder: .inbox,
                category: .updates,
                isUnread: false,
                attachments: [
                    makeAttachment(.product, filename: "hero-v3.png", title: "Hero Option V3", subtitle: "Preferred launch image"),
                    makeAttachment(.product, filename: "alt-product.png", title: "Backup Product Shot", subtitle: "Secondary visual")
                ]
            ),
            MailStore.makeItem(
                from: "Zillow Premier Agent",
                to: "You",
                subject: "Updated listing packet",
                body: "Attaching the latest listing image and the refreshed copy block for the open house page.",
                date: now.addingTimeInterval(-(5 * 3600)),
                folder: .inbox,
                category: .updates,
                isUnread: false,
                attachments: [makeAttachment(.property, filename: "listing-hero.png", title: "Updated Listing", subtitle: "Open house hero shot")]
            ),
            MailStore.makeItem(
                from: "Product Ops",
                to: "You",
                subject: "Workshop notes from today's planning session",
                body: "Captured the whiteboard before everyone cleared the room. This should help when we write the spec follow-up.",
                date: now.addingTimeInterval(-(9 * 3600)),
                folder: .inbox,
                category: .updates,
                isUnread: false,
                attachments: [makeAttachment(.whiteboard, filename: "planning-board.png", title: "Planning Whiteboard", subtitle: "Roadmap workshop notes")]
            ),
            MailStore.makeItem(
                from: "Raku Omakase",
                to: "You",
                subject: "Chef's menu proof",
                body: "Here's the final menu proof before tonight's print run. Let me know if you want the alternate layout instead.",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false,
                attachments: [makeAttachment(.menu, filename: "omakase-menu.png", title: "Menu Proof", subtitle: "Dinner service layout")]
            ),
            MailStore.makeItem(
                from: "You",
                to: "Devon Hart",
                subject: "Draft: Partnership follow-up",
                body: "Devon,\n\nFollowing up on the partnership terms we discussed last week. I also dropped the updated deck image below so you can see the new headline treatment.",
                date: Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now,
                folder: .drafts,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.dashboard, filename: "partner-deck.png", title: "Deck Cover", subtitle: "Updated headline treatment")]
            ),
            MailStore.makeItem(
                from: "You",
                to: "Micah Chen",
                subject: "Re: Site visit agenda",
                body: "I can send this after the finance review wraps up. Queueing it for later this afternoon, along with the venue map.",
                date: Calendar.current.date(byAdding: .minute, value: 55, to: now) ?? now,
                folder: .scheduled,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.whiteboard, filename: "venue-map.png", title: "Venue Map", subtitle: "Walkthrough routing sketch")]
            ),
            MailStore.makeItem(
                from: "You",
                to: "Riley Shah",
                subject: "Re: Q1 KPI summary",
                body: "Sharing the simplified KPI snapshot we referenced on the call. The dashboard image is attached for the follow-up note.",
                date: now.addingTimeInterval(-(95 * 60)),
                folder: .sent,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.dashboard, filename: "kpi-snapshot.png", title: "KPI Snapshot", subtitle: "Q1 executive summary")]
            ),
            MailStore.makeItem(
                from: "You",
                to: "Operations",
                subject: "Updated runbook visuals",
                body: "Attached the revised flow and the whiteboard capture from today's incident rehearsal.",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false,
                attachments: [
                    makeAttachment(.whiteboard, filename: "incident-flow.png", title: "Incident Flow", subtitle: "Escalation handoff map"),
                    makeAttachment(.dashboard, filename: "status-board.png", title: "Status Board", subtitle: "Executive response view")
                ]
            ),
            MailStore.makeItem(
                from: "Operations",
                to: "You",
                subject: "Runbook updated",
                body: "The incident runbook now reflects the revised escalation flow and updated contact roster for the launch weekend.",
                date: Calendar.current.date(byAdding: .day, value: -4, to: now) ?? now,
                folder: .archive,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Travel Desk",
                to: "You",
                subject: "Tahoe itinerary options",
                body: "Archiving the travel image options here in case you need them next week.",
                date: Calendar.current.date(byAdding: .day, value: -8, to: now) ?? now,
                folder: .archive,
                category: .updates,
                isUnread: false,
                attachments: [makeAttachment(.property, filename: "tahoe-cabin.png", title: "Cabin Exterior", subtitle: "Lakeview option")]
            ),
            MailStore.makeItem(
                from: "Nimbus Workspace",
                to: "You",
                subject: "Your spring savings are ready",
                body: "Upgrade your workspace with 20 percent off your next renewal. Offer valid through the end of the month.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now,
                folder: .trash,
                category: .promotions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Promo Studio",
                to: "You",
                subject: "Three more hero concepts",
                body: "Leaving these alternate concepts here in case you need them, but I know they are likely out of scope.",
                date: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                folder: .trash,
                category: .promotions,
                isUnread: false,
                attachments: [makeAttachment(.poster, filename: "unused-hero.png", title: "Unused Hero", subtitle: "Archived promo art")]
            ),

            // ── Meeting-related emails ──────────────────────────────────────

            MailStore.makeItem(
                from: "Jordan Park",
                to: "You",
                subject: "Invitation: Sprint retrospective",
                body: "Scheduling the sprint retro for Friday at 3 PM. We'll cover what went well, what didn't, and action items for next sprint. Bring any blockers you want to discuss.",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Sam Lee",
                to: "You",
                subject: "Re: Standup notes — March 12",
                body: "Sharing my standup update early since I'll be out tomorrow. Key items: API migration is on track, staging deploy passed all checks. No blockers from my side.",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "DevOps Team",
                to: "You",
                subject: "Cancelled: Infrastructure review meeting",
                body: "The infrastructure review meeting scheduled for Wednesday has been cancelled. We'll reschedule once the migration is complete. No action needed on your end.",
                date: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Blair Morgan",
                to: "You",
                subject: "Reminder: All-hands meeting tomorrow at 11 AM",
                body: "Just a reminder that the monthly all-hands is tomorrow at 11 AM in the main conference room. Agenda includes quarterly results, new hire introductions, and the product roadmap update.",
                date: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                folder: .archive,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Mina Shah",
                to: "You",
                subject: "Meeting notes: Client onboarding sync",
                body: "Attaching the notes from today's client onboarding sync. Key decisions: launch timeline moved to April 15, design handoff by end of next week. Follow-up meeting scheduled for Monday.",
                date: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now,
                folder: .archive,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Jordan Park",
                subject: "Re: 1:1 agenda items",
                body: "Here are my agenda items for our 1:1 meeting: career growth discussion, project handoff timeline, and the open headcount question. Let me know if you want to add anything.",
                date: Calendar.current.date(byAdding: .day, value: -4, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Riley Brooks",
                to: "You",
                subject: "Updated invitation: Product review — new time",
                body: "The product review meeting has been rescheduled to 4 PM on Thursday. Same Zoom link as before. The agenda now includes the competitive analysis section that was deferred last week.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now,
                folder: .archive,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Sam Lee",
                to: "You",
                subject: "Invitation: Eng sync — API v2 rollout",
                body: "Setting up a sync meeting to align on the API v2 rollout plan. Tuesday at 1 PM works for most of the team. We'll cover the migration timeline, breaking changes, and client communication plan.",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ── Additional seed emails ──────────────────────────────────────

            // 2 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has shipped!",
                body: "Your order #112-4839201-7782943 containing Anker USB-C Hub and 2 other items has shipped. Estimated delivery: Thursday. Track your package for real-time updates.",
                date: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "Maya Patel",
                to: "You",
                subject: "Quick question about the deck",
                body: "Hey Jordan,\n\nDo you want me to pull the usage metrics from last quarter or this quarter for the board deck? I can grab either but want to make sure we are aligned before I start formatting.\n\nThanks,\nMaya",
                date: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: true
            ),
            MailStore.makeItem(
                from: "TeamChat",
                to: "You",
                subject: "You have 14 unread messages in #product-launches",
                body: "Catch up on what you missed in #product-launches. Leo Chen, Nina Brooks, and 3 others posted new messages since you last checked in.",
                date: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // 3 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your QuickBite order receipt",
                body: "Thanks for your order from Sushi Ran! Your total was $47.82. Order #9284710382. Rate your experience to earn QuickPass credits on your next order.",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "doordash-receipt.png", title: "QuickBite Receipt", subtitle: "Sushi Ran • $47.82")]
            ),
            MailStore.makeItem(
                from: "You",
                to: "Leo Chen",
                subject: "Re: API rate limits",
                body: "Leo,\n\nI talked to the infra team and they are fine bumping us to 5k RPM for the staging environment. I will submit the ticket today. Let me know if you need anything else on your end.\n\nJordan",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Morning Brew",
                to: "You",
                subject: "Daily Brew: Fed signals rate pause through summer",
                body: "Good morning. The Fed held rates steady and signaled no cuts before September. Markets rallied on the news. In other headlines: Nvidia posted record earnings, and a startup just raised $400M to build humanoid robots.",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // 4 days ago
            MailStore.makeItem(
                from: "GitHub",
                to: "You",
                subject: "[mobile-app] PR #482: Refactor auth token refresh logic",
                body: "Arnav Srikanth requested your review on pull request #482 in mobile-app. 12 files changed, 340 additions, 198 deletions. The PR consolidates token refresh into a single middleware layer.",
                date: Calendar.current.date(byAdding: .day, value: -4, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt from Saturday",
                body: "Trip from Mission District to SFO International Airport. Total: $38.14. You saved $6.20 with CityRide One. Your driver was Marco and you rated the trip 5 stars.",
                date: Calendar.current.date(byAdding: .day, value: -4, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt.png", title: "CityRide Receipt", subtitle: "Mission to SFO • $38.14")]
            ),

            // 5 days ago
            MailStore.makeItem(
                from: "Theo Nguyen",
                to: "You",
                subject: "Dinner Friday?",
                body: "Hey Jordan, a few of us are grabbing dinner at Flour + Water on Friday around 7:30. You in? Lmk and I will add you to the reservation.\n\n- Theo",
                date: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Theo Nguyen",
                subject: "Re: Dinner Friday?",
                body: "Count me in! I might be a few minutes late if my 6pm wraps late but I will be there.",
                date: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // 6 days ago
            MailStore.makeItem(
                from: "LockedIn",
                to: "You",
                subject: "Devon Hart endorsed you for Product Strategy",
                body: "Devon Hart has endorsed you for Product Strategy and 2 other skills. You now have 34 endorsements for this skill. See who else has viewed your profile this week.",
                date: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "REI",
                to: "You",
                subject: "Member exclusive: 20% off one full-price item",
                body: "As a valued REI Co-op member, enjoy 20% off one full-price item now through Sunday. Whether you are gearing up for spring trails or your next camping trip, this is your chance to save. Use code MEMBER20 at checkout.",
                date: Calendar.current.date(byAdding: .day, value: -6, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // 8 days ago
            MailStore.makeItem(
                from: "TrailBlaze",
                to: "You",
                subject: "Your weekly activity summary",
                body: "This week: 3 runs, 14.2 miles total, 1h 52m moving time. You set a new personal record on your Wednesday morning run. Your average pace improved by 12 seconds per mile compared to last week.",
                date: Calendar.current.date(byAdding: .day, value: -8, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Nina Brooks",
                to: "You",
                subject: "Design review feedback",
                body: "Jordan,\n\nI went through the latest mockups this morning. Overall looking great. I left some comments in Figma about the spacing on the settings page and the color contrast on the CTA buttons. Nothing blocking, just polish. Let me know if you want to hop on a quick call to walk through them.\n\nBest,\nNina",
                date: Calendar.current.date(byAdding: .day, value: -8, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.whiteboard, filename: "figma-annotations.png", title: "Design Annotations", subtitle: "Settings page feedback")]
            ),

            // ~9 days ago (Feb 28)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Maya on Saturday",
                body: "Thanks for riding, Jordan.\n\nWork → Home\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -9, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb28.png", title: "CityRide Receipt", subtitle: "Work to Home • $16.50")]
            ),

            // 10 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed: Lake Tahoe cabin",
                body: "Your reservation is confirmed! You are staying at Lakeview A-Frame, South Lake Tahoe from Mar 21-24. Check-in is at 3 PM. Your host Sarah will send you the door code 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Nina Brooks",
                subject: "Re: Design review feedback",
                body: "Thanks Nina, I saw the comments. Agree on the spacing issue. I will push a fix today and flag you for another look tomorrow morning.",
                date: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // 12 days ago
            MailStore.makeItem(
                from: "Chase",
                to: "You",
                subject: "Your credit card statement is ready",
                body: "Your MyBank Sapphire Reserve statement for the period ending Feb 25 is now available. Statement balance: $2,847.31. Minimum payment: $35.00. Payment due date: March 22.",
                date: Calendar.current.date(byAdding: .day, value: -12, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "The Hustle",
                to: "You",
                subject: "The side hustle that makes $12K/mo selling spreadsheets",
                body: "A former accountant turned a weekend hobby into a six-figure business by selling custom CloudSheets templates on Etsy. Plus: why VCs are flooding the nuclear energy space, and a founder shares the cold email that landed his first 100 customers.",
                date: Calendar.current.date(byAdding: .day, value: -12, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // ~13 days ago (Feb 24)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sophia on Tuesday",
                body: "Thanks for riding, Jordan.\n\nAirport → Home\nCityRideXL\n\nTotal: $65.10\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -13, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb24.png", title: "CityRide Receipt", subtitle: "Airport to Home • $65.10")]
            ),

            // 14 days ago
            MailStore.makeItem(
                from: "Spencer Bowman",
                to: "You",
                subject: "Offsite logistics",
                body: "Jordan,\n\nI finalized the offsite details. Hotel block is at the Marriott downtown, shuttle leaves from the office at 8 AM on the 15th. I attached the full itinerary. Let me know if you have any dietary restrictions for the team dinner.\n\nCheers,\nSpencer",
                date: Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.dashboard, filename: "offsite-itinerary.png", title: "Offsite Itinerary", subtitle: "March 15-17 schedule")]
            ),
            MailStore.makeItem(
                from: "Uniqlo",
                to: "You",
                subject: "New arrivals + free shipping this weekend",
                body: "Discover our new spring collection. Lightweight layers, breathable linens, and updated basics designed for everyday comfort. Free shipping on all orders over $75 this weekend only.",
                date: Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // ~15 days ago (Feb 22)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Daniel on Sunday",
                body: "Thanks for riding, Jordan.\n\nHome → Oracle Park\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -15, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb22.png", title: "CityRide Receipt", subtitle: "Home to Oracle Park • $16.50")]
            ),

            // 18 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-3920194-5521837 was delivered to your front door today at 2:14 PM. Items: Sony WH-1000XM5 Headphones. If you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -18, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "GitHub",
                to: "You",
                subject: "[mobile-app] PR #471 merged: Dark mode support",
                body: "Your pull request #471 has been merged into main. 28 files changed, 1,204 additions, 389 deletions. CI passed all 142 tests. Great work on the dark mode implementation.",
                date: Calendar.current.date(byAdding: .day, value: -18, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ~19 days ago (Feb 18)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Alex on Wednesday",
                body: "Thanks for riding, Jordan.\n\nHome → Airport\nCityRide Black\n\nTotal: $79.95\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -19, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb18.png", title: "CityRide Receipt", subtitle: "Home to Airport • $79.95")]
            ),

            // 21 days ago
            MailStore.makeItem(
                from: "Grace Lin",
                to: "You",
                subject: "Book recommendation",
                body: "Hey! I just finished reading \"Four Thousand Weeks\" by Oliver Burkeman and it really changed how I think about productivity. Thought you would enjoy it given our last conversation. Let me know if you want to borrow my copy.\n\n- Grace",
                date: Calendar.current.date(byAdding: .day, value: -21, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Priya Raman",
                to: "You",
                subject: "Updated project timeline",
                body: "Hi Jordan,\n\nI adjusted the project timeline based on the feedback from last week's review. The new target for beta is April 7 instead of March 28. I moved the design freeze up by two days to give engineering more runway. Let me know if you see any conflicts.\n\nThanks,\nPriya",
                date: Calendar.current.date(byAdding: .day, value: -21, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.dashboard, filename: "project-timeline.png", title: "Project Timeline", subtitle: "Updated Gantt chart")]
            ),

            // ~24 days ago (Feb 13)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Tom on Friday",
                body: "Thanks for riding, Jordan.\n\nHome → Work\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -24, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb13.png", title: "CityRide Receipt", subtitle: "Home to Work • $16.50")]
            ),

            // ~22 days ago (Feb 15)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Jordan on Sunday",
                body: "Thanks for riding, Jordan.\n\nSoMa → Home\nComfort\n\nTotal: $23.30\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -22, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb15.png", title: "CityRide Receipt", subtitle: "SoMa to Home • $23.30")]
            ),

            // 25 days ago
            MailStore.makeItem(
                from: "Target",
                to: "You",
                subject: "Your Target order is ready for pickup",
                body: "Your order is ready! Pick up at Target San Francisco Central before March 5. Items: Brita water filter, Method hand soap 3-pack, Clorox wipes. Show your barcode at Guest Services or use Drive Up.",
                date: Calendar.current.date(byAdding: .day, value: -25, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Spencer Bowman",
                subject: "Re: Offsite logistics",
                body: "Thanks for pulling this together, Spencer. No dietary restrictions from me. I will be at the shuttle at 8. Looking forward to it.",
                date: Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // ~26 days ago (Feb 11)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Fatima on Wednesday",
                body: "Thanks for riding, Jordan.\n\nHome → Marina\nComfort\n\nTotal: $24.96\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -26, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb11.png", title: "CityRide Receipt", subtitle: "Home to Marina • $24.96")]
            ),

            // 28 days ago
            MailStore.makeItem(
                from: "Lena Ortiz",
                to: "You",
                subject: "Photos from the hike",
                body: "Jordan! Here are the photos from our Lands End hike last weekend. That sunset was unreal. Let me know if you want the full-res versions, these are compressed for email.\n\n- Lena",
                date: Calendar.current.date(byAdding: .day, value: -28, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false,
                attachments: [makeAttachment(.property, filename: "lands-end-sunset.png", title: "Lands End Sunset", subtitle: "Hike photos • Feb 9")]
            ),
            MailStore.makeItem(
                from: "Morning Brew",
                to: "You",
                subject: "Daily Brew: Apple unveils AI-powered Siri overhaul",
                body: "Apple just previewed a major Siri redesign powered by on-device AI. The update promises contextual awareness across apps and real-time translation. Also: housing starts hit a 2-year high, and Costco beat Q4 earnings estimates.",
                date: Calendar.current.date(byAdding: .day, value: -28, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // ~29 days ago (Feb 8)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Jenny on Sunday",
                body: "Thanks for riding, Jordan.\n\nHome → Hayes Valley\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -29, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb8.png", title: "CityRide Receipt", subtitle: "Home to Hayes Valley • $16.50")]
            ),

            // ~32 days ago (Feb 5)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sarah on Thursday",
                body: "Thanks for riding, Jordan.\n\nWork → Home\nComfort\n\nTotal: $23.30\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -32, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-feb5.png", title: "CityRide Receipt", subtitle: "Work to Home • $23.30")]
            ),

            // 32 days ago
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your CityRide Eats receipt",
                body: "Order from Tartine Bakery delivered. Subtotal: $24.50. Delivery fee: $0.00 (CityRide One). Service fee: $3.68. Total: $28.18. Thank you for your order!",
                date: Calendar.current.date(byAdding: .day, value: -32, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-eats-receipt.png", title: "CityRide Eats Receipt", subtitle: "Tartine Bakery • $28.18")]
            ),
            MailStore.makeItem(
                from: "Diego Alvarez",
                to: "You",
                subject: "Re: Quarterly goals",
                body: "Jordan,\n\nAll good on my end. I aligned my OKRs with the updated company priorities. The only thing I want to flag is that the analytics migration might push into Q2 if we do not get the data eng resources confirmed by end of this week.\n\nDiego",
                date: Calendar.current.date(byAdding: .day, value: -32, to: now) ?? now,
                folder: .archive,
                category: .all,
                isUnread: false
            ),

            // 35 days ago
            MailStore.makeItem(
                from: "LockedIn",
                to: "You",
                subject: "3 people viewed your profile this week",
                body: "Your profile was viewed by a Hiring Manager at Stripe, a Senior PM at Figma, and 1 other person. See who is looking at your profile and discover new opportunities in your network.",
                date: Calendar.current.date(byAdding: .day, value: -35, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Priya Raman",
                subject: "Re: Updated project timeline",
                body: "Priya, the new timeline works. I flagged the design freeze change to the design leads so they are aware. We should be good.",
                date: Calendar.current.date(byAdding: .day, value: -21, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // ~37 days ago (Jan 31)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Emma on Saturday",
                body: "Thanks for riding, Jordan.\n\nHome → Nob Hill\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -37, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan31.png", title: "CityRide Receipt", subtitle: "Home to Nob Hill • $16.50")]
            ),

            // 40 days ago
            MailStore.makeItem(
                from: "Chase",
                to: "You",
                subject: "Direct deposit received: $4,218.73",
                body: "A direct deposit of $4,218.73 from ACME CORP PAYROLL has been posted to your Chase Total Checking account ending in 8842. Your available balance is $12,491.05.",
                date: Calendar.current.date(byAdding: .day, value: -40, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "TeamChat",
                to: "You",
                subject: "Weekly digest: 6 channels with new activity",
                body: "Here is what you missed this week: #product-launches (23 messages), #eng-standup (18 messages), #random (42 messages), #design-crit (11 messages), #office-sf (8 messages), #book-club (5 messages).",
                date: Calendar.current.date(byAdding: .day, value: -40, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ~42 days ago (Jan 26)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Diego on Monday",
                body: "Thanks for riding, Jordan.\n\nHome → Airport\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -42, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan26.png", title: "CityRide Receipt", subtitle: "Home to Airport • $16.50")]
            ),

            // ~39 days ago (Jan 29)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Priya on Thursday",
                body: "Thanks for riding, Jordan.\n\nAirport → Home\nCityRideXL\n\nTotal: $65.10\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -39, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan29.png", title: "CityRide Receipt", subtitle: "Airport to Home • $65.10")]
            ),

            // ~45 days ago (Jan 23)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Anna on Friday",
                body: "Thanks for riding, Jordan.\n\nWork → Castro\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -45, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan23.png", title: "CityRide Receipt", subtitle: "Work to Castro • $16.50")]
            ),

            // 45 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Rate your stay at Cozy Studio in Hayes Valley",
                body: "How was your stay with host Michael? Leave a review to help other travelers and earn StayFinder credits toward your next booking. Your feedback matters to our community.",
                date: Calendar.current.date(byAdding: .day, value: -45, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "REI",
                to: "You",
                subject: "Your Co-op Member Dividend is here",
                body: "Congratulations! You earned a $32.40 member dividend this year based on your eligible purchases. Use it online or in-store, it never expires. Thank you for being a Co-op member since 2019.",
                date: Calendar.current.date(byAdding: .day, value: -45, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // 50 days ago
            MailStore.makeItem(
                from: "Sofia Kim",
                to: "You",
                subject: "Happy birthday!",
                body: "Happy birthday Jordan!! Hope you have an amazing day. Let's get coffee this week and celebrate properly. Miss you!\n\nxo Sofia",
                date: Calendar.current.date(byAdding: .day, value: -50, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your return has been processed",
                body: "We have processed your return for order #112-8843201-1129384 (Kindle Paperwhite Case). A refund of $29.99 has been issued to your Visa ending in 4821. Please allow 3-5 business days for the credit to appear.",
                date: Calendar.current.date(byAdding: .day, value: -50, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // ~52 days ago (Jan 16)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Jenny on Friday",
                body: "Thanks for riding, Jordan.\n\nHome → Inner Sunset\nCityRideXL\n\nTotal: $65.10\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -52, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan16.png", title: "CityRide Receipt", subtitle: "Home to Inner Sunset • $65.10")]
            ),

            // 55 days ago
            MailStore.makeItem(
                from: "Rohan Mehta",
                to: "You",
                subject: "Ping pong tournament results",
                body: "Final results are in! You came in 3rd out of 16 in the office tournament. Not bad at all. Rematch next month? I am setting up a bracket for February.\n\n- Rohan",
                date: Calendar.current.date(byAdding: .day, value: -55, to: now) ?? now,
                folder: .archive,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "TrailBlaze",
                to: "You",
                subject: "January activity recap",
                body: "Your January stats: 14 activities, 48.3 miles, 6h 12m total time. You were most active on Wednesdays. Your longest run was 8.1 miles on Jan 18. You gave 23 kudos and received 41.",
                date: Calendar.current.date(byAdding: .day, value: -55, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ~59 days ago (Jan 9)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Diego on Friday",
                body: "Thanks for riding, Jordan.\n\nHome → Mission\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -59, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan9.png", title: "CityRide Receipt", subtitle: "Home to Mission • $16.50")]
            ),

            // ~57 days ago (Jan 11)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sarah on Sunday",
                body: "Thanks for riding, Jordan.\n\nHome → Marina\nCityRide Black\n\nTotal: $79.95\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -57, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan11.png", title: "CityRide Receipt", subtitle: "Home to Marina • $79.95")]
            ),

            // 60 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Free delivery on your next 3 orders",
                body: "We miss you, Jordan! As a valued QuickPass member, enjoy free delivery on your next 3 orders of $15 or more. No code needed, the discount will apply automatically at checkout. Offer expires in 14 days.",
                date: Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now,
                folder: .trash,
                category: .promotions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Grace Lin",
                subject: "Re: Book recommendation",
                body: "Oh I have heard great things about that one! I would love to borrow it. I will grab it next time I see you. Just finishing up Project Hail Mary right now.",
                date: Calendar.current.date(byAdding: .day, value: -21, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // ~65 days ago (Jan 3)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Alex on Saturday",
                body: "Thanks for riding, Jordan.\n\nHome → Airport\nComfort\n\nTotal: $24.96\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -65, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-jan3.png", title: "CityRide Receipt", subtitle: "Home to Airport • $24.96")]
            ),

            // 65 days ago
            MailStore.makeItem(
                from: "GitHub",
                to: "You",
                subject: "[mobile-app] Issue #389: Memory leak in image cache",
                body: "Mason Ward opened a new issue: Memory leak detected in the image caching layer when scrolling through large galleries. Heap grows by ~50MB per minute in the photo grid view. Assigned to you and tagged as P1.",
                date: Calendar.current.date(byAdding: .day, value: -65, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "The Hustle",
                to: "You",
                subject: "Why big tech is betting on nuclear power",
                body: "Microsoft, Google, and MegaMart are all investing in nuclear energy to power their data centers. The AI boom is driving electricity demand through the roof, and tech giants think small modular reactors are the answer. Plus: a deep dive into the economics of cloud kitchens.",
                date: Calendar.current.date(byAdding: .day, value: -65, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: false
            ),

            // 70 days ago
            MailStore.makeItem(
                from: "Chase",
                to: "You",
                subject: "Fraud alert: Unusual activity on your card",
                body: "We detected unusual activity on your MyBank Sapphire card ending in 4821. A charge of $312.00 at ELECTRONICS-STORE.NET was flagged. If you recognize this transaction, no action is needed. Otherwise, please call us immediately at 1-800-555-0198.",
                date: Calendar.current.date(byAdding: .day, value: -70, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Miles Chen",
                to: "You",
                subject: "Ski trip planning",
                body: "Hey Jordan,\n\nI am looking at Palisades Tahoe for MLK weekend. Found a cabin that sleeps 8, would be about $150/person for the long weekend. Theo, Lena, and Sofia are in. You down? Need to book by Friday.\n\n- Miles",
                date: Calendar.current.date(byAdding: .day, value: -70, to: now) ?? now,
                folder: .archive,
                category: .all,
                isUnread: false
            ),

            // ~74 days ago (Dec 25)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sophia on Thursday",
                body: "Thanks for riding, Jordan.\n\nHome → Noe Valley\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -74, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec25.png", title: "CityRide Receipt", subtitle: "Home to Noe Valley • $16.50")]
            ),

            // ~72 days ago (Dec 27)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Jordan on Saturday",
                body: "Thanks for riding, Jordan.\n\nWork → Lower Haight\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -72, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec27.png", title: "CityRide Receipt", subtitle: "Work to Lower Haight • $16.50")]
            ),

            // 75 days ago
            MailStore.makeItem(
                from: "Target",
                to: "You",
                subject: "Save 15% on home essentials this week",
                body: "Stock up and save! Get 15% off cleaning supplies, paper products, and home storage. Plus, save an extra 5% with your Target Circle membership. Valid through Sunday, in-store and online.",
                date: Calendar.current.date(byAdding: .day, value: -75, to: now) ?? now,
                folder: .trash,
                category: .promotions,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "You",
                to: "Diego Alvarez",
                subject: "Quarterly goals alignment",
                body: "Diego,\n\nCan you take a look at your OKRs and make sure they align with the updated company priorities from the all-hands? Especially the analytics migration piece. Want to make sure we are all on the same page before the planning review next week.\n\nThanks,\nJordan",
                date: Calendar.current.date(byAdding: .day, value: -35, to: now) ?? now,
                folder: .sent,
                category: .all,
                isUnread: false
            ),

            // ~79 days ago (Dec 20)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Kevin on Saturday",
                body: "Thanks for riding, Jordan.\n\nHome → Work\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -79, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec20.png", title: "CityRide Receipt", subtitle: "Home to Work • $16.50")]
            ),

            // 80 days ago
            MailStore.makeItem(
                from: "Camille Hart",
                to: "You",
                subject: "New Year's photos",
                body: "Finally uploaded the NYE photos! You looked great btw. Such a fun night. Here is the album link: icloud.com/sharedalbum/NYE2026. Let me know your favorites and I will print a couple for you.\n\n- Camille",
                date: Calendar.current.date(byAdding: .day, value: -80, to: now) ?? now,
                folder: .inbox,
                category: .all,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "Chase",
                to: "You",
                subject: "Your year-end account summary is ready",
                body: "Your 2025 year-end account summary is now available. Review your spending breakdown, rewards earned, and account activity for the year. Log in to your Chase account to view the full report.",
                date: Calendar.current.date(byAdding: .day, value: -80, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // ~86 days ago (Dec 13)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Fatima on Saturday",
                body: "Thanks for riding, Jordan.\n\nWork → Airport\nCityRideX\n\nTotal: $16.50\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -86, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec13.png", title: "CityRide Receipt", subtitle: "Work to Airport • $16.50")]
            ),

            // 85 days ago
            MailStore.makeItem(
                from: "LockedIn",
                to: "You",
                subject: "Congratulations on your work anniversary!",
                body: "Happy 3-year work anniversary at Acme Corp! Your connections are celebrating with you. Share an update with your network and let them know what you have been working on.",
                date: Calendar.current.date(byAdding: .day, value: -85, to: now) ?? now,
                folder: .trash,
                category: .updates,
                isUnread: false
            ),
            MailStore.makeItem(
                from: "TrailBlaze",
                to: "You",
                subject: "Your 2025 Year in Sport",
                body: "What a year, Jordan! In 2025 you logged 156 activities, covered 412 miles, and spent 54 hours moving. Your most active month was October with 18 activities. You earned 8 trophies and gave 287 kudos.",
                date: Calendar.current.date(byAdding: .day, value: -85, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ~89 days ago (Dec 10)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Raj on Wednesday",
                body: "Thanks for riding, Jordan.\n\nAirport → Home\nComfort\n\nTotal: $24.96\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -89, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec10.png", title: "CityRide Receipt", subtitle: "Airport to Home • $24.96")]
            ),

            // ~95 days ago (Dec 4)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sarah on Thursday",
                body: "Thanks for riding, Jordan.\n\nNob Hill → Home\nCityRide Black\n\nTotal: $79.95\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -95, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec4b.png", title: "CityRide Receipt", subtitle: "Nob Hill to Home • $79.95")]
            ),
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Sarah on Thursday",
                body: "Thanks for riding, Jordan.\n\nHome → Nob Hill\nCityRide Black\n\nTotal: $79.95\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -95, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-dec4a.png", title: "CityRide Receipt", subtitle: "Home to Nob Hill • $79.95")]
            ),

            // ~100 days ago (Nov 29)
            MailStore.makeItem(
                from: "CityRide Receipts",
                to: "jordan.avery@email.com",
                subject: "Trip with Alex on Saturday",
                body: "Thanks for riding, Jordan.\n\nHome → Golden Gate Park\nCityRideXL\n\nTotal: $65.10\n\nRate your driver and tip.",
                date: Calendar.current.date(byAdding: .day, value: -100, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "uber-receipt-nov29.png", title: "CityRide Receipt", subtitle: "Home to Golden Gate Park • $65.10")]
            ),

            // ── QuickBite receipt emails ─────────────────────────────────────

            // 1 day ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Chipotle order receipt",
                body: "Hi Jordan, here's your receipt.\n\nChipotle Mexican Grill\nBurrito Bowl, Chips & Guac\n\nSubtotal: $19.75\nDelivery Fee: $0.00\nService Fee: $2.76\nTip: $3.49\nTotal: $26.00",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: true,
                attachments: [makeAttachment(.receipt, filename: "dd-chipotle-1d.png", title: "QuickBite Receipt", subtitle: "Chipotle • $26.00")]
            ),

            // 5 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Shake Shack order receipt",
                body: "Hi Jordan, here's your receipt.\n\nShake Shack\nShackBurger, Crinkle Cut Fries, Shake\n\nSubtotal: $20.47\nDelivery Fee: $0.00\nService Fee: $2.60\nTip: $3.50\nTotal: $26.57",
                date: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-shakeshack-5d.png", title: "QuickBite Receipt", subtitle: "Shake Shack • $26.57")]
            ),

            // 10 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Sugarfish order receipt",
                body: "Hi Jordan, here's your receipt.\n\nSugarfish by Sushi Nozawa\nTrust Me Lite, Edamame\n\nSubtotal: $38.00\nDelivery Fee: $0.00\nService Fee: $5.00\nTip: $7.00\nTotal: $50.00",
                date: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-sugarfish-10d.png", title: "QuickBite Receipt", subtitle: "Sugarfish • $50.00")]
            ),

            // 22 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Pizza Hut order receipt",
                body: "Hi Jordan, here's your receipt.\n\nPizza Hut\nLarge Pepperoni Pizza, Breadsticks, 2L Pepsi\n\nSubtotal: $26.98\nDelivery Fee: $0.00\nService Fee: $3.00\nTip: $5.00\nTotal: $34.98",
                date: Calendar.current.date(byAdding: .day, value: -22, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-pizzahut-22d.png", title: "QuickBite Receipt", subtitle: "Pizza Hut • $34.98")]
            ),

            // 33 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Chipotle order receipt",
                body: "Hi Jordan, here's your receipt.\n\nChipotle Mexican Grill\nChicken Burrito, Chips & Salsa\n\nSubtotal: $13.20\nDelivery Fee: $0.00\nService Fee: $1.50\nTip: $3.00\nTotal: $17.70",
                date: Calendar.current.date(byAdding: .day, value: -33, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-chipotle-33d.png", title: "QuickBite Receipt", subtitle: "Chipotle • $17.70")]
            ),

            // 44 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your QuickMart order receipt",
                body: "Hi Jordan, here's your receipt.\n\nQuickMart\nOrange Juice, Greek Yogurt, Bananas, Almonds, Sparkling Water\n\nSubtotal: $22.46\nDelivery Fee: $0.00\nService Fee: $2.50\nTip: $4.00\nTotal: $28.96",
                date: Calendar.current.date(byAdding: .day, value: -44, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-dashmart-44d.png", title: "QuickBite Receipt", subtitle: "QuickMart • $28.96")]
            ),

            // 58 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your CVS Pharmacy order receipt",
                body: "Hi Jordan, here's your receipt.\n\nCVS Pharmacy\nAdvil, Vitamin D, Band-Aids, Toothpaste\n\nSubtotal: $21.46\nDelivery Fee: $0.00\nService Fee: $2.00\nTip: $3.50\nTotal: $26.96",
                date: Calendar.current.date(byAdding: .day, value: -58, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-cvs-58d.png", title: "QuickBite Receipt", subtitle: "CVS Pharmacy • $26.96")]
            ),

            // 71 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Nobu order receipt",
                body: "Hi Jordan, here's your receipt.\n\nNobu\nBlack Cod Miso, Rock Shrimp Tempura, Edamame\n\nSubtotal: $64.00\nDelivery Fee: $0.00\nService Fee: $6.00\nTip: $12.00\nTotal: $82.00",
                date: Calendar.current.date(byAdding: .day, value: -71, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-nobu-71d.png", title: "QuickBite Receipt", subtitle: "Nobu • $82.00")]
            ),

            // 78 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Total Wine order receipt",
                body: "Hi Jordan, here's your receipt.\n\nTotal Wine & More\nKendall-Jackson Chardonnay, La Marca Prosecco, Tito's Vodka\n\nSubtotal: $38.97\nDelivery Fee: $0.00\nService Fee: $3.00\nTip: $6.00\nTotal: $47.97",
                date: Calendar.current.date(byAdding: .day, value: -78, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-totalwine-78d.png", title: "QuickBite Receipt", subtitle: "Total Wine • $47.97")]
            ),

            // 83 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Levain Bakery order receipt",
                body: "Hi Jordan, here's your receipt.\n\nLevain Bakery\nChocolate Chip Walnut Cookie x4, Dark Chocolate Cookie x4\n\nSubtotal: $32.00\nDelivery Fee: $0.00\nService Fee: $3.00\nTip: $5.00\nTotal: $40.00",
                date: Calendar.current.date(byAdding: .day, value: -83, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-levain-83d.png", title: "QuickBite Receipt", subtitle: "Levain Bakery • $40.00")]
            ),

            // 89 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your QuickMart order receipt",
                body: "Hi Jordan, here's your receipt.\n\nQuickMart\nGatorade x2, Clif Bars, Goldfish\n\nSubtotal: $12.48\nDelivery Fee: $0.00\nService Fee: $1.50\nTip: $2.50\nTotal: $16.48",
                date: Calendar.current.date(byAdding: .day, value: -89, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-dashmart-89d.png", title: "QuickBite Receipt", subtitle: "QuickMart • $16.48")]
            ),

            // 95 days ago
            MailStore.makeItem(
                from: "QuickBite",
                to: "You",
                subject: "Your Chipotle order receipt",
                body: "Hi Jordan, here's your receipt.\n\nChipotle Mexican Grill\nSteak Bowl, Queso Blanco, Large Chips & Guac\n\nSubtotal: $23.15\nDelivery Fee: $0.00\nService Fee: $2.50\nTip: $5.00\nTotal: $30.65",
                date: Calendar.current.date(byAdding: .day, value: -95, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "dd-chipotle-95d.png", title: "QuickBite Receipt", subtitle: "Chipotle • $30.65")]
            ),

            // ── MegaMart order emails ────────────────────────────────────────

            // 10 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has shipped",
                body: "Your order #112-9384756-2019384 has shipped!\n\nSony WH-1000XM5 Wireless Noise Canceling Headphones\n\nTotal: $209.99\n\nEstimated delivery: Thursday. Track your package for real-time updates.",
                date: Calendar.current.date(byAdding: .day, value: -10, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // 20 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-7482930-6182745 was delivered to your front door today at 11:32 AM.\n\nCeraVe Moisturizing Cream (2-pack)\n\nTotal: $24.98\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -20, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // 32 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-5930274-8391024 was delivered to your front door today at 3:47 PM.\n\nMilk-Bone Original Dog Treats, Greenies Dental Treats\n\nTotal: $38.98\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -32, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 44 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-3847592-1029384 was delivered to your front door today at 1:15 PM.\n\nCuisinart 12-Piece Stainless Steel Cookware Set\n\nTotal: $134.99\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -44, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 57 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-6284019-3748291 was delivered to your front door today at 4:22 PM.\n\nNike Air Zoom Pegasus 41 Running Shoes, Balega Hidden Comfort Socks (3-pack)\n\nTotal: $121.99\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -57, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 66 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-8471036-5920184 was delivered to your mailroom today at 10:08 AM.\n\nMoleskine 2026 Weekly Planner, Pilot G2 Gel Pens (12-pack)\n\nTotal: $37.94\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -66, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 72 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-2049385-7192038 was delivered to your front door today at 2:50 PM.\n\nManduka PRO Yoga Mat 71\", TriggerPoint GRID Foam Roller\n\nTotal: $119.99\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -72, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 84 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-4728193-0384756 was delivered to your front door today at 12:33 PM.\n\nLEGO Icons Flower Bouquet, Crayola Inspiration Art Case (140 pieces)\n\nTotal: $64.98\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -84, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 97 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-9182037-4829103 was delivered to your front door today at 5:18 PM.\n\nLavazza Super Crema Whole Bean Coffee (2.2 lb), Salt Fat Acid Heat Cookbook\n\nTotal: $40.98\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -97, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 116 days ago
            MailStore.makeItem(
                from: "MegaMart",
                to: "You",
                subject: "Your order has been delivered",
                body: "Your order #112-3019284-5738291 was delivered to your front door today at 9:45 AM.\n\nBounty Select-A-Size Paper Towels (12-pack), Tide PODS Laundry Detergent (42 ct)\n\nTotal: $43.98\n\nIf you did not receive your package, please let us know within 48 hours.",
                date: Calendar.current.date(byAdding: .day, value: -116, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // ── StayFinder booking confirmation emails ──────────────────────────

            // 356 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed - Alfama tile apartment",
                body: "Your reservation is confirmed!\n\nAlfama Tile Apartment\nLisbon, Portugal\n\n$173/night x 4 nights\nCleaning fee: $45\nService fee: $98\nTotal: $835\n\nCheck-in: 3:00 PM\nYour host Ana will send you access details 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -356, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 275 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed - Redwood canyon room",
                body: "Your reservation is confirmed!\n\nRedwood Canyon Room\nSequoia National Park, CA\n\n$96/night x 3 nights\nCleaning fee: $30\nService fee: $41\nTotal: $359\n\nCheck-in: 4:00 PM\nYour host David will send you access details 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -275, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 147 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed - Big Sur ridge cabin",
                body: "Your reservation is confirmed!\n\nBig Sur Ridge Cabin\nBig Sur, CA\n\n$149/night x 2 nights\nCleaning fee: $40\nService fee: $48\nTotal: $386\n\nCheck-in: 3:00 PM\nYour host Rachel will send you access details 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -147, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 540 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed - Boutique harbor stay",
                body: "Your reservation is confirmed!\n\nBoutique Harbor Stay\nAvalon, Catalina Island, CA\n\n$148/night x 3 nights\nCleaning fee: $35\nService fee: $63\nTotal: $542\n\nCheck-in: 2:00 PM\nYour host Maria will send you access details 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -540, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 720 days ago
            MailStore.makeItem(
                from: "StayFinder",
                to: "You",
                subject: "Booking confirmed - Cove-view guest suite",
                body: "Your reservation is confirmed!\n\nCove-View Guest Suite\nCatalina Island, CA\n\n$86/night x 2 nights\nCleaning fee: $25\nService fee: $28\nTotal: $225\n\nCheck-in: 3:00 PM\nYour host James will send you access details 24 hours before arrival.",
                date: Calendar.current.date(byAdding: .day, value: -720, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // ── FreshCart receipt emails ────────────────────────────────────

            // 23 days ago
            MailStore.makeItem(
                from: "FreshCart",
                to: "You",
                subject: "Your Whole Foods delivery receipt",
                body: "Hi Jordan, your Whole Foods Market delivery is complete!\n\nOrganic Chicken Breast, Baby Spinach, Avocados x4, Sourdough Bread, Oat Milk, Wild Salmon Fillet, Blueberries, and 6 more items\n\nItems: $86.42\nService fee: $5.99\nTip: $6.26\nTotal: $98.67",
                date: Calendar.current.date(byAdding: .day, value: -23, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "instacart-wholefoods-23d.png", title: "FreshCart Receipt", subtitle: "Whole Foods • $98.67")]
            ),

            // 20 days ago
            MailStore.makeItem(
                from: "FreshCart",
                to: "You",
                subject: "Your Trader Joe's delivery receipt",
                body: "Hi Jordan, your Trader Joe's delivery is complete!\n\nMandarin Orange Chicken, Everything But The Bagel Seasoning, Cauliflower Gnocchi, Dark Chocolate PB Cups, and 5 more items\n\nItems: $48.12\nService fee: $4.99\nTip: $5.23\nTotal: $58.34",
                date: Calendar.current.date(byAdding: .day, value: -20, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "instacart-tj-20d.png", title: "FreshCart Receipt", subtitle: "Trader Joe's • $58.34")]
            ),

            // 17 days ago
            MailStore.makeItem(
                from: "FreshCart",
                to: "You",
                subject: "Your CVS delivery receipt",
                body: "Hi Jordan, your CVS delivery is complete!\n\nCeraVe Facial Cleanser, Flonase Allergy Relief, Advil Liqui-Gels\n\nItems: $24.47\nService fee: $2.99\nTip: $1.45\nTotal: $28.91",
                date: Calendar.current.date(byAdding: .day, value: -17, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "instacart-cvs-17d.png", title: "FreshCart Receipt", subtitle: "CVS • $28.91")]
            ),

            // 14 days ago
            MailStore.makeItem(
                from: "FreshCart",
                to: "You",
                subject: "Your Panera Bread delivery receipt",
                body: "Hi Jordan, your Panera Bread delivery is complete!\n\nBroccoli Cheddar Soup (bowl), Caesar Salad, Baguette, Chocolate Chip Cookie\n\nItems: $31.28\nService fee: $3.99\nTip: $2.25\nTotal: $37.52",
                date: Calendar.current.date(byAdding: .day, value: -14, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "instacart-panera-14d.png", title: "FreshCart Receipt", subtitle: "Panera Bread • $37.52")]
            ),

            // 8 days ago
            MailStore.makeItem(
                from: "FreshCart",
                to: "You",
                subject: "Your Costco delivery receipt",
                body: "Hi Jordan, your Costco delivery is complete!\n\nKirkland Organic Eggs, Rotisserie Chicken, Kirkland Water (40-pack), Mixed Berries, and 3 more items\n\nItems: $52.64\nService fee: $5.99\nTip: $5.15\nTotal: $63.78",
                date: Calendar.current.date(byAdding: .day, value: -8, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false,
                attachments: [makeAttachment(.receipt, filename: "instacart-costco-8d.png", title: "FreshCart Receipt", subtitle: "Costco • $63.78")]
            ),

            // ── SkyTrip Airlines confirmation emails ─────────────────────────

            // 18 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to SEA",
                body: "Your trip is booked!\n\nConfirmation #: V1L7ZE\nSan Francisco (SFO) to Seattle (SEA)\nSkyTrip Flight 1482\n\nPassenger: Jordan Avery\nTotal: $249.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -18, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // 31 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to SAN",
                body: "Your trip is booked!\n\nConfirmation #: T3P9HS\nSan Francisco (SFO) to San Diego (SAN)\nSkyTrip Flight 2195\n\nPassenger: Jordan Avery\nTotal: $284.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -31, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 39 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to LAS",
                body: "Your trip is booked!\n\nConfirmation #: G8J5WA\nSan Francisco (SFO) to Las Vegas (LAS)\nSkyTrip Flight 834\n\nPassenger: Jordan Avery\nTotal: $189.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -39, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 60 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to LAX",
                body: "Your trip is booked!\n\nConfirmation #: F2V6NK\nSan Francisco (SFO) to Los Angeles (LAX)\nSkyTrip Flight 1073\n\nPassenger: Jordan Avery\nTotal: $312.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 78 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to BOS",
                body: "Your trip is booked!\n\nConfirmation #: D7Y4QC\nSan Francisco (SFO) to Boston (BOS)\nSkyTrip Flight 562\n\nPassenger: Jordan Avery\nTotal: $359.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -78, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 105 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to ATL",
                body: "Your trip is booked!\n\nConfirmation #: M5X1PL\nSan Francisco (SFO) to Atlanta (ATL)\nSkyTrip Flight 2847\n\nPassenger: Jordan Avery\nTotal: $246.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -105, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 127 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to ORD",
                body: "Your trip is booked!\n\nConfirmation #: K9T2FJ\nSan Francisco (SFO) to Chicago (ORD)\nSkyTrip Flight 1926\n\nPassenger: Jordan Avery\nTotal: $295.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -127, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 153 days ago
            MailStore.makeItem(
                from: "SkyTrip Airlines",
                to: "You",
                subject: "Trip confirmation: SFO to JFK",
                body: "Your trip is booked!\n\nConfirmation #: B6H3RV\nSan Francisco (SFO) to New York (JFK)\nSkyTrip Flight 418\n\nPassenger: Jordan Avery\nTotal: $388.00\n\nManage your trip at skytrip.com or in the Fly SkyTrip app.",
                date: Calendar.current.date(byAdding: .day, value: -153, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // ── TicketBox ticket confirmation emails ─────────────────────────

            // 178 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Rockies at Giants",
                body: "You're in!\n\nRockies at Giants\nOracle Park, San Francisco\nSection 127, Row 14, Seats 5-6\n\nTotal: $45.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the game!",
                date: Calendar.current.date(byAdding: .day, value: -178, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 165 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Padres at Giants",
                body: "You're in!\n\nPadres at Giants\nOracle Park, San Francisco\nSection 109, Row 22, Seats 8-9\n\nTotal: $52.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the game!",
                date: Calendar.current.date(byAdding: .day, value: -165, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 139 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Suns at Warriors",
                body: "You're in!\n\nSuns at Warriors\nChase Center, San Francisco\nSection 215, Row 8, Seats 3-4\n\nTotal: $78.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the game!",
                date: Calendar.current.date(byAdding: .day, value: -139, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 129 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Dave Chappelle",
                body: "You're in!\n\nDave Chappelle\nThe Masonic, San Francisco\nOrchestra, Row M, Seats 11-12\n\nTotal: $65.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the show!",
                date: Calendar.current.date(byAdding: .day, value: -129, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 117 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Khruangbin",
                body: "You're in!\n\nKhruangbin\nThe Fillmore, San Francisco\nGeneral Admission\n\nTotal: $55.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the show!",
                date: Calendar.current.date(byAdding: .day, value: -117, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 95 days ago
            MailStore.makeItem(
                from: "TicketBox",
                to: "You",
                subject: "Your tickets for Nuggets at Warriors",
                body: "You're in!\n\nNuggets at Warriors\nChase Center, San Francisco\nSection 107, Row 18, Seats 1-2\n\nTotal: $85.00 x 2 tickets\n\nYour tickets will be available in the TicketBox app 24 hours before the event. Enjoy the game!",
                date: Calendar.current.date(byAdding: .day, value: -95, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 13 days ago
            MailStore.makeItem(
                from: "Netflix",
                to: "You",
                subject: "Your Netflix monthly charge receipt",
                body: "Hi there,\n\nYour Netflix Standard plan has been renewed.\n\nAmount charged: $15.49\nBilling date: April 7, 2026\nPayment method: Visa ending in 4821\n\nManage your subscription anytime at netflix.com/account.",
                date: Calendar.current.date(byAdding: .day, value: -13, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 11 days ago
            MailStore.makeItem(
                from: "Spotify",
                to: "You",
                subject: "Your Spotify Premium receipt",
                body: "Thanks for being a Premium member!\n\nPlan: Spotify Premium Individual\nAmount: $10.99\nDate: April 9, 2026\nPayment method: Visa ending in 4821\n\nView your full billing history at spotify.com/account.",
                date: Calendar.current.date(byAdding: .day, value: -11, to: now) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // 9 days ago
            MailStore.makeItem(
                from: "Apple",
                to: "You",
                subject: "Your Apple Music subscription has been renewed",
                body: "Your subscription has been renewed.\n\nApple Music Individual\nRenewal date: April 11, 2026\nPrice: $10.99/month\nPayment method: Apple ID balance & Visa ending in 4821\n\nManage subscriptions in Settings > Apple ID > Subscriptions.",
                date: Calendar.current.date(byAdding: .day, value: -9, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // 7 days ago
            MailStore.makeItem(
                from: "YouTube Premium",
                to: "You",
                subject: "Your YouTube Premium billing receipt",
                body: "Your YouTube Premium membership has been renewed.\n\nPlan: YouTube Premium Individual\nCharge: $13.99\nBilling date: April 13, 2026\nPayment method: Visa ending in 4821\n\nManage your membership at youtube.com/paid_memberships.",
                date: Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),

            // 5 days ago
            MailStore.makeItem(
                from: "GitHub",
                to: "You",
                subject: "GitHub Pro billing receipt — April 2026",
                body: "Thanks for using GitHub Pro!\n\nPlan: GitHub Pro\nAmount: $4.00\nBilling period: April 15 – May 15, 2026\nPayment method: Visa ending in 4821\n\nView your billing summary at github.com/settings/billing.",
                date: Calendar.current.date(byAdding: .day, value: -5, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: false
            ),

            // 4 days ago
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your reservation is confirmed — San Diego",
                body: "Reservation Confirmed\n\nMarriott Marquis San Diego Marina\n333 W Harbor Dr, San Diego, CA 92101\n\nCheck-in: May 2, 2026 (3:00 PM)\nCheck-out: May 5, 2026 (11:00 AM)\nRoom: King, Marina View\nConfirmation #: 89X7K2QW\n\nBonvoy members earn points on every eligible stay. See you soon!",
                date: Calendar.current.date(byAdding: .day, value: -4, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),

            // 3 days ago
            MailStore.makeItem(
                from: "Hilton Honors",
                to: "You",
                subject: "Booking confirmation — Hilton Union Square",
                body: "Your booking is confirmed!\n\nHilton San Francisco Union Square\n333 O'Farrell St, San Francisco, CA 94102\n\nCheck-in: April 25, 2026 (4:00 PM)\nCheck-out: April 27, 2026 (12:00 PM)\nRoom: Queen, City View\nConfirmation #: 3HLT90284\nTotal: $389.00 (2 nights)\n\nHonors members enjoy complimentary Wi-Fi and digital key access.",
                date: Calendar.current.date(byAdding: .day, value: -3, to: now) ?? now,
                folder: .inbox,
                category: .transactions,
                isUnread: true
            ),

            // 2 days ago
            MailStore.makeItem(
                from: "Spotify",
                to: "You",
                subject: "Upgrade to Spotify Family — share with 5 others",
                body: "Love Spotify Premium? Share it with the whole household.\n\nSpotify Family Plan — $16.99/month\n• Up to 6 Premium accounts\n• Explicit content filter for kids\n• Spotify Kids app included\n\nUpgrade today and everyone listens their way. Offer valid through April 30, 2026.",
                date: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: true
            ),

            // 1 day ago
            MailStore.makeItem(
                from: "Netflix",
                to: "You",
                subject: "New on Netflix this week: titles you'll love",
                body: "Don't miss what's new this week!\n\n★ The Wandering Dark — Season 2 premiere\n★ Coast to Coast — New limited series\n★ Last Light — Award-winning documentary\n★ Neon Nights — Stand-up special\n\nStart watching now at netflix.com.",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .inbox,
                category: .promotions,
                isUnread: true
            ),

            // 1 day ago
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your Bonvoy points summary — April 2026",
                body: "Here's your Marriott Bonvoy points update.\n\nCurrent balance: 48,320 points\nPoints earned this month: 2,150\nElite status: Gold Elite\nNights toward next tier: 22 of 50\n\nYou're making great progress! Book your next stay at marriott.com to keep earning.",
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                folder: .inbox,
                category: .updates,
                isUnread: false
            ),

            // ── Past hotel receipts (matching SkyTrip past trips) ────────

            // Oct 8-10, 2025 — SFO→JFK 2-night business trip
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your stay receipt — New York Marriott Marquis",
                body: "Thank you for your stay!\n\nNew York Marriott Marquis\n1535 Broadway, New York, NY 10036\n\nCheck-in: October 8, 2025\nCheck-out: October 10, 2025\nRoom: King, City View (2 nights)\nRate: $329/night\nTaxes & fees: $118.44\nTotal: $776.44\nConfirmation #: 72MQ4R8X\n\nBonvoy points earned: 4,658\n\nWe hope to welcome you back soon!",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 10, hour: 12)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // Nov 3-4, 2025 — SFO→ORD 1-night business trip
            MailStore.makeItem(
                from: "Hilton Honors",
                to: "You",
                subject: "Folio for your stay — Hilton Chicago",
                body: "Thank you for staying with us!\n\nHilton Chicago\n720 S Michigan Ave, Chicago, IL 60605\n\nCheck-in: November 3, 2025\nCheck-out: November 4, 2025\nRoom: King, Lake View (1 night)\nRoom charge: $259.00\nTaxes & fees: $46.62\nTotal: $305.62\nConfirmation #: 9HLT20351\n\nHonors points earned: 2,447\n\nSee you next time!",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 4, hour: 11)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // Nov 25-29, 2025 — SFO→ATL 4-night Thanksgiving trip
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your stay receipt — Atlanta Marriott Marquis",
                body: "Thank you for your stay!\n\nAtlanta Marriott Marquis\n265 Peachtree Center Ave NE, Atlanta, GA 30303\n\nCheck-in: November 25, 2025\nCheck-out: November 29, 2025\nRoom: King, Atrium View (4 nights)\nRate: $199/night\nTaxes & fees: $143.28\nTotal: $939.28\nConfirmation #: 44MQ7K1B\n\nBonvoy points earned: 5,636\n\nHappy holidays!",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 29, hour: 11)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // Dec 22-27, 2025 — SFO→BOS 5-night Christmas trip
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your stay receipt — Boston Marriott Copley Place",
                body: "Thank you for your stay!\n\nBoston Marriott Copley Place\n110 Huntington Ave, Boston, MA 02116\n\nCheck-in: December 22, 2025\nCheck-out: December 27, 2025\nRoom: King, City View (5 nights)\nRate: $289/night\nTaxes & fees: $217.54\nTotal: $1,662.54\nConfirmation #: 88MQ2D5P\n\nBonvoy points earned: 9,975\n\nThank you for choosing Marriott!",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 27, hour: 11)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // Jan 9-11, 2026 — SFO→LAX 2-night weekend trip
            MailStore.makeItem(
                from: "Hilton Honors",
                to: "You",
                subject: "Folio for your stay — Hilton Santa Monica",
                body: "Thank you for staying with us!\n\nHilton Santa Monica Hotel & Suites\n1707 4th St, Santa Monica, CA 90401\n\nCheck-in: January 9, 2026\nCheck-out: January 11, 2026\nRoom: King, Ocean View (2 nights)\nRoom charge: $349/night\nTaxes & fees: $104.70\nTotal: $802.70\nConfirmation #: 5HLT83719\n\nHonors points earned: 4,816\n\nWe look forward to your next visit!",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 11, hour: 12)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // Feb 7-9, 2026 — SFO→SAN 2-night weekend trip
            MailStore.makeItem(
                from: "Marriott Bonvoy",
                to: "You",
                subject: "Your stay receipt — Marriott Marquis San Diego Marina",
                body: "Thank you for your stay!\n\nMarriott Marquis San Diego Marina\n333 W Harbor Dr, San Diego, CA 92101\n\nCheck-in: February 7, 2026\nCheck-out: February 9, 2026\nRoom: King, Marina View (2 nights)\nRate: $279/night\nTaxes & fees: $83.70\nTotal: $641.70\nConfirmation #: 61MQ9A3T\n\nBonvoy points earned: 3,850\n\nSee you again soon!",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 9, hour: 11)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),

            // ── CityRide receipts for out-of-town airport rides ─────────

            // Oct 8, 2025 — JFK arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — JFK to Midtown Manhattan",
                body: "Thanks for riding with CityRide!\n\nTrip: JFK International Airport → Midtown Manhattan\nDate: October 8, 2025 at 7:45 PM\nDistance: 16.2 mi\nDuration: 48 min\n\nBase fare: $42.50\nService fee: $5.80\nTolls: $6.50\nTip: $7.50\nTotal: $62.30\n\nCharged to Visa ending in 2095\nRide ID: CR-NYC-1008A",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 8, hour: 20)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Oct 10, 2025 — JFK departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Midtown Manhattan to JFK",
                body: "Thanks for riding with CityRide!\n\nTrip: Midtown Manhattan → JFK International Airport\nDate: October 10, 2025 at 2:20 PM\nDistance: 15.8 mi\nDuration: 52 min\n\nBase fare: $39.00\nService fee: $5.65\nTolls: $6.50\nTip: $7.00\nTotal: $58.15\n\nCharged to Visa ending in 2095\nRide ID: CR-NYC-1010B",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 10, day: 10, hour: 15)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Nov 3, 2025 — ORD arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — O'Hare to Loop",
                body: "Thanks for riding with CityRide!\n\nTrip: O'Hare International Airport → The Loop, Chicago\nDate: November 3, 2025 at 6:30 PM\nDistance: 17.4 mi\nDuration: 38 min\n\nBase fare: $30.50\nService fee: $4.80\nTip: $7.50\nTotal: $42.80\n\nCharged to Visa ending in 2095\nRide ID: CR-CHI-1103A",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 3, hour: 19)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Nov 4, 2025 — ORD departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Loop to O'Hare",
                body: "Thanks for riding with CityRide!\n\nTrip: The Loop, Chicago → O'Hare International Airport\nDate: November 4, 2025 at 2:10 PM\nDistance: 17.1 mi\nDuration: 42 min\n\nBase fare: $28.00\nService fee: $4.50\nTip: $7.00\nTotal: $39.50\n\nCharged to Visa ending in 2095\nRide ID: CR-CHI-1104B",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 4, hour: 15)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Nov 25, 2025 — ATL arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — ATL Airport to Downtown",
                body: "Thanks for riding with CityRide!\n\nTrip: Hartsfield-Jackson Atlanta Airport → Downtown Atlanta\nDate: November 25, 2025 at 5:15 PM\nDistance: 10.8 mi\nDuration: 22 min\n\nBase fare: $22.50\nService fee: $4.20\nTip: $7.50\nTotal: $34.20\n\nCharged to Visa ending in 2095\nRide ID: CR-ATL-1125A",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 25, hour: 18)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Nov 29, 2025 — ATL departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Downtown to ATL Airport",
                body: "Thanks for riding with CityRide!\n\nTrip: Downtown Atlanta → Hartsfield-Jackson Atlanta Airport\nDate: November 29, 2025 at 8:45 AM\nDistance: 10.5 mi\nDuration: 20 min\n\nBase fare: $20.40\nService fee: $4.00\nTip: $7.50\nTotal: $31.90\n\nCharged to Visa ending in 2095\nRide ID: CR-ATL-1129B",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 11, day: 29, hour: 9)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Dec 22, 2025 — BOS arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Logan Airport to Copley",
                body: "Thanks for riding with CityRide!\n\nTrip: Boston Logan Airport → Copley Square, Boston\nDate: December 22, 2025 at 6:00 PM\nDistance: 4.2 mi\nDuration: 18 min\n\nBase fare: $24.50\nService fee: $4.20\nTolls: $3.50\nTip: $6.50\nTotal: $38.70\n\nCharged to Visa ending in 2095\nRide ID: CR-BOS-1222A",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 22, hour: 19)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Dec 27, 2025 — BOS departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Copley to Logan Airport",
                body: "Thanks for riding with CityRide!\n\nTrip: Copley Square, Boston → Boston Logan Airport\nDate: December 27, 2025 at 1:30 PM\nDistance: 4.0 mi\nDuration: 16 min\n\nBase fare: $22.00\nService fee: $3.90\nTolls: $3.50\nTip: $6.00\nTotal: $35.40\n\nCharged to Visa ending in 2095\nRide ID: CR-BOS-1227B",
                date: Calendar.current.date(from: DateComponents(year: 2025, month: 12, day: 27, hour: 14)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Jan 9, 2026 — LAX arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — LAX to Santa Monica",
                body: "Thanks for riding with CityRide!\n\nTrip: Los Angeles International Airport → Santa Monica\nDate: January 9, 2026 at 6:15 PM\nDistance: 12.1 mi\nDuration: 35 min\n\nBase fare: $32.00\nService fee: $5.10\nTip: $8.50\nTotal: $45.60\n\nCharged to Visa ending in 2095\nRide ID: CR-LAX-0109A",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 9, hour: 19)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Jan 11, 2026 — LAX departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Santa Monica to LAX",
                body: "Thanks for riding with CityRide!\n\nTrip: Santa Monica → Los Angeles International Airport\nDate: January 11, 2026 at 2:30 PM\nDistance: 12.4 mi\nDuration: 40 min\n\nBase fare: $34.50\nService fee: $5.20\nTip: $8.50\nTotal: $48.20\n\nCharged to Visa ending in 2095\nRide ID: CR-LAX-0111B",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 11, hour: 15)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Feb 7, 2026 — SAN arrival
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — SAN Airport to Gaslamp",
                body: "Thanks for riding with CityRide!\n\nTrip: San Diego International Airport → Gaslamp Quarter\nDate: February 7, 2026 at 5:45 PM\nDistance: 3.1 mi\nDuration: 10 min\n\nBase fare: $14.00\nService fee: $3.40\nTip: $5.00\nTotal: $22.40\n\nCharged to Visa ending in 2095\nRide ID: CR-SAN-0207A",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 7, hour: 18)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            ),
            // Feb 9, 2026 — SAN departure
            MailStore.makeItem(
                from: "CityRide",
                to: "You",
                subject: "Your ride receipt — Gaslamp to SAN Airport",
                body: "Thanks for riding with CityRide!\n\nTrip: Gaslamp Quarter → San Diego International Airport\nDate: February 9, 2026 at 1:00 PM\nDistance: 3.0 mi\nDuration: 9 min\n\nBase fare: $12.50\nService fee: $3.30\nTip: $4.00\nTotal: $19.80\n\nCharged to Visa ending in 2095\nRide ID: CR-SAN-0209B",
                date: Calendar.current.date(from: DateComponents(year: 2026, month: 2, day: 9, hour: 14)) ?? now,
                folder: .archive,
                category: .transactions,
                isUnread: false
            )
        ]
    }
}

struct MailNotificationPayload {
    let from: String
    let subject: String
    let body: String
    let category: MailCategory

    var preview: String {
        let compact = body.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespaces)
        return compact.count > 90 ? String(compact.prefix(90)) + "..." : compact
    }

    var userInfo: [String: Any] {
        [
            "from": from,
            "subject": subject,
            "body": body,
            "category": category.rawValue,
            "preview": preview
        ]
    }

    static func from(userInfo: [AnyHashable: Any]) -> MailNotificationPayload? {
        guard let from = userInfo["from"] as? String,
              let subject = userInfo["subject"] as? String,
              let body = userInfo["body"] as? String else {
            return nil
        }
        let rawCategory = userInfo["category"] as? Int ?? MailCategory.updates.rawValue
        let category = MailCategory(rawValue: rawCategory) ?? .updates
        return MailNotificationPayload(from: from, subject: subject, body: body, category: category)
    }
}

final class MailNotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MailNotificationScheduler()

    private let center = UNUserNotificationCenter.current()
    private let intervalKey = "mail_notification_interval_minutes"
    private let enabledKey = "mail_notification_enabled"
    private let prefix = "mail_auto_"
    private let maxPending = 60
    private var processedIDs = Set<String>()

    override init() {
        super.init()
        center.delegate = self
    }

    var intervalMinutes: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: intervalKey)
            return stored == 0 ? 5 : max(1, stored)
        }
        set {
            let value = max(1, newValue)
            UserDefaults.standard.set(value, forKey: intervalKey)
        }
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    func configureOnLaunch() {
        center.delegate = self
        if isEnabled {
            scheduleNotifications()
        }
    }

    func ensureAuthorizedAndSchedule(completion: ((String) -> Void)? = nil) {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion?("Notifications error: \(error.localizedDescription)")
                    return
                }
                guard granted else {
                    completion?("Notifications are disabled. Enable them in iOS Settings.")
                    return
                }
                self?.scheduleNotifications()
                completion?("Notifications scheduled every \(self?.intervalMinutes ?? 5) minute(s).")
            }
        }
    }

    func scheduleNotifications() {
        center.removeAllPendingNotificationRequests()
        let interval = max(1, intervalMinutes)
        let count = min(maxPending, max(1, 60 / interval))
        for index in 1...count {
            let payload = MailStore.shared.randomNotificationPayload()
            let content = UNMutableNotificationContent()
            content.title = payload.from
            content.subtitle = payload.subject
            content.body = payload.preview
            content.sound = .default
            content.userInfo = payload.userInfo

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(interval * 60 * index), repeats: false)
            let request = UNNotificationRequest(identifier: "\(prefix)\(UUID().uuidString)", content: content, trigger: trigger)
            center.add(request)
        }
        isEnabled = true
    }

    func stopNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        isEnabled = false
    }

    func processDeliveredNotifications() {
        center.getDeliveredNotifications { [weak self] notifications in
            guard let self = self else { return }
            let mailNotifications = notifications.filter { $0.request.identifier.hasPrefix(self.prefix) }
            guard !mailNotifications.isEmpty else { return }
            let identifiers = mailNotifications.map { $0.request.identifier }
            mailNotifications.forEach { self.insertMail(from: $0) }
            self.center.removeDeliveredNotifications(withIdentifiers: identifiers)
        }
    }

    private func insertMail(from notification: UNNotification) {
        let identifier = notification.request.identifier
        guard !processedIDs.contains(identifier),
              let payload = MailNotificationPayload.from(userInfo: notification.request.content.userInfo) else {
            return
        }
        processedIDs.insert(identifier)
        DispatchQueue.main.async {
            MailStore.shared.addIncomingMail(from: payload.from, subject: payload.subject, body: payload.body, category: payload.category, date: notification.date)
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        insertMail(from: notification)
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.alert, .sound])
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        insertMail(from: response.notification)
        completionHandler()
    }
}

final class OpenAISettings {
    static let shared = OpenAISettings()

    private init() {}

    func validatedApiKey() -> (key: String?, error: String?) {
        let candidate = keyFromEnvironment() ?? keyFromInfoPlist() ?? keyFromEnvFile() ?? keyFromUserDefaults()
        guard let rawKey = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !rawKey.isEmpty else {
            return (nil, "Missing OpenAI API key. Set OPENAI_API_KEY environment variable or in .env file.")
        }
        return (rawKey, nil)
    }

    private func keyFromEnvironment() -> String? {
        guard let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty else {
            return nil
        }
        return envKey
    }

    private func keyFromInfoPlist() -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !value.isEmpty, !value.contains("$(") else {
            return nil
        }
        return value
    }

    private func keyFromEnvFile() -> String? {
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
        return nil
    }

    private func keyFromUserDefaults() -> String? {
        guard let value = UserDefaults.standard.string(forKey: "openai_api_key"), !value.isEmpty else {
            return nil
        }
        return value
    }
}

final class OpenAIClient {
    static let shared = OpenAIClient()

    struct OpenAIError: Error {
        let message: String
    }

    private struct ChatResponse: Decodable {
        struct Choice: Decodable {
            struct Message: Decodable {
                let content: String
            }
            let message: Message
        }
        let choices: [Choice]
    }

    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func generateReply(to recipient: String, subject: String, body: String, apiKey: String, completion: @escaping (Result<String, OpenAIError>) -> Void) {

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(OpenAIError(message: "Invalid OpenAI endpoint URL.")))
            return
        }

        let systemPrompt = """
        You are \(recipient) replying to an email you received. \
        Write a concise, complete reply in 2-4 sentences as \(recipient). \
        Use a professional but natural tone. \
        CRITICAL RULES: \
        Never use square brackets like [Name] or [amount]. \
        Never include placeholder text. \
        Never add a signature block (no Best regards, no sign-off name, no title/company/contact). \
        If you do not know a specific detail, give a plausible answer rather than using a placeholder. \
        Just write the reply body and stop.
        """
        let userPrompt = """
        You received this email:
        Subject: \(subject)
        Message: \(body)

        Write your reply as \(recipient). Do not include any signature or sign-off:
        """

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.6,
            "max_tokens": 240
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(.failure(OpenAIError(message: "Failed to encode request payload.")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(OpenAIError(message: "Network error: \(error.localizedDescription)")))
                return
            }
            guard let data = data,
                  let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let content = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
                  !content.isEmpty else {
                completion(.failure(OpenAIError(message: "OpenAI response was empty.")))
                return
            }
            completion(.success(content))
        }.resume()
    }
}

final class ViewController: UINavigationController {
    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = .systemBlue
        viewControllers = [MailListViewController()]
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
    }
}

final class MailListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchResultsUpdating {
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let headerContainer = UIView()
    private let summaryLabel = UILabel()
    private let categoryScrollView = UIScrollView()
    private let categoryStack = UIStackView()
    private let floatingComposeButton = UIButton(type: .system)
    private let refreshControl = UIRefreshControl()
    private var headerHeightConstraint: NSLayoutConstraint?
    private var categoryButtons: [UIButton] = []
    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var selectButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(toggleSelectionMode))
        button.accessibilityIdentifier = "select_button"
        return button
    }()

    private lazy var settingsButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "gearshape"), style: .plain, target: self, action: #selector(openSettings))
        button.accessibilityIdentifier = "settings_button"
        return button
    }()

    private lazy var mailboxesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Mailboxes", style: .plain, target: self, action: #selector(openMailboxes))
        button.accessibilityIdentifier = "mailboxes_button"
        return button
    }()

    private lazy var archiveAction: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Archive", style: .plain, target: self, action: #selector(handleBulkArchive))
        button.accessibilityIdentifier = "bulk_archive_button"
        return button
    }()

    private lazy var deleteAction: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Delete", style: .plain, target: self, action: #selector(handleBulkDelete))
        button.accessibilityIdentifier = "bulk_delete_button"
        return button
    }()

    private lazy var readAction: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Read", style: .plain, target: self, action: #selector(handleBulkRead))
        button.accessibilityIdentifier = "bulk_read_button"
        return button
    }()

    private var isSelectionMode = false
    private var selectedFolder: MailFolder = .inbox {
        didSet {
            updateTitle()
            tableView.reloadData()
            updateHeaderSummary()
            updateCategoryVisibility()
            updateEmptyState()
        }
    }
    private var selectedCategory: MailCategory = .all {
        didSet {
            updateCategoryButtons()
            tableView.reloadData()
            updateHeaderSummary()
            updateEmptyState()
        }
    }

    private var baseItems: [MailItem] {
        let base = MailStore.shared.items(in: selectedFolder)
        guard selectedFolder == .inbox, selectedCategory != .all else { return base }
        return base.filter { $0.category == selectedCategory }
    }

    private var filteredItems: [MailItem] {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !query.isEmpty else { return baseItems }
        let lowercased = query.lowercased()
        return baseItems.filter { item in
            item.from.lowercased().contains(lowercased)
                || item.to.lowercased().contains(lowercased)
                || item.subject.lowercased().contains(lowercased)
                || item.preview.lowercased().contains(lowercased)
                || item.body.lowercased().contains(lowercased)
                || item.attachments.contains(where: {
                    $0.filename.lowercased().contains(lowercased)
                        || $0.title.lowercased().contains(lowercased)
                        || $0.subtitle.lowercased().contains(lowercased)
                })
        }
    }

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    private let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = MailTheme.groupedBackground
        configureNavigationItems()
        configureSearch()
        configureHeader()
        configureTable()
        configureFloatingComposeButton()
        updateTitle()
        updateCategoryButtons()
        updateHeaderSummary()
        updateCategoryVisibility()
        updateEmptyState()

        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChange), name: .mailStoreDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIReplyFailed(_:)), name: .mailAIReplyFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailAppearance.apply(to: self)
        navigationController?.setToolbarHidden(!isSelectionMode, animated: false)
        tableView.reloadData()
        updateHeaderSummary()
        updateEmptyState()
        updateFloatingComposeVisibility(animated: false)
    }

    private func updateTitle() {
        title = mailFolderDisplayTitle(selectedFolder)
    }

    private func configureNavigationItems() {
        navigationItem.leftBarButtonItems = [mailboxesButton]
        navigationItem.rightBarButtonItems = [selectButton, settingsButton]
        navigationItem.largeTitleDisplayMode = .always
    }

    private func configureSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Mail"
        searchController.searchBar.accessibilityIdentifier = "mail_search_bar"
        searchController.searchBar.searchTextField.backgroundColor = MailTheme.cardBackground
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func configureHeader() {
        headerContainer.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.backgroundColor = .clear

        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.font = .systemFont(ofSize: 14, weight: .medium)
        summaryLabel.textColor = .secondaryLabel

        categoryScrollView.translatesAutoresizingMaskIntoConstraints = false
        categoryScrollView.showsHorizontalScrollIndicator = false
        categoryScrollView.alwaysBounceHorizontal = true

        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        categoryStack.axis = .horizontal
        categoryStack.alignment = .center
        categoryStack.spacing = 10

        categoryButtons = MailCategory.allCases.map { category in
            let button = UIButton(type: .system)
            button.tag = category.rawValue
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            button.accessibilityIdentifier = "category_\(category.title.replacingOccurrences(of: " ", with: "_").lowercased())"
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.semanticContentAttribute = .forceLeftToRight
            categoryStack.addArrangedSubview(button)
            return button
        }

        view.addSubview(headerContainer)
        headerContainer.addSubview(summaryLabel)
        headerContainer.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStack)

        headerHeightConstraint = headerContainer.heightAnchor.constraint(equalToConstant: 82)
        headerHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            summaryLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 2),
            summaryLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            summaryLabel.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),

            categoryScrollView.topAnchor.constraint(equalTo: summaryLabel.bottomAnchor, constant: 10),
            categoryScrollView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor),
            categoryScrollView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor),
            categoryScrollView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),

            categoryStack.topAnchor.constraint(equalTo: categoryScrollView.topAnchor),
            categoryStack.leadingAnchor.constraint(equalTo: categoryScrollView.leadingAnchor, constant: 16),
            categoryStack.trailingAnchor.constraint(equalTo: categoryScrollView.trailingAnchor, constant: -16),
            categoryStack.bottomAnchor.constraint(equalTo: categoryScrollView.bottomAnchor)
        ])
    }

    private func configureTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorColor = .separator
        tableView.rowHeight = 96
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        tableView.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 96, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MailCell.self, forCellReuseIdentifier: "MailCell")
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 16)
        tableView.allowsMultipleSelectionDuringEditing = true
        refreshControl.tintColor = .systemBlue
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func configureFloatingComposeButton() {
        floatingComposeButton.translatesAutoresizingMaskIntoConstraints = false
        floatingComposeButton.backgroundColor = MailTheme.cardBackground
        floatingComposeButton.tintColor = .label
        floatingComposeButton.layer.cornerRadius = 28
        floatingComposeButton.layer.borderWidth = 0.5
        floatingComposeButton.layer.borderColor = UIColor.separator.cgColor
        floatingComposeButton.layer.shadowColor = UIColor.black.cgColor
        floatingComposeButton.layer.shadowOpacity = 0.16
        floatingComposeButton.layer.shadowOffset = CGSize(width: 0, height: 8)
        floatingComposeButton.layer.shadowRadius = 18
        floatingComposeButton.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        floatingComposeButton.accessibilityIdentifier = "compose_button"
        floatingComposeButton.addTarget(self, action: #selector(compose), for: .touchUpInside)

        view.addSubview(floatingComposeButton)

        NSLayoutConstraint.activate([
            floatingComposeButton.widthAnchor.constraint(equalToConstant: 56),
            floatingComposeButton.heightAnchor.constraint(equalToConstant: 56),
            floatingComposeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18),
            floatingComposeButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18)
        ])
    }

    private func updateFloatingComposeVisibility(animated: Bool) {
        let updates = {
            self.floatingComposeButton.alpha = self.isSelectionMode ? 0 : 1
            self.floatingComposeButton.transform = self.isSelectionMode ? CGAffineTransform(scaleX: 0.92, y: 0.92) : .identity
        }
        floatingComposeButton.isUserInteractionEnabled = !isSelectionMode
        if animated {
            UIView.animate(withDuration: 0.18, animations: updates)
        } else {
            updates()
        }
    }

    private func updateHeaderSummary() {
        let visibleCount = baseItems.count
        switch selectedFolder {
        case .inbox:
            let unread = baseItems.filter { $0.isUnread }.count
            if selectedCategory == .all {
                summaryLabel.text = "\(formatMailCount(unread)) unread • Updated just now"
            } else {
                summaryLabel.text = "\(selectedCategory.title) • \(formatMailCount(unread)) unread"
            }
        case .drafts:
            summaryLabel.text = visibleCount == 1 ? "1 draft ready to finish" : "\(formatMailCount(visibleCount)) drafts ready to finish"
        case .scheduled:
            summaryLabel.text = visibleCount == 1 ? "1 message scheduled" : "\(formatMailCount(visibleCount)) messages scheduled"
        case .sent:
            summaryLabel.text = visibleCount == 1 ? "1 sent message" : "\(formatMailCount(visibleCount)) sent messages"
        case .archive:
            summaryLabel.text = visibleCount == 1 ? "1 archived message" : "\(formatMailCount(visibleCount)) archived messages"
        case .trash:
            summaryLabel.text = visibleCount == 1 ? "1 message in trash" : "\(formatMailCount(visibleCount)) messages in trash"
        }
    }

    private func updateCategoryButtons() {
        for button in categoryButtons {
            guard let category = MailCategory(rawValue: button.tag) else { continue }
            let isSelected = category == selectedCategory
            button.setTitle(category.title, for: .normal)
            button.setImage(categoryIcon(for: category), for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            button.tintColor = isSelected ? .systemBlue : .secondaryLabel
            button.setTitleColor(isSelected ? .label : .secondaryLabel, for: .normal)
            button.backgroundColor = isSelected ? MailTheme.tintedBackground(for: .systemBlue) : MailTheme.cardBackground
            button.layer.cornerRadius = 17
            button.layer.borderWidth = 1
            button.layer.borderColor = (isSelected ? UIColor.systemBlue : UIColor.separator).withAlphaComponent(isSelected ? 0.18 : 0.35).cgColor
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -2, bottom: 0, right: 6)
            button.titleEdgeInsets = .zero
        }
    }

    private func updateCategoryVisibility() {
        let showCategories = selectedFolder == .inbox
        categoryScrollView.isHidden = !showCategories
        headerHeightConstraint?.constant = showCategories ? 82 : 34
        if view.window != nil {
            UIView.animate(withDuration: 0.18) {
                self.view.layoutIfNeeded()
            }
        } else {
            view.layoutIfNeeded()
        }
    }

    private func categoryIcon(for category: MailCategory) -> UIImage? {
        let name: String
        switch category {
        case .all:
            name = "tray.full"
        case .transactions:
            name = "creditcard"
        case .updates:
            name = "bell"
        case .promotions:
            name = "megaphone"
        }
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        return UIImage(systemName: name)?.applyingSymbolConfiguration(config)
    }

    private func updateEmptyState() {
        guard filteredItems.isEmpty else {
            tableView.backgroundView = nil
            return
        }

        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.numberOfLines = 0
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !query.isEmpty {
            label.text = "No results for \"\(query)\""
        } else if selectedFolder == .inbox && selectedCategory != .all {
            label.text = "No \(selectedCategory.title.lowercased()) messages"
        } else {
            label.text = "No messages"
        }
        tableView.backgroundView = label
    }

    @objc private func categoryTapped(_ sender: UIButton) {
        guard let category = MailCategory(rawValue: sender.tag) else { return }
        selectedCategory = category
    }

    @objc private func handlePullToRefresh() {
        MailStore.shared.importSharedInbox()
        refreshControl.endRefreshing()
        updateHeaderSummary()
    }

    @objc private func compose() {
        let compose = ComposeViewController(mode: .new)
        let nav = UINavigationController(rootViewController: compose)
        nav.navigationBar.prefersLargeTitles = false
        nav.navigationBar.tintColor = .systemBlue
        present(nav, animated: true, completion: nil)
    }

    @objc private func openMailboxes() {
        let mailboxes = MailboxesViewController(selectedFolder: selectedFolder) { [weak self] folder in
            self?.selectedFolder = folder
            self?.selectedCategory = .all
        }
        navigationController?.pushViewController(mailboxes, animated: true)
    }

    @objc private func openSettings() {
        let settings = SettingsViewController()
        navigationController?.pushViewController(settings, animated: true)
    }

    @objc private func toggleSelectionMode() {
        isSelectionMode.toggle()
        tableView.setEditing(isSelectionMode, animated: true)
        tableView.allowsMultipleSelectionDuringEditing = true
        selectButton.title = isSelectionMode ? "Done" : "Select"
        settingsButton.isEnabled = !isSelectionMode
        navigationController?.setToolbarHidden(!isSelectionMode, animated: true)
        updateFloatingComposeVisibility(animated: true)

        if isSelectionMode {
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            setToolbarItems([archiveAction, spacer, deleteAction, spacer, readAction], animated: true)
        } else {
            tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }
        }
    }

    @objc private func handleBulkArchive() {
        let selected = selectedItems()
        guard !selected.isEmpty else { return }
        selected.forEach { item in
            if item.folder != .archive {
                MailStore.shared.move(id: item.id, to: .archive)
            }
        }
        finishBulkAction()
    }

    @objc private func handleBulkDelete() {
        let selected = selectedItems()
        guard !selected.isEmpty else { return }
        selected.forEach { item in
            if item.folder == .trash {
                MailStore.shared.delete(id: item.id)
            } else {
                MailStore.shared.move(id: item.id, to: .trash)
            }
        }
        finishBulkAction()
    }

    @objc private func handleBulkRead() {
        let selected = selectedItems()
        guard !selected.isEmpty else { return }
        selected.forEach { item in
            MailStore.shared.markRead(id: item.id)
        }
        finishBulkAction()
    }

    private func finishBulkAction() {
        tableView.reloadData()
        updateHeaderSummary()
        updateEmptyState()
        toggleSelectionMode()
    }

    private func selectedItems() -> [MailItem] {
        guard let selectedRows = tableView.indexPathsForSelectedRows else { return [] }
        return selectedRows.compactMap { indexPath in
            let list = filteredItems
            guard indexPath.row < list.count else { return nil }
            return list[indexPath.row]
        }
    }

    @objc private func handleStoreChange() {
        tableView.reloadData()
        updateHeaderSummary()
        updateEmptyState()
    }

    @objc private func handleAIReplyFailed(_ notification: Notification) {
        guard view.window != nil else { return }
        let message = (notification.userInfo?["message"] as? String) ?? "AI reply failed."
        let alert = UIAlertController(title: "AI reply unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
        updateCategoryButtons()
    }

    func updateSearchResults(for searchController: UISearchController) {
        tableView.reloadData()
        updateHeaderSummary()
        updateEmptyState()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MailCell", for: indexPath) as? MailCell else {
            return UITableViewCell()
        }
        let item = filteredItems[indexPath.row]
        cell.configure(with: item, folder: selectedFolder, dateText: formatListDate(item.date))
        let subjectSlug = item.subject.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
            .prefix(40)
        cell.accessibilityIdentifier = "mail_row_\(subjectSlug.isEmpty ? "idx\(indexPath.row)" : String(subjectSlug))"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let item = filteredItems[indexPath.row]
        if selectedFolder == .drafts || selectedFolder == .scheduled {
            let compose = ComposeViewController(mode: .edit(item))
            let nav = UINavigationController(rootViewController: compose)
            nav.navigationBar.prefersLargeTitles = false
            nav.navigationBar.tintColor = .systemBlue
            present(nav, animated: true, completion: nil)
            return
        }

        let detail = MailDetailViewController(itemID: item.id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let item = filteredItems[indexPath.row]
        switch selectedFolder {
        case .inbox:
            let archive = UIContextualAction(style: .normal, title: "Archive") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .archive)
                completion(true)
            }
            archive.backgroundColor = .systemBlue

            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .trash)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete, archive])
        case .archive:
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .trash)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .drafts:
            let send = UIContextualAction(style: .normal, title: "Send") { _, _, completion in
                MailStore.shared.delete(id: item.id)
                MailStore.shared.sendMessage(to: item.to, subject: item.subject, body: item.body, category: item.category, attachments: item.attachments)
                completion(true)
            }
            send.backgroundColor = .systemGreen

            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .trash)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete, send])
        case .scheduled:
            let sendNow = UIContextualAction(style: .normal, title: "Send") { _, _, completion in
                MailStore.shared.delete(id: item.id)
                MailStore.shared.sendMessage(to: item.to, subject: item.subject, body: item.body, category: item.category, attachments: item.attachments)
                completion(true)
            }
            sendNow.backgroundColor = .systemGreen

            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .trash)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete, sendNow])
        case .sent:
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.move(id: item.id, to: .trash)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        case .trash:
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                MailStore.shared.delete(id: item.id)
                completion(true)
            }
            return UISwipeActionsConfiguration(actions: [delete])
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .none
    }

    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    private func formatListDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return timeFormatter.string(from: date)
        }
        if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        }
        if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return weekdayFormatter.string(from: date)
        }
        return monthFormatter.string(from: date)
    }
}

final class MailboxesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let selectedFolder: MailFolder
    private let onSelect: (MailFolder) -> Void
    private let sections: [(title: String, folders: [MailFolder])] = [
        ("Favorites", [.inbox, .drafts, .scheduled]),
        (MailTheme.accountName, [.sent, .archive, .trash])
    ]

    init(selectedFolder: MailFolder, onSelect: @escaping (MailFolder) -> Void) {
        self.selectedFolder = selectedFolder
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = MailTheme.groupedBackground
        title = "Mailboxes"
        navigationItem.prompt = "Updated just now"
        navigationItem.largeTitleDisplayMode = .always
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 60
        tableView.register(MailboxCell.self, forCellReuseIdentifier: "MailboxCell")
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 8
        }
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipe.direction = .left
        view.addGestureRecognizer(swipe)

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailAppearance.apply(to: self)
        tableView.reloadData()
    }

    @objc private func handleSwipeLeft() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
        tableView.reloadData()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].folders.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MailboxCell", for: indexPath) as? MailboxCell else {
            return UITableViewCell()
        }
        let folder = sections[indexPath.section].folders[indexPath.row]
        cell.configure(
            title: mailFolderDisplayTitle(folder),
            countText: folderCountText(for: folder),
            icon: folderIcon(folder),
            tintColor: MailTheme.folderTint(for: folder),
            isSelected: folder == selectedFolder
        )
        cell.accessibilityIdentifier = "mailbox_\(folder.title.lowercased())"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let folder = sections[indexPath.section].folders[indexPath.row]
        onSelect(folder)
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    private func folderCountText(for folder: MailFolder) -> String? {
        let count: Int
        switch folder {
        case .inbox:
            count = MailStore.shared.unreadCount(in: .inbox)
        case .drafts, .scheduled, .sent, .archive, .trash:
            count = MailStore.shared.count(in: folder)
        }
        return count > 0 ? formatMailCount(count) : nil
    }

    private func folderIcon(_ folder: MailFolder) -> UIImage? {
        let name: String
        switch folder {
        case .inbox:
            name = "tray"
        case .drafts:
            name = "doc.text"
        case .scheduled:
            name = "clock"
        case .sent:
            name = "paperplane"
        case .archive:
            name = "archivebox"
        case .trash:
            name = "trash"
        }
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
        return UIImage(systemName: name)?.applyingSymbolConfiguration(config)
    }
}

final class MailboxCell: UITableViewCell {
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let checkmarkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .default

        let selectedView = UIView()
        selectedView.backgroundColor = MailTheme.mutedFill
        selectedBackgroundView = selectedView

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.layer.cornerRadius = 14

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.font = .systemFont(ofSize: 17, weight: .regular)
        countLabel.textColor = .secondaryLabel
        countLabel.setContentHuggingPriority(.required, for: .horizontal)

        checkmarkView.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.image = UIImage(systemName: "checkmark")
        checkmarkView.tintColor = .systemBlue
        checkmarkView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)

        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(countLabel)
        contentView.addSubview(checkmarkView)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 28),
            iconContainer.heightAnchor.constraint(equalToConstant: 28),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 17),
            iconView.heightAnchor.constraint(equalToConstant: 17),

            titleLabel.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 14),
            checkmarkView.heightAnchor.constraint(equalToConstant: 14),

            countLabel.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -10),
            countLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, countText: String?, icon: UIImage?, tintColor: UIColor, isSelected: Bool) {
        titleLabel.text = title
        countLabel.text = countText
        countLabel.isHidden = countText == nil
        iconView.image = icon
        iconView.tintColor = tintColor
        iconContainer.backgroundColor = MailTheme.tintedBackground(for: tintColor)
        checkmarkView.isHidden = !isSelected
    }
}

final class SettingsViewController: UIViewController {
    private let darkModeSwitch = UISwitch()
    private let intervalStepper = UIStepper()
    private let intervalValueLabel = UILabel()
    private let notificationsStatusLabel = UILabel()
    private let applyNotificationsButton = UIButton(type: .system)
    private let stopNotificationsButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = MailTheme.groupedBackground
        title = "Settings"

        let titleLabel = UILabel()
        titleLabel.text = "Dark Mode"
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label

        darkModeSwitch.isOn = MailAppearance.isDarkMode
        darkModeSwitch.addTarget(self, action: #selector(toggleDarkMode), for: .valueChanged)
        darkModeSwitch.accessibilityIdentifier = "dark_mode_toggle"

        let row = UIStackView(arrangedSubviews: [titleLabel, darkModeSwitch])
        row.axis = .horizontal
        row.alignment = .center
        row.distribution = .equalSpacing
        row.translatesAutoresizingMaskIntoConstraints = false

        let appearanceContainer = UIView()
        appearanceContainer.backgroundColor = MailTheme.cardBackground
        appearanceContainer.layer.cornerRadius = 12
        appearanceContainer.translatesAutoresizingMaskIntoConstraints = false
        appearanceContainer.addSubview(row)

        let notificationsTitle = UILabel()
        notificationsTitle.text = "Auto Notifications"
        notificationsTitle.font = .systemFont(ofSize: 17, weight: .semibold)
        notificationsTitle.textColor = .label

        let intervalLabel = UILabel()
        intervalLabel.text = "Interval (minutes)"
        intervalLabel.font = .systemFont(ofSize: 15, weight: .regular)
        intervalLabel.textColor = .secondaryLabel

        intervalValueLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        intervalValueLabel.textColor = .label
        intervalValueLabel.textAlignment = .right
        intervalValueLabel.accessibilityIdentifier = "notification_interval_value"

        intervalStepper.minimumValue = 1
        intervalStepper.maximumValue = 60
        intervalStepper.stepValue = 1
        intervalStepper.value = Double(MailNotificationScheduler.shared.intervalMinutes)
        intervalStepper.addTarget(self, action: #selector(intervalChanged), for: .valueChanged)
        intervalStepper.accessibilityIdentifier = "notification_interval_stepper"

        let intervalRow = UIStackView(arrangedSubviews: [intervalLabel, intervalValueLabel])
        intervalRow.axis = .horizontal
        intervalRow.distribution = .equalSpacing

        let stepperRow = UIStackView(arrangedSubviews: [intervalStepper])
        stepperRow.axis = .horizontal
        stepperRow.alignment = .leading
        stepperRow.distribution = .fill

        notificationsStatusLabel.font = .systemFont(ofSize: 13, weight: .regular)
        notificationsStatusLabel.textColor = .secondaryLabel
        notificationsStatusLabel.accessibilityIdentifier = "notifications_status_label"

        applyNotificationsButton.setTitle("Update Notifications", for: .normal)
        applyNotificationsButton.backgroundColor = UIColor.systemBlue
        applyNotificationsButton.tintColor = .white
        applyNotificationsButton.layer.cornerRadius = 10
        applyNotificationsButton.addTarget(self, action: #selector(applyNotifications), for: .touchUpInside)
        applyNotificationsButton.accessibilityIdentifier = "notifications_apply_button"

        stopNotificationsButton.setTitle("Stop Notifications", for: .normal)
        stopNotificationsButton.backgroundColor = MailTheme.elevatedBackground
        stopNotificationsButton.tintColor = .label
        stopNotificationsButton.layer.cornerRadius = 10
        stopNotificationsButton.addTarget(self, action: #selector(stopNotifications), for: .touchUpInside)
        stopNotificationsButton.accessibilityIdentifier = "notifications_stop_button"

        let buttonRow = UIStackView(arrangedSubviews: [applyNotificationsButton, stopNotificationsButton])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 12
        buttonRow.distribution = .fillEqually

        let notificationsStack = UIStackView(arrangedSubviews: [notificationsTitle, intervalRow, stepperRow, notificationsStatusLabel, buttonRow])
        notificationsStack.axis = .vertical
        notificationsStack.spacing = 10
        notificationsStack.translatesAutoresizingMaskIntoConstraints = false

        let notificationsContainer = UIView()
        notificationsContainer.backgroundColor = MailTheme.cardBackground
        notificationsContainer.layer.cornerRadius = 12
        notificationsContainer.translatesAutoresizingMaskIntoConstraints = false
        notificationsContainer.addSubview(notificationsStack)

        view.addSubview(appearanceContainer)
        view.addSubview(notificationsContainer)

        NSLayoutConstraint.activate([
            appearanceContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            appearanceContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            appearanceContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            appearanceContainer.heightAnchor.constraint(equalToConstant: 52),

            row.leadingAnchor.constraint(equalTo: appearanceContainer.leadingAnchor, constant: 16),
            row.trailingAnchor.constraint(equalTo: appearanceContainer.trailingAnchor, constant: -16),
            row.topAnchor.constraint(equalTo: appearanceContainer.topAnchor),
            row.bottomAnchor.constraint(equalTo: appearanceContainer.bottomAnchor),

            notificationsContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            notificationsContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            notificationsContainer.topAnchor.constraint(equalTo: appearanceContainer.bottomAnchor, constant: 16),

            notificationsStack.leadingAnchor.constraint(equalTo: notificationsContainer.leadingAnchor, constant: 16),
            notificationsStack.trailingAnchor.constraint(equalTo: notificationsContainer.trailingAnchor, constant: -16),
            notificationsStack.topAnchor.constraint(equalTo: notificationsContainer.topAnchor, constant: 16),
            notificationsStack.bottomAnchor.constraint(equalTo: notificationsContainer.bottomAnchor, constant: -16),

            applyNotificationsButton.heightAnchor.constraint(equalToConstant: 44),
            stopNotificationsButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
        updateNotificationUI()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailAppearance.apply(to: self)
        darkModeSwitch.isOn = MailAppearance.isDarkMode
        updateNotificationUI()
    }

    @objc private func toggleDarkMode() {
        MailAppearance.setDarkMode(darkModeSwitch.isOn)
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
        darkModeSwitch.isOn = MailAppearance.isDarkMode
    }

    @objc private func intervalChanged() {
        updateNotificationUI()
    }

    @objc private func applyNotifications() {
        let minutes = Int(intervalStepper.value)
        MailNotificationScheduler.shared.intervalMinutes = minutes
        MailNotificationScheduler.shared.ensureAuthorizedAndSchedule { [weak self] message in
            self?.notificationsStatusLabel.text = message
        }
    }

    @objc private func stopNotifications() {
        MailNotificationScheduler.shared.stopNotifications()
        updateNotificationUI()
    }

    private func updateNotificationUI() {
        let minutes = Int(intervalStepper.value)
        intervalValueLabel.text = "\(minutes) min"
        let status = MailNotificationScheduler.shared.isEnabled ? "Status: On" : "Status: Off"
        notificationsStatusLabel.text = status
    }
}

final class MailCell: UITableViewCell {
    private let unreadDot = UIView()
    private let avatarView = MailAvatarView()
    private let senderLabel = UILabel()
    private let attachmentView = UIImageView()
    private let subjectLabel = UILabel()
    private let previewLabel = UILabel()
    private let dateLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupViews() {
        selectionStyle = .default
        separatorInset = UIEdgeInsets(top: 0, left: 84, bottom: 0, right: 16)

        let selectedView = UIView()
        selectedView.backgroundColor = MailTheme.mutedFill
        selectedBackgroundView = selectedView

        unreadDot.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.backgroundColor = .systemBlue
        unreadDot.layer.cornerRadius = 5

        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        senderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        senderLabel.textColor = .label
        senderLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        subjectLabel.font = .systemFont(ofSize: 14, weight: .regular)
        subjectLabel.textColor = .label
        subjectLabel.numberOfLines = 1

        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.font = .systemFont(ofSize: 13, weight: .regular)
        previewLabel.textColor = .secondaryLabel
        previewLabel.numberOfLines = 2

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .secondaryLabel
        dateLabel.textAlignment = .right
        dateLabel.setContentHuggingPriority(.required, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        attachmentView.translatesAutoresizingMaskIntoConstraints = false
        attachmentView.image = UIImage(systemName: "paperclip")
        attachmentView.tintColor = .secondaryLabel
        attachmentView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        attachmentView.setContentHuggingPriority(.required, for: .horizontal)
        attachmentView.isHidden = true

        contentView.addSubview(avatarView)
        contentView.addSubview(unreadDot)

        let headerStack = UIStackView(arrangedSubviews: [senderLabel, attachmentView, dateLabel])
        headerStack.axis = .horizontal
        headerStack.spacing = 8
        headerStack.alignment = .top

        let textStack = UIStackView(arrangedSubviews: [headerStack, subjectLabel, previewLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            unreadDot.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            unreadDot.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            unreadDot.heightAnchor.constraint(equalToConstant: 10),
            unreadDot.widthAnchor.constraint(equalToConstant: 10),

            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            avatarView.heightAnchor.constraint(equalToConstant: 44),
            avatarView.widthAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with item: MailItem, folder: MailFolder, dateText: String) {
        let displayName: String
        let avatarSender: String
        switch folder {
        case .drafts:
            displayName = item.to
            avatarSender = item.to
        case .scheduled, .sent:
            displayName = item.to
            avatarSender = item.to
        default:
            displayName = item.from
            avatarSender = item.from
        }

        senderLabel.text = displayName
        subjectLabel.text = item.subject.isEmpty ? "(no subject)" : item.subject
        previewLabel.text = item.preview
        dateLabel.text = dateText
        attachmentView.isHidden = item.attachments.isEmpty

        unreadDot.isHidden = !item.isUnread
        senderLabel.font = item.isUnread ? .systemFont(ofSize: 16, weight: .bold) : .systemFont(ofSize: 16, weight: .semibold)
        dateLabel.textColor = item.isUnread ? .label : .secondaryLabel
        subjectLabel.textColor = folder == .drafts ? .systemOrange : .label

        if folder == .scheduled {
            previewLabel.text = "Scheduled to send later. \(item.preview)"
        }
        if folder == .drafts {
            previewLabel.text = item.preview.isEmpty ? "Draft saved" : item.preview
        }

        avatarView.configure(sender: avatarSender)
    }
}

final class MailDetailViewController: UIViewController {
    private let itemID: UUID
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let toolbar = UIToolbar()
    private var activeAttachments: [MailAttachment] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    init(itemID: UUID) {
        self.itemID = itemID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = MailTheme.groupedBackground
        configureLayout()
        configureToolbar()
        updateContent()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAIReplyFailed(_:)), name: .mailAIReplyFailed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleStoreChanged), name: .mailStoreDidChange, object: nil)
    }

    @objc private func handleStoreChanged() {
        updateContent()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailAppearance.apply(to: self)
        MailStore.shared.markRead(id: itemID)
    }

    private func updateContent() {
        guard let item = MailStore.shared.item(for: itemID) else { return }
        activeAttachments = item.attachments

        let threadMessages = MailStore.shared.threadItems(for: item.threadId)
        let displayItems = threadMessages.count > 1 ? threadMessages : [item]
        let otherParty = item.from == "You" ? item.to : item.from
        title = otherParty

        contentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let subjectLabel = UILabel()
        subjectLabel.text = displayItems.first?.subject ?? item.subject
        subjectLabel.textColor = .label
        subjectLabel.font = .systemFont(ofSize: 28, weight: .bold)
        subjectLabel.numberOfLines = 0
        contentStack.addArrangedSubview(subjectLabel)

        for threadItem in displayItems {
            contentStack.addArrangedSubview(makeThreadMessageCard(for: threadItem, showCategory: false))
            if !threadItem.attachments.isEmpty {
                contentStack.addArrangedSubview(makeAttachmentCard(for: threadItem.attachments))
            }
        }
    }

    private func makeThreadMessageCard(for item: MailItem, showCategory: Bool) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = MailTheme.cardBackground
        card.layer.cornerRadius = 18

        let displaySender = item.from == "You" ? item.to : item.from
        let avatarView = MailAvatarView()
        avatarView.configure(sender: displaySender)

        let senderLabel = UILabel()
        senderLabel.translatesAutoresizingMaskIntoConstraints = false
        senderLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        senderLabel.textColor = .label
        senderLabel.text = item.from == "You" ? "You" : item.from

        let routeLabel = UILabel()
        routeLabel.translatesAutoresizingMaskIntoConstraints = false
        routeLabel.font = .systemFont(ofSize: 13, weight: .regular)
        routeLabel.textColor = .secondaryLabel
        routeLabel.text = item.from == "You" ? "to \(item.to)" : "to \(item.to == "You" ? "me" : item.to)"

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.text = dateFormatter.string(from: item.date)
        dateLabel.textColor = .secondaryLabel
        dateLabel.font = .systemFont(ofSize: 13, weight: .regular)
        dateLabel.textAlignment = .right
        dateLabel.numberOfLines = 2
        dateLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let senderStack = UIStackView(arrangedSubviews: [senderLabel, routeLabel])
        senderStack.translatesAutoresizingMaskIntoConstraints = false
        senderStack.axis = .vertical
        senderStack.spacing = 2

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.text = item.body.isEmpty ? "No message body." : item.body
        bodyLabel.textColor = .label
        bodyLabel.font = .systemFont(ofSize: 17, weight: .regular)
        bodyLabel.numberOfLines = 0

        card.addSubview(avatarView)
        card.addSubview(senderStack)
        card.addSubview(dateLabel)
        card.addSubview(bodyLabel)

        var constraints = [
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 44),
            avatarView.heightAnchor.constraint(equalToConstant: 44),

            senderStack.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            senderStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: senderStack.trailingAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            dateLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            bodyLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            bodyLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            bodyLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 14)
        ]

        if showCategory {
            let categoryPill = makePill(
                text: item.folder == .inbox ? item.category.title : item.folder.title,
                tintColor: item.folder == .inbox ? .systemBlue : MailTheme.folderTint(for: item.folder)
            )
            card.addSubview(categoryPill)
            constraints.append(contentsOf: [
                categoryPill.leadingAnchor.constraint(equalTo: senderStack.leadingAnchor),
                categoryPill.topAnchor.constraint(equalTo: senderStack.bottomAnchor, constant: 6),
                bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
            ])
        } else {
            constraints.append(bodyLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18))
        }

        NSLayoutConstraint.activate(constraints)
        return card
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(toolbar)
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbar.topAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -20),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func configureToolbar() {
        toolbar.tintColor = .systemBlue
        let reply = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.left"), style: .plain, target: self, action: #selector(handleReply))
        reply.accessibilityIdentifier = "detail_reply_button"
        let forward = UIBarButtonItem(image: UIImage(systemName: "arrowshape.turn.up.right"), style: .plain, target: self, action: #selector(handleForward))
        forward.accessibilityIdentifier = "detail_forward_button"
        let archive = UIBarButtonItem(image: UIImage(systemName: "archivebox"), style: .plain, target: self, action: #selector(handleArchive))
        archive.accessibilityIdentifier = "detail_archive_button"
        let delete = UIBarButtonItem(image: UIImage(systemName: "trash"), style: .plain, target: self, action: #selector(handleDelete))
        delete.accessibilityIdentifier = "detail_delete_button"
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [reply, spacer, forward, spacer, archive, spacer, delete]
    }

    private func makePill(text: String, tintColor: UIColor) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = MailTheme.tintedBackground(for: tintColor)
        container.layer.cornerRadius = 12

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = tintColor

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    private func makeAttachmentCard(for attachments: [MailAttachment]) -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = MailTheme.cardBackground
        card.layer.cornerRadius = 18

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = attachments.count == 1 ? "Attachment" : "Attachments"
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        let countLabel = UILabel()
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.text = formatMailAttachmentCount(attachments.count)
        countLabel.font = .systemFont(ofSize: 13, weight: .medium)
        countLabel.textColor = .secondaryLabel

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), countLabel])
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        let attachmentScrollView = UIScrollView()
        attachmentScrollView.translatesAutoresizingMaskIntoConstraints = false
        attachmentScrollView.showsHorizontalScrollIndicator = false

        let attachmentStack = UIStackView()
        attachmentStack.translatesAutoresizingMaskIntoConstraints = false
        attachmentStack.axis = .horizontal
        attachmentStack.spacing = 12

        attachmentScrollView.addSubview(attachmentStack)
        card.addSubview(headerStack)
        card.addSubview(attachmentScrollView)

        NSLayoutConstraint.activate([
            headerStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            headerStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            headerStack.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            attachmentScrollView.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            attachmentScrollView.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            attachmentScrollView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 12),
            attachmentScrollView.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            attachmentScrollView.heightAnchor.constraint(equalToConstant: 186),

            attachmentStack.leadingAnchor.constraint(equalTo: attachmentScrollView.leadingAnchor, constant: 16),
            attachmentStack.trailingAnchor.constraint(equalTo: attachmentScrollView.trailingAnchor, constant: -16),
            attachmentStack.topAnchor.constraint(equalTo: attachmentScrollView.topAnchor),
            attachmentStack.bottomAnchor.constraint(equalTo: attachmentScrollView.bottomAnchor),
            attachmentStack.heightAnchor.constraint(equalTo: attachmentScrollView.heightAnchor)
        ])

        for (index, attachment) in attachments.enumerated() {
            let button = MailAttachmentTileButton()
            button.tag = index
            button.configure(with: attachment)
            button.addTarget(self, action: #selector(openAttachmentPreview(_:)), for: .touchUpInside)
            attachmentStack.addArrangedSubview(button)
        }

        return card
    }

    @objc private func handleReply() {
        guard let item = MailStore.shared.item(for: itemID) else { return }
        let mode: ComposeMode
        if item.folder == .drafts || item.folder == .scheduled {
            mode = .edit(item)
        } else {
            mode = .reply(item)
        }
        let compose = ComposeViewController(mode: mode)
        let nav = UINavigationController(rootViewController: compose)
        nav.navigationBar.prefersLargeTitles = false
        nav.navigationBar.tintColor = .systemBlue
        present(nav, animated: true, completion: nil)
    }

    @objc private func handleForward() {
        guard let item = MailStore.shared.item(for: itemID) else { return }
        let compose = ComposeViewController(mode: .forward(item))
        let nav = UINavigationController(rootViewController: compose)
        nav.navigationBar.prefersLargeTitles = false
        nav.navigationBar.tintColor = .systemBlue
        present(nav, animated: true, completion: nil)
    }

    @objc private func handleArchive() {
        guard let item = MailStore.shared.item(for: itemID) else { return }
        MailStore.shared.move(id: item.id, to: .archive)
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleDelete() {
        guard let item = MailStore.shared.item(for: itemID) else { return }
        if item.folder == .trash {
            MailStore.shared.delete(id: item.id)
        } else {
            MailStore.shared.move(id: item.id, to: .trash)
        }
        navigationController?.popViewController(animated: true)
    }

    @objc private func handleAIReplyFailed(_ notification: Notification) {
        guard view.window != nil else { return }
        let message = (notification.userInfo?["message"] as? String) ?? "AI reply failed."
        let alert = UIAlertController(title: "AI reply unavailable", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
    }

    @objc private func openAttachmentPreview(_ sender: UIControl) {
        guard sender.tag >= 0, sender.tag < activeAttachments.count else { return }
        let preview = MailImagePreviewViewController(attachment: activeAttachments[sender.tag])
        let nav = UINavigationController(rootViewController: preview)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
}

final class MailAttachmentTileButton: UIControl {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = MailTheme.elevatedBackground
        layer.cornerRadius = 16
        clipsToBounds = true

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 1

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .systemFont(ofSize: 11, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.axis = .vertical
        labelStack.spacing = 2

        addSubview(imageView)
        addSubview(labelStack)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 154),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 126),

            labelStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            labelStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            labelStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 10),
            labelStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with attachment: MailAttachment) {
        imageView.image = MailAttachmentRenderer.image(for: attachment, size: CGSize(width: 420, height: 320))
        titleLabel.text = attachment.title
        subtitleLabel.text = attachment.filename
    }
}

final class MailImagePreviewViewController: UIViewController, UIScrollViewDelegate {
    private let attachment: MailAttachment
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()

    init(attachment: MailAttachment) {
        self.attachment = attachment
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = .black
        title = attachment.filename
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.image = MailAttachmentRenderer.image(for: attachment)

        view.addSubview(scrollView)
        scrollView.addSubview(imageView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
}

enum ComposeMode {
    case new
    case reply(MailItem)
    case forward(MailItem)
    case edit(MailItem)
}

final class ComposeViewController: UIViewController {
    private let mode: ComposeMode
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let toField = UITextField()
    private let subjectField = UITextField()
    private let fromValueLabel = UILabel()
    private let bodyView = UITextView()
    private let bodyPlaceholder = UILabel()
    private let attachmentCard = UIView()
    private let attachmentEmptyLabel = UILabel()
    private let attachmentScrollView = UIScrollView()
    private let attachmentStack = UIStackView()
    private lazy var sendButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Send", style: .done, target: self, action: #selector(send))
        btn.accessibilityIdentifier = "compose_send_button"
        return btn
    }()

    private var draftID: UUID?
    private var selectedAttachments: [MailAttachment] = []

    init(mode: ComposeMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        MailAppearance.apply(to: self)
        view.backgroundColor = MailTheme.groupedBackground
        title = "New Message"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = sendButton
        configureLayout()
        applyMode()
        updateAttachmentComposerUI()
        updateSendButtonState()
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppearanceChanged), name: .mailAppearanceDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        MailAppearance.apply(to: self)
    }

    private func configureLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 16

        toField.translatesAutoresizingMaskIntoConstraints = false
        toField.placeholder = "Recipient"
        toField.keyboardType = .emailAddress
        toField.autocapitalizationType = .none
        toField.autocorrectionType = .no
        toField.clearButtonMode = .whileEditing
        toField.font = .systemFont(ofSize: 17, weight: .regular)
        toField.accessibilityIdentifier = "compose_to_field"
        toField.addTarget(self, action: #selector(textFieldsChanged), for: .editingChanged)

        fromValueLabel.translatesAutoresizingMaskIntoConstraints = false
        fromValueLabel.font = .systemFont(ofSize: 17, weight: .regular)
        fromValueLabel.textColor = .secondaryLabel
        fromValueLabel.text = MailTheme.accountEmail

        subjectField.translatesAutoresizingMaskIntoConstraints = false
        subjectField.placeholder = "Subject"
        subjectField.font = .systemFont(ofSize: 17, weight: .regular)
        subjectField.clearButtonMode = .whileEditing
        subjectField.accessibilityIdentifier = "compose_subject_field"

        bodyView.translatesAutoresizingMaskIntoConstraints = false
        bodyView.font = .systemFont(ofSize: 17, weight: .regular)
        bodyView.backgroundColor = .clear
        bodyView.textContainerInset = UIEdgeInsets(top: 12, left: 0, bottom: 16, right: 0)
        bodyView.delegate = self
        bodyView.accessibilityIdentifier = "compose_body_field"

        bodyPlaceholder.text = "Message"
        bodyPlaceholder.textColor = .secondaryLabel
        bodyPlaceholder.font = .systemFont(ofSize: 17, weight: .regular)
        bodyPlaceholder.translatesAutoresizingMaskIntoConstraints = false
        bodyView.addSubview(bodyPlaceholder)

        let addContactButton = UIButton(type: .system)
        addContactButton.translatesAutoresizingMaskIntoConstraints = false
        addContactButton.setImage(UIImage(systemName: "person.crop.circle.badge.plus"), for: .normal)
        addContactButton.tintColor = .systemBlue
        addContactButton.accessibilityIdentifier = "compose_add_contact_button"
        addContactButton.addTarget(self, action: #selector(contactPickerTapped), for: .touchUpInside)

        let editorCard = UIView()
        editorCard.translatesAutoresizingMaskIntoConstraints = false
        editorCard.backgroundColor = MailTheme.cardBackground
        editorCard.layer.cornerRadius = 18

        let editorStack = UIStackView()
        editorStack.translatesAutoresizingMaskIntoConstraints = false
        editorStack.axis = .vertical
        editorStack.spacing = 0

        let toRow = makeInputRow(title: "To", field: toField, trailingView: addContactButton)
        let fromRow = makeValueRow(title: "From", valueLabel: fromValueLabel)
        let subjectRow = makeInputRow(title: "Subject", field: subjectField, trailingView: nil)

        let bodyContainer = UIView()
        bodyContainer.translatesAutoresizingMaskIntoConstraints = false
        bodyContainer.addSubview(bodyView)

        editorCard.addSubview(editorStack)
        editorStack.addArrangedSubview(toRow)
        editorStack.addArrangedSubview(makeDivider())
        editorStack.addArrangedSubview(fromRow)
        editorStack.addArrangedSubview(makeDivider())
        editorStack.addArrangedSubview(subjectRow)
        editorStack.addArrangedSubview(makeDivider())
        editorStack.addArrangedSubview(bodyContainer)

        attachmentCard.translatesAutoresizingMaskIntoConstraints = false
        attachmentCard.backgroundColor = MailTheme.cardBackground
        attachmentCard.layer.cornerRadius = 18

        let attachmentTitleLabel = UILabel()
        attachmentTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        attachmentTitleLabel.text = "Images"
        attachmentTitleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        attachmentTitleLabel.textColor = .label

        let addImageButton = UIButton(type: .system)
        addImageButton.translatesAutoresizingMaskIntoConstraints = false
        addImageButton.setTitle("Add Image", for: .normal)
        addImageButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        addImageButton.accessibilityIdentifier = "compose_add_image_button"
        addImageButton.addTarget(self, action: #selector(addImageTapped(_:)), for: .touchUpInside)

        let attachmentHeader = UIStackView(arrangedSubviews: [attachmentTitleLabel, UIView(), addImageButton])
        attachmentHeader.translatesAutoresizingMaskIntoConstraints = false
        attachmentHeader.axis = .horizontal
        attachmentHeader.alignment = .center

        attachmentEmptyLabel.translatesAutoresizingMaskIntoConstraints = false
        attachmentEmptyLabel.font = .systemFont(ofSize: 14, weight: .regular)
        attachmentEmptyLabel.textColor = .secondaryLabel
        attachmentEmptyLabel.text = "No images attached yet."

        attachmentScrollView.translatesAutoresizingMaskIntoConstraints = false
        attachmentScrollView.showsHorizontalScrollIndicator = false

        attachmentStack.translatesAutoresizingMaskIntoConstraints = false
        attachmentStack.axis = .horizontal
        attachmentStack.spacing = 12

        attachmentCard.addSubview(attachmentHeader)
        attachmentCard.addSubview(attachmentEmptyLabel)
        attachmentCard.addSubview(attachmentScrollView)
        attachmentScrollView.addSubview(attachmentStack)

        let footerStack = UIStackView()
        footerStack.translatesAutoresizingMaskIntoConstraints = false
        footerStack.axis = .horizontal
        footerStack.spacing = 12
        footerStack.distribution = .fillEqually

        let saveDraft = makeActionButton(title: "Save Draft", systemImage: "square.and.arrow.down", selector: #selector(saveDraftTapped), accessibilityID: "compose_save_draft_button")
        let schedule = makeActionButton(title: "Send Later", systemImage: "clock", selector: #selector(scheduleTapped), accessibilityID: "compose_send_later_button")
        footerStack.addArrangedSubview(saveDraft)
        footerStack.addArrangedSubview(schedule)

        let helperLabel = UILabel()
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.text = "Send Later queues this message for one hour from now."
        helperLabel.font = .systemFont(ofSize: 13, weight: .regular)
        helperLabel.textColor = .secondaryLabel
        helperLabel.numberOfLines = 0

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        contentStack.addArrangedSubview(editorCard)
        contentStack.addArrangedSubview(attachmentCard)
        contentStack.addArrangedSubview(footerStack)
        contentStack.addArrangedSubview(helperLabel)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            editorStack.leadingAnchor.constraint(equalTo: editorCard.leadingAnchor),
            editorStack.trailingAnchor.constraint(equalTo: editorCard.trailingAnchor),
            editorStack.topAnchor.constraint(equalTo: editorCard.topAnchor),
            editorStack.bottomAnchor.constraint(equalTo: editorCard.bottomAnchor),

            attachmentHeader.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 16),
            attachmentHeader.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -16),
            attachmentHeader.topAnchor.constraint(equalTo: attachmentCard.topAnchor, constant: 16),

            attachmentEmptyLabel.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 16),
            attachmentEmptyLabel.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -16),
            attachmentEmptyLabel.topAnchor.constraint(equalTo: attachmentHeader.bottomAnchor, constant: 12),

            attachmentScrollView.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor),
            attachmentScrollView.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor),
            attachmentScrollView.topAnchor.constraint(equalTo: attachmentHeader.bottomAnchor, constant: 12),
            attachmentScrollView.bottomAnchor.constraint(equalTo: attachmentCard.bottomAnchor, constant: -16),
            attachmentScrollView.heightAnchor.constraint(equalToConstant: 120),

            attachmentStack.leadingAnchor.constraint(equalTo: attachmentScrollView.leadingAnchor, constant: 16),
            attachmentStack.trailingAnchor.constraint(equalTo: attachmentScrollView.trailingAnchor, constant: -16),
            attachmentStack.topAnchor.constraint(equalTo: attachmentScrollView.topAnchor),
            attachmentStack.bottomAnchor.constraint(equalTo: attachmentScrollView.bottomAnchor),
            attachmentStack.heightAnchor.constraint(equalTo: attachmentScrollView.heightAnchor),

            bodyView.leadingAnchor.constraint(equalTo: bodyContainer.leadingAnchor, constant: 16),
            bodyView.trailingAnchor.constraint(equalTo: bodyContainer.trailingAnchor, constant: -16),
            bodyView.topAnchor.constraint(equalTo: bodyContainer.topAnchor, constant: 2),
            bodyView.bottomAnchor.constraint(equalTo: bodyContainer.bottomAnchor, constant: -2),
            bodyView.heightAnchor.constraint(greaterThanOrEqualToConstant: 320),

            bodyPlaceholder.leadingAnchor.constraint(equalTo: bodyView.leadingAnchor, constant: 4),
            bodyPlaceholder.topAnchor.constraint(equalTo: bodyView.topAnchor, constant: 14),

            footerStack.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func applyMode() {
        switch mode {
        case .new:
            title = "New Message"
        case .reply(let item):
            title = "Reply"
            toField.text = item.from == "You" ? item.to : item.from
            subjectField.text = item.subject.lowercased().hasPrefix("re:") ? item.subject : "Re: \(item.subject)"
        case .forward(let item):
            title = "Forward"
            subjectField.text = item.subject.lowercased().hasPrefix("fwd:") ? item.subject : "Fwd: \(item.subject)"
            let fwdBody = "\n\n---------- Forwarded message ----------\nFrom: \(item.from)\nSubject: \(item.subject)\n\n\(item.body)"
            bodyView.text = fwdBody
            bodyPlaceholder.isHidden = !fwdBody.isEmpty
            selectedAttachments = item.attachments
        case .edit(let item):
            title = item.folder == .scheduled ? "Edit Scheduled" : "Edit Draft"
            toField.text = item.to
            subjectField.text = item.subject
            bodyView.text = item.body
            bodyPlaceholder.isHidden = !item.body.isEmpty
            draftID = item.id
            selectedAttachments = item.attachments
        }
    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func textFieldsChanged() {
        updateSendButtonState()
    }

    @objc private func contactPickerTapped() {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { [weak self] granted, _ in
            var contactEntries: [MailContactEntry] = []
            if granted {
                let keys: [CNKeyDescriptor] = [
                    CNContactGivenNameKey as CNKeyDescriptor,
                    CNContactFamilyNameKey as CNKeyDescriptor,
                    CNContactEmailAddressesKey as CNKeyDescriptor
                ]
                let request = CNContactFetchRequest(keysToFetch: keys)
                request.sortOrder = .givenName
                try? store.enumerateContacts(with: request) { contact, _ in
                    let fullName = [contact.givenName, contact.familyName]
                        .filter { !$0.isEmpty }
                        .joined(separator: " ")
                    guard !fullName.isEmpty else { return }
                    let email = contact.emailAddresses.first?.value as String? ?? ""
                    contactEntries.append(MailContactEntry(name: fullName, email: email))
                }
            }
            // Fallback: add mail senders not already in system contacts
            let existingNames = Set(contactEntries.map { $0.name.lowercased() })
            let excludedNames: Set<String> = ["you", "unknown"]
            var seen = Set<String>()
            for item in MailStore.shared.items {
                let name = item.from == "You" ? item.to : item.from
                let lower = name.lowercased()
                guard !excludedNames.contains(lower), !name.isEmpty,
                      !existingNames.contains(lower),
                      seen.insert(lower).inserted else { continue }
                contactEntries.append(MailContactEntry(name: name, email: ""))
            }

            DispatchQueue.main.async {
                let picker = MailContactPickerViewController(contacts: contactEntries) { [weak self] selected in
                    self?.toField.text = selected.email.isEmpty ? selected.name : selected.email
                    self?.updateSendButtonState()
                }
                let nav = UINavigationController(rootViewController: picker)
                nav.modalPresentationStyle = .pageSheet
                self?.present(nav, animated: true)
            }
        }
    }

    @objc private func handleAppearanceChanged() {
        MailAppearance.apply(to: self)
        updateAttachmentComposerUI()
    }

    @objc private func send() {
        let toText = toField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subjectText = subjectField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !toText.isEmpty else { return }

        if let existingID = draftID {
            MailStore.shared.delete(id: existingID)
        }

        var replyThreadId: String? = nil
        if case .reply(let original) = mode {
            replyThreadId = original.threadId
        }
        MailStore.shared.sendMessage(to: toText, subject: subjectText, body: bodyText, category: .all, attachments: selectedAttachments, threadId: replyThreadId)
        dismiss(animated: true, completion: nil)
    }

    @objc private func saveDraftTapped() {
        let toText = toField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subjectText = subjectField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subjectText.isEmpty ? "(no subject)" : subjectText

        if let existingID = draftID {
            guard var item = MailStore.shared.item(for: existingID) else { return }
            item.to = toText.isEmpty ? "Unknown" : toText
            item.subject = subject
            item.body = bodyText
            item.preview = mailPreviewText(body: bodyText, attachments: selectedAttachments)
            item.date = Date()
            item.folder = .drafts
            item.attachments = selectedAttachments
            MailStore.shared.update(item)
        } else {
            let item = MailItem(
                id: UUID(),
                threadId: UUID().uuidString,
                from: "You",
                to: toText.isEmpty ? "Unknown" : toText,
                subject: subject,
                body: bodyText,
                preview: mailPreviewText(body: bodyText, attachments: selectedAttachments),
                date: Date(),
                folder: .drafts,
                category: .all,
                isUnread: false,
                scheduledSend: nil,
                attachments: selectedAttachments
            )
            MailStore.shared.add(item)
        }
        dismiss(animated: true, completion: nil)
    }

    @objc private func scheduleTapped() {
        let toText = toField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let subjectText = subjectField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let bodyText = bodyView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = subjectText.isEmpty ? "(no subject)" : subjectText
        let scheduleDate = Date().addingTimeInterval(3600)

        if let existingID = draftID {
            guard var item = MailStore.shared.item(for: existingID) else { return }
            item.to = toText.isEmpty ? "Unknown" : toText
            item.subject = subject
            item.body = bodyText
            item.preview = mailPreviewText(body: bodyText, attachments: selectedAttachments)
            item.date = scheduleDate
            item.folder = .scheduled
            item.scheduledSend = scheduleDate
            item.attachments = selectedAttachments
            MailStore.shared.update(item)
        } else {
            let item = MailItem(
                id: UUID(),
                threadId: UUID().uuidString,
                from: "You",
                to: toText.isEmpty ? "Unknown" : toText,
                subject: subject,
                body: bodyText,
                preview: mailPreviewText(body: bodyText, attachments: selectedAttachments),
                date: scheduleDate,
                folder: .scheduled,
                category: .all,
                isUnread: false,
                scheduledSend: scheduleDate,
                attachments: selectedAttachments
            )
            MailStore.shared.add(item)
        }
        dismiss(animated: true, completion: nil)
    }

    private func updateSendButtonState() {
        let toText = toField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        sendButton.isEnabled = !toText.isEmpty
    }

    private func updateAttachmentComposerUI() {
        attachmentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        attachmentEmptyLabel.isHidden = !selectedAttachments.isEmpty
        attachmentScrollView.isHidden = selectedAttachments.isEmpty

        for (index, attachment) in selectedAttachments.enumerated() {
            let wrapper = UIView()
            wrapper.translatesAutoresizingMaskIntoConstraints = false

            let previewButton = MailAttachmentTileButton()
            previewButton.tag = index
            previewButton.configure(with: attachment)
            previewButton.addTarget(self, action: #selector(previewAttachment(_:)), for: .touchUpInside)

            let removeButton = UIButton(type: .system)
            removeButton.translatesAutoresizingMaskIntoConstraints = false
            removeButton.tag = index
            removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            removeButton.tintColor = .white
            removeButton.backgroundColor = UIColor.black.withAlphaComponent(0.24)
            removeButton.layer.cornerRadius = 14
            removeButton.addTarget(self, action: #selector(removeAttachment(_:)), for: .touchUpInside)

            wrapper.addSubview(previewButton)
            wrapper.addSubview(removeButton)

            NSLayoutConstraint.activate([
                wrapper.widthAnchor.constraint(equalToConstant: 154),

                previewButton.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
                previewButton.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor),
                previewButton.topAnchor.constraint(equalTo: wrapper.topAnchor),
                previewButton.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),

                removeButton.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
                removeButton.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -8),
                removeButton.widthAnchor.constraint(equalToConstant: 28),
                removeButton.heightAnchor.constraint(equalToConstant: 28)
            ])

            attachmentStack.addArrangedSubview(wrapper)
        }
    }

    @objc private func addImageTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: "Add Image", message: "Choose a sample image attachment.", preferredStyle: .actionSheet)
        for template in MailAttachmentTemplate.allCases {
            let sample = makeAttachment(template)
            sheet.addAction(UIAlertAction(title: sample.title, style: .default) { [weak self] _ in
                self?.selectedAttachments.append(sample)
                self?.updateAttachmentComposerUI()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(sheet, animated: true, completion: nil)
    }

    @objc private func removeAttachment(_ sender: UIButton) {
        guard sender.tag >= 0, sender.tag < selectedAttachments.count else { return }
        selectedAttachments.remove(at: sender.tag)
        updateAttachmentComposerUI()
    }

    @objc private func previewAttachment(_ sender: UIControl) {
        guard sender.tag >= 0, sender.tag < selectedAttachments.count else { return }
        let preview = MailImagePreviewViewController(attachment: selectedAttachments[sender.tag])
        let nav = UINavigationController(rootViewController: preview)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }

    private func makeRowLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        NSLayoutConstraint.activate([
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        return divider
    }

    private func makeInputRow(title: String, field: UIView, trailingView: UIView?) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let label = makeRowLabel(title)
        row.addSubview(label)
        row.addSubview(field)
        if let trailingView = trailingView {
            row.addSubview(trailingView)
            NSLayoutConstraint.activate([
                trailingView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                trailingView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                trailingView.widthAnchor.constraint(equalToConstant: 28),
                trailingView.heightAnchor.constraint(equalToConstant: 28),

                field.trailingAnchor.constraint(equalTo: trailingView.leadingAnchor, constant: -10)
            ])
        } else {
            NSLayoutConstraint.activate([
                field.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16)
            ])
        }

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 52),

            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 58),

            field.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            field.topAnchor.constraint(equalTo: row.topAnchor),
            field.bottomAnchor.constraint(equalTo: row.bottomAnchor)
        ])
        return row
    }

    private func makeValueRow(title: String, valueLabel: UILabel) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        let label = makeRowLabel(title)
        row.addSubview(label)
        row.addSubview(valueLabel)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 52),

            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 58),

            valueLabel.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 12),
            valueLabel.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            valueLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor)
        ])
        return row
    }

    private func makeActionButton(title: String, systemImage: String, selector: Selector, accessibilityID: String? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = MailTheme.cardBackground
        button.layer.cornerRadius = 14
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.separator.withAlphaComponent(0.4).cgColor
        button.tintColor = .label
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: systemImage), for: .normal)
        button.addTarget(self, action: selector, for: .touchUpInside)
        if let id = accessibilityID { button.accessibilityIdentifier = id }
        return button
    }
}

extension ComposeViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        bodyPlaceholder.isHidden = !textView.text.isEmpty
    }
}

// MARK: - Mail Contact Picker

private struct MailContactEntry {
    let name: String
    let email: String
}

private final class MailContactPickerViewController: UITableViewController {
    private let contacts: [MailContactEntry]
    private var filtered: [MailContactEntry]
    private let onSelect: (MailContactEntry) -> Void
    private let searchController = UISearchController(searchResultsController: nil)

    init(contacts: [MailContactEntry], onSelect: @escaping (MailContactEntry) -> Void) {
        self.contacts = contacts
        self.filtered = contacts
        self.onSelect = onSelect
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Contacts"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissPicker))
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ContactCell")

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search contacts"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    @objc private func dismissPicker() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ContactCell")
        let entry = filtered[indexPath.row]
        cell.textLabel?.text = entry.name
        cell.textLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        cell.detailTextLabel?.text = entry.email.isEmpty ? nil : entry.email
        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel

        let palette = mailAvatarPalette(for: entry.name)
        let initials = mailInitials(from: entry.name)
        let size: CGFloat = 36
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        let image = renderer.image { ctx in
            palette.background.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: size, height: size)).fill()
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: palette.foreground
            ]
            let str = initials as NSString
            let textSize = str.size(withAttributes: attrs)
            str.draw(at: CGPoint(x: (size - textSize.width) / 2, y: (size - textSize.height) / 2), withAttributes: attrs)
        }
        cell.imageView?.image = image
        cell.imageView?.layer.cornerRadius = size / 2
        cell.imageView?.clipsToBounds = true
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selected = filtered[indexPath.row]
        onSelect(selected)
        dismiss(animated: true)
    }
}

extension MailContactPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text?.lowercased() ?? ""
        filtered = query.isEmpty ? contacts : contacts.filter {
            $0.name.lowercased().contains(query) || $0.email.lowercased().contains(query)
        }
        tableView.reloadData()
    }
}
