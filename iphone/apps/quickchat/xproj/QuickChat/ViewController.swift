import UIKit
import SwiftUI
import Combine
import CoreImage

/// Deterministic, gender-aware face asset lookup (mirrored across the chat / social / fitness / payments clones,
/// the rideshare/fitness/payments/messaging clones — keep implementations in sync). See
/// `LockedIn/Utilities/LockedInTheme.swift` for documentation.
enum FaceAssetResolver {
    static let feminineSlots: [Int] = [
        1, 4, 5, 6, 7, 8, 9, 12, 14, 18, 24, 26, 28, 29, 32, 34, 37, 38, 41, 42,
        44, 48, 50, 51, 52, 56, 63, 65, 67, 69, 70, 72, 75, 78, 79, 80, 81, 84,
        85, 86, 88, 89, 91, 92, 93, 94
    ]
    static let masculineSlots: [Int] = [
        2, 3, 10, 11, 13, 15, 16, 17, 19, 20, 21, 22, 23, 25, 26, 27, 28, 30,
        31, 33, 35, 36, 39, 40, 43, 45, 46, 47, 49, 53, 54, 55, 56, 57, 58, 59,
        60, 61, 62, 64, 65, 66, 68, 71, 73, 74, 76, 77, 81, 82, 83, 87, 90, 95,
        96, 97
    ]
    static let feminineFirstNames: Set<String> = [
        "aisha","amara","amy","ana","anna","ava","aya","ayla",
        "beatrice","bianca","camila","camille","celeste","chloe","claire","claudia",
        "devi","diana","elena","eleanor","elise","elizabeth","ella","emma","erin","esme","eva","evelyn",
        "fatima","felicia","fiona","flora","freya",
        "grace","greta","hannah","hazel","helen","hillary",
        "imani","ingrid","iris","isabel","ivy",
        "jasmine","jenna","jessica","juno",
        "kira","laura","lena","lila","linda","lisa","lucia","luna",
        "maren","maria","marina","martha","mary","maya","mei","meera","melissa","mia","mira","monica",
        "nadia","naomi","natasha","nina","nora","olivia",
        "paige","petra","phoebe","priscilla","priya",
        "rachel","rebekah","renee","rosa","ruby","sarah","sienna","sofia","sophia","stephanie","susan",
        "tanya","tara","teresa","tessa","tiffany",
        "vanessa","vera","veronica","victoria","violet",
        "whitney","yuki","yuna","zara","zoe"
    ]
    static let masculineFirstNames: Set<String> = [
        "aaron","adam","aiden","alan","alex","alfredo","ali","amir","andrew","andy","antonio",
        "arjun","arnav","arthur","austin",
        "benjamin","bill","blake","brandon","brian","bruce","bryce",
        "callum","calvin","cameron","carl","carlos","charles","charlie","chase","chris","christopher",
        "clay","cole","colin","connor","craig",
        "damon","daniel","dante","darius","david","declan","derek","devon","diego","dominic","dylan",
        "eddie","edwin","eli","elio","elvis","emmanuel","eric","ernesto","ethan","evan","ezra",
        "felipe","felix","fernando","francisco","frank",
        "gabriel","gary","george","graham","gus",
        "hank","harry","hassan","hector","henrik","henry","hiroshi","hugo","hunter",
        "isaac","isaiah","ivan",
        "jack","jackson","jacob","jake","james","jamie","jared","jason","javier","jeremy","joel","john",
        "jonah","jonathan","joseph","josh","joshua","juan","justin",
        "kenji","kevin","kurt","kyle",
        "lance","leo","leon","lewis","liam","logan","lorenzo","lucas","luca","luis","luke",
        "malcolm","manuel","marcus","mario","mark","markus","martin","mason","mateo","matt","matthew",
        "miguel","miles","mohammed","mohamed",
        "nathan","nathaniel","neil","nicholas","nick","noah","noel",
        "omar","oscar","owen",
        "pablo","patrick","paul","peter","philip","phil","pierre","preston",
        "rafael","ramon","raphael","ravi","raymond","reese","richard","rob","robert","roberto","rohan",
        "ron","ronald","ryan",
        "samir","samuel","scott","sean","sergio","seth","shane","shawn","simon","spencer","stephen",
        "stuart",
        "tariq","ted","terrence","theo","thomas","tim","tobias","todd","tom","tony","tyler",
        "victor","vijay","vince",
        "walter","warren","wesley","william","willie","wyatt",
        "xavier","xander",
        "zachary"
    ]

    enum PersonaGender { case feminine, masculine, neutral }

    static func genderOfKey(_ key: String) -> PersonaGender {
        let lower = key.lowercased()
        let tokens = lower.split(whereSeparator: { !$0.isLetter })
        for token in tokens {
            let candidate = String(token)
            if feminineFirstNames.contains(candidate) { return .feminine }
            if masculineFirstNames.contains(candidate) { return .masculine }
        }
        return .neutral
    }

    static func index(for key: String, poolSize: Int = 97) -> Int {
        var hash: UInt64 = 14695981039346656037
        for byte in key.lowercased().utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        if poolSize == 97 {
            switch genderOfKey(key) {
            case .feminine:
                return feminineSlots[Int(hash % UInt64(feminineSlots.count))]
            case .masculine:
                return masculineSlots[Int(hash % UInt64(masculineSlots.count))]
            case .neutral:
                break
            }
        }
        return Int(hash % UInt64(poolSize)) + 1
    }

    static func assetName(prefix: String, key: String, poolSize: Int = 97) -> String {
        let idx = index(for: key, poolSize: poolSize)
        return String(format: "\(prefix)%02d", idx)
    }
}

final class ViewController: UIHostingController<AnyView> {
    private let store: MessagesStore

    init(store: MessagesStore = MessagesStore()) {
        self.store = store
        super.init(rootView: AnyView(MessagesRootView().environmentObject(store)))
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        let store = MessagesStore()
        self.store = store
        super.init(coder: aDecoder, rootView: AnyView(MessagesRootView().environmentObject(store)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        overrideUserInterfaceStyle = .dark
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
}

enum MessagesTab: String, CaseIterable {
    case updates
    case calls
    case communities
    case chats
    case you
}

typealias WhatsAppTab = MessagesTab

enum ChatFilter: String, CaseIterable {
    case all = "All"
    case unread = "Unread"
    case groups = "Groups"
    case archived = "Archived"
}

enum VisualKind: String, Hashable {
    case photo
    case gif
    case video
}

enum DeliveryState: Hashable {
    case sent
    case delivered
    case read

    var iconName: String {
        switch self {
        case .sent:
            return "checkmark"
        case .delivered:
            return "checkmark.circle"
        case .read:
            return "checkmark.circle.fill"
        }
    }
}

enum SearchCategory: String, CaseIterable, Identifiable {
    case photos
    case gifs
    case links
    case videos
    case documents
    case audio
    case polls
    case events

    var id: String { rawValue }

    var title: String {
        switch self {
        case .photos:
            return "Photos"
        case .gifs:
            return "GIFs"
        case .links:
            return "Links"
        case .videos:
            return "Videos"
        case .documents:
            return "Documents"
        case .audio:
            return "Audio"
        case .polls:
            return "Polls"
        case .events:
            return "Events"
        }
    }

    var symbolName: String {
        switch self {
        case .photos:
            return "camera"
        case .gifs:
            return "photo.on.rectangle"
        case .links:
            return "link"
        case .videos:
            return "video"
        case .documents:
            return "doc"
        case .audio:
            return "waveform"
        case .polls:
            return "chart.bar"
        case .events:
            return "calendar"
        }
    }
}

enum ProfileSettingsRoute: String, CaseIterable, Identifiable {
    case avatar
    case lists
    case broadcasts
    case starred
    case linkedDevices
    case account
    case privacy
    case storage

    var id: String { rawValue }

    var title: String {
        switch self {
        case .avatar:
            return "Avatar"
        case .lists:
            return "Lists"
        case .broadcasts:
            return "Message lists"
        case .starred:
            return "Starred"
        case .linkedDevices:
            return "Linked devices"
        case .account:
            return "Account"
        case .privacy:
            return "Privacy"
        case .storage:
            return "Storage and data"
        }
    }

    var subtitle: String {
        switch self {
        case .avatar:
            return "Profile photo, name, and headline"
        case .lists:
            return "Organize chats by workflow"
        case .broadcasts:
            return "Reusable recipient groups for one-tap sends"
        case .starred:
            return "Saved messages you marked"
        case .linkedDevices:
            return "Desktop and tablet access"
        case .account:
            return "Phone, recovery, and backups"
        case .privacy:
            return "Read receipts and locked chats"
        case .storage:
            return "Usage and download preferences"
        }
    }

    var icon: String {
        switch self {
        case .avatar:
            return "person.crop.circle"
        case .lists:
            return "list.bullet"
        case .broadcasts:
            return "megaphone"
        case .starred:
            return "star"
        case .linkedDevices:
            return "desktopcomputer"
        case .account:
            return "key.fill"
        case .privacy:
            return "hand.raised.fill"
        case .storage:
            return "chart.pie.fill"
        }
    }
}

enum CallMode: Hashable {
    case voice
    case video

    var symbolName: String {
        switch self {
        case .voice:
            return "phone.fill"
        case .video:
            return "video.fill"
        }
    }
}

enum CallDirection: Hashable {
    case outgoing
    case incoming
    case missed

    var label: String {
        switch self {
        case .outgoing:
            return "Outgoing"
        case .incoming:
            return "Incoming"
        case .missed:
            return "Missed"
        }
    }

    var tint: Color {
        switch self {
        case .missed:
            return AppTheme.error
        case .incoming:
            return AppTheme.accent
        case .outgoing:
            return AppTheme.secondaryText
        }
    }
}

struct AvatarSeed: Hashable {
    let topHex: Int
    let bottomHex: Int
    var initials: String
    let symbolName: String?
    var name: String? = nil
}

struct MediaTemplate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
    let symbolName: String
    let topHex: Int
    let bottomHex: Int
    let accentHex: Int
}

struct PollChoice: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let votes: Int
}

enum MessageContent: Hashable {
    case text(String)
    case visual(MediaTemplate, kind: VisualKind, caption: String)
    case link(title: String, url: String, description: String)
    case document(name: String, size: String)
    case audio(duration: String, transcript: String)
    case poll(question: String, choices: [PollChoice])
    case event(title: String, detail: String)

    var previewText: String {
        switch self {
        case .text(let value):
            return value
        case .visual(let template, let kind, let caption):
            let prefix: String
            switch kind {
            case .photo:
                prefix = "Photo"
            case .gif:
                prefix = "GIF"
            case .video:
                prefix = "Video"
            }
            return caption.isEmpty ? "\(prefix): \(template.title)" : "\(prefix): \(caption)"
        case .link(let title, _, _):
            return "Link: \(title)"
        case .document(let name, _):
            return "Document: \(name)"
        case .audio(let duration, _):
            return "Voice note (\(duration))"
        case .poll(let question, _):
            return "Poll: \(question)"
        case .event(let title, _):
            return "Event: \(title)"
        }
    }

    var searchCategory: SearchCategory? {
        switch self {
        case .text:
            return nil
        case .visual(_, let kind, _):
            switch kind {
            case .photo:
                return .photos
            case .gif:
                return .gifs
            case .video:
                return .videos
            }
        case .link:
            return .links
        case .document:
            return .documents
        case .audio:
            return .audio
        case .poll:
            return .polls
        case .event:
            return .events
        }
    }
}

struct ChatMessage: Identifiable, Hashable {
    let id: UUID
    let senderID: UUID
    let sentAt: Date
    let content: MessageContent
    var delivery: DeliveryState
    var isStarred: Bool
    var replyToID: UUID?
    var hearted: Bool = false
}

struct AutomatedReply: Hashable {
    let senderID: UUID
    let content: MessageContent
}

struct GeneratedReplyContextMessage: Hashable {
    let senderName: String
    let isCurrentUser: Bool
    let text: String
}

struct GeneratedReplyError: Error {
    let message: String
}

protocol ReplyGenerating {
    func generateReply(
        as senderName: String,
        bio: String,
        threadTitle: String,
        isGroupChat: Bool,
        recentMessages: [GeneratedReplyContextMessage],
        completion: @escaping (Result<String, GeneratedReplyError>) -> Void
    )
}

struct Contact: Identifiable, Hashable {
    let id: UUID
    var name: String
    var phoneNumber: String
    var about: String
    private var _avatar: AvatarSeed
    var avatar: AvatarSeed {
        get {
            var a = _avatar
            if a.name == nil { a.name = name }
            return a
        }
        set { _avatar = newValue }
    }
    var isFavorite: Bool

    init(id: UUID, name: String, phoneNumber: String, about: String, avatar: AvatarSeed, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.about = about
        self._avatar = avatar
        self.isFavorite = isFavorite
    }
}

struct ChatThread: Identifiable, Hashable {
    let id: UUID
    var title: String
    var avatar: AvatarSeed
    var participantIDs: [UUID]
    var isGroup: Bool
    var communityID: UUID?
    var messages: [ChatMessage]
    var unreadCount: Int
    var pinned: Bool
    var muted: Bool
    var archived: Bool = false
    var subtitle: String
    var automatedReplies: [AutomatedReply]
    var automatedReplyCursor: Int

    var lastMessage: ChatMessage? {
        messages.last
    }

    var lastActivity: Date {
        lastMessage?.sentAt ?? Date.distantPast
    }
}

struct StatusUpdate: Identifiable, Hashable {
    let id: UUID
    let ownerID: UUID?
    var ownerName: String
    var avatar: AvatarSeed
    var postedAt: Date
    var body: String
    var media: MediaTemplate?
    var isViewed: Bool
    var isMine: Bool
}

struct ChannelPost: Identifiable, Hashable {
    let id: UUID
    let headline: String
    let body: String
    let postedAt: Date
    let media: MediaTemplate?
}

struct Channel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var description: String
    var followersLabel: String
    var avatar: AvatarSeed
    var verified: Bool
    var isFollowed: Bool
    var posts: [ChannelPost]
}

struct Community: Identifiable, Hashable {
    let id: UUID
    var name: String
    var description: String
    var avatar: AvatarSeed
    var memberCount: Int
    var announcementThreadID: UUID
    var groupThreadIDs: [UUID]
}

struct ActiveCallInfo: Identifiable, Hashable {
    let id: UUID
    var title: String
    var avatar: AvatarSeed
    var mode: CallMode
    var startedAt: Date
}

struct CallRecord: Identifiable, Hashable {
    let id: UUID
    var title: String
    var detail: String
    var avatar: AvatarSeed
    var timestamp: Date
    var mode: CallMode
    var direction: CallDirection
    var duration: String
    var threadID: UUID?
}

struct ScheduledCall: Identifiable, Hashable {
    let id: UUID
    var contactID: UUID?
    var title: String
    var scheduledFor: Date
    var note: String
    var mode: CallMode
}

struct MessageListItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var summary: String
}

struct BroadcastListItem: Identifiable, Hashable {
    let id: UUID
    var name: String
    var memberIDs: [UUID]
    var lastSent: Date
}

struct LinkedDevice: Identifiable, Hashable {
    let id: UUID
    var name: String
    var lastSeen: String
    var isActive: Bool
}

struct ProfileState: Hashable {
    var displayName: String
    var phoneNumber: String
    var headline: String
    var recoveryEmail: String?
    var avatar: AvatarSeed
    var readReceiptsEnabled: Bool
    var lockedChatsEnabled: Bool
    var disappearingMessagesEnabled: Bool
    var autoDownloadOnWiFi: Bool
    var verifyEmailBannerVisible: Bool
}

struct ToastBanner: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let subtitle: String
}

struct SearchHit: Identifiable, Hashable {
    let threadID: UUID
    let threadTitle: String
    let message: ChatMessage

    var id: String { "\(threadID.uuidString)-\(message.id.uuidString)" }
}

enum MessageRowItem: Identifiable, Hashable {
    case dateMarker(String)
    case message(ChatMessage)

    var id: String {
        switch self {
        case .dateMarker(let label):
            return "date-\(label)"
        case .message(let message):
            return message.id.uuidString
        }
    }
}

final class MessagesStore: ObservableObject {
    @Published var currentTab: MessagesTab = .chats
    @Published var profile: ProfileState
    @Published var contacts: [Contact]
    @Published var chats: [ChatThread]
    @Published var statuses: [StatusUpdate]
    @Published var channels: [Channel]
    @Published var communities: [Community]
    @Published var calls: [CallRecord]
    @Published var scheduledCalls: [ScheduledCall]
    @Published var messageLists: [MessageListItem]
    @Published var broadcastLists: [BroadcastListItem]
    @Published var linkedDevices: [LinkedDevice]
    @Published var toast: ToastBanner?
    @Published var activeCall: ActiveCallInfo?
    @Published var typingThreadIDs: Set<UUID> = []

    let currentUserID: UUID
    let mediaTemplates: [MediaTemplate]
    private let referenceNow: Date
    private let replyGenerator: ReplyGenerating?
    private let replyDelay: TimeInterval
    @Published private(set) var activeThreadID: UUID?
    private var replyWorkItems: [UUID: DispatchWorkItem] = [:]
    private var replyRequestTokens: [UUID: UUID] = [:]
    private var toastWorkItem: DispatchWorkItem?

    init(
        referenceNow: Date = MessagesStore.makeReferenceDate(),
        replyGenerator: ReplyGenerating? = OpenAIReplyGenerator.makeIfConfigured(),
        replyDelay: TimeInterval = 1.0
    ) {
        self.referenceNow = referenceNow
        self.replyGenerator = replyGenerator
        self.replyDelay = replyDelay
        self.currentUserID = UUID()
        self.mediaTemplates = MessagesStore.makeMediaTemplates()
        self.profile = ProfileState(
            displayName: "Jordan Avery",
            phoneNumber: "+1 (206) 555-0147",
            headline: "In transit, but I reply fast here.",
            recoveryEmail: nil,
            avatar: AvatarSeed(topHex: 0x045A5C, bottomHex: 0x0A7F77, initials: "JA", symbolName: "person.fill"),
            readReceiptsEnabled: true,
            lockedChatsEnabled: true,
            disappearingMessagesEnabled: false,
            autoDownloadOnWiFi: true,
            verifyEmailBannerVisible: true
        )
        self.contacts = []
        self.chats = []
        self.statuses = []
        self.channels = []
        self.communities = []
        self.calls = []
        self.scheduledCalls = []
        self.messageLists = []
        self.broadcastLists = []
        self.linkedDevices = []
        seedAppData()
    }

    private static func makeReferenceDate() -> Date {
        Date()
    }

    private static func makeMediaTemplates() -> [MediaTemplate] {
        [
            MediaTemplate(title: "Harbor Setup", subtitle: "Soft gold lights over the dock", symbolName: "star.fill", topHex: 0x11263A, bottomHex: 0xF3A84B, accentHex: 0xFDE1B6),
            MediaTemplate(title: "Market Run", subtitle: "Fruit crates and neon umbrellas", symbolName: "leaf.fill", topHex: 0x0E4B4C, bottomHex: 0x43C06B, accentHex: 0xD5FFD2),
            MediaTemplate(title: "Mood Board", subtitle: "Tape, notes, and fresh mockups", symbolName: "square.and.pencil", topHex: 0x33224D, bottomHex: 0xF08382, accentHex: 0xFFE0D9),
            MediaTemplate(title: "Track Lights", subtitle: "Blue lanes under stadium lamps", symbolName: "bolt.fill", topHex: 0x13253F, bottomHex: 0x2C88FF, accentHex: 0xD5E8FF),
            MediaTemplate(title: "Window Seat", subtitle: "Coffee, passport, and a rainy gate", symbolName: "airplane", topHex: 0x3C1C1A, bottomHex: 0xD48B55, accentHex: 0xF8DFC8),
            MediaTemplate(title: "Kitchen Notes", subtitle: "Handwritten recipe cards on stone", symbolName: "fork.knife", topHex: 0x203128, bottomHex: 0x81B067, accentHex: 0xE1F4D2),
            MediaTemplate(title: "Loop GIF", subtitle: "A quick celebratory confetti loop", symbolName: "star.fill", topHex: 0x3B1A46, bottomHex: 0xD44B93, accentHex: 0xFFD6EC),
            MediaTemplate(title: "Walkthrough Clip", subtitle: "Stage lights flicker on for the first time", symbolName: "video.fill", topHex: 0x1A1A2F, bottomHex: 0x4E65D7, accentHex: 0xDCE2FF)
        ]
    }

    private func seedAppData() {
        let mayaID = UUID()
        let leoID = UUID()
        let ninaID = UUID()
        let omarID = UUID()
        let theoID = UUID()
        let priyaID = UUID()
        let diegoID = UUID()
        let sofiaID = UUID()
        let lenaID = UUID()
        let camilleID = UUID()
        let marcusID = UUID()
        let kaiID = UUID()
        let irisID = UUID()
        let nadiaID = UUID()
        let felixID = UUID()
        let danteID = UUID()
        let rohanID = UUID()
        let elenaID = UUID()
        let spencerID = UUID()
        let arnavID = UUID()
        let avaID = UUID()
        let graceID = UUID()
        let milesID = UUID()
        let jasmineID = UUID()
        let tomasID = UUID()
        let runningCommunityID = UUID()
        let studioCommunityID = UUID()

        let maya = Contact(
            id: mayaID,
            name: "Maya Patel",
            phoneNumber: "+1 (312) 555-0184",
            about: "Venue scout, tea optimist, and ruthless packer.",
            avatar: AvatarSeed(topHex: 0x5B3B1C, bottomHex: 0xE0B35C, initials: "MP", symbolName: "person.fill"),
            isFavorite: true
        )
        let leo = Contact(
            id: leoID,
            name: "Leo Chen",
            phoneNumber: "+1 (917) 555-0131",
            about: "Launch ops and tiny spreadsheet details.",
            avatar: AvatarSeed(topHex: 0x0E355B, bottomHex: 0x4F98FF, initials: "LC", symbolName: "person.fill"),
            isFavorite: true
        )
        let nina = Contact(
            id: ninaID,
            name: "Nina Brooks",
            phoneNumber: "+1 (415) 555-0169",
            about: "Keeps the room calm and the team fed.",
            avatar: AvatarSeed(topHex: 0x4E1831, bottomHex: 0xF07AA6, initials: "NB", symbolName: "person.fill"),
            isFavorite: false
        )
        let omar = Contact(
            id: omarID,
            name: "Omar Reyes",
            phoneNumber: "+1 (646) 555-0190",
            about: "Client comms, stage cues, and backup plans.",
            avatar: AvatarSeed(topHex: 0x143127, bottomHex: 0x39B379, initials: "OR", symbolName: "person.fill"),
            isFavorite: false
        )
        let theo = Contact(
            id: theoID,
            name: "Theo Nguyen",
            phoneNumber: "+1 (213) 555-0140",
            about: "Red-eyes, voice notes, and very fast edits.",
            avatar: AvatarSeed(topHex: 0x172B40, bottomHex: 0x5F8CD7, initials: "TN", symbolName: "person.fill"),
            isFavorite: true
        )
        let priya = Contact(
            id: priyaID,
            name: "Priya Raman",
            phoneNumber: "+1 (408) 555-0178",
            about: "Always brings snacks and backup chargers.",
            avatar: AvatarSeed(topHex: 0x421B51, bottomHex: 0xC272FF, initials: "PR", symbolName: "person.fill"),
            isFavorite: false
        )
        let diego = Contact(
            id: diegoID,
            name: "Diego Alvarez",
            phoneNumber: "+1 (310) 555-0125",
            about: "Routes, playlists, and low-stress logistics.",
            avatar: AvatarSeed(topHex: 0x12343A, bottomHex: 0x4CC5C7, initials: "DA", symbolName: "person.fill"),
            isFavorite: false
        )
        let sofia = Contact(
            id: sofiaID,
            name: "Sofia Kim",
            phoneNumber: "+1 (206) 555-0155",
            about: "Never misses a train or a photo moment.",
            avatar: AvatarSeed(topHex: 0x42251E, bottomHex: 0xEA8C68, initials: "SK", symbolName: "person.fill"),
            isFavorite: false
        )
        let lena = Contact(
            id: lenaID,
            name: "Lena Ortiz",
            phoneNumber: "+1 (718) 555-0113",
            about: "Floral installs, delivery windows, and graceful pivots.",
            avatar: AvatarSeed(topHex: 0x2A3D18, bottomHex: 0x7CCB59, initials: "LO", symbolName: "leaf.fill"),
            isFavorite: false
        )
        let camille = Contact(
            id: camilleID,
            name: "Camille Hart",
            phoneNumber: "+1 (646) 555-0108",
            about: "Always finds the right post-event dinner spot.",
            avatar: AvatarSeed(topHex: 0x402033, bottomHex: 0xF37FB4, initials: "CH", symbolName: "moon.fill"),
            isFavorite: true
        )
        let marcus = Contact(
            id: marcusID,
            name: "Marcus Vale",
            phoneNumber: "+1 (503) 555-0194",
            about: "Dock access, truck timing, and backup loading plans.",
            avatar: AvatarSeed(topHex: 0x183243, bottomHex: 0x4DA7D2, initials: "MV", symbolName: "shippingbox.fill"),
            isFavorite: false
        )
        let devonH = Contact(
            id: UUID(),
            name: "Devon Hart",
            phoneNumber: "+1 (510) 555-0147",
            about: "Product lead, user research evangelist.",
            avatar: AvatarSeed(topHex: 0x1A3C2D, bottomHex: 0x4DB882, initials: "DH", symbolName: "person.fill"),
            isFavorite: false
        )
        let spencerB = Contact(
            id: spencerID,
            name: "Spencer Bowman",
            phoneNumber: "+1 (773) 555-0172",
            about: "Fantasy football commissioner, grill master.",
            avatar: AvatarSeed(topHex: 0x1E3327, bottomHex: 0x5BC47E, initials: "SB", symbolName: "person.fill"),
            isFavorite: false
        )
        let arnavS = Contact(
            id: arnavID,
            name: "Arnav Srikanth",
            phoneNumber: "+1 (469) 555-0188",
            about: "Trail runner, podcast addict, weekend chef.",
            avatar: AvatarSeed(topHex: 0x2C1842, bottomHex: 0x9A5FCF, initials: "AS", symbolName: "person.fill"),
            isFavorite: false
        )
        let avaT = Contact(
            id: avaID,
            name: "Ava Torres",
            phoneNumber: "+1 (512) 555-0203",
            about: "Sunrise yogis and spontaneous road trips.",
            avatar: AvatarSeed(topHex: 0x3B1845, bottomHex: 0xD46BBF, initials: "AT", symbolName: "person.fill"),
            isFavorite: true
        )
        let milesC = Contact(
            id: milesID,
            name: "Miles Chen",
            phoneNumber: "+1 (858) 555-0217",
            about: "Always has a better shortcut.",
            avatar: AvatarSeed(topHex: 0x1A2D4A, bottomHex: 0x5A8FE0, initials: "MC", symbolName: "music.note"),
            isFavorite: false
        )
        let elenaB = Contact(
            id: elenaID,
            name: "Elena Brooks",
            phoneNumber: "+1 (303) 555-0229",
            about: "Half-marathon playlist curator.",
            avatar: AvatarSeed(topHex: 0x2D1940, bottomHex: 0xA76BD4, initials: "EB", symbolName: "book.fill"),
            isFavorite: true
        )
        let noahP = Contact(
            id: UUID(),
            name: "Noah Patel",
            phoneNumber: "+1 (404) 555-0241",
            about: "Keeps the group chat alive at midnight.",
            avatar: AvatarSeed(topHex: 0x1B3828, bottomHex: 0x4FCC7D, initials: "NP", symbolName: "person.fill"),
            isFavorite: false
        )
        let graceL = Contact(
            id: graceID,
            name: "Grace Lin",
            phoneNumber: "+1 (617) 555-0253",
            about: "Film prints, matcha, and vintage maps.",
            avatar: AvatarSeed(topHex: 0x243D1B, bottomHex: 0x6FD44A, initials: "GL", symbolName: "leaf.fill"),
            isFavorite: true
        )
        let samR = Contact(
            id: UUID(),
            name: "Sam Rivera",
            phoneNumber: "+1 (202) 555-0265",
            about: "Quiet leader, loud celebrations.",
            avatar: AvatarSeed(topHex: 0x3D1E12, bottomHex: 0xE87A4F, initials: "SR", symbolName: "person.fill"),
            isFavorite: false
        )
        let rubyF = Contact(
            id: UUID(),
            name: "Ruby Flores",
            phoneNumber: "+1 (305) 555-0277",
            about: "Never forgets your birthday.",
            avatar: AvatarSeed(topHex: 0x451A1A, bottomHex: 0xE85C5C, initials: "RF", symbolName: "heart.fill"),
            isFavorite: false
        )
        let masonW = Contact(
            id: UUID(),
            name: "Mason Ward",
            phoneNumber: "+1 (720) 555-0289",
            about: "Board games and cold brew.",
            avatar: AvatarSeed(topHex: 0x1E2845, bottomHex: 0x5B7FD4, initials: "MW", symbolName: "person.fill"),
            isFavorite: false
        )
        let henryC = Contact(
            id: UUID(),
            name: "Henry Cooper",
            phoneNumber: "+1 (919) 555-0301",
            about: "Thrift-store treasure hunter.",
            avatar: AvatarSeed(topHex: 0x0F3340, bottomHex: 0x3FC4D9, initials: "HC", symbolName: "person.fill"),
            isFavorite: false
        )
        let loganH = Contact(
            id: UUID(),
            name: "Logan Hughes",
            phoneNumber: "+1 (971) 555-0313",
            about: "Night owl, early bird at airports.",
            avatar: AvatarSeed(topHex: 0x2B3B17, bottomHex: 0x8FCC4D, initials: "LH", symbolName: "person.fill"),
            isFavorite: false
        )
        let ivyF = Contact(
            id: UUID(),
            name: "Ivy Foster",
            phoneNumber: "+1 (240) 555-0325",
            about: "Trail mix architect and sunset chaser.",
            avatar: AvatarSeed(topHex: 0x381C3E, bottomHex: 0xC56BD9, initials: "IF", symbolName: "person.fill"),
            isFavorite: false
        )
        let eliS = Contact(
            id: UUID(),
            name: "Eli Sanders",
            phoneNumber: "+1 (614) 555-0337",
            about: "Sketchbook always in the bag.",
            avatar: AvatarSeed(topHex: 0x2A1D10, bottomHex: 0xC48F4A, initials: "ES", symbolName: "person.fill"),
            isFavorite: false
        )
        let chloeB = Contact(
            id: UUID(),
            name: "Chloe Bennett",
            phoneNumber: "+1 (480) 555-0349",
            about: "Concert tickets and last-minute plans.",
            avatar: AvatarSeed(topHex: 0x401833, bottomHex: 0xF07AA0, initials: "CB", symbolName: "person.fill"),
            isFavorite: false
        )
        let jackS = Contact(
            id: UUID(),
            name: "Jack Sullivan",
            phoneNumber: "+1 (216) 555-0361",
            about: "Fixes anything with duct tape.",
            avatar: AvatarSeed(topHex: 0x162D3E, bottomHex: 0x4B9EC4, initials: "JS", symbolName: "person.fill"),
            isFavorite: false
        )
        let lilaB = Contact(
            id: UUID(),
            name: "Lila Brooks",
            phoneNumber: "+1 (615) 555-0373",
            about: "Podcast voice, quiet in person.",
            avatar: AvatarSeed(topHex: 0x331645, bottomHex: 0xBB5CE8, initials: "LB", symbolName: "person.fill"),
            isFavorite: false
        )
        let rileyS = Contact(
            id: UUID(),
            name: "Riley Shah",
            phoneNumber: "+1 (628) 555-0385",
            about: "Spreadsheet whisperer, weekend potter.",
            avatar: AvatarSeed(topHex: 0x1C2C48, bottomHex: 0x5F8BD9, initials: "RS", symbolName: "person.fill"),
            isFavorite: false
        )
        let owenP = Contact(
            id: UUID(),
            name: "Owen Price",
            phoneNumber: "+1 (707) 555-0397",
            about: "Always knows the score.",
            avatar: AvatarSeed(topHex: 0x273816, bottomHex: 0x7ACC4E, initials: "OP", symbolName: "person.fill"),
            isFavorite: false
        )
        let tessaM = Contact(
            id: UUID(),
            name: "Tessa Monroe",
            phoneNumber: "+1 (530) 555-0409",
            about: "Connector of people and dots.",
            avatar: AvatarSeed(topHex: 0x3A1A2E, bottomHex: 0xD46B8F, initials: "TM", symbolName: "person.fill"),
            isFavorite: false
        )
        let wyattL = Contact(
            id: UUID(),
            name: "Wyatt Lin",
            phoneNumber: "+1 (347) 555-0421",
            about: "Calm in a crisis, steady at the grill.",
            avatar: AvatarSeed(topHex: 0x12354B, bottomHex: 0x4A93E8, initials: "WL", symbolName: "bolt.fill"),
            isFavorite: false
        )
        let naomiT = Contact(
            id: UUID(),
            name: "Naomi Tanaka",
            phoneNumber: "+1 (206) 555-0445",
            about: "Code reviews and crochet patterns.",
            avatar: AvatarSeed(topHex: 0x401E28, bottomHex: 0xE87A8F, initials: "NT", symbolName: "person.fill"),
            isFavorite: false
        )
        let zaraO = Contact(
            id: UUID(),
            name: "Zara Okonkwo",
            phoneNumber: "+1 (415) 555-0457",
            about: "Always first to the dance floor.",
            avatar: AvatarSeed(topHex: 0x35182E, bottomHex: 0xCC5EA0, initials: "ZO", symbolName: "person.fill"),
            isFavorite: false
        )
        let aidenC = Contact(
            id: UUID(),
            name: "Aiden Cross",
            phoneNumber: "+1 (312) 555-0469",
            about: "Espresso machine tinkerer.",
            avatar: AvatarSeed(topHex: 0x182840, bottomHex: 0x4D7FCC, initials: "AC", symbolName: "person.fill"),
            isFavorite: false
        )
        let celesteH = Contact(
            id: UUID(),
            name: "Celeste Huang",
            phoneNumber: "+1 (626) 555-0501",
            about: "Early morning pool laps, evening sketches.",
            avatar: AvatarSeed(topHex: 0x102E42, bottomHex: 0x4596D9, initials: "CH", symbolName: "person.fill"),
            isFavorite: false
        )
        let raviK = Contact(
            id: UUID(),
            name: "Ravi Krishnan",
            phoneNumber: "+1 (408) 555-0513",
            about: "Cricket stats and chai experiments.",
            avatar: AvatarSeed(topHex: 0x2E3510, bottomHex: 0x94CC42, initials: "RK", symbolName: "person.fill"),
            isFavorite: false
        )
        let amaraO = Contact(
            id: UUID(),
            name: "Amara Osei",
            phoneNumber: "+1 (678) 555-0525",
            about: "Beadwork and bold color palettes.",
            avatar: AvatarSeed(topHex: 0x3D1438, bottomHex: 0xD45CBB, initials: "AO", symbolName: "bolt.fill"),
            isFavorite: false
        )
        let junoA = Contact(
            id: UUID(),
            name: "Juno Adler",
            phoneNumber: "+1 (503) 555-0601",
            about: "Collects vinyl and postcards.",
            avatar: AvatarSeed(topHex: 0x2D2D12, bottomHex: 0xB8B84A, initials: "JA", symbolName: "person.fill"),
            isFavorite: false
        )
        let kiraN = Contact(
            id: UUID(),
            name: "Kira Nakamura",
            phoneNumber: "+1 (818) 555-0613",
            about: "Street photography and fresh pasta.",
            avatar: AvatarSeed(topHex: 0x3B2018, bottomHex: 0xD48A5C, initials: "KN", symbolName: "camera.fill"),
            isFavorite: false
        )
        let meeraJ = Contact(
            id: UUID(),
            name: "Meera Joshi",
            phoneNumber: "+1 (571) 555-0637",
            about: "Calm planner, chaotic baker.",
            avatar: AvatarSeed(topHex: 0x351845, bottomHex: 0xBB5CE8, initials: "MJ", symbolName: "person.fill"),
            isFavorite: false
        )
        let esmeL = Contact(
            id: UUID(),
            name: "Esme Laurent",
            phoneNumber: "+1 (646) 555-0661",
            about: "Perfume collector and map hoarder.",
            avatar: AvatarSeed(topHex: 0x40201E, bottomHex: 0xE8887A, initials: "EL", symbolName: "person.fill"),
            isFavorite: false
        )
        let hazelD = Contact(
            id: UUID(),
            name: "Hazel Dunn",
            phoneNumber: "+1 (503) 555-0701",
            about: "Bookshelf organizer, cat person.",
            avatar: AvatarSeed(topHex: 0x351E35, bottomHex: 0xBB7ABB, initials: "HD", symbolName: "book.fill"),
            isFavorite: false
        )
        let veraS = Contact(
            id: UUID(),
            name: "Vera Strom",
            phoneNumber: "+1 (612) 555-0725",
            about: "Cabin weekends and crossword puzzles.",
            avatar: AvatarSeed(topHex: 0x182840, bottomHex: 0x5C8ED4, initials: "VS", symbolName: "person.fill"),
            isFavorite: false
        )
        let rohanM = Contact(
            id: rohanID,
            name: "Rohan Mehta",
            phoneNumber: "+1 (832) 555-0761",
            about: "Marathon finisher, amateur astronomer.",
            avatar: AvatarSeed(topHex: 0x102845, bottomHex: 0x4580D9, initials: "RM", symbolName: "bolt.fill"),
            isFavorite: true
        )
        let camilaD = Contact(
            id: UUID(),
            name: "Camila Duarte",
            phoneNumber: "+1 (786) 555-0797",
            about: "Salsa nights and Sunday markets.",
            avatar: AvatarSeed(topHex: 0x3D1835, bottomHex: 0xD46BB8, initials: "CD", symbolName: "person.fill"),
            isFavorite: true
        )
        let kaiS = Contact(
            id: kaiID,
            name: "Kai Santos",
            phoneNumber: "+1 (415) 555-0538",
            about: "Surf reports and spicy ramen rankings.",
            avatar: AvatarSeed(topHex: 0x3A2811, bottomHex: 0xD4A34E, initials: "KS", symbolName: "person.fill"),
            isFavorite: true
        )
        let irisY = Contact(
            id: irisID,
            name: "Iris Yamamoto",
            phoneNumber: "+1 (503) 555-0549",
            about: "Ceramics, cold brew, and crossword speedruns.",
            avatar: AvatarSeed(topHex: 0x2D1B42, bottomHex: 0xB86AD8, initials: "IY", symbolName: "person.fill"),
            isFavorite: false
        )
        let nadiaK = Contact(
            id: nadiaID,
            name: "Nadia Kovacs",
            phoneNumber: "+1 (646) 555-0562",
            about: "Data viz nerd and weekend baker.",
            avatar: AvatarSeed(topHex: 0x1A2E44, bottomHex: 0x4A8FD4, initials: "NK", symbolName: "person.fill"),
            isFavorite: false
        )
        let felixO = Contact(
            id: felixID,
            name: "Felix Oduya",
            phoneNumber: "+1 (773) 555-0574",
            about: "Vinyl collector and pickup basketball regular.",
            avatar: AvatarSeed(topHex: 0x142B1E, bottomHex: 0x3EB86A, initials: "FO", symbolName: "person.fill"),
            isFavorite: false
        )
        let danteM = Contact(
            id: danteID,
            name: "Dante Morales",
            phoneNumber: "+1 (310) 555-0586",
            about: "Film scores, street tacos, and very long walks.",
            avatar: AvatarSeed(topHex: 0x3D2815, bottomHex: 0xD4A053, initials: "DM", symbolName: "camera.fill"),
            isFavorite: false
        )
        let jasmineO = Contact(
            id: jasmineID,
            name: "Jasmine Obi",
            phoneNumber: "+1 (415) 555-0598",
            about: "Breathwork before breakfast, herbal tea after sunset.",
            avatar: AvatarSeed(topHex: 0x2D4A3A, bottomHex: 0x6BB88F, initials: "JO", symbolName: "person.fill"),
            isFavorite: false
        )
        let tomasV = Contact(
            id: tomasID,
            name: "Tomas Vega",
            phoneNumber: "+1 (718) 555-0611",
            about: "Building 4B, dog walks, and rooftop sunsets.",
            avatar: AvatarSeed(topHex: 0x4A2A1A, bottomHex: 0xC87A4A, initials: "TV", symbolName: "person.fill"),
            isFavorite: false
        )

        contacts = [maya, leo, nina, omar, theo, priya, diego, sofia, lena, camille, marcus, devonH, spencerB, arnavS, avaT, milesC, elenaB, noahP, graceL, samR, rubyF, masonW, henryC, loganH, ivyF, eliS, chloeB, jackS, lilaB, rileyS, owenP, tessaM, wyattL, naomiT, zaraO, aidenC, celesteH, raviK, amaraO, junoA, kiraN, meeraJ, esmeL, hazelD, veraS, rohanM, camilaD, kaiS, irisY, nadiaK, felixO, danteM, jasmineO, tomasV]

        let fallbackTemplate = mediaTemplates[0]
        let harborPhoto = mediaTemplates[safe: 0] ?? fallbackTemplate
        let marketPhoto = mediaTemplates[safe: 1] ?? fallbackTemplate
        let moodBoard = mediaTemplates[safe: 2] ?? fallbackTemplate
        let trackLights = mediaTemplates[safe: 3] ?? fallbackTemplate
        let windowSeat = mediaTemplates[safe: 4] ?? fallbackTemplate
        let kitchenNotes = mediaTemplates[safe: 5] ?? fallbackTemplate
        let confettiGIF = mediaTemplates[safe: 6] ?? fallbackTemplate
        let walkthroughClip = mediaTemplates[safe: 7] ?? fallbackTemplate

        let runningAnnouncementThreadID = UUID()
        let runningGroupThreadID = UUID()
        let studioAnnouncementThreadID = UUID()
        let studioLaunchThreadID = UUID()
        let mayaThreadID = UUID()
        let theoThreadID = UUID()
        let weekendTripThreadID = UUID()
        let lenaThreadID = UUID()
        let vendorThreadID = UUID()
        let camilleThreadID = UUID()
        let kaiThreadID = UUID()
        let familyThreadID = UUID()
        let apartmentThreadID = UUID()
        let concertThreadID = UUID()
        let elenaThreadID = UUID()
        let projectAlphaThreadID = UUID()
        let danteThreadID = UUID()
        let brunchCrewThreadID = UUID()
        let rohanThreadID = UUID()
        let irisThreadID = UUID()
        let sofiaThreadID = UUID()
        let marcusThreadID = UUID()
        let spencerThreadID = UUID()
        let arnavThreadID = UUID()
        let avaThreadID = UUID()
        let leoThreadID = UUID()
        let ninaThreadID = UUID()
        let omarThreadID = UUID()
        let priyaThreadID = UUID()
        let diegoThreadID = UUID()
        let graceThreadID = UUID()
        let felixThreadID = UUID()
        let nadiaThreadID = UUID()
        let milesThreadID = UUID()
        let jasmineThreadID = UUID()
        let tomasThreadID = UUID()

        chats = [
            // ───────────────────────────────────────
            // 1. Maya Patel DM (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: mayaThreadID,
                title: maya.name,
                avatar: maya.avatar,
                participantIDs: [maya.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (oldest first) ──
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -350, to: referenceNow), content: .text("Ok so I've been thinking about that studio idea nonstop. Are we actually doing this?"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -350, to: referenceNow), content: .text("I think we are. I keep sketching floor plans on napkins at lunch."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -348, to: referenceNow), content: .text("Same. I found a few listings in the warehouse district. Want to go look Saturday?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -347, to: referenceNow), content: .text("Absolutely. Morning works best. Coffee first though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -340, to: referenceNow), content: .text("That second space had incredible light but the lease terms were brutal. Still thinking about it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -338, to: referenceNow), content: .text("Yeah the 3-year minimum is a lot. Let's keep looking but hold it as a backup."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -330, to: referenceNow), content: .text("New lead on a space. Ground floor, big windows, month to month for the first year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -329, to: referenceNow), content: .text("That sounds too good. What's the catch?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -329, to: referenceNow), content: .text("No AC. But honestly with those windows we could do fans until October."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -320, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "First mood board draft for the pitch deck. Thoughts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -319, to: referenceNow), content: .text("Love the direction. The color palette feels exactly right. Maybe pull back on the serif fonts though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -310, to: referenceNow), content: .text("Client pitch went SO well today. They want to move forward with the full brand package."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -310, to: referenceNow), content: .text("MAYA. That's huge!! Our first real client. I'm getting celebratory pastries tomorrow."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Summer is flying by. Want to do a working session at that new cafe on 5th?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -299, to: referenceNow), content: .text("Yes please. I need to get out of my apartment. The walls are closing in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -288, to: referenceNow), content: .link(title: "Design Matters podcast - studio partnerships", url: "https://podcast.example/design-matters-ep412", description: "This episode hit different. Two designers who started a studio together talk about the first year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -286, to: referenceNow), content: .text("Just finished it. The part about dividing creative vs business roles was so relevant."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -275, to: referenceNow), content: .text("Happy birthday Jordan!! I left something at your door. Don't open it until you have coffee in hand."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -275, to: referenceNow), content: .text("You got me the Pentagram monograph?? Maya this is incredible. Thank you so much."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -275, to: referenceNow), content: .text("You've been eyeing it for months. Consider it a future studio bookshelf starter."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -260, to: referenceNow), content: .audio(duration: "1:12", transcript: "Quick voice note because I'm walking. The second client wants revisions on the logo suite but honestly I think their feedback is solid. Can we hop on a call tonight?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -259, to: referenceNow), content: .text("Yeah 8pm works. I'll pull up the files beforehand."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -245, to: referenceNow), content: .text("Fall weather is finally here and I am ALIVE. Sweater season is my creative peak."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -244, to: referenceNow), content: .text("Same. Something about cooler air makes everything feel more focused."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -230, to: referenceNow), content: .text("Work stress is through the roof this week. The packaging project timeline got cut in half."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -230, to: referenceNow), content: .text("That's brutal. Want to vent over ramen tonight? My treat."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -230, to: referenceNow), content: .text("You read my mind. 7pm at the usual spot."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -215, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Working from the cafe today. This light is unreal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -214, to: referenceNow), content: .text("Jealous. I'm stuck in back to back calls until 4."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Starting to think about holiday gifts. Do you have a list going yet?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("Not yet but I should. Last year I was wrapping things on Christmas Eve like a disaster."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Holiday party at my place Dec 20. You're obviously coming. Bring that mulled wine recipe."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("Wouldn't miss it. I'll double the batch this year since it disappeared in 20 minutes last time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -160, to: referenceNow), content: .audio(duration: "0:38", transcript: "Happy New Year! I know it's loud here but I wanted to say I'm really grateful for this year and everything we built. Next year is going to be even bigger."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -160, to: referenceNow), content: .text("Happy New Year Maya!! Honestly this year wouldn't have been the same without you. Here's to the studio taking off."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -145, to: referenceNow), content: .text("New year resolution check-in: I said I'd read one design book a month. Already behind."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -144, to: referenceNow), content: .text("Mine was to sketch daily. Made it 9 days. We're both frauds."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Just booked my Seattle trip for March. There's a design expo that could be huge for us."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Wait really? I've been looking at that same expo. Should we get a booth?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -128, to: referenceNow), content: .text("YES. I already have the application tab open. Sending you the link now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -128, to: referenceNow), content: .link(title: "Seattle Design Expo - Exhibitor Application", url: "https://seattledesignexpo.example/apply", description: "Booth registration closes February 15. Early bird pricing still available."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Booth application is in! Now we just need to figure out what we're actually showing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("I have some ideas. Let's do a brainstorm session this weekend. Your place or mine?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -90, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Saw this mural on my walk today. The color blocking is giving me booth inspo."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("Oh that's beautiful. The teal and terracotta combo would work perfectly for our display panels."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Booth layout draft is done. We have 10x10 feet to work with. I think we can make it feel bigger."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("Mirrors and good lighting. Works every time. Send me the sketch and I'll do a 3D mockup."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("Sample cards are at the printer. Should have them by end of next week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -39, to: referenceNow), content: .text("Perfect. That gives us time to do a dry run of the whole setup."), delivery: .read, isStarred: false),
                    // ── Recent messages (existing) ──
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Just confirmed the Seattle dates. We're a go for the first week of March."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -14, to: referenceNow), content: .text("Amazing. I'll block my calendar and start on booth layouts."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -10, to: referenceNow), content: .link(title: "Venue floor plan PDF", url: "https://venue.example/floorplan", description: "They finally posted the updated layout with the west wing."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("This is way bigger than last year. We should grab the corner near the atrium."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Already requested it. Also, do you still have that fabric sample binder?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("Yeah it's in my office closet. I'll grab it before I fly out."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -3, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Gate vibes. Two hours until boarding."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Landed in Seattle. Hotel is five minutes from the venue."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -18, to: referenceNow), content: .text("Nice. I dropped the booth sketches in our shared album."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.hour, -17, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "The waterfront entrance is better in person."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.hour, -2, to: referenceNow), content: .link(title: "Cedar Room tea menu", url: "https://cedar-room.example/menu", description: "They still have that smoked oolong you liked."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.hour, -1, to: referenceNow), content: .text("Oh also — just sent you a SplitPay request for that dinner split from last night. $42 for your half. No rush!"), delivery: .delivered, isStarred: false),
                    ChatMessage(id: UUID(), senderID: maya.id, sentAt: adding(.minute, -20, to: referenceNow), content: .text("If you're back before 7, let's do tea at Cedar Room."), delivery: .read, isStarred: false)
                ],
                unreadCount: 3,
                pinned: true,
                muted: false,
                subtitle: "online recently",
                automatedReplies: [
                    AutomatedReply(senderID: maya.id, content: .text("Back from setup. Tea at 6:30 works if you're around.")),
                    AutomatedReply(senderID: maya.id, content: .text("Perfect. I'll grab the corner booth and send you the pin.")),
                    AutomatedReply(senderID: maya.id, content: .visual(windowSeat, kind: .photo, caption: "Proof I packed the sample cards this time."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 2. Studio Launch group (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: studioLaunchThreadID,
                title: "Studio Launch",
                avatar: AvatarSeed(topHex: 0x0C3560, bottomHex: 0x236ED8, initials: "SL", symbolName: "person.3.fill"),
                participantIDs: [leo.id, nina.id, omar.id],
                isGroup: true,
                communityID: studioCommunityID,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -180, to: referenceNow), content: .text("Okay so we're really doing this. Studio launch. Let's make it happen."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("I mocked up three logo options last night. Thoughts incoming."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -179, to: referenceNow), content: .text("Option B is clean. Let's go with that direction."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("Agreed. Option B with the thinner stroke weight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -170, to: referenceNow), content: .document(name: "studio_brand_guide_v1.pdf", size: "3.4 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -165, to: referenceNow), content: .text("Brand guide looks great Omar. The color palette section is especially strong."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -155, to: referenceNow), content: .link(title: "Website wireframes - Figma", url: "https://figma.example/studio-wireframes", description: "First pass on the landing page and booking flow"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -154, to: referenceNow), content: .text("The booking flow is intuitive. Love the calendar integration idea."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Investor meeting is set for next Thursday. Who's presenting the pitch?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("I'll do the financials. Jordan, can you handle the vision section?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -139, to: referenceNow), content: .text("On it. I'll have slides ready by Tuesday for a dry run."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -130, to: referenceNow), content: .event(title: "Investor Pitch Meeting", detail: "Thu Nov 6 · 2:00 PM · WeWork 4th Floor"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -125, to: referenceNow), content: .text("Investor meeting went well. They want a follow-up in January with progress metrics."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -125, to: referenceNow), content: .text("Huge. Let's keep the momentum. I'll draft a timeline for the next three months."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -110, to: referenceNow), content: .document(name: "launch_timeline_v1.pdf", size: "1.1 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -100, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Website design is coming together. Here's the hero section."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Equipment list is finalized. Ordering this week so we get everything in time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -80, to: referenceNow), content: .text("Venue walkthrough is tomorrow. Omar, can you get us the floor plan?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -79, to: referenceNow), content: .document(name: "venue_floor_plan.pdf", size: "2.8 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -65, to: referenceNow), content: .text("Website is live in staging. Give it a look and send me feedback by Friday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -60, to: referenceNow), content: .link(title: "Studio Launch - Staging Site", url: "https://staging.studio-launch.example", description: "Password: preview2026"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -55, to: referenceNow), content: .text("Site looks fantastic. A few copy tweaks on the about page but otherwise ship it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("Milestone check: we're on track for everything except the AV install. Pushed one week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("One week delay is fine. We have buffer built in. Let's not stress."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("Signage vendor needs final files by end of this week. I'll prep everything tonight."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("Alright team, two weeks out. Let's lock the run of show by Friday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("I'll have the signage mockups ready by Wednesday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -11, to: referenceNow), content: .document(name: "run_of_show_v2.pdf", size: "1.8 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("Looks solid. I added notes on the transition between demo stations."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -7, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Signage proof. Thoughts on the font weight?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("Bolder. We need it readable from twenty feet."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -3, to: referenceNow), content: .document(name: "run_of_show_v3.pdf", size: "2.1 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Deck is locked. Please keep edits to timing and not copy."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.hour, -12, to: referenceNow), content: .poll(question: "Which demo opens the booth?", choices: [PollChoice(title: "Harbor lights", votes: 5), PollChoice(title: "Live dashboard", votes: 3), PollChoice(title: "Before/after mockups", votes: 2)]), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.hour, -3, to: referenceNow), content: .event(title: "Client walk-through", detail: "Fri 4:30 PM · South entrance"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.minute, -32, to: referenceNow), content: .text("Please keep Friday night free for the soft open."), delivery: .read, isStarred: false)
                ],
                unreadCount: 2,
                pinned: true,
                muted: false,
                subtitle: "Leo, Nina, Omar",
                automatedReplies: [
                    AutomatedReply(senderID: nina.id, content: .text("I can handle signage if someone else grabs check-in.")),
                    AutomatedReply(senderID: omar.id, content: .document(name: "run_of_show_v4.pdf", size: "2.4 MB")),
                    AutomatedReply(senderID: leo.id, content: .text("Locked. I'll push the final timing block in ten."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 3. Theo Nguyen DM (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: theoThreadID,
                title: theo.name,
                avatar: theo.avatar,
                participantIDs: [theo.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (oldest first) ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Dude. I just got accepted into that documentary fellowship. The one in Portland."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -300, to: referenceNow), content: .text("THEO! That's amazing. You've been working toward this for so long. Congrats man."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -299, to: referenceNow), content: .text("Thanks. Still doesn't feel real. First session starts in June."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -288, to: referenceNow), content: .text("Question for you. Thinking about upgrading my camera rig. A7S III or the FX3?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -287, to: referenceNow), content: .text("FX3 if you're doing mostly handheld doc work. The ventilation alone is worth it for long shoots."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -286, to: referenceNow), content: .text("That's what I was leaning toward. Pulling the trigger this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -272, to: referenceNow), content: .link(title: "No Film School - DaVinci vs Premiere deep dive", url: "https://nofilmschool.example/davinci-vs-premiere-2025", description: "This comparison is the best one I've seen. Makes a strong case for switching."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -271, to: referenceNow), content: .text("I've been hearing this from everyone. Is DaVinci really that much better for color?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -270, to: referenceNow), content: .text("Night and day difference. I switched last month and I'm never going back."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -255, to: referenceNow), content: .text("First rough cut of the doc is done. 22 minutes. It's messy but the bones are there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -254, to: referenceNow), content: .text("Can I see it? Even the messy version. I'm curious about the structure."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -253, to: referenceNow), content: .text("Sending a private link tonight. Be brutal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -248, to: referenceNow), content: .text("Watched it twice. The interview segment in the middle is the strongest part. The opening feels like it's searching for a hook."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -247, to: referenceNow), content: .text("Agree completely. I've been struggling with that opening. Going to try starting with the rooftop scene instead."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -232, to: referenceNow), content: .text("You free for a run this Saturday? I need to get out of the edit cave."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -231, to: referenceNow), content: .text("Absolutely. 7am at the park? Easy 5 miler."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -231, to: referenceNow), content: .text("Perfect. I'll bring the new headphones so you can test them too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -215, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Post-run sunrise. This is why we do early mornings."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -214, to: referenceNow), content: .text("Incredible shot. You should use this in your reel."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -200, to: referenceNow), content: .link(title: "Submitted to Portland Film Festival", url: "https://portlandfilmfest.example/submissions", description: "Just hit submit. 18-minute final cut. Feeling nervous."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("You're going to get in. That final cut was beautiful."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -180, to: referenceNow), content: .audio(duration: "0:55", transcript: "Just got the email. They accepted the doc for the emerging voices program. Screening is in January. I can't stop shaking."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -180, to: referenceNow), content: .text("THEO. I knew it. I literally knew it. This is your moment man. So proud of you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -165, to: referenceNow), content: .text("Have you heard that new Floating Points album? It's basically an editing soundtrack."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -164, to: referenceNow), content: .text("Not yet but adding it now. I need new focus music badly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Happy new year! Resolution: finish two more short docs by summer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("That's ambitious but if anyone can do it, it's you. Happy new year Theo."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("The screening was incredible. Full house. People stayed for the Q&A and asked real questions."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("I wish I could've been there. Save me a screener link. I want to see the final theater version."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -110, to: referenceNow), content: .visual(walkthroughClip, kind: .video, caption: "Testing a new gimbal setup for the next project. Smooth as butter."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("That stabilization is ridiculous. Which gimbal is that?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -108, to: referenceNow), content: .text("DJI RS4. Worth every penny for run and gun work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -85, to: referenceNow), content: .text("Tried that ramen place you recommended in Greenpoint. The spicy miso was unreal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -84, to: referenceNow), content: .text("Told you! The black garlic one is even better. Next time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Thinking about doing a behind-the-scenes doc for an event. Know anyone launching something soon?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("Actually yeah. Maya and I have the Seattle expo coming up in March. Could be perfect for you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -58, to: referenceNow), content: .text("Wait seriously? That sounds amazing. Let me think about the angle."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("Have you thought more about the Seattle doc idea?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -39, to: referenceNow), content: .text("Yeah I'm in. I want to capture the build-up, the stress, the payoff. Classic behind the scenes arc."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -38, to: referenceNow), content: .text("Love it. I'll loop you in on the timeline so you can plan your shots."), delivery: .read, isStarred: false),
                    // ── Recent messages (existing) ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("Hey, I'm thinking about shooting a short doc on the launch prep. You in?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -15, to: referenceNow), content: .text("Absolutely. Behind the scenes stuff always does well."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("Cool. I'll bring the small rig and the wireless lav."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -8, to: referenceNow), content: .link(title: "Reference reel - backstage doc", url: "https://vimeo.example/backstage-ref", description: "This is the tone I'm going for. Raw but polished."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -8, to: referenceNow), content: .text("Love this. The handheld stuff in the second half is exactly right."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -5, to: referenceNow), content: .audio(duration: "0:42", transcript: "Just wrapped a test shoot in my apartment. The lighting setup is dialed. We're good to go."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -2, to: referenceNow), content: .audio(duration: "0:28", transcript: "Boarded. If the Wi-Fi holds, I'll trim the reel before we land."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -28, to: referenceNow), content: .text("Do it if you can, but sleep first."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.hour, -7, to: referenceNow), content: .visual(walkthroughClip, kind: .video, caption: "Pulled a quick walkthrough clip from rehearsal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.hour, -1, to: referenceNow), content: .text("Editing is done. Sending the export once I hit the lounge."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 2m ago",
                automatedReplies: [
                    AutomatedReply(senderID: theo.id, content: .text("Just uploaded the clip. Give me ten and I'll do captions too.")),
                    AutomatedReply(senderID: theo.id, content: .visual(confettiGIF, kind: .gif, caption: "Mood when the export finally finishes.")),
                    AutomatedReply(senderID: theo.id, content: .text("Deal. I owe you a coffee once I stop living in airports."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 4. Weekend Trip group (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: weekendTripThreadID,
                title: "Weekend Trip",
                avatar: AvatarSeed(topHex: 0x15502D, bottomHex: 0x31C06A, initials: "WT", symbolName: "house.fill"),
                participantIDs: [priya.id, diego.id, sofia.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("We should plan a weekend getaway. I need to get out of the city."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Yes please. Cabin in the mountains? Somewhere with a fireplace."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("I'm very into this. Let's pick a date and go."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("Count me in. I can drive. My car fits four comfortably."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -110, to: referenceNow), content: .link(title: "Catskills cabin options", url: "https://cabins.example/catskills-winter", description: "Cozy spots with hot tubs and hiking trails nearby"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -105, to: referenceNow), content: .text("The one with the hot tub and the creek view is calling my name."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -100, to: referenceNow), content: .text("Budget check: how much are we each comfortable spending?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("I'm good up to $200 for two nights. That should cover most places split four ways."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Same budget works for me. Let's book before prices go up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -80, to: referenceNow), content: .document(name: "trip_activity_ideas.pdf", size: "450 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Made a list of activities: hiking, stargazing, cooking together, board games."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -70, to: referenceNow), content: .text("Love all of these. I'll bring my telescope for the stargazing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -60, to: referenceNow), content: .link(title: "Carpool route - estimated 3h drive", url: "https://maps.example/catskills-route", description: "Best route avoids tolls and has a great rest stop at mile 90"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("Should we wait until after Jordan's launch? Might be better timing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("Good call. First weekend of March would be ideal. Right after the launch wraps."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("Who's actually free the first weekend of March? Cabin idea is back on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("I'm in. I've been looking for an excuse to use that Dutch oven."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("Same. I can drive if we leave Friday after work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("Count me in. I call shotgun."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -8, to: referenceNow), content: .link(title: "Pine Ridge cabin listing", url: "https://cabins.example/pine-ridge-A4", description: "Three bedrooms, fire pit, and a creek view."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -8, to: referenceNow), content: .text("Booked. Split four ways it's nothing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -4, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Cabin groceries secured."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -3, to: referenceNow), content: .document(name: "route_options.pdf", size: "980 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -2, to: referenceNow), content: .event(title: "Sunrise trail start", detail: "Sat 6:15 AM · Pine Ridge lot"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -1, to: referenceNow), content: .text("I'll bring the stove and the lanterns."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.hour, -10, to: referenceNow), content: .text("Car is packed. Picking up Priya at 5, then swinging by your place."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.hour, -8, to: referenceNow), content: .text("I made a playlist for the drive. Three hours of bangers guaranteed."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "Priya, Diego, Sofia",
                automatedReplies: [
                    AutomatedReply(senderID: priya.id, content: .text("Perfect. I'll cover breakfast burritos and coffee.")),
                    AutomatedReply(senderID: diego.id, content: .text("I updated the route map with a dry weather option too.")),
                    AutomatedReply(senderID: sofia.id, content: .visual(trackLights, kind: .photo, caption: "This is the lookout we should hit before breakfast."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 5. Lena Ortiz DM (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: lenaThreadID,
                title: lena.name,
                avatar: lena.avatar,
                participantIDs: [lena.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (oldest first) ──
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Jordan! I just got asked to do floral installs for a gallery opening in SoHo. My first solo gig."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -250, to: referenceNow), content: .text("Lena that's amazing! You've been working toward this. What's the concept?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("Suspended installations. Think floating gardens. Lots of dried florals and moss."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -248, to: referenceNow), content: .text("That sounds stunning. If you need help with layout or lighting ideas, I'm here."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -235, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Mood board for the gallery install. Going for ethereal but grounded."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -234, to: referenceNow), content: .text("This is beautiful. The dried pampas with the copper wire is such a good combo."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Gallery opening was a hit! The curator wants to keep the install up for an extra two weeks."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("That's the biggest compliment. Your work deserves to be seen longer. Congrats Lena!"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -205, to: referenceNow), content: .text("I need new shelving for my workshop. Ikea or should I invest in something custom?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -204, to: referenceNow), content: .text("Custom if your budget allows it. For a workshop you need something that can handle weight and weird shapes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -203, to: referenceNow), content: .text("Good point. I know a woodworker in Red Hook who might give me a deal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -190, to: referenceNow), content: .link(title: "The Sill - winter plant care guide", url: "https://thesill.example/winter-care", description: "My fiddle leaf fig is looking sad. This guide might save it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -189, to: referenceNow), content: .text("Humidity trays. That's the secret. My monstera almost died until I started using one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -188, to: referenceNow), content: .text("Adding it to my list. You're saving a life today."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -175, to: referenceNow), content: .text("Have you read Braiding Sweetgrass? Our book club is reading it this month and it's incredible."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("I haven't but I've heard so many good things. Adding it to my nightstand pile."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -160, to: referenceNow), content: .text("Happy new year! I want to do more venue scouting this year. Every neighborhood has hidden gems."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Happy new year Lena! I'd love to tag along on some of those scouting trips."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -145, to: referenceNow), content: .text("Weekend market in Williamsburg this Saturday. They have a vintage furniture section. Come with?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -144, to: referenceNow), content: .text("Yes! I've been looking for a side table for my entryway."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -143, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Market haul. Found a brass planter and a set of ceramic vases for the workshop."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -142, to: referenceNow), content: .text("Those ceramic vases are gorgeous. I found my side table too. Productive morning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -125, to: referenceNow), content: .document(name: "venue_scouting_notes.pdf", size: "1.2 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -124, to: referenceNow), content: .text("Compiled my scouting notes from the last few weekends. Some amazing spaces in there for future events."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -123, to: referenceNow), content: .text("This is so thorough. The rooftop in Bushwick could be perfect for a summer launch."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -105, to: referenceNow), content: .text("Book club update: we're reading Dept. of Speculation next. Short but devastating. You'd love it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -104, to: referenceNow), content: .text("Downloaded it. If it makes me cry on the subway that's on you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -80, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Scouted this waterfront venue today. The natural light is unbelievable."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("Wow. The light coming through those windows is perfect for an event space. Filing this away."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -55, to: referenceNow), content: .text("Are you doing floral for the Seattle booth or keeping it minimal?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -54, to: referenceNow), content: .text("I was thinking minimal but now you're making me reconsider. Any ideas?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -53, to: referenceNow), content: .text("A single statement piece. Tall dried arrangement, asymmetric. It'll photograph well and not compete with the booth."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -52, to: referenceNow), content: .text("That's brilliant. Can you help me source something before I fly out?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -51, to: referenceNow), content: .text("Already on it. I know a supplier who can ship to Seattle directly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -30, to: referenceNow), content: .document(name: "floral_arrangement_spec.pdf", size: "780 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("This spec is perfect. Exactly what I envisioned. You're a lifesaver."), delivery: .read, isStarred: false),
                    // ── Recent messages (existing) ──
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("Hey Jordan, quick question. What's the ceiling height at the venue entrance?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -11, to: referenceNow), content: .text("Around fourteen feet. There's a beam about twelve feet up on the left side."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("Perfect. I can do the tall fern arch then. It'll clear with room to spare."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -6, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Test arrangement with the Italian ruscus. Thoughts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("Gorgeous. The draping on the right side is exactly the look we want."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("The fern wall mock is approved. I can bring the taller version on Friday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Do the taller version. It will frame the entry photos better."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.hour, -20, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "Palette check against the stone tables."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.hour, -11, to: referenceNow), content: .document(name: "install_window_notes.pdf", size: "540 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.minute, -12, to: referenceNow), content: .text("Driver is confirming the dock slot now. I should have final timing in a few minutes."), delivery: .read, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "last seen 9m ago",
                automatedReplies: [
                    AutomatedReply(senderID: lena.id, content: .text("Dock slot cleared for 11:10 AM. I'll be there before the drape vendor.")),
                    AutomatedReply(senderID: lena.id, content: .visual(marketPhoto, kind: .photo, caption: "Quick snap of the finished arch once it's in place.")),
                    AutomatedReply(senderID: lena.id, content: .text("If anything shifts, I'll keep this thread updated first."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 6. Venue Vendors group (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: vendorThreadID,
                title: "Venue Vendors",
                avatar: AvatarSeed(topHex: 0x2A3122, bottomHex: 0x9FC75B, initials: "VV", symbolName: "shippingbox.fill"),
                participantIDs: [lena.id, marcus.id, omar.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -90, to: referenceNow), content: .text("Starting this thread early. Venue vendors, let's get aligned on the timeline."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -88, to: referenceNow), content: .text("Good idea. I'll compile all the vendor contacts this week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -85, to: referenceNow), content: .document(name: "floral_quote_v1.pdf", size: "320 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -85, to: referenceNow), content: .text("Here's my initial quote for the floral installations. Happy to adjust based on budget."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Equipment rental quote is coming tomorrow. AV and staging included."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -75, to: referenceNow), content: .document(name: "vendor_budget_tracker.pdf", size: "210 KB"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -65, to: referenceNow), content: .event(title: "Venue Site Visit", detail: "Sat Jan 25 · 10:00 AM · South entrance"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Site visit went well. Dock access is tight but manageable. I'll draw up a loading sequence."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Revised floral plan based on the site visit. Taller arrangements for the lobby, lower for the tables."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("Budget is tracking well. We have about 10% buffer left. Let's keep it tight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -30, to: referenceNow), content: .document(name: "install_schedule_draft.pdf", size: "480 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -20, to: referenceNow), content: .event(title: "Equipment Delivery Window", detail: "Wed Mar 5 · 7:00 AM - 10:00 AM · Loading dock"), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -9, to: referenceNow), content: .text("Created this group to keep vendor logistics in one place. Everyone say hi."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -9, to: referenceNow), content: .text("Hey all. Marcus here, handling dock access and truck scheduling."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.day, -9, to: referenceNow), content: .text("Hi! I've got floral and greenery installs. Happy to coordinate timing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("I'll be the point person on the venue side. Tag me if you need anything approved."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -3, to: referenceNow), content: .link(title: "Loading dock entry map", url: "https://ops.example/dock-map", description: "Security needs truck plates fifteen minutes before arrival."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -1, to: referenceNow), content: .event(title: "Install window", detail: "Fri 11:00 AM · South dock"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: lena.id, sentAt: adding(.hour, -6, to: referenceNow), content: .text("I can clear the lobby in forty minutes if the truck gets in on time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -2, to: referenceNow), content: .text("Perfect. Keep this thread live if the dock timing changes."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "Lena, Marcus, Omar",
                automatedReplies: [
                    AutomatedReply(senderID: marcus.id, content: .text("Copy that. I'll update the truck ETA here as soon as dispatch confirms.")),
                    AutomatedReply(senderID: omar.id, content: .document(name: "dock_clearance_sheet.pdf", size: "284 KB")),
                    AutomatedReply(senderID: lena.id, content: .text("If we slip more than fifteen minutes, I can swap the install order and still finish before walkthrough."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 7. Camille Hart DM (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: camilleThreadID,
                title: camille.name,
                avatar: camille.avatar,
                participantIDs: [camille.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (oldest first) ──
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -280, to: referenceNow), content: .text("Jordan. Emergency. I just found the most perfect little wine bar and you need to come with me this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -280, to: referenceNow), content: .text("You had me at emergency. Where is it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -279, to: referenceNow), content: .link(title: "Sotto Voce Wine Bar", url: "https://sottovoce.example", description: "Hidden entrance through the bookshop. Natural wines only. Twelve seats."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -278, to: referenceNow), content: .text("A hidden wine bar through a bookshop. That's aggressively on brand for you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -278, to: referenceNow), content: .text("I know who I am and I'm at peace with it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -265, to: referenceNow), content: .text("So I'm planning a dinner party for the solstice. Keeping it small. You, me, Lena, and maybe Theo."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -264, to: referenceNow), content: .text("I'm in. What should I bring?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -264, to: referenceNow), content: .text("Just yourself and a bottle of something interesting. I'll handle the food."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -250, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "Menu test run for the dinner party. The risotto needs work but the braised leeks are perfect."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("This looks incredible. You're secretly a chef and just pretending to have a day job."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -240, to: referenceNow), content: .text("Career crisis moment. My manager wants me to take the leadership track but I'm not sure I want to manage people."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("What does your gut say? Not the practical answer, the honest one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -239, to: referenceNow), content: .text("That I'd rather stay hands-on. But the money is hard to ignore."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -238, to: referenceNow), content: .text("Give it a month before you decide. You don't have to answer right away."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -225, to: referenceNow), content: .text("Fall concert season is here. There's a Japanese Breakfast show next month. Interested?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -224, to: referenceNow), content: .text("Absolutely yes. Get two tickets and I'll SplitPay you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -210, to: referenceNow), content: .text("Have you explored the new neighborhood around the canal? There are like three new brunch spots."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -209, to: referenceNow), content: .text("Not yet. Sunday morning tour?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -209, to: referenceNow), content: .text("Deal. I'll make a list of three spots and we'll rank them."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -195, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Brunch spot number two. The shakshuka was life-changing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -194, to: referenceNow), content: .text("That was honestly the best brunch I've had all year. Spot two wins by a mile."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Starting my holiday gift shopping early for once. Any hints for what you want?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("Honestly? A good candle and a bottle of wine and I'm happy. Keep it simple."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -178, to: referenceNow), content: .text("I can work with that. I know exactly the right wine."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -160, to: referenceNow), content: .text("New year's resolution: actually commit to the gym three times a week instead of just saying I will."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Want an accountability buddy? I need the same push."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -158, to: referenceNow), content: .text("Yes. Tuesdays and Thursdays after work, Saturdays in the morning. Non-negotiable."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Ok so I didn't go to the gym today but I DID walk 12,000 steps. That counts right?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -139, to: referenceNow), content: .text("I'll allow it this once. But Thursday is non-negotiable. I'm dragging you there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -120, to: referenceNow), content: .link(title: "Eater - 12 Best New Restaurants", url: "https://eater.example/best-new-restaurants-2026", description: "Three of these are within walking distance of us. We need a crawl."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("A restaurant crawl is the most Camille idea ever proposed. I'm in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("Update on the career thing. I told them I want to stay on the individual contributor track. Feels right."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("Proud of you for choosing what actually makes you happy. That takes guts."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -75, to: referenceNow), content: .text("Valentine's Day plan: anti-Valentine's dinner at my place. Fancy cheese, good wine, zero romance."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -74, to: referenceNow), content: .text("The best kind of Valentine's. I'll bring the fancy cheese."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("How's prep going for Seattle? You've been quiet which either means focused or overwhelmed."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("Little of both honestly. But it's coming together. I'll resurface soon I promise."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -48, to: referenceNow), content: .text("No rush. Just checking in. Post-launch celebration is going to be epic though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Found another wine bar. This one has a jazz trio on Wednesdays. Adding it to the list."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Your wine bar radar is unmatched. Save it for when I'm back from Seattle."), delivery: .read, isStarred: false),
                    // ── Recent messages (existing) ──
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -16, to: referenceNow), content: .text("I found this tiny wine bar in the East Village. We need to go before they get discovered."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -16, to: referenceNow), content: .text("Send me the name. I'm always looking for new spots."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -16, to: referenceNow), content: .link(title: "Bar Celeste", url: "https://barceleste.example", description: "Natural wines, small plates, no reservations before 9 PM."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("How's launch prep treating you? Scale of 1 to existential dread."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("Solid 7. But the venue is gorgeous so it's worth it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("That's the spirit. Suffering with taste."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("If launch week breaks your brain, I'm stealing you for noodles after."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("Deal. I'll deserve it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.hour, -15, to: referenceNow), content: .audio(duration: "0:17", transcript: "Found a late spot near the venue that still does walk-ins after ten."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.minute, -48, to: referenceNow), content: .text("Hold next Thursday night. I have a reservation with your name all over it."), delivery: .read, isStarred: false)
                ],
                unreadCount: 2,
                pinned: false,
                muted: false,
                subtitle: "online now",
                automatedReplies: [
                    AutomatedReply(senderID: camille.id, content: .text("Excellent. I'll keep it low-key and carb-heavy.")),
                    AutomatedReply(senderID: camille.id, content: .visual(confettiGIF, kind: .gif, caption: "Mood when your calendar finally has something fun in it.")),
                    AutomatedReply(senderID: camille.id, content: .text("If work runs late, just drop me a pin and I'll adjust."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 8. Running Club Announcements (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: runningAnnouncementThreadID,
                title: "Running Club Announcements",
                avatar: AvatarSeed(topHex: 0x163D22, bottomHex: 0x42D26F, initials: "RC", symbolName: "megaphone.fill"),
                participantIDs: [theo.id, priya.id, diego.id],
                isGroup: true,
                communityID: runningCommunityID,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Welcome to Running Club Announcements! All official info will be posted here."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -290, to: referenceNow), content: .event(title: "Summer Kickoff 5K", detail: "Sat Jun 7 · 7:30 AM · Prospect Park East"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -285, to: referenceNow), content: .text("Great turnout for the kickoff! 42 runners total. New record for us."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -270, to: referenceNow), content: .text("Pace groups are now posted on the bulletin board. Check your group before Saturday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -260, to: referenceNow), content: .link(title: "Brooklyn Half Marathon - Registration", url: "https://nyrr.example/brooklyn-half", description: "Early bird registration is open. $45 for club members."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Reminder: hydration stations will be at mile 2 and mile 4 this week. Bring your own for longer runs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -230, to: referenceNow), content: .text("Route change for Saturday: the north loop trail is closed for maintenance. We'll use the south loop instead."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -210, to: referenceNow), content: .event(title: "Fall 10K Race", detail: "Sat Oct 18 · 8:00 AM · Golden Gate Park"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Who's signing up for the fall 10K? Group discount if we get 10+ runners."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -200, to: referenceNow), content: .text("I'm in. That course is beautiful in October."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Seasonal tip: the days are getting shorter. Wear reflective gear for evening runs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -160, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Group photo from the fall 10K! Great showing everyone."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Winter schedule is up. We're shifting Saturday runs to 8 AM until daylight saving."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Welcome to all new members who joined this month! Feel free to introduce yourselves."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -100, to: referenceNow), content: .link(title: "Winter running guide", url: "https://runclub.example/winter-tips", description: "Layer up, warm up, and watch for ice. Stay safe out there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Reminder: no run this Saturday due to the ice storm forecast. Stay safe everyone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -60, to: referenceNow), content: .event(title: "New Year Resolution Run", detail: "Sat Jan 4 · 9:00 AM · Prospect Park West"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Spring race calendar is out. Lots of great options this year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("The new route through the botanical garden is gorgeous. Highly recommend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Spring schedule starts next week. Back to 7 AM Saturday starts."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -18, to: referenceNow), content: .text("New members: please check in at the east pavilion for your first run. We'll have pace groups posted."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -14, to: referenceNow), content: .event(title: "Spring kickoff 5K", detail: "Sat Mar 1 · 7:00 AM · Prospect Park"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("Reminder: the water fountain near the north loop is back in service."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("Water station moved to the north entrance this week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Trail conditions are great this week. Dry and packed."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -1, to: referenceNow), content: .document(name: "5k_pacer_grid.pdf", size: "612 KB"), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: true,
                subtitle: "Theo, Priya, Diego",
                automatedReplies: [
                    AutomatedReply(senderID: theo.id, content: .text("Good call. I'll add it to the pinned note for Saturday."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 9. Saturday Long Run (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: runningGroupThreadID,
                title: "Saturday Long Run",
                avatar: AvatarSeed(topHex: 0x0E355B, bottomHex: 0x31A1FF, initials: "LR", symbolName: "bolt.fill"),
                participantIDs: [theo.id, priya.id, diego.id, sofia.id],
                isGroup: true,
                communityID: runningCommunityID,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Starting the Saturday long run thread. This is where we coordinate our weekly long runs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -148, to: referenceNow), content: .text("Love it. I need accountability partners for my marathon training."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -145, to: referenceNow), content: .text("I'm in for Saturdays. 7 AM works best for me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -145, to: referenceNow), content: .text("Same. I'll bring extra water and gels for whoever needs them."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Count me in! I'm slow but steady. Hope that's okay."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("All paces welcome. That's the whole point."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -130, to: referenceNow), content: .event(title: "Saturday Long Run - 8 miles", detail: "Sat Nov 8 · 7:00 AM · Boathouse parking lot"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Great run today! That hill at mile 5 was brutal though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Weather looks rough for Saturday. Rain and 38 degrees. Are we still on?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Let's reschedule to Sunday. Same time, same spot."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -90, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Sunrise from the trail this morning. Worth waking up for."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -80, to: referenceNow), content: .text("Post-run coffee at the cafe by the bridge? My treat."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("You had me at coffee. I'm there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Let's bump the distance up. 10 miles this Saturday. Who's ready?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Ready. I've been building up to this. Let's do it."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Who's in for a long one this Saturday? I'm thinking 10 to 12 miles."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("I'm in. Need to shake off the desk legs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -6, to: referenceNow), content: .text("Same. Let's keep it conversational pace though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("I'll bring gels and an extra water bottle."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("I mapped a river loop that's mostly flat. Good for easy long runs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Let's keep this one conversational. 12 miles max."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.hour, -6, to: referenceNow), content: .link(title: "Route pin", url: "https://maps.example/river-loop", description: "Start and finish are both at the boathouse."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: theo.id, sentAt: adding(.hour, -4, to: referenceNow), content: .text("Perfect. 7 AM start?"), delivery: .read, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "Theo, Priya, Diego, Sofia",
                automatedReplies: [
                    AutomatedReply(senderID: diego.id, content: .text("Works for me. I'll bring gels and a backup speaker.")),
                    AutomatedReply(senderID: priya.id, content: .text("Thank you. Keeping this one chatty and not chaotic.")),
                    AutomatedReply(senderID: theo.id, content: .visual(trackLights, kind: .photo, caption: "Weather should look like this right after sunrise."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 10. Studio Ops Network (expanded)
            // ───────────────────────────────────────
            ChatThread(
                id: studioAnnouncementThreadID,
                title: "Studio Ops Network",
                avatar: AvatarSeed(topHex: 0x17243C, bottomHex: 0x5A80F4, initials: "SO", symbolName: "person.3.fill"),
                participantIDs: [leo.id, nina.id, omar.id],
                isGroup: true,
                communityID: studioCommunityID,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Setting up this channel for all studio operations updates. Keep it organized."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -115, to: referenceNow), content: .text("Good idea. I'll use this for design and signage updates."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -110, to: referenceNow), content: .document(name: "equipment_inventory.pdf", size: "1.5 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Full equipment inventory attached. Let me know if anything's missing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("Scheduling conflict: the lighting vendor and the AV vendor both want Thursday morning. Suggestions?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -100, to: referenceNow), content: .text("Can we bump AV to Thursday afternoon? That gives lighting the morning slot."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -90, to: referenceNow), content: .event(title: "Client Onboarding Walk-through", detail: "Tue Jan 6 · 1:00 PM · Studio space"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Space booking for the soft open is confirmed. March 7, full day."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -70, to: referenceNow), content: .text("Maintenance request submitted for the HVAC unit. Should be fixed by next week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -50, to: referenceNow), content: .document(name: "signage_placement_map.pdf", size: "890 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("Everything is tracking. Let's keep this channel active during install week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -25, to: referenceNow), content: .event(title: "Install Week Kickoff", detail: "Mon Mar 3 · 8:00 AM · Studio main entrance"), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Welcome to the Studio Ops channel. All launch announcements will go here."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("Vendor contracts are signed. Install week is confirmed for March 3-7."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Signage vendor confirmed. Files go to print Monday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Welcome aboard. Announcements live here; working groups stay separate."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -2, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Lobby signage direction is now final."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.hour, -5, to: referenceNow), content: .text("Soft open guest list is locked at 85. No more additions."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: true,
                subtitle: "Leo, Nina, Omar",
                automatedReplies: [
                    AutomatedReply(senderID: leo.id, content: .text("Thanks. I'll pin it in the ops note too."))
                ],
                automatedReplyCursor: 0
            ),
            // ═══════════════════════════════════════
            // NEW THREADS BELOW
            // ═══════════════════════════════════════
            // ───────────────────────────────────────
            // 11. Kai Santos DM (dating/flirty)
            // ───────────────────────────────────────
            ChatThread(
                id: kaiThreadID,
                title: kaiS.name,
                avatar: kaiS.avatar,
                participantIDs: [kaiS.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Hey! It was great meeting you at Camille's party last night."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -120, to: referenceNow), content: .text("Likewise! You're the surfer, right? Camille said you'd get along with everyone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("Ha, guilty. Though I prefer 'ocean enthusiast.' Sounds classier."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("Very classy. So do you actually know how to surf or do you just sit on the board and look cool?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -118, to: referenceNow), content: .text("I'll have you know I stood up on my first try. Fell immediately after, but I stood up."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -113, to: referenceNow), content: .text("So hypothetically, if someone wanted to grab coffee this weekend, would you be free?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -113, to: referenceNow), content: .text("Hypothetically, that someone should just ask directly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -113, to: referenceNow), content: .text("Okay. Coffee this Saturday? There's a place on Valencia that does a perfect cortado."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -112, to: referenceNow), content: .text("I'm in. 11 works?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -112, to: referenceNow), content: .text("Perfect. See you there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -108, to: referenceNow), content: .text("That was fun. I haven't talked that long over coffee in years."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -108, to: referenceNow), content: .text("Same. Three hours went by like nothing. Also your cortado recommendation was spot on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -101, to: referenceNow), content: .text("Sending you that playlist I mentioned. Lots of Khruangbin and Toro y Moi."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -101, to: referenceNow), content: .link(title: "Kai's Sunset Drive Mix", url: "https://music.example/kai-sunset", description: "Chill vibes for the PCH."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -100, to: referenceNow), content: .text("This is so good. I've had it on repeat all morning. Adding some Tycho to your queue in return."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -93, to: referenceNow), content: .text("Okay serious question. Best ramen in the city. Go."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -93, to: referenceNow), content: .text("Marufuku for tonkotsu. No debate. What's yours?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -92, to: referenceNow), content: .text("Bold pick. I'm a Mensho guy but I respect it. We should do a ramen crawl sometime."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -84, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Dawn patrol this morning. Glassy conditions."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -84, to: referenceNow), content: .text("Okay that looks incredible. I'm jealous. Take me next time?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -83, to: referenceNow), content: .text("Done. I'll teach you. Fair warning: you will wipe out a lot."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -75, to: referenceNow), content: .text("My friends want to know who 'the surfer' is. Apparently I talk about you too much."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -75, to: referenceNow), content: .text("Tell them I'm charming and mysterious. Also that I make great playlists."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Saturday plan: surf in the morning, ramen crawl after. I'll pick you up at 7."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -60, to: referenceNow), content: .text("7 AM on a Saturday? You're lucky I like you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -58, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Post-surf glow. You did way better than I expected out there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -58, to: referenceNow), content: .text("I stood up TWICE. That counts as a victory. Also the spicy miso at Mensho was unreal. You win that round."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -45, to: referenceNow), content: .text("Camille is doing a game night Friday. Wanna go together?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -45, to: referenceNow), content: .text("Like... together together?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -45, to: referenceNow), content: .text("Yeah. Together together. If you're up for it."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -44, to: referenceNow), content: .text("I'm up for it. Pick me up at 7 again?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -44, to: referenceNow), content: .text("This time it's PM. Even I have limits."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Your friends are great by the way. Camille already texted me a meme this morning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -30, to: referenceNow), content: .text("She does that. It means she approves of you. Consider yourself vetted."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("Thinking about you. How's the launch prep going?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -20, to: referenceNow), content: .text("Stressful but good. I'll be more free after next week. Miss hanging out."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("No rush. I'll be here with surf reports and ramen rankings when you surface."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -9, to: referenceNow), content: .text("So are you always this hard to pin down, or just when someone's trying to buy you coffee?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -9, to: referenceNow), content: .text("Ha. I'm in the middle of a launch at work. My schedule is chaos right now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -9, to: referenceNow), content: .text("Chaos sounds fun. I'll wait."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -6, to: referenceNow), content: .link(title: "Surf forecast - Saturday", url: "https://surf.example/forecast-sat", description: "Clean sets all morning. Just saying."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("Tempting. I haven't been in the water in months."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -6, to: referenceNow), content: .text("All the more reason. I have an extra wetsuit."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("Okay, I'm interested. But after the launch wraps. I owe you that much focus."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("Deal. But I'm picking the ramen spot after."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -2, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Sunrise from the pier this morning. Thought you'd appreciate it."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Okay that's beautiful. You might be winning me over."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.hour, -3, to: referenceNow), content: .text("How's the launch prep going? Almost free?"), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "last seen 1h ago",
                automatedReplies: [
                    AutomatedReply(senderID: kaiS.id, content: .text("No rush. Just wanted you to know I'm still thinking about that ramen deal.")),
                    AutomatedReply(senderID: kaiS.id, content: .text("Also I found an even better surf spot. Saving it for when you're free.")),
                    AutomatedReply(senderID: kaiS.id, content: .visual(windowSeat, kind: .photo, caption: "Morning light from the boardwalk. Your future office."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 12. Avery Fam group (family/sibling chat)
            // ───────────────────────────────────────
            ChatThread(
                id: familyThreadID,
                title: "Avery Fam",
                avatar: AvatarSeed(topHex: 0x3A1A30, bottomHex: 0xD86090, initials: "AF", symbolName: "house.fill"),
                participantIDs: [elenaB.id, spencerB.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -365, to: referenceNow), content: .text("Happy birthday Jordan!!! Can't believe you're getting old."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -365, to: referenceNow), content: .text("Happy birthday! Mom says she's mailing your gift today."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -365, to: referenceNow), content: .text("Thanks you two. Getting old is a team sport apparently."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -340, to: referenceNow), content: .text("Has anyone talked to Dad this week? He sounded tired on the phone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -339, to: referenceNow), content: .text("I called him yesterday. He's fine, just busy with the yard."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -339, to: referenceNow), content: .text("I'll FaceTime him this weekend. Maybe we should schedule regular check-ins."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -310, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "Mom sent her lasagna recipe. Finally wrote it down!"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -310, to: referenceNow), content: .text("I've been trying to get that recipe for YEARS."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -309, to: referenceNow), content: .text("She literally guards that recipe like a state secret."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -280, to: referenceNow), content: .text("Thanksgiving plans? I'm flying in Wednesday night."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -280, to: referenceNow), content: .text("Same. I booked a red-eye. Should land around 6 AM Thursday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -279, to: referenceNow), content: .text("I'm driving down Tuesday. Can pick someone up from the airport if needed."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -275, to: referenceNow), content: .event(title: "Thanksgiving Dinner", detail: "Thu Nov 27 · 4:00 PM · Mom & Dad's"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -270, to: referenceNow), content: .text("That was the best Thanksgiving in years. We need to do that cranberry sauce again."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -270, to: referenceNow), content: .text("Agreed. Also Dad's face when the dog stole the rolls was priceless."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -270, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Flight home. Already miss everyone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -240, to: referenceNow), content: .text("Christmas gift ideas for Mom? I'm drawing a blank."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -240, to: referenceNow), content: .text("She mentioned wanting a nice cookbook stand. The wooden kind."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -239, to: referenceNow), content: .text("I'll get that. Spencer, you do the fancy tea set she keeps looking at. Jordan, candles or kitchen stuff?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("I'll do the Le Creuset dutch oven she's been eyeing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -220, to: referenceNow), content: .link(title: "Family photo gallery - Christmas 2025", url: "https://photos.example/avery-xmas", description: "48 photos from Christmas Eve and Christmas Day"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("These are amazing. The one of Dad asleep in the recliner with the cat is frame-worthy."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -190, to: referenceNow), content: .text("Happy birthday Spencer!! Hope Portland is treating you well today."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -190, to: referenceNow), content: .text("Happy birthday big bro! Mom says your card is in the mail."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -190, to: referenceNow), content: .text("Thanks fam. Treating myself to a hike and a steak dinner."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("I'm thinking about visiting SF next month. Jordan, can I crash at your place?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -150, to: referenceNow), content: .text("Always. Guest room is yours. Let me know the dates."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("Jealous. I want to visit too. Maybe we all overlap?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("Mom got a new puppy and didn't tell us?? Dad just sent me this."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -100, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Meet Biscuit. He's already chewed through two shoes."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("BISCUIT. That's the best name. I need to go home immediately."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("I can't handle how cute he is. Mom is going to spoil him rotten."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Quick update: I got promoted at work. Senior designer now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -60, to: referenceNow), content: .text("SPENCER! That's huge. Congrats. You deserve it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("So proud of you! We need to celebrate when we're all together."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -17, to: referenceNow), content: .text("Mom wants to know if we're all coming for Easter this year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -17, to: referenceNow), content: .text("Tell her yes from me. I already booked the flight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -17, to: referenceNow), content: .text("Same. I'll be there. Do we need to coordinate gifts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("She said she doesn't want gifts. She wants us to cook dinner together."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("I'll handle the grill. Nobody touch the grill."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -14, to: referenceNow), content: .text("Fine. I'll do sides and dessert."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("I'll handle appetizers and make sure Spencer doesn't burn everything."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("That was ONE time and it was a brisket."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -7, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Finally got my half marathon photos back!"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("You look fast even in photos. Proud of you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Legend. What was your time?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("1:48:22. New PR by three minutes."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Jordan, how's the big launch going? You've been quiet."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("Controlled chaos. Opens Friday. I'll send pics."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.hour, -4, to: referenceNow), content: .text("Dad says good luck and to eat real food this week."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: true,
                muted: false,
                subtitle: "Elena, Spencer",
                automatedReplies: [
                    AutomatedReply(senderID: spencerB.id, content: .text("Seconded. Eat a vegetable.")),
                    AutomatedReply(senderID: elenaB.id, content: .text("We believe in you. Send us a photo when it's done!")),
                    AutomatedReply(senderID: spencerB.id, content: .text("Also can you bring that hot sauce from the market when you come for Easter?"))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 13. Apartment 4B group (roommate chat)
            // ───────────────────────────────────────
            ChatThread(
                id: apartmentThreadID,
                title: "Apartment 4B",
                avatar: AvatarSeed(topHex: 0x2A1842, bottomHex: 0x9A6AD8, initials: "4B", symbolName: "building.2.fill"),
                participantIDs: [felixO.id, nadiaK.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Welcome to the apartment group chat! House rules: label your food, take out trash on Tuesdays."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Love it. Also can we agree on a quiet hours policy? I WFH most days."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -299, to: referenceNow), content: .text("Works for me. Quiet after 10 PM on weeknights?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -280, to: referenceNow), content: .text("Rent is $2,400 total. $800 each. I'll collect on the 1st via SplitPay."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -265, to: referenceNow), content: .text("The dishwasher is making a weird grinding noise. Anyone else hearing it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -265, to: referenceNow), content: .text("Yeah it started yesterday. I'll text the super."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -264, to: referenceNow), content: .text("Super says he can come Friday between 9 and 11. Someone needs to be here."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -264, to: referenceNow), content: .text("I'll be here. I have a morning meeting but can let him in after."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -240, to: referenceNow), content: .poll(question: "Grocery run - who's going to Trader Joe's?", choices: [PollChoice(title: "Felix", votes: 0), PollChoice(title: "Nadia", votes: 1), PollChoice(title: "Jordan", votes: 1)]), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -240, to: referenceNow), content: .text("I can go. Send me your lists."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("The AC is barely working. It's 82 degrees in my room right now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Same. I'll submit a maintenance request. In the meantime I have a spare fan."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -200, to: referenceNow), content: .text("Hey, I'm having a few friends over Saturday for the game. Cool with everyone?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Fine by me! Just keep it reasonable volume-wise."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("I'll join. I'll grab chips and salsa."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Package at the door for Felix. I brought it inside."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Thanks! That's my new keyboard. Been waiting forever."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -140, to: referenceNow), content: .document(name: "utility_bill_november.pdf", size: "180 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Utilities this month: $186 total. $62 each."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -140, to: referenceNow), content: .text("Sent. We should switch to LED bulbs, might help with the electric bill."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Whose turn is it to clean the bathroom? I did it two weeks ago."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -110, to: referenceNow), content: .text("Pretty sure it's Felix's turn."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Fair enough. I'll do it tonight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Anyone know the wifi password? My friend is visiting and needs it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("It's on the sticker under the router. apartment4b_guest"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -50, to: referenceNow), content: .text("I want to put some plants in the living room. Any objections?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Love that idea. I'll chip in for a nice fern."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("As long as someone waters them. My track record with plants is not great."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("Rent reminder: it's due the 1st. SplitPay me your share whenever."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -12, to: referenceNow), content: .text("Sent. Also, someone finished the oat milk and didn't replace it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("...that was me. I'm sorry. I'll grab some on my way home."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("Heads up, the super is coming Thursday to fix the kitchen faucet. Someone needs to be here between 10 and 12."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("I can WFH that day. I'll be here."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -5, to: referenceNow), content: .poll(question: "WiFi upgrade - split three ways?", choices: [PollChoice(title: "Yes, faster is worth it", votes: 2), PollChoice(title: "No, current plan is fine", votes: 0)]), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -5, to: referenceNow), content: .text("Voted yes. The buffering during video calls is killing me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("I'm making a big batch of chili tomorrow if anyone wants some."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Yes please. Save me a bowl. I'll be at the venue most of the day."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.hour, -9, to: referenceNow), content: .text("Package arrived for you Jordan. I put it on your desk."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -8, to: referenceNow), content: .text("Thanks! That's the backup cables for the launch."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "Felix, Nadia",
                automatedReplies: [
                    AutomatedReply(senderID: nadiaK.id, content: .text("Chili is done. There's a container in the fridge with your name on it.")),
                    AutomatedReply(senderID: felixO.id, content: .text("Also, we're out of dish soap. Adding it to the shared grocery list.")),
                    AutomatedReply(senderID: nadiaK.id, content: .text("I'll grab it. Anyone need anything else from the store?"))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 14. Concert crew group (friend planning)
            // ───────────────────────────────────────
            ChatThread(
                id: concertThreadID,
                title: "Concert Crew",
                avatar: AvatarSeed(topHex: 0x3B1A46, bottomHex: 0xD44B93, initials: "CC", symbolName: "music.note"),
                participantIDs: [arnavS.id, avaT.id, graceL.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Created this group for all things live music. Let's never miss a show again."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -198, to: referenceNow), content: .text("Love it. First order of business: who's going to the Japanese Breakfast show next month?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -198, to: referenceNow), content: .text("I am. Already have tickets. You all need to get on it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -197, to: referenceNow), content: .text("Just bought mine. GA floor. Let's do pre-show dinner."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -180, to: referenceNow), content: .link(title: "Spotify Playlist - Concert Crew Picks", url: "https://open.spotify.example/playlist/concertcrew", description: "Our running playlist of artists we're seeing live"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Japanese Breakfast was INCREDIBLE. Michelle Zauner's energy is unmatched."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("The encore was everything. I still have chills."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -170, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Post-show vibes at the waterfront. What a night."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Tyler the Creator just announced a festival set. Anyone interested in going?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Absolutely. That lineup is stacked this year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -140, to: referenceNow), content: .link(title: "Festival lineup announcement", url: "https://fest.example/lineup-2026", description: "Three days, four stages, and some serious headliners"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -140, to: referenceNow), content: .text("That Saturday lineup alone is worth the ticket price. I'm in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("New Radiohead album is streaming. Has anyone listened yet?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Twice already. Track 4 is unreal. They need to tour."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("SZA just added a second show in our city. Who needs tickets?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -100, to: referenceNow), content: .text("Me. Please grab me one if you get through the queue."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -80, to: referenceNow), content: .visual(walkthroughClip, kind: .video, caption: "Found this incredible street musician downtown. Watch."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -60, to: referenceNow), content: .link(title: "Arnav's 2026 concert wishlist", url: "https://playlist.example/arnav-wishlist", description: "Artists I need to see live this year. Adding constantly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("March concert calendar is packed. We have three shows this month alone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -30, to: referenceNow), content: .text("My wallet is crying but my soul is thriving. No regrets."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("Khruangbin tickets go on sale Friday at 10 AM. Who's in?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -11, to: referenceNow), content: .text("Absolutely. I've been waiting for this tour."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("I'm in. Do we want floor or balcony?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -11, to: referenceNow), content: .text("Floor. Always floor. I want to feel the bass."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("GOT THEM. Four floor tickets. April 18."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -8, to: referenceNow), content: .visual(confettiGIF, kind: .gif, caption: ""), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("Hero. SplitPay incoming."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("We should do dinner before. There's a Thai place near the venue."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -5, to: referenceNow), content: .link(title: "Siam Garden", url: "https://siamgarden.example/menu", description: "Best pad see ew in the city. Not even close."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -5, to: referenceNow), content: .text("Sold. I'll make a reservation for 6."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -1, to: referenceNow), content: .event(title: "Khruangbin @ The Anthem", detail: "Apr 18 · Doors 7 PM · Floor GA"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.hour, -5, to: referenceNow), content: .text("Just listened to their new single. This show is going to be unreal."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 2,
                pinned: false,
                muted: false,
                subtitle: "Arnav, Ava, Grace",
                automatedReplies: [
                    AutomatedReply(senderID: graceL.id, content: .text("The setlist from their LA show is incredible. We're in for a treat.")),
                    AutomatedReply(senderID: avaT.id, content: .text("I'm already planning my outfit. This is a vibe check.")),
                    AutomatedReply(senderID: arnavS.id, content: .audio(duration: "0:12", transcript: "Just putting it out there, we should do matching band tees."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 15. Elena Brooks DM (catch-up / sibling-like friend)
            // ───────────────────────────────────────
            ChatThread(
                id: elenaThreadID,
                title: elenaB.name,
                avatar: elenaB.avatar,
                participantIDs: [elenaB.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~10 months back) ──
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Hey! Are you still running? I just signed up for the Prospect Park 10K in June."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -299, to: referenceNow), content: .text("I've been slacking honestly. A 10K might be exactly the kick I need."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -299, to: referenceNow), content: .text("Do it! We can train together. I'll keep us accountable."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -290, to: referenceNow), content: .text("Okay I registered. No turning back now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -290, to: referenceNow), content: .text("YES. Running buddy activated. Let's start with three miles this Saturday."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -275, to: referenceNow), content: .link(title: "Couch to 10K plan", url: "https://running.example/c210k", description: "Gentle build-up over 8 weeks. Perfect for getting back into it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -274, to: referenceNow), content: .text("This looks doable. Three days a week plus a long run on weekends?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -274, to: referenceNow), content: .text("Exactly. And we brunch after the long run. Non-negotiable."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -260, to: referenceNow), content: .text("Did 4 miles today without stopping. Felt amazing. Summer heat is brutal though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -259, to: referenceNow), content: .text("Proud of you! Hydration vest is a game changer. I'll send you the one I use."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -259, to: referenceNow), content: .link(title: "Nathan QuickSqueeze Hydration Pack", url: "https://gear.example/nathan-vest", description: "Lightweight, bounces less than you'd think."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -240, to: referenceNow), content: .text("Race day tomorrow! How are you feeling?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -240, to: referenceNow), content: .text("Nervous but ready. Carb-loaded like a professional pasta eater."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -239, to: referenceNow), content: .text("WE DID IT! 10K done! My time was 52:14. What was yours?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("54:38! I'll take it for my first race. That last hill nearly ended me though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -239, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Finish line photo! We look exhausted and happy."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -220, to: referenceNow), content: .text("Post-race recovery has been rough. My knees are staging a protest."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -219, to: referenceNow), content: .text("Foam roller and ice baths. Trust me. Also try those KT tape strips on your IT band."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Fall running is the best running. Cool air, leaves everywhere, no sunburn."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("Agreed. Did a solo 5 this morning along the river. Felt like a new person."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Career update: I got the promotion! Senior account manager starting January."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -170, to: referenceNow), content: .text("ELENA. That's incredible! You've been working so hard for this. Celebratory brunch?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -169, to: referenceNow), content: .text("Absolutely. This weekend. Mimosas mandatory."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -120, to: referenceNow), content: .document(name: "strava_year_in_review.pdf", size: "890 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Check out our TrailBlaze stats! We ran 312 miles together this year. Not bad for a slacker and a try-hard."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("I'm the slacker in this scenario right? Also 312 miles is insane. We're basically athletes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("New year resolution: half marathon. I'm serious. We're doing this."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("You're going to drag me into this aren't you. Fine. When and where?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -79, to: referenceNow), content: .text("Brooklyn Half in May. It's the perfect next step. I'll find a training plan."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -50, to: referenceNow), content: .text("Got new shoes for training. Brooks Ghost 16. They feel like clouds."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -49, to: referenceNow), content: .text("Great choice. I'm in the Hoka Cliftons and they're unreal. Happy feet = happy miles."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -19, to: referenceNow), content: .text("I signed up for the Brooklyn half. Please tell me you're doing it too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -19, to: referenceNow), content: .text("When is it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -19, to: referenceNow), content: .text("May 17. Perfect weather window."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -18, to: referenceNow), content: .text("I'm in. I need a goal to keep me running after this launch."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -18, to: referenceNow), content: .text("YES. Training buddy activated."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -10, to: referenceNow), content: .document(name: "half_marathon_training_plan.pdf", size: "340 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("This looks manageable. Three runs a week plus a long one?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("Exactly. We start easy and build. No hero pace in week one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: elenaB.id, sentAt: adding(.day, -4, to: referenceNow), content: .audio(duration: "0:22", transcript: "Did four miles this morning. Legs felt great. I think we can bump the long run to six this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("Let's do it. I'm sore from venue setup but a run will help."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 30m ago",
                automatedReplies: [
                    AutomatedReply(senderID: elenaB.id, content: .text("Perfect. Saturday morning? I'll map a route near the park.")),
                    AutomatedReply(senderID: elenaB.id, content: .text("Also found these new running socks that are life-changing. Sending you a link.")),
                    AutomatedReply(senderID: elenaB.id, content: .link(title: "Feetures Elite Light Cushion", url: "https://gear.example/feetures", description: "No blisters, no bunching. Trust me."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 16. Project Alpha group (work/project)
            // ───────────────────────────────────────
            ChatThread(
                id: projectAlphaThreadID,
                title: "Project Alpha",
                avatar: AvatarSeed(topHex: 0x1A2844, bottomHex: 0x4A72D4, initials: "PA", symbolName: "laptopcomputer"),
                participantIDs: [rohanM.id, nadiaK.id, irisY.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -150, to: referenceNow), content: .text("Hey team, I'm spinning up a new project. Codename: Alpha. Interested?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Always. What's the scope?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("I'm in. Been looking for a new challenge."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("Count me in too. I can lead the design system side."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -145, to: referenceNow), content: .document(name: "project_alpha_brief.pdf", size: "890 KB"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -145, to: referenceNow), content: .text("Here's the brief. Take a look and let's discuss Friday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("Read through the brief. The auth architecture needs some thought. I'll draft options."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -135, to: referenceNow), content: .text("Database schema is drafted. Going with PostgreSQL. Any objections?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -135, to: referenceNow), content: .text("Postgres is perfect for this. Go for it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -125, to: referenceNow), content: .link(title: "Design system reference - Linear style", url: "https://design.example/linear-ds", description: "Using this as inspiration for our component library"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Auth module is done. JWT with refresh tokens. Tests are passing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -110, to: referenceNow), content: .document(name: "api_endpoints_v1.pdf", size: "620 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -100, to: referenceNow), content: .text("Sprint 1 retro: solid start. Let's tighten up the standup cadence though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -90, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Color system and typography scale are locked in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Found a race condition in the data sync layer. Fixing now. No blockers."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -70, to: referenceNow), content: .text("Dashboard queries are optimized. Sub-100ms on all endpoints now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -60, to: referenceNow), content: .event(title: "Mid-project Review", detail: "Fri Jan 9 · 3:00 PM · Zoom"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Onboarding flow is designed. Five screens. Clean and fast."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -40, to: referenceNow), content: .link(title: "CI/CD Pipeline dashboard", url: "https://ci.example/alpha-pipeline", description: "All green. 94% test coverage."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -30, to: referenceNow), content: .text("We're ahead of schedule. Prototype demo is looking solid for end of month."), delivery: .read, isStarred: true),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -16, to: referenceNow), content: .text("Kicking off Project Alpha. Goal is to have the prototype ready by end of month."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -16, to: referenceNow), content: .text("On it. I'll set up the repo and CI pipeline today."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -16, to: referenceNow), content: .text("I'll draft the data model and share it by tomorrow."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("I have the design system tokens ready. Will push them to Figma."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -12, to: referenceNow), content: .document(name: "data_model_v1.pdf", size: "1.2 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -12, to: referenceNow), content: .text("Looks great. One question about the user table schema, let's sync tomorrow."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -9, to: referenceNow), content: .text("CI is green. All tests passing. We're ready to start feature branches."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -6, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Component library preview. Buttons, cards, and nav are done."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("Beautiful work Iris. The spacing feels really clean."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("Sprint review is Thursday at 2. Everyone good with that?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("Works for me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Same. I'll have the onboarding flow mocked up by then."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.hour, -6, to: referenceNow), content: .event(title: "Sprint Review", detail: "Thu 2:00 PM · Zoom"), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "Rohan, Nadia, Iris",
                automatedReplies: [
                    AutomatedReply(senderID: rohanM.id, content: .text("Also, I fixed the auth token expiry bug. Should be smooth now.")),
                    AutomatedReply(senderID: nadiaK.id, content: .text("Nice. The dashboard queries are 3x faster with the new index.")),
                    AutomatedReply(senderID: irisY.id, content: .visual(moodBoard, kind: .photo, caption: "Onboarding flow v2. Simplified the steps from five to three."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 17. Dante Morales DM (general catch-up)
            // ───────────────────────────────────────
            ChatThread(
                id: danteThreadID,
                title: danteM.name,
                avatar: danteM.avatar,
                participantIDs: [danteM.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~12 months back) ──
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -350, to: referenceNow), content: .text("Dude I just found our old dorm playlist on Spotify. Instant time machine."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -349, to: referenceNow), content: .text("No way. Please tell me 'Midnight City' is on there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -349, to: referenceNow), content: .text("Track three. Right after that Tame Impala deep cut you were obsessed with."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -349, to: referenceNow), content: .link(title: "College Nights Playlist", url: "https://music.example/college-nights", description: "47 songs. Every single one hits different now."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -335, to: referenceNow), content: .text("How's the composing going? You still working on that indie film?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -334, to: referenceNow), content: .text("Yeah, it's a slow burn. Director keeps changing the tone. One day it's melancholy, next day it's hopeful. I'm writing two scores basically."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -334, to: referenceNow), content: .text("That sounds exhausting but also kind of exciting? You're basically writing the emotional DNA of the whole film."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -333, to: referenceNow), content: .text("That's a really good way to put it. I'm stealing that for my portfolio page."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -310, to: referenceNow), content: .audio(duration: "0:45", transcript: "Just demoed this cue for the opening scene. Sparse piano over field recordings. Tell me if it's too quiet or if the restraint works."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -309, to: referenceNow), content: .text("The restraint works. It gave me goosebumps honestly. The field recordings underneath are such a nice touch."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -309, to: referenceNow), content: .text("You always give the best feedback. Most people just say 'sounds good' and move on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -280, to: referenceNow), content: .text("We need to plan the annual reunion. Marcus keeps asking about it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -279, to: referenceNow), content: .text("October would be perfect. We could do a cabin somewhere upstate. Relive the glory days minus the bad decisions."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -278, to: referenceNow), content: .text("Minus MOST of the bad decisions. Some of them were character-building."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Have you seen 'Past Lives'? It wrecked me. The restraint in the storytelling is unreal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("Not yet but it's on my list. You always recommend the ones that make me feel things I wasn't prepared for."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("That's my brand. Emotional ambushes via film recommendations."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Found a taco truck on Venice that might be the best al pastor I've ever had. This is not hyperbole."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("Bold claim from the guy who said the same thing about three other trucks this year."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -219, to: referenceNow), content: .text("This time I mean it. I went back twice in one week."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Big news: the film got accepted into the Bay Area Film Fest. I might actually cry."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -180, to: referenceNow), content: .text("DANTE. That's huge. I'm so proud of you. When is it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -179, to: referenceNow), content: .text("Screening is in March. I'll send details when they post the schedule."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -140, to: referenceNow), content: .audio(duration: "0:32", transcript: "Holiday update: I'm back home in LA for a few weeks. Found a pristine copy of Kind of Blue on vinyl at a flea market. Sixty bucks. A steal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -139, to: referenceNow), content: .text("Miles Davis on vinyl for sixty bucks is basically theft. Well played. Enjoy being home."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -100, to: referenceNow), content: .link(title: "New Spotify playlist: Winter Noir", url: "https://music.example/winter-noir", description: "Dark jazz, ambient, and late-night piano. For the moody season."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("This is perfect for late work nights. You should score playlists for a living. Oh wait."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -70, to: referenceNow), content: .text("Started a new score commission. Documentary about migrant farmers. Heavy subject but the director has a beautiful vision."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -69, to: referenceNow), content: .text("That sounds like exactly the kind of project you were born for. Keep me posted on how it goes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("Reunion plans fell through but let's do something just the two of us. Tacos and catching up?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -39, to: referenceNow), content: .text("I'm down. After my launch wraps in March. It's consuming my entire life right now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -39, to: referenceNow), content: .text("No rush. The taco truck isn't going anywhere. Hopefully."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("Yo, long time. How've you been?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -20, to: referenceNow), content: .text("Dante! I'm good. Busy with a studio launch thing. You?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("Same energy over here. Just wrapped a short film score. It nearly killed me but it's done."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -19, to: referenceNow), content: .text("That's amazing. When can I hear it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -19, to: referenceNow), content: .audio(duration: "1:14", transcript: "Here's a clip from the main theme. Strings come in around the forty-second mark. Tell me what you think."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -18, to: referenceNow), content: .text("Dude. The strings section gave me chills. You're ridiculously talented."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -18, to: referenceNow), content: .text("Appreciate that more than you know. We should grab tacos when your launch is done."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -18, to: referenceNow), content: .text("Absolutely. The truck on 4th and Main?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -18, to: referenceNow), content: .text("The only correct choice."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -5, to: referenceNow), content: .link(title: "Film fest screening schedule", url: "https://filmfest.example/schedule", description: "My film screens Sunday at 4 PM. Come if you can."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -5, to: referenceNow), content: .text("I'll try my best. This launch is eating my weekends but I want to be there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("No pressure at all. Just knowing you listened to the theme means a lot."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen yesterday",
                automatedReplies: [
                    AutomatedReply(senderID: danteM.id, content: .text("The screening went well by the way. Full house. I'll send you the recording.")),
                    AutomatedReply(senderID: danteM.id, content: .text("Also, taco truck has a new al pastor option. Just saying.")),
                    AutomatedReply(senderID: danteM.id, content: .audio(duration: "0:18", transcript: "Okay I just tried the al pastor. It's phenomenal. We're going."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 18. Brunch Crew group (friend planning - dinners/brunch)
            // ───────────────────────────────────────
            ChatThread(
                id: brunchCrewThreadID,
                title: "Brunch Crew",
                avatar: AvatarSeed(topHex: 0x42251E, bottomHex: 0xEA8C68, initials: "BC", symbolName: "fork.knife"),
                participantIDs: [camille.id, kaiS.id, danteM.id],
                isGroup: true,
                communityID: nil,
                messages: [
                    // ── Historical messages ──
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Alright, making this group official. Monthly brunch is non-negotiable."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("I'm so in. Where are we starting?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Anywhere with good pancakes and I'm happy."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -195, to: referenceNow), content: .link(title: "Egg Shop - Williamsburg", url: "https://eggshop.example", description: "Best eggs in Brooklyn. No reservations needed."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -190, to: referenceNow), content: .text("Egg Shop was perfect. The shakshuka was incredible."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Next spot suggestion: that new place in Park Slope with the rooftop."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -170, to: referenceNow), content: .text("The one with the lavender lattes? I've been dying to try it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Can we do somewhere with vegan options next time? Trying something new."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Absolutely. I know a great plant-based cafe in the East Village."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -130, to: referenceNow), content: .link(title: "Avant Garden Brunch", url: "https://avantgarden.example/brunch", description: "Plant-based brunch with a beautiful garden patio"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Sorry I have to bail on this Sunday. Work emergency. Save me a pastry?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -110, to: referenceNow), content: .text("No worries. We'll take photos of everything you're missing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -80, to: referenceNow), content: .poll(question: "Next neighborhood to explore for brunch?", choices: [PollChoice(title: "Bushwick", votes: 1), PollChoice(title: "Greenpoint", votes: 2), PollChoice(title: "Lower East Side", votes: 1)]), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Greenpoint wins! I know the perfect spot. Trust me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -40, to: referenceNow), content: .text("We skipped last month. This cannot happen again. Scheduling now."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("Okay the monthly brunch needs to happen this month. No excuses."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("I'm free every Sunday. Just pick one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("Same. Bonus points if the place has bottomless mimosas."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -12, to: referenceNow), content: .text("March 15? That's the Sunday after my launch. I'll need it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("Perfect. I know a new spot in the West Village with a garden patio."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -8, to: referenceNow), content: .link(title: "The Garden Table", url: "https://gardentable.example", description: "Farm-to-table brunch, great pastries, and outdoor seating."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: kaiS.id, sentAt: adding(.day, -8, to: referenceNow), content: .text("This place looks incredible. I'm already hungry."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: danteM.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("I looked at the menu. The ricotta pancakes are calling my name."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("Reservation for four at 11?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("Booked. See you all there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: camille.id, sentAt: adding(.day, -1, to: referenceNow), content: .event(title: "Brunch @ The Garden Table", detail: "Sun Mar 15 · 11:00 AM"), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "Camille, Kai, Dante",
                automatedReplies: [
                    AutomatedReply(senderID: kaiS.id, content: .text("Can't wait. Should I bring anything?")),
                    AutomatedReply(senderID: camille.id, content: .text("Just your appetite and good stories.")),
                    AutomatedReply(senderID: danteM.id, content: .text("I have both. Plus a new al pastor taco story that will change lives."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 19. Rohan Mehta DM (work friend catch-up)
            // ───────────────────────────────────────
            ChatThread(
                id: rohanThreadID,
                title: rohanM.name,
                avatar: rohanM.avatar,
                participantIDs: [rohanM.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~8 months back) ──
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Hey, welcome to the team! I'm Rohan. I sit near the ping pong table if you ever need anything."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -250, to: referenceNow), content: .text("Thanks! Good to meet you. I've heard the ping pong scene here is intense."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("Intense is one word for it. I'm undefeated this quarter. Fair warning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -240, to: referenceNow), content: .text("Quick question: is there a wiki page for the deploy process? I keep getting stuck on the staging step."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -240, to: referenceNow), content: .link(title: "Deploy Runbook v3", url: "https://wiki.example/deploy-runbook", description: "Step-by-step guide. The staging gotcha is on page 4."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("You're a lifesaver. That env variable section cleared everything up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Heads up: staging is down. Looks like a bad config push. I'm rolling it back now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -220, to: referenceNow), content: .text("Thanks for the heads up. Need help debugging?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Found it. Someone hardcoded a prod URL in the test config. Classic."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Ping pong after standup? I need to defend my title."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -200, to: referenceNow), content: .text("You're on. I've been practicing my serve."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Okay that serve was actually nasty. I'm shook. Rematch tomorrow."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -180, to: referenceNow), content: .text("Have you read 'Designing Data-Intensive Applications'? Someone on the team recommended it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -179, to: referenceNow), content: .text("It's the best technical book I've ever read. The chapter on replication changed how I think about distributed systems."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -160, to: referenceNow), content: .text("Happy hour tonight? A few of us are heading to that rooftop bar on 3rd."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -160, to: referenceNow), content: .text("I'm in. I'll rally the backend team too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Just got back from re:Invent. So many talks on serverless. My brain is full."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Anything worth sharing with the team? I'm curious about the observability talks."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -129, to: referenceNow), content: .document(name: "reinvent_notes.pdf", size: "2.1 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -129, to: referenceNow), content: .text("Compiled my notes. The OpenTelemetry talk on page 8 is the one you'll care about most."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Side project idea: what if we built a TeamChat bot that summarizes PR reviews? I keep missing context in long threads."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("I've thought about the exact same thing. We could use the OpenAI API for summarization."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -89, to: referenceNow), content: .text("Let's prototype it over a weekend. Hackathon energy."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -60, to: referenceNow), content: .text("Reading 'The Pragmatic Programmer' on your recommendation. The rubber duck debugging chapter is gold."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -59, to: referenceNow), content: .text("Right? I keep a literal rubber duck on my desk now. The team thinks I'm weird but it works."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -35, to: referenceNow), content: .text("Ping pong score update: you've won 12, I've won 14. The rivalry lives on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -35, to: referenceNow), content: .text("I'm coming for that lead. Best of three this week?"), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("Hey, wanted to flag something before standup. The deploy pipeline has a flaky test on the auth module."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -15, to: referenceNow), content: .text("Is it the token refresh one? That's been intermittent for weeks."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("Yep. I'll add a retry and a proper timeout. Should fix it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("Fixed. Pipeline is green for the last 20 runs. We're clean."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("You're the best. I owe you a coffee."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -6, to: referenceNow), content: .text("Unrelated: have you tried that new telescope app? The sky was insane last night."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("No but now I need to. Send me the link."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -6, to: referenceNow), content: .link(title: "SkyView app", url: "https://apps.example/skyview", description: "Point your phone at the sky and it labels everything. Stars, planets, satellites."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: rohanM.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Sprint retro went well. Team morale is high. Good week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -14, to: referenceNow), content: .text("Agreed. Let's keep this momentum into the prototype."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 3h ago",
                automatedReplies: [
                    AutomatedReply(senderID: rohanM.id, content: .text("For sure. I'll start the API integration branch tonight.")),
                    AutomatedReply(senderID: rohanM.id, content: .text("Also, there's a meteor shower next week. We should find a dark spot.")),
                    AutomatedReply(senderID: rohanM.id, content: .link(title: "Meteor shower viewing guide", url: "https://astro.example/meteor-mar", description: "Best viewing window is Tuesday 11 PM to 2 AM."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 20. Iris Yamamoto DM (creative friend)
            // ───────────────────────────────────────
            ChatThread(
                id: irisThreadID,
                title: irisY.name,
                avatar: irisY.avatar,
                participantIDs: [irisY.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~7 months back) ──
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Hey Jordan! I'm having a small ceramics workshop at my studio next Saturday. Want to come throw some pots?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("I've never done ceramics but that sounds amazing. Count me in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Perfect. I'll have the wheel set up. Wear something you don't mind getting clay on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -192, to: referenceNow), content: .text("That workshop was incredible. My bowl looks like a kindergartner made it but I love it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -192, to: referenceNow), content: .text("It has character! I'll glaze and fire it for you. What color family are you thinking?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -191, to: referenceNow), content: .text("Something earthy? Sage green or a warm terracotta."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -191, to: referenceNow), content: .text("Sage green it is. Great eye. That'll pair beautifully with the texture."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -175, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Gallery opening tonight! These are the pieces going up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -175, to: referenceNow), content: .text("These are gorgeous. The tall vessel in the back is stunning. Is that a new glaze technique?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -174, to: referenceNow), content: .text("Yes! Layered ash glaze. Took me three months of testing to get that finish. It reacts differently every firing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -155, to: referenceNow), content: .text("I've been in a creative block for two weeks. Nothing feels right. Everything I make ends up in the reclaim bucket."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -154, to: referenceNow), content: .text("That sounds frustrating. Sometimes stepping away helps. Want to grab coffee and talk through it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -154, to: referenceNow), content: .text("Yes please. That little place on Oak Street? They have the best pour-over and the light is perfect for sketching."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -148, to: referenceNow), content: .text("Coffee session helped so much. I sketched twelve new forms on the train ride home. Thank you for listening."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -147, to: referenceNow), content: .text("Anytime. That's what friends are for. Can't wait to see what you make next."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -120, to: referenceNow), content: .link(title: "Color palette inspo", url: "https://design.example/autumn-palette", description: "Found this palette and thought of your apartment. Dusty rose, cream, and warm gray."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("You know my taste better than I do. Those tones are exactly what I'd pick."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("I have a wild idea. What if we collaborated on something? Your design sense plus my ceramics. Custom pieces for your launch event?"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("I love that idea. Handmade centerpieces would make the venue feel so special. Let's sketch something out."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -60, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "First batch of collaboration prototypes. Small planters and catch-all dishes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("Iris these are beautiful. The proportions are perfect. Can we do twenty for the event tables?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -59, to: referenceNow), content: .text("Twenty is doable. I'll need about four weeks. The kiln schedule is tight but I'll make it work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -35, to: referenceNow), content: .text("My friend's birthday is coming up. Any gift ideas from your shop? She loves minimalist home stuff."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -34, to: referenceNow), content: .link(title: "Iris Yamamoto ceramics shop", url: "https://shop.example/iris-ceramics", description: "The incense holders and bud vases are my bestsellers."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -34, to: referenceNow), content: .text("The bud vase in speckled cream is perfect. Ordering now. Thanks!"), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("Hey! I have a ceramics show coming up and I made something for you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("Wait really? That's so thoughtful. What is it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("A pour-over dripper. Glazed in this ocean blue that reminded me of your apartment."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -12, to: referenceNow), content: .text("I love that. When's the show?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -12, to: referenceNow), content: .event(title: "Iris Yamamoto ceramics show", detail: "Mar 22 · 5-9 PM · Beacon Gallery"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -7, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "Kiln day. These are all going in the show."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("These are stunning. The glaze work is so clean."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Thank you! Sixteen hours of sanding will do that."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("How's the component library coming along? I pushed the latest tokens."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Looks great. The spacing scale is perfect. Rohan and I integrated it already."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: irisY.id, sentAt: adding(.hour, -10, to: referenceNow), content: .text("Amazing. Also, save the 22nd for the show! I'll put your name at the door."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "last seen 2h ago",
                automatedReplies: [
                    AutomatedReply(senderID: irisY.id, content: .text("Gallery just confirmed catering. There will be wine and small bites.")),
                    AutomatedReply(senderID: irisY.id, content: .visual(kitchenNotes, kind: .photo, caption: "Your pour-over dripper, fresh out of the kiln. It turned out perfect.")),
                    AutomatedReply(senderID: irisY.id, content: .text("Can't wait for you to see it in person."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 21. Grace Lin DM (book club friend)
            // ───────────────────────────────────────
            ChatThread(
                id: graceThreadID,
                title: graceL.name,
                avatar: graceL.avatar,
                participantIDs: [graceL.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~250 days back) ──
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Jordan! So glad you joined the book club. We just picked our next read and I think you'll love it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("I've been meaning to read more this year so the timing is perfect. What's the pick?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("'The Goldfinch' by Donna Tartt. Dense but beautiful. We have three weeks."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -240, to: referenceNow), content: .text("Okay I'm 80 pages in and completely hooked. The museum scene destroyed me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -239, to: referenceNow), content: .text("Right?? Tartt's pacing is so deliberate. Every sentence earns its place."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -225, to: referenceNow), content: .link(title: "The Paris Review - Donna Tartt interview", url: "https://theparisreview.example/tartt-interview", description: "She talks about spending ten years on a single novel. Incredible discipline."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -224, to: referenceNow), content: .text("Ten years! That makes me feel better about taking a week to write one email."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -210, to: referenceNow), content: .text("Book club discussion was so good tonight. I loved your point about unreliable narrators."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -209, to: referenceNow), content: .text("Thanks! Your take on the art restoration metaphor blew my mind. I hadn't even considered that angle."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Next pick is a memoir: 'Educated' by Tara Westover. Have you read it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("It's been on my list forever. Finally have an excuse."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -185, to: referenceNow), content: .text("Do you prefer audiobooks or physical copies? I've been going back and forth."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -184, to: referenceNow), content: .text("Physical for fiction, audiobooks for nonfiction. Something about holding a novel just feels different."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -184, to: referenceNow), content: .text("Completely agree. The smell of a new book is half the experience."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Found the coziest reading nook at that cafe on Elm Street. Window seat, afternoon sun, perfect silence."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -169, to: referenceNow), content: .text("I need to check that out. My apartment has terrible reading light."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -155, to: referenceNow), content: .document(name: "reading_challenge_2026.pdf", size: "340 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -155, to: referenceNow), content: .text("I made a reading challenge tracker for the year. 52 books. One a week. Want to do it together?"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -154, to: referenceNow), content: .text("52 is ambitious but I'm in. I'm at book 4 right now so I need to catch up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -140, to: referenceNow), content: .text("There's an author event at the library next week. Ocean Vuong is reading from his new collection."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -139, to: referenceNow), content: .text("Ocean Vuong?? I'll be there. His poetry makes me want to quit everything and just write."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -125, to: referenceNow), content: .text("That reading was transcendent. I cried twice and I'm not even embarrassed about it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -124, to: referenceNow), content: .text("Same. The one about his mother had me completely undone. Have you ever tried writing poetry yourself?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -124, to: referenceNow), content: .text("I journal every morning and sometimes a poem sneaks out. Nothing I'd share though. Not yet."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -110, to: referenceNow), content: .text("I'd love to read something of yours someday. No pressure though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -90, to: referenceNow), content: .link(title: "Literary Hub - Best memoirs of the decade", url: "https://lithub.example/best-memoirs", description: "Great list. 'Crying in H Mart' is number one and I couldn't agree more."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("'Crying in H Mart' wrecked me. I called my mom right after finishing it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -70, to: referenceNow), content: .text("Library haul today: three novels, two poetry collections, and a writing craft book. My bag weighed a ton."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -69, to: referenceNow), content: .text("That's the best kind of heavy bag. What writing craft book did you grab?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -69, to: referenceNow), content: .text("'Bird by Bird' by Anne Lamott. Everyone says it's the one to start with."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("I actually wrote a poem this morning and I don't hate it. That feels like progress."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("That IS progress! Celebrate the small wins. What's it about?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -49, to: referenceNow), content: .text("Morning light through the kitchen window. Simple, but it felt true."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Reading challenge update: I'm at book 9. You?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Book 7. I got stuck on a 600-page behemoth. But I'm catching up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -15, to: referenceNow), content: .document(name: "grace_poem_draft.pdf", size: "45 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("Okay I'm doing it. Here's the kitchen window poem. Be honest but gentle."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -14, to: referenceNow), content: .text("Grace. This is genuinely beautiful. The last stanza gave me chills. You should share this with the group."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("That means more than you know. Maybe I will. Baby steps."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Book club picked 'Pachinko' for next month. Have you read it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("Not yet but I've heard it's incredible. Multi-generational family saga, right?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -6, to: referenceNow), content: .text("Yes. Spanning four generations. The prose is supposedly breathtaking."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.day, -2, to: referenceNow), content: .link(title: "Pachinko - Min Jin Lee", url: "https://bookshop.example/pachinko", description: "National Book Award finalist. 'A powerful family chronicle.'"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Just ordered it. Physical copy of course."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: graceL.id, sentAt: adding(.hour, -6, to: referenceNow), content: .text("Same. There's something about cracking open a new spine. Happy reading!"), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 4h ago",
                automatedReplies: [
                    AutomatedReply(senderID: graceL.id, content: .text("I already read the first chapter of Pachinko on my lunch break. Hooked.")),
                    AutomatedReply(senderID: graceL.id, content: .text("Also, the library is having a poetry open mic next month. Want to come?")),
                    AutomatedReply(senderID: graceL.id, content: .text("No pressure to read anything. Just being in the audience is enough."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 22. Felix Oduya DM (roommate / vinyl collector)
            // ───────────────────────────────────────
            ChatThread(
                id: felixThreadID,
                title: felixO.name,
                avatar: felixO.avatar,
                participantIDs: [felixO.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~200 days back) ──
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Dude. I just found a first pressing of Rumours at that spot on Atlantic Ave. I'm shaking."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("NO WAY. How much? Is it in good shape?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("$45 and the sleeve is near mint. The vinyl has a couple surface marks but plays clean."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -190, to: referenceNow), content: .text("Hey quick apartment thing - the bathroom drain is super slow. Did you notice?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -190, to: referenceNow), content: .text("Yeah it's been bugging me for a week. I'll grab some drain cleaner on my way home."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -175, to: referenceNow), content: .text("Record Store Day is April 12 this year. Want to hit up a few shops early?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("Absolutely. What time do those places open? I'm guessing there'll be a line."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -174, to: referenceNow), content: .text("Most open at 8 but people start lining up at 6. I'll set an alarm."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -160, to: referenceNow), content: .audio(duration: "0:42", transcript: "Quick thought - I've been messing with the turntable alignment and I think the anti-skate was off. The right channel sounds way cleaner now. Come listen when you're home."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Oh nice. I noticed some distortion on the inner grooves last week. That might fix it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -145, to: referenceNow), content: .text("I'm making jerk chicken tonight. There's going to be enough for everyone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -144, to: referenceNow), content: .text("Your jerk chicken is the reason I renewed the lease. Save me a plate."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -130, to: referenceNow), content: .link(title: "Vinyl Me Please - March selections", url: "https://vinylmeplease.example/march", description: "This month's essentials pick is a remastered Fela Kuti album. Might have to subscribe."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Fela Kuti on fresh vinyl? That's worth it. The pressings are usually really high quality too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -115, to: referenceNow), content: .text("Late night thought: do you think we chose our careers or did our careers choose us?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -114, to: referenceNow), content: .text("That's deep for a Tuesday. I think I stumbled into mine and then decided to stay. You?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -114, to: referenceNow), content: .text("Same honestly. I never planned to end up in logistics but I'm weirdly good at it. Maybe that's enough."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -95, to: referenceNow), content: .audio(duration: "1:05", transcript: "Hey, just discovered this band called Khruangbin. Their guitar tone is incredible. I left the album playing on the turntable if you want to listen when you get home. Side A is the one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -94, to: referenceNow), content: .text("Listened to the whole thing. The bass lines are hypnotic. Adding them to my list."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -75, to: referenceNow), content: .text("Weekend plan: I'm thinking a farmers market run Saturday morning, then I'll cook something new."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -74, to: referenceNow), content: .text("I'm down for the market. I need fresh herbs for that pasta recipe I've been wanting to try."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -55, to: referenceNow), content: .link(title: "Discogs - rare finds alert", url: "https://discogs.example/rare-soul", description: "Someone in Brooklyn is selling a collection of 70s soul 45s. This could be a goldmine."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -54, to: referenceNow), content: .text("Want to go check it out this weekend? I'll drive."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("I'm reorganizing the living room shelves. Any opinion on alphabetical vs genre for the vinyl collection?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Genre first, then alphabetical within genre. It's the only way that makes sense."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Thinking about getting a better cartridge for the turntable. The Ortofon 2M Red is on sale."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("Do it. The upgrade from the stock stylus is night and day. My friend had one and the difference was wild."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -7, to: referenceNow), content: .audio(duration: "0:28", transcript: "Just installed the new cartridge. Put on Kind of Blue and I swear I heard instruments I'd never noticed before. The imaging is insane."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("That's the audiophile bug biting. Next thing you know you'll be buying tube amps."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Don't tempt me. Also, are you good for rent on the 1st? Just checking."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("Already sent it. Check SplitPay."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.day, -1, to: referenceNow), content: .text("Got it. Thanks. Hey, want to do a listening session tonight? I grabbed a new D'Angelo pressing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -20, to: referenceNow), content: .text("D'Angelo on that new cartridge? Say less. I'll bring snacks."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: felixO.id, sentAt: adding(.hour, -4, to: referenceNow), content: .text("Perfect. I'll have the setup dialed in by 8."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "online recently",
                automatedReplies: [
                    AutomatedReply(senderID: felixO.id, content: .text("Voodoo is spinning right now. Hurry up.")),
                    AutomatedReply(senderID: felixO.id, content: .text("Also I made popcorn. The good kind with the nutritional yeast.")),
                    AutomatedReply(senderID: felixO.id, content: .text("This cartridge was the best purchase I've made all year."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 23. Nadia Kovacs DM (roommate / data viz nerd)
            // ───────────────────────────────────────
            ChatThread(
                id: nadiaThreadID,
                title: nadiaK.name,
                avatar: nadiaK.avatar,
                participantIDs: [nadiaK.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~200 days back) ──
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Hey, can I pick your brain about something? I'm working on a data viz portfolio piece and want a designer's eye."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("Of course! Send me what you have. I love looking at data viz stuff."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -199, to: referenceNow), content: .link(title: "Nadia's D3.js dashboard prototype", url: "https://observable.example/nadia-dash", description: "Interactive climate data dashboard. Still rough but the interactions are there."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -198, to: referenceNow), content: .text("This is really impressive. The color scale works perfectly. Only note: the tooltip font is a bit small on mobile."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -185, to: referenceNow), content: .text("Have you been to that coffee shop on Bergen? It's become my WFH office. Great wifi and nobody talks to you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -184, to: referenceNow), content: .text("The one with the exposed brick? I've walked past it a hundred times but never gone in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -184, to: referenceNow), content: .text("Go. The oat milk cortado is perfect and there's a big communal table by the window. I'll be there tomorrow if you want to cowork."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Career question: I got approached by a startup for a senior data engineer role. More money but less stability. Thoughts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -169, to: referenceNow), content: .text("What's the product? If you believe in what they're building, the risk might be worth it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -169, to: referenceNow), content: .text("Climate tech. Carbon tracking for supply chains. It's genuinely meaningful work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -168, to: referenceNow), content: .text("That sounds like a perfect fit for you. I'd take the meeting at least."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Python vs R debate: go. I need ammunition for a work argument."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("Python for production, R for exploration and stats. Use both. The debate is fake."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("Diplomatic answer but you're probably right. My coworker is a die-hard R purist though."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -130, to: referenceNow), content: .link(title: "Creative coding with p5.js", url: "https://p5js.example/generative-art", description: "Started experimenting with generative art. This tutorial is a great starting point."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Oh this is cool. The intersection of code and art is so underexplored."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("There's a data viz conference in Chicago next month. Want to go? The speaker lineup is incredible."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("Send me the details. I could definitely make a case for it as professional development."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -109, to: referenceNow), content: .document(name: "dataviz_conf_agenda.pdf", size: "890 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Weekend coding session? I want to build a side project and could use a thought partner."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("I'm in. What's the idea?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -89, to: referenceNow), content: .text("A personal dashboard that visualizes my daily habits. Sleep, steps, reading time, coffee intake."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -88, to: referenceNow), content: .text("That's such a you project. I'll handle the UI design if you handle the data pipeline."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -70, to: referenceNow), content: .link(title: "Podcast: Data Stories ep 204", url: "https://datastori.es/example/204", description: "This episode on ethical data visualization is a must-listen. Changed how I think about chart defaults."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -69, to: referenceNow), content: .text("Added to my queue. I've been meaning to get more into data ethics."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Side project update: the habits dashboard is live! At least a local version. Want to see?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Obviously. Screenshot or screen share?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("That coffee shop on Bergen closed for renovations. I'm devastated. Need a new WFH spot."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("There's a new place on Smith Street that has a similar vibe. Quiet, good wifi, great pastries."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Checked it out today. You were right. The almond croissant alone is worth the walk."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Got the conference tickets! Chicago in April. This is going to be amazing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Let's go! I'll look into flights this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.hour, -8, to: referenceNow), content: .text("Also, I finally tried that generative art technique. The results are wild."), delivery: .delivered, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nadiaK.id, sentAt: adding(.hour, -7, to: referenceNow), content: .link(title: "Nadia's generative art experiments", url: "https://observable.example/nadia-gen-art", description: "Algorithmic landscapes using Perlin noise. Each one is unique."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 2,
                pinned: false,
                muted: false,
                subtitle: "last seen 1h ago",
                automatedReplies: [
                    AutomatedReply(senderID: nadiaK.id, content: .text("Want to do a coworking session at the new cafe tomorrow?")),
                    AutomatedReply(senderID: nadiaK.id, content: .text("I'll bring my laptop and we can iterate on the dashboard design.")),
                    AutomatedReply(senderID: nadiaK.id, content: .text("Also the conference hotel has a rooftop bar. Just saying."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 24. Miles Chen DM (college friend, data scientist)
            // ───────────────────────────────────────
            ChatThread(
                id: milesThreadID,
                title: milesC.name,
                avatar: milesC.avatar,
                participantIDs: [milesC.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~180 days back) ──
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("JORDAN. I just saw your name on LockedIn. It's been what, four years? How are you??"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("MILES! No way! I'm great, living in Brooklyn now. What about you? Last I heard you were heading to NYC."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -179, to: referenceNow), content: .text("Still here! Working as a data scientist at a fintech startup in Midtown. NYC swallowed me whole and I never left."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -178, to: referenceNow), content: .text("That's awesome. Remember when we pulled that all-nighter for Professor Kim's stats final? Good times."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -178, to: referenceNow), content: .text("That final almost ended me. But we passed! Barely. I think about that study room in the library sometimes."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -160, to: referenceNow), content: .text("We should meet up. I come to Brooklyn every other weekend for the food scene alone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Absolutely. Name a weekend and I'll make it work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -145, to: referenceNow), content: .text("Okay career update: I just got promoted to senior data scientist. The imposter syndrome is REAL."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -144, to: referenceNow), content: .text("Congrats!! You deserve it. The imposter syndrome never goes away, you just get better at ignoring it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("SF vs NYC debate: go. I know you moved from the Bay Area. Do you miss it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("I miss the weather and the burritos. That's about it. Brooklyn has everything else."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -129, to: referenceNow), content: .text("Fair. NYC has the energy though. You can't replicate that walk-everywhere lifestyle."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Fantasy football update: I'm in last place. My draft strategy of all running backs was a mistake."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("ALL running backs?? Miles. That's not a strategy, that's chaos."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -109, to: referenceNow), content: .text("In my defense the model I built predicted it would work. Turns out my model was garbage."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -85, to: referenceNow), content: .link(title: "Severance Season 3 trailer", url: "https://tv.example/severance-s3", description: "Have you been watching this show? It's the best thing on TV right now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -84, to: referenceNow), content: .text("I binged both seasons in a weekend. The office floor scenes are so unsettling. Can't wait for S3."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Dating in NYC is a full-contact sport. I just had someone cancel on me via LockedIn message."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("Via LINKEDIN?? That's a new low. Or a new high? I can't tell anymore."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("I'm thinking about visiting Brooklyn next month. You around mid-March?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Should be! I have a launch thing early March but after that I'm free."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Perfect. I'll aim for the weekend of the 21st. We can do a proper catch-up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("I'll take you to my favorite ramen spot. It'll ruin all other ramen for you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Bold claim. I've had ramen in Tokyo. But I'm ready to be proven wrong."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.day, -2, to: referenceNow), content: .link(title: "Tech Twitter drama thread", url: "https://twitter.example/tech-drama", description: "Another startup founder meltdown. This one involves a yacht and an SEC filing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -1, to: referenceNow), content: .text("The yacht detail is wild. Silicon Valley never disappoints."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: milesC.id, sentAt: adding(.hour, -5, to: referenceNow), content: .text("Booked my train for the 21st. See you soon!"), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 3h ago",
                automatedReplies: [
                    AutomatedReply(senderID: milesC.id, content: .text("Also, I need restaurant recommendations. I want to eat my way through Brooklyn.")),
                    AutomatedReply(senderID: milesC.id, content: .text("And is that pizza place from college still around? The one with the garlic knots?")),
                    AutomatedReply(senderID: milesC.id, content: .text("Never mind, I'll just follow you around and eat whatever you eat."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 25. Jasmine Obi DM (yoga instructor / wellness friend)
            // ───────────────────────────────────────
            ChatThread(
                id: jasmineThreadID,
                title: jasmineO.name,
                avatar: jasmineO.avatar,
                participantIDs: [jasmineO.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~150 days back) ──
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Hey Jordan! I saw you at the Saturday morning class. So glad you came! How are you feeling?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("Honestly? My hamstrings are screaming. But in a good way. That flow was incredible."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("Ha! That's the sign of a good stretch. Come again next week and it'll feel easier, I promise."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -135, to: referenceNow), content: .link(title: "Insight Timer - guided meditation", url: "https://insighttimer.example/morning-calm", description: "This 10-minute morning meditation changed my whole routine. Try it before your coffee."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -134, to: referenceNow), content: .text("Before coffee? That's asking a lot. But I'll try it. I need to be better about mornings."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("How did the meditation go? Be honest."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("I did it three times this week! The first time I fell back asleep. But by the third time I actually felt calmer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("That's progress! The falling asleep part is totally normal. Your body needed the rest."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -105, to: referenceNow), content: .text("I'm leading a breathwork workshop next Saturday. It's different from yoga - more focused on nervous system regulation. Interested?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -104, to: referenceNow), content: .text("I don't know much about breathwork but I trust your recommendations. Count me in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -90, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Morning walk through the botanical garden. This is my church."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("That's beautiful. I need more nature in my life. My screen time report this week was embarrassing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -89, to: referenceNow), content: .text("Let's do a nature walk this weekend. No phones for an hour. Just trees and fresh air."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -75, to: referenceNow), content: .text("Made a turmeric golden milk latte tonight. It's my new evening ritual. Want the recipe?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -74, to: referenceNow), content: .text("Yes please! I've been trying to cut back on coffee after 2pm and need alternatives."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -74, to: referenceNow), content: .text("Oat milk, turmeric, cinnamon, black pepper, maple syrup. Warm it slow. It's a hug in a mug."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -55, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Sunrise yoga on the rooftop this morning. Caught this light between poses."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -54, to: referenceNow), content: .text("That light is unreal. You make 6am look appealing. Almost."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -40, to: referenceNow), content: .link(title: "Wellness retreat in the Catskills", url: "https://retreat.example/catskills-spring", description: "Three days, yoga, meditation, farm-to-table meals, and forest bathing. April dates just dropped."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -39, to: referenceNow), content: .text("Forest bathing? I'm intrigued and slightly confused. But the Catskills in spring sounds amazing."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -20, to: referenceNow), content: .text("Sleep tip that actually works: no screens 30 minutes before bed, chamomile tea, and a body scan meditation."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -19, to: referenceNow), content: .text("I tried the body scan last night. Fell asleep before I got past my knees. So... success?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -19, to: referenceNow), content: .text("That IS success. That's literally the point."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("New class schedule is up! I added a Sunday evening restorative session. Perfect for end-of-weekend decompression."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -9, to: referenceNow), content: .text("Sunday evening is perfect timing. I always dread Mondays less when I end Sunday on a calm note."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("I'm recommending a new herbal tea: lemon balm with lavender. It's like drinking a deep breath."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("'Drinking a deep breath' is the most Jasmine description ever. I'll grab some at the market."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.hour, -12, to: referenceNow), content: .text("See you at the Saturday class tomorrow? I'm teaching a new hip opener sequence."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -11, to: referenceNow), content: .text("Wouldn't miss it. My hips are practically concrete at this point."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: jasmineO.id, sentAt: adding(.hour, -3, to: referenceNow), content: .text("We'll fix that. Bring water and an open mind."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: "last seen 2h ago",
                automatedReplies: [
                    AutomatedReply(senderID: jasmineO.id, content: .text("Class was wonderful today. Your pigeon pose is really improving!")),
                    AutomatedReply(senderID: jasmineO.id, content: .text("Also, I'm hosting a sound bath next Friday. Singing bowls and everything. You in?")),
                    AutomatedReply(senderID: jasmineO.id, content: .text("It's deeply relaxing. Most people fall asleep and that's totally okay."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 26. Tomas Vega DM (neighbor / building friend)
            // ───────────────────────────────────────
            ChatThread(
                id: tomasThreadID,
                title: tomasV.name,
                avatar: tomasV.avatar,
                participantIDs: [tomasV.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~120 days back) ──
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Hey, you're in 4B right? I'm Tomas from 4D. I think I have a package of yours."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("Oh hey! Yes that's me. Thank you so much, I've been waiting for that one. I'll swing by after work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("No rush. I'll leave it by your door if I step out. Also, welcome to the floor! How long have you been here?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -118, to: referenceNow), content: .text("About six months now. Still getting used to the elevator schedule. Is it always this slow?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -118, to: referenceNow), content: .text("Always. I take the stairs most days. Good exercise and you avoid the awkward small talk."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -105, to: referenceNow), content: .text("Heads up - building management sent a notice about water shut-off tomorrow 9am to noon. Just in case you missed the email."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -104, to: referenceNow), content: .text("I did miss it. Thanks for the heads up. I'll fill some bottles tonight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Sorry if my music was loud last night. Had some friends over and lost track of time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("Honestly I didn't hear a thing. These walls are surprisingly solid. No worries at all."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Random question: do you have a Phillips head screwdriver I could borrow? My shelf bracket is loose."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("Yeah I have a whole toolkit. Come grab whatever you need. I'm home all evening."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -79, to: referenceNow), content: .text("You're a lifesaver. I'll bring it back with a beer as a thank you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -65, to: referenceNow), content: .link(title: "Taqueria Los Hermanos", url: "https://loshermaos.example/menu", description: "Found the best tacos within walking distance. The al pastor is life-changing."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -64, to: referenceNow), content: .text("Life-changing tacos? That's a strong claim but I'm willing to investigate."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Rooftop is open tonight. Weather is perfect. A few of us from the building are heading up around 7."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("I'll be there. Should I bring anything?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -49, to: referenceNow), content: .text("Just yourself. I've got drinks covered. Maria from 5A is bringing snacks."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -25, to: referenceNow), content: .text("Trash day reminder: they moved it to Wednesday this week because of the holiday."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -24, to: referenceNow), content: .text("Good looking out. I would have put it out Tuesday night and been confused."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("My dog got out of the apartment this morning and was just sitting in front of your door. I think she likes you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("Ha! I saw her when I opened the door. She looked very polite about it. What's her name?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -13, to: referenceNow), content: .text("Luna. She's a golden retriever with zero boundaries and maximum friendliness."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -7, to: referenceNow), content: .event(title: "Building rooftop BBQ", detail: "Sat Mar 15 · 5:00 PM · Rooftop"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Building management approved a rooftop BBQ. Everyone on the 4th and 5th floors is invited."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -6, to: referenceNow), content: .text("Count me in. I'll bring that pasta salad recipe I've been perfecting."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("Another package at your door. This one is heavy. What are you ordering, bricks?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -1, to: referenceNow), content: .text("Books. Which are basically bricks. Thanks for the heads up!"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: tomasV.id, sentAt: adding(.hour, -5, to: referenceNow), content: .text("Luna says hi. She's parked outside your door again."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: "last seen 1h ago",
                automatedReplies: [
                    AutomatedReply(senderID: tomasV.id, content: .text("She just wants attention. Feel free to give her a treat if you have one.")),
                    AutomatedReply(senderID: tomasV.id, content: .text("Also, I found another taco spot that might be even better. El Rey on Smith Street.")),
                    AutomatedReply(senderID: tomasV.id, content: .text("Want to grab some this weekend after the BBQ?"))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 27. Sofia Kim DM (travel buddy)
            // ───────────────────────────────────────
            ChatThread(
                id: sofiaThreadID,
                title: sofia.name,
                avatar: sofia.avatar,
                participantIDs: [sofia.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~220 days back) ──
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Ok I'm officially obsessed with planning our Portugal trip. Lisbon first, then Porto?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("Lisbon first makes sense. I want at least three days there before we head north."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -215, to: referenceNow), content: .link(title: "StayFinder - Alfama rooftop flat", url: "https://stayfinder.example/lisbon-alfama-rooftop", description: "Two bedrooms, private terrace with a view of the Tagus. Under budget."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -214, to: referenceNow), content: .text("That terrace view is unreal. Book it before someone else does."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -210, to: referenceNow), content: .text("BOOKED. Also started a packing list. Layers are key for October in Portugal apparently."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -205, to: referenceNow), content: .text("Smart. I always overpack. Need your help editing my suitcase before we leave."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Deal. Also my travel credit card just hit 80k points. We might be able to upgrade one of the flights."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -198, to: referenceNow), content: .text("Wait how do you have that many points? I've had my card for a year and I barely have 20k."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -197, to: referenceNow), content: .text("Put everything on it. Groceries, gas, subscriptions. Then pay it off immediately. The sign-up bonus helped a lot too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -180, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Flight deal alert! SF to Lisbon nonstop, $489 round trip. Expires tonight."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -180, to: referenceNow), content: .text("Just bought it. That's insanely cheap. Good looking out."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -165, to: referenceNow), content: .text("Random but do you have a good travel photography setup? I'm debating between bringing my mirrorless or just using my phone."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -164, to: referenceNow), content: .text("Phone honestly. Less weight, less stress about losing gear. The new cameras on these phones are insane."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Adding Japan to the 2027 wishlist. Cherry blossom season. Just putting it on your radar early."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("I have wanted to go to Japan my entire life. Say less. I'm already mentally there."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Portugal research update: apparently the pastéis de nata in Belém are a spiritual experience. We need to go first morning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("I've seen so many reels about those. Adding it to the must-eat list right now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -110, to: referenceNow), content: .link(title: "Duolingo - Portuguese basics", url: "https://duolingo.example/portuguese", description: "Started a streak for Portuguese. Join me so we can at least order food without pointing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("Downloading now. If I lose my streak it's on you."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Cultural tip I read: dinner in Lisbon doesn't start until like 8 or 9 PM. We need to adjust our whole schedule."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("Fine by me. That means long afternoon naps are basically required."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -60, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Found this in my camera roll from our last trip. Remember that harbor sunset?"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("That was one of the best evenings. We need to recreate that energy in Portugal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -35, to: referenceNow), content: .text("Packing tip: roll everything instead of folding. Fits way more and nothing wrinkles."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -34, to: referenceNow), content: .text("My mom has been telling me this for years and I never listen. Maybe I'll finally try it."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -12, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Stumbled into this street market today. The colors reminded me of what Porto probably looks like."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -12, to: referenceNow), content: .text("That's gorgeous. We are going to take SO many photos on this trip."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: sofia.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("90 days until Portugal! I made a countdown widget on my phone. Is that too much?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -9, to: referenceNow), content: .text("Not even a little. I'm right there with you. Let's finalize the Porto StayFinder this weekend."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: sofia.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: sofia.id, content: .text("Yes! I found three options. Sending you a comparison tonight.")),
                    AutomatedReply(senderID: sofia.id, content: .link(title: "Porto riverside StayFinder", url: "https://stayfinder.example/porto-riverside", description: "Walking distance to wine cellars and the Douro. Reviews are incredible.")),
                    AutomatedReply(senderID: sofia.id, content: .text("Also, I just hit 100k points. Upgrade confirmed."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 28. Marcus Vale DM (music lover)
            // ───────────────────────────────────────
            ChatThread(
                id: marcusThreadID,
                title: marcus.name,
                avatar: marcus.avatar,
                participantIDs: [marcus.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~200 days back) ──
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Dude. I just found a first pressing of Rumours at this little shop in the Mission. Fleetwood Mac. Mint condition."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("No way. How much did they want for it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("$85. I didn't even hesitate. The sleeve is pristine."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -185, to: referenceNow), content: .text("Caught a DJ set at that bar on Valencia last night. The guy played three hours of deep house and it was transcendent."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -184, to: referenceNow), content: .text("I keep missing these. You need to text me day-of so I actually show up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -175, to: referenceNow), content: .link(title: "Khruangbin live at Red Rocks", url: "https://music.example/khruangbin-redrocks", description: "Full concert stream. The bass tone on this is unreal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("Watching now. Mark is probably the smoothest guitarist alive. Zero effort."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -160, to: referenceNow), content: .text("Home audio update: I finally pulled the trigger on the Klipsch speakers. Setting them up this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Big upgrade. What amp are you pairing with them?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -158, to: referenceNow), content: .text("Yamaha A-S501. Warm tube-like sound without the tube hassle. Found it refurbished for half price."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -140, to: referenceNow), content: .audio(duration: "0:45", transcript: "Quick voice note. Just finished a beat on Ableton, first track I'm actually proud of. Gonna send it to you later but wanted to share the excitement first."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -139, to: referenceNow), content: .text("Send it! I love hearing what you're making. The last one had such a good groove."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Found a new bar in the Outer Sunset. Dive vibes, great jukebox, no pretension. Our kind of place."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("Say less. Friday?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("Friday works. I'll send the pin."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("Pickup basketball Saturday morning? We need a fifth and you owe me a rematch from last time."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("I'll be there. My jumper has been feeling automatic lately. Fair warning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Fantasy football update: your trade proposal is insulting and I respect the audacity."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("You miss 100% of the trades you don't propose. Accept it and thank me later."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -79, to: referenceNow), content: .audio(duration: "0:22", transcript: "Counter offer: I'll give you my WR2 and a bench stash for your RB1 and your dignity. Think about it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -50, to: referenceNow), content: .link(title: "Spotify - Marcus's Late Night Selects", url: "https://open.spotify.example/playlist/marcus-late-night", description: "Jazz, neo-soul, and lo-fi. Perfect for 11 PM vibes."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("This playlist is exactly what I needed. Track 7 is incredible. Who is that?"), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Vinyl haul this weekend. Three records for $20 at the flea market. Including a D'Angelo pressing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -13, to: referenceNow), content: .text("D'Angelo for under $10 is criminal. Protect that with your life."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: marcus.id, sentAt: adding(.day, -4, to: referenceNow), content: .audio(duration: "1:05", transcript: "Just leaving the show. Thundercat was insane. The bass solo in the encore literally made people gasp. You would have lost your mind."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -6, to: referenceNow), content: .text("I'm so jealous. Next show he does here I'm going no matter what. Put me on the alert list."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: marcus.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: marcus.id, content: .text("Done. Also, new Ableton track is almost finished. Sending you a preview tonight.")),
                    AutomatedReply(senderID: marcus.id, content: .audio(duration: "0:30", transcript: "Here's a clip. Still rough but the drums are locked in. Let me know what you think.")),
                    AutomatedReply(senderID: marcus.id, content: .text("Pickup game tomorrow at 9 if you're free. Same court."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 29. Spencer Bowman DM (sibling / family)
            // ───────────────────────────────────────
            ChatThread(
                id: spencerThreadID,
                title: spencerB.name,
                avatar: spencerB.avatar,
                participantIDs: [spencerB.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~365 days back) ──
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -365, to: referenceNow), content: .text("Happy anniversary to us surviving another year of being siblings. You're welcome for my existence."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -365, to: referenceNow), content: .text("Truly the gift that keeps on giving. How are Mom and Dad doing?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -350, to: referenceNow), content: .text("Good! Dad's obsessed with his new grill and Mom started a book club. They're thriving."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -340, to: referenceNow), content: .text("When are you coming to visit? It's been months."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -339, to: referenceNow), content: .text("Trying to coordinate with work. Maybe end of next month? I'll check flights."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -320, to: referenceNow), content: .visual(confettiGIF, kind: .gif, caption: "Biscuit learned a new trick. He sits AND shakes now. Dog genius."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -319, to: referenceNow), content: .text("Biscuit is literally the most talented member of this family and it's not close."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Career question: my boss offered me a lateral move to a new team. More interesting work but no raise. Thoughts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -299, to: referenceNow), content: .text("If the work is more interesting and it positions you better long-term, I'd take it. Money follows growth."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -298, to: referenceNow), content: .text("That's actually really good advice. Thanks for not just saying 'get the bag' like our friends would."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -275, to: referenceNow), content: .text("Mom's birthday is in two weeks. I was thinking we go in on a nice dinner for her and Dad. Split it?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -274, to: referenceNow), content: .text("Absolutely. That Italian place she loves? I can make a reservation from here."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -274, to: referenceNow), content: .text("Perfect. She'll love it. I'll get the flowers."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -250, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "Found this in Mom's kitchen. Our old height chart from when we were kids."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("I can't believe she still has that. I was apparently 4'2 in third grade. Tiny legend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -230, to: referenceNow), content: .text("Thanksgiving logistics: I'm flying in Wednesday night. Can you pick me up or should I Uber?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -229, to: referenceNow), content: .text("I'll pick you up. Send me your flight info when you have it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -210, to: referenceNow), content: .text("Thanksgiving was so good. Dad's turkey game has leveled up significantly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -209, to: referenceNow), content: .text("The brine made all the difference. I need to get that recipe from him."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Elena's birthday is next month. I want to plan something she won't expect. Ideas?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("What about a surprise brunch with her college friends? I can help coordinate."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -178, to: referenceNow), content: .text("That's genius. She'd never see it coming. I'll start a separate group chat to plan it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -150, to: referenceNow), content: .link(title: "Apartment listing - Wicker Park 2BR", url: "https://zillow.example/wicker-park-2br", description: "Finally looking at bigger places. What do you think of this layout?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("The kitchen is huge. And that's a real dining room, not a glorified hallway. Go see it in person."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Toured the apartment. It's even better in person. Hardwood floors, tons of light. I think this is it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("Do it. You deserve a nice place. Plus I need a guest room for when I visit."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Remember that time we convinced Dad we saw a bear in the backyard and he ran outside with a broom?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("And it was just the neighbor's dog. The look on his face was the funniest thing I've ever seen."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -60, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Biscuit at the park this morning. He's getting so big."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("I miss that dog so much. Give him a belly rub from me."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Big news: I signed the lease on the new apartment. Moving in April 1st."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -14, to: referenceNow), content: .text("SPENCE!! That's amazing. I'm so proud of you. Need help moving?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -7, to: referenceNow), content: .text("Mom called. She wants to do Easter at their place this year. Are you in?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("Wouldn't miss it. I'll book flights this week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: spencerB.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("Random life update: I started running again. Only two miles but it felt great."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.hour, -4, to: referenceNow), content: .text("Look at you! That's awesome. We should do a sibling run when I'm in town."), delivery: .read, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: spencerB.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: spencerB.id, content: .text("Deal. But I'm warning you, my pace is embarrassing.")),
                    AutomatedReply(senderID: spencerB.id, content: .text("Also Biscuit says hi. He's currently asleep on my suitcase.")),
                    AutomatedReply(senderID: spencerB.id, content: .visual(trackLights, kind: .photo, caption: "Proof. This dog owns everything I have."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 30. Arnav Srikanth DM (social friend / foodie)
            // ───────────────────────────────────────
            ChatThread(
                id: arnavThreadID,
                title: arnavS.name,
                avatar: arnavS.avatar,
                participantIDs: [arnavS.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~250 days back) ──
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Ok so I tried that ramen place you mentioned and I'm genuinely upset I didn't go sooner. The tonkotsu is life-changing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("TOLD YOU. The extra egg is non-negotiable. Welcome to the obsession."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -240, to: referenceNow), content: .text("I'm on a mission to make homemade pasta this weekend. Bought a pasta roller and everything. Wish me luck."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("You're going to love it. The dough is meditative once you get the feel for it. Don't skip the resting step."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -235, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "First batch. They're not pretty but they taste incredible. Cacio e pepe with fresh pappardelle."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -234, to: referenceNow), content: .text("Dude those look great for a first attempt. The sauce coating is perfect."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -220, to: referenceNow), content: .link(title: "NYT Cooking - Shakshuka recipe", url: "https://cooking.example/shakshuka", description: "Made this for brunch yesterday. Easiest crowd-pleaser ever."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("Shakshuka is the ultimate brunch move. I add feta on top which might be controversial but I stand by it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Hosting a dinner party Saturday. Six people, four courses. Am I insane?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("Yes but that's what makes it fun. What's the menu looking like?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Burrata salad, risotto, braised short ribs, and a panna cotta. Going full Italian."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -198, to: referenceNow), content: .text("That menu is flawless. The short ribs and risotto combo is chef behavior."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -175, to: referenceNow), content: .text("Wine tasting event at that natural wine bar next Thursday. You in? It's a guided flight of orange wines."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("I've been curious about orange wine. Count me in."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -155, to: referenceNow), content: .text("Farmers market haul this morning was absurd. Heirloom tomatoes, fresh basil, stone fruit. Summer cooking is peak."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -154, to: referenceNow), content: .text("Those heirloom tomatoes with just salt and olive oil are a full meal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("New cuisine unlocked: Ethiopian. Went to this spot in Oakland and the injera changed my perspective on bread."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Ethiopian food is incredible. The communal eating aspect makes it so social. We should go together."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -100, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "My hot sauce collection is getting out of hand. This shelf used to be for books."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("That's at least 30 bottles. You need an intervention. Or a YouTube channel."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Meal prep Sunday is becoming my religion. Four containers of chicken tikka and rice ready for the week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("I aspire to your level of food organization. I'm over here eating cereal for dinner."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -50, to: referenceNow), content: .link(title: "SF Street Food Festival - April", url: "https://streetfood.example/sf-april", description: "60+ vendors, live cooking demos, and a hot sauce competition. We have to go."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("Hot sauce competition? You were literally born for this. I'll be your hype man."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -12, to: referenceNow), content: .text("Tried making croissants from scratch. It took 14 hours and three butter tantrums but they turned out perfect."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -11, to: referenceNow), content: .text("14 hours?? You're a different breed. Save me one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("Dinner party round two this Saturday. You're invited. Theme: homemade dumpling bar."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("I'll be there with bells on. Want me to bring anything?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: arnavS.id, sentAt: adding(.hour, -3, to: referenceNow), content: .text("Just a good appetite and maybe that chili crisp you mentioned. The one with the mushrooms."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: arnavS.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: arnavS.id, content: .text("Actually, bring two jars. I have a feeling it'll disappear fast.")),
                    AutomatedReply(senderID: arnavS.id, content: .text("Also I'm entering the hot sauce competition at the food festival. Training starts now.")),
                    AutomatedReply(senderID: arnavS.id, content: .visual(kitchenNotes, kind: .photo, caption: "Dumpling filling prep. Three varieties: pork, shrimp, and mushroom."))
                ],
                automatedReplyCursor: 0
            ),
            // ───────────────────────────────────────
            // 31. Ava Torres DM (creative friend / photographer)
            // ───────────────────────────────────────
            ChatThread(
                id: avaThreadID,
                title: avaT.name,
                avatar: avaT.avatar,
                participantIDs: [avaT.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~200 days back) ──
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("I'm finally pulling the trigger on a new camera body. Torn between the Sony A7IV and the Fuji X-T5. Thoughts?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("Depends on what you shoot most. Sony for versatility, Fuji for that color science straight out of camera."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Honestly the Fuji colors are what drew me in. I hate spending hours color grading. I just want it to look good."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -185, to: referenceNow), content: .text("Went with the Fuji. First photo walk with it tomorrow morning. Golden hour at Baker Beach. Want to come?"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -184, to: referenceNow), content: .text("I'm in. What time is golden hour right now, like 6:15?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -184, to: referenceNow), content: .text("6:22 AM to be exact. I'll meet you at the parking lot at 6. Coffee on me."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -180, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Baker Beach this morning. The fog was just rolling in over the bridge. This camera is magic."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("That shot is incredible. The fog layering is so moody. You should print this big."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -165, to: referenceNow), content: .text("Speaking of printing, do you use any print services? I want to start selling prints but don't know where to start."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -164, to: referenceNow), content: .text("A friend of mine uses Artifact Uprising. The paper quality is gorgeous. Museum-grade stuff."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Gallery exhibition next month at SFMOMA. Three photographers from the Bay Area including someone I follow. Want to go?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("Absolutely. Opening night or regular visit?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("Opening night. Free wine and you get to talk to the artists. No brainer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Editing workflow question: are you team Lightroom or Capture One? I've been a Lightroom loyalist but the tethering in C1 is tempting."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Lightroom for personal stuff, but I've heard C1's color tools are way more precise. Try the free trial."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -110, to: referenceNow), content: .link(title: "Best golden hour spots in SF - curated list", url: "https://photospots.example/sf-golden-hour", description: "I've been building this guide for a year. 12 spots with exact timing and parking info."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("This is incredible. You should publish this as a proper guide. People would pay for this."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("Ugh. Instagram algorithm is killing my reach. I posted my best work this month and got half the engagement."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("Reels seem to be the only thing that gets pushed now. Have you tried short behind-the-scenes clips?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -89, to: referenceNow), content: .text("I hate that you're right. Maybe I'll film some process stuff. My editing workflow is pretty visual."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -60, to: referenceNow), content: .text("Had a creative block for two weeks and finally broke through it today. Shot portraits on the street for three hours and felt alive again."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("Street portraits always reset things. There's something about approaching strangers that forces you out of your head."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -35, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Client shoot wrapped. The light in this studio was unreal. Natural window light only."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -34, to: referenceNow), content: .text("Natural light only is so bold for a client shoot. But when it works, nothing beats it."), delivery: .read, isStarred: false),
                    // ── Recent messages ──
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("The portrait vs landscape debate: I've been shooting almost exclusively vertical lately. Blame phone screens."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("Landscape will always have my heart for environmental stuff. But yeah, vertical rules on mobile."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.day, -3, to: referenceNow), content: .link(title: "Photo walk meetup - Lands End Trail", url: "https://meetup.example/photowalk-landsend", description: "Saturday 7 AM. Coastal fog expected. Bring layers and your widest lens."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("I'll be there. Lands End in the fog is basically a photography cheat code."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: avaT.id, sentAt: adding(.hour, -5, to: referenceNow), content: .text("Just ordered my first print run. Twenty 16x20s on hahnemühle paper. This feels real now."), delivery: .delivered, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: avaT.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: avaT.id, content: .text("SO real. I'm nervous and excited. If they turn out good I might do a pop-up sale.")),
                    AutomatedReply(senderID: avaT.id, content: .visual(harborPhoto, kind: .photo, caption: "Preview of the Baker Beach print. The colors on paper are even better than on screen.")),
                    AutomatedReply(senderID: avaT.id, content: .text("Also, golden hour walk this weekend? I found a new rooftop spot."))
                ],
                automatedReplyCursor: 0
            ),

            // ───────────────────────────────────────
            // 32. Leo Chen DM (tech lead / work friend)
            // ───────────────────────────────────────
            ChatThread(
                id: leoThreadID,
                title: leo.name,
                avatar: leo.avatar,
                participantIDs: [leo.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~10 months back) ──
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -300, to: referenceNow), content: .text("Hey, saw your PR this morning. Clean approach on the caching layer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -300, to: referenceNow), content: .text("Thanks! Took me three tries to get the invalidation right."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -298, to: referenceNow), content: .text("That's the thing about caches. Easy to add, nightmare to invalidate correctly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -280, to: referenceNow), content: .text("Team standup ran long again. We should propose async standups and see if anyone revolts."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -279, to: referenceNow), content: .text("I've been thinking the same thing. A TeamChat thread with blockers would save us 30 min a day."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -279, to: referenceNow), content: .text("Exactly. I'll draft a proposal and run it by you before I send it to management."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -260, to: referenceNow), content: .link(title: "Modular Architecture in Practice", url: "https://blog.example/modular-arch", description: "This mirrors the approach I pitched for the core SDK refactor"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -259, to: referenceNow), content: .text("Great find. The section on dependency injection is exactly what we need for the plugin system."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -240, to: referenceNow), content: .audio(duration: "1:05", transcript: "Quick voice note. Just finished the code review on your feature branch. Couple of naming nitpicks but the structure is solid. The way you handled the race condition in the sync manager is elegant. Let's chat more at coffee tomorrow."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("Coffee sounds great. I'll push the naming fixes tonight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("Have you looked into that new Swift concurrency proposal? The structured task groups could simplify half our networking layer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("Read through it yesterday. The cancellation propagation is the real win. No more manual cleanup."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -219, to: referenceNow), content: .text("Right? I already spiked a proof of concept on a branch. Want to pair on it Friday?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -218, to: referenceNow), content: .text("Friday works. Block 2-4 and I'll bring the good coffee."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -195, to: referenceNow), content: .document(name: "tech_stack_decision_matrix.pdf", size: "1.2 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -195, to: referenceNow), content: .text("Put together this comparison for the infra meeting. GraphQL vs REST for the new API surface. Would love your take before I present."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -194, to: referenceNow), content: .text("This is thorough. I'd push harder on the tooling maturity column. Our team's familiarity with REST tooling is a real advantage."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -175, to: referenceNow), content: .text("Conference CFP deadline is next week. You submitting a talk?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("Thinking about it. Maybe something on the migration patterns we used for the data layer rewrite."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -174, to: referenceNow), content: .text("That would be a great talk. Real-world migration stories always draw a crowd. I'll review your abstract if you want."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -150, to: referenceNow), content: .text("Side project update: got the CLI tool parsing arguments correctly. Might open source it this weekend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("Nice. Need a hand with the README or CI setup? I've been wanting to play with GitHub Actions more."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -149, to: referenceNow), content: .text("That would be amazing actually. I'll share the repo link once I clean up the commit history."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Debugging war story of the day: spent three hours on a flaky test. Turns out it was a timezone issue in the date formatter."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("Classic. Timezones and floating point math. The two horsemen of dev despair."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -90, to: referenceNow), content: .text("We shipped the new onboarding flow. Conversion is up 14% in the first week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("That's incredible. The team should be proud. Your architecture made the A/B testing trivial."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -60, to: referenceNow), content: .link(title: "Vim vs Neovim in 2026", url: "https://devtools.example/editor-wars", description: "Thought of you immediately"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("You know I'm ride or die Neovim. But that Zed integration section is tempting."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Heads up, I'm recommending you for the senior architect track. Your work on the platform layer was exactly what the committee looks for."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("That means a lot coming from you. Seriously. Thank you for championing it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -10, to: referenceNow), content: .audio(duration: "0:35", transcript: "Just wanted to say the demo went really well today. The way you walked through the system design was clear and confident. The VP was impressed."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -10, to: referenceNow), content: .text("Appreciate the feedback. I was nervous but the prep sessions with you made all the difference."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: leo.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Coffee run? I found a new spot with single origin pour-overs. It's dangerously close to the office."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -3, to: referenceNow), content: .text("Say less. I'm already grabbing my jacket."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: leo.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: leo.id, content: .text("Just merged the feature flag cleanup PR. 400 lines deleted and nothing broke. Best feeling.")),
                    AutomatedReply(senderID: leo.id, content: .text("Also, the architect review board meets next Thursday. I'll keep you posted.")),
                    AutomatedReply(senderID: leo.id, content: .link(title: "Swift 6.2 concurrency updates", url: "https://swift.example/6-2-concurrency", description: "The new task executor API is exactly what we needed"))
                ],
                automatedReplyCursor: 0
            ),

            // ───────────────────────────────────────
            // 33. Nina Okafor DM (designer / creative collaborator)
            // ───────────────────────────────────────
            ChatThread(
                id: ninaThreadID,
                title: nina.name,
                avatar: nina.avatar,
                participantIDs: [nina.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~8 months back) ──
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Jordan! Did you see the new iOS design guidelines? The typography section is completely reworked."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("I skimmed it. The variable font support is going to change how we handle dynamic type."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("Exactly. I'm already updating our type scale in the design system. Want to sync on token naming?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -235, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Mood board for the rebrand exploration. Playing with warmer tones and more organic shapes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -234, to: referenceNow), content: .text("Love the direction. The earthy palette feels more approachable than what we have now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -234, to: referenceNow), content: .text("That's exactly the vibe I'm going for. Warm, human, not another cold SaaS look."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -215, to: referenceNow), content: .link(title: "Figma auto-layout deep dive", url: "https://figma.example/auto-layout-tips", description: "This nested auto-layout trick saved me an hour today"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -214, to: referenceNow), content: .text("The min/max width technique in section 3 is brilliant. Forwarding to the whole team."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -200, to: referenceNow), content: .text("Hey, I'm reviewing portfolios for the junior designer role. Any red flags I should watch for?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("Look for process, not just polish. If every project is a dribbble shot with no context, that's a flag. I want to see messy explorations and real constraints."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("That's a great filter. I've been too focused on visual quality and not enough on thinking."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("UX research findings are in. Users are dropping off at the third onboarding screen. The illustration style is confusing them."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("Interesting. Should we simplify the illustrations or rethink the flow entirely?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -179, to: referenceNow), content: .text("Both. Simpler art, fewer screens. I have a sketch that combines screens 2 and 3. Sending tonight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -160, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Design meetup tonight was amazing. The talk on spatial design for Vision Pro had everyone buzzing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -159, to: referenceNow), content: .text("Jealous I missed it. Save me a seat next month?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -159, to: referenceNow), content: .text("Already registered you. Third Thursday, same venue. The speaker is doing a live Figma teardown."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Hot take: bento grids are the new hero banners. Every portfolio site looks the same now."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("Agreed. Though I'll admit our marketing team just asked me for one and I didn't fight it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -129, to: referenceNow), content: .text("Ha! At least make the grid items animate on scroll. Give it some life."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -100, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Client presentation deck is done. 42 slides. I need a nap and a medal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("42 slides? That's a marathon. How'd it land?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -99, to: referenceNow), content: .text("They loved it. Approved the full rebrand with zero revisions. I might frame the approval email."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -98, to: referenceNow), content: .text("Zero revisions? That's legendary. You deserve that medal and then some."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -70, to: referenceNow), content: .link(title: "Design awards shortlist 2026", url: "https://designawards.example/shortlist", description: "We made the shortlist for the onboarding redesign!"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -69, to: referenceNow), content: .text("NO WAY. That's amazing! We need to celebrate this properly."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -69, to: referenceNow), content: .text("Dinner on me. Pick the place. We earned this one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -40, to: referenceNow), content: .visual(moodBoard, kind: .photo, caption: "Experimenting with claymorphism for the settings screens. Softer shadows, frosted layers."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -39, to: referenceNow), content: .text("That's really elegant. The layering makes it feel three-dimensional without being heavy."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -15, to: referenceNow), content: .text("Can you take a look at my updated portfolio when you get a chance? I redid the case studies with more process shots."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -14, to: referenceNow), content: .link(title: "Nina's portfolio review notes", url: "https://docs.example/nina-portfolio-notes", description: "Reviewed! Left comments in the shared doc. The Fintech case study is chef's kiss."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -14, to: referenceNow), content: .text("Your notes are so helpful. Reworking the hierarchy on the health app study tonight."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: nina.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("Design system tokens are published. 87 colors, 12 type styles, 24 spacing values. We're official."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("That's a milestone. The engineering team is going to love having a single source of truth."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: nina.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: nina.id, content: .text("Just got word: we won the design award. I'm literally shaking.")),
                    AutomatedReply(senderID: nina.id, content: .visual(moodBoard, kind: .photo, caption: "Trophy arrived. Putting it right next to my monitor.")),
                    AutomatedReply(senderID: nina.id, content: .text("Celebration dinner this Friday? I found a place with the best tasting menu."))
                ],
                automatedReplyCursor: 0
            ),

            // ───────────────────────────────────────
            // 34. Omar Hassan DM (operations / project manager)
            // ───────────────────────────────────────
            ChatThread(
                id: omarThreadID,
                title: omar.name,
                avatar: omar.avatar,
                participantIDs: [omar.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~7 months back) ──
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -200, to: referenceNow), content: .text("Jordan, quick heads up. The vendor for the AV equipment pushed delivery back two days. I've already called three alternates."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("You're always three steps ahead. Any of the alternates looking promising?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -199, to: referenceNow), content: .text("ProTech AV can do same-day delivery and they're $200 cheaper. Already sent the PO for approval."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -185, to: referenceNow), content: .document(name: "project_timeline_q4.pdf", size: "2.1 MB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -185, to: referenceNow), content: .text("Updated Q4 timeline with buffer days built in. Learned my lesson from last quarter's crunch."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -184, to: referenceNow), content: .text("Buffer days are genius. The two-week cushion before launch is going to save us."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -170, to: referenceNow), content: .text("Spreadsheet tip of the day: XLOOKUP with wildcard matching. Changed my life for vendor tracking."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -169, to: referenceNow), content: .text("You and your spreadsheet wizardry. I'm still using VLOOKUP like a caveman."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -169, to: referenceNow), content: .text("I'll send you my template. It has conditional formatting that turns red when deadlines are within 48 hours. Game changer."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -150, to: referenceNow), content: .link(title: "Notion project dashboard template", url: "https://notion.example/pm-dashboard", description: "Best free PM template I've found. Kanban plus timeline in one view"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("This is clean. I've been looking for something that doesn't require a PhD to set up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -130, to: referenceNow), content: .text("Team coordination is an art form. Had to reschedule the same meeting four times today. Everyone's calendar is a disaster."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("The eternal struggle. Have you tried the Calendly round-robin feature? Might help with the multi-team syncs."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -129, to: referenceNow), content: .text("Setting it up now. You just saved me from sending another poll with twelve time slots."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -110, to: referenceNow), content: .text("Weekend photography update: finally nailed long exposure at the bridge. The light trails are incredible at dusk."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -109, to: referenceNow), content: .text("I keep forgetting you're a photographer on the side. You should post more of your work."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -109, to: referenceNow), content: .text("Maybe one day. For now it's just my way of turning off the project manager brain for a few hours."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -80, to: referenceNow), content: .document(name: "vendor_comparison_sheet.xlsx", size: "890 KB"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -80, to: referenceNow), content: .text("Vendor comparison for the catering. Color-coded by price tier, dietary options, and lead time. Yes I'm extra."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -79, to: referenceNow), content: .text("This is beautiful. The conditional formatting alone deserves an award. Going with Vendor C."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -50, to: referenceNow), content: .text("Found the best food truck near the office. Korean-Mexican fusion. The bulgogi tacos are unreal."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -49, to: referenceNow), content: .text("You had me at bulgogi tacos. Tomorrow's lunch is decided."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -20, to: referenceNow), content: .link(title: "Linear - project management for builders", url: "https://linear.example/features", description: "Might be time to switch from Jira. The keyboard shortcuts alone are worth it"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -19, to: referenceNow), content: .text("I've been hearing great things. The cycle planning feature looks perfect for our sprint cadence."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -5, to: referenceNow), content: .text("All event logistics are locked in. Caterer confirmed, AV tested, parking passes distributed. We're golden."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -4, to: referenceNow), content: .text("You make it look effortless. Seriously, I don't know how you keep track of it all."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: omar.id, sentAt: adding(.day, -4, to: referenceNow), content: .text("Spreadsheets and an unhealthy amount of color-coded sticky notes. That's the secret."), delivery: .read, isStarred: false)
                ],
                unreadCount: 0,
                pinned: false,
                muted: false,
                subtitle: omar.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: omar.id, content: .text("Post-event debrief doc is ready. We came in 8% under budget.")),
                    AutomatedReply(senderID: omar.id, content: .document(name: "event_debrief_notes.pdf", size: "1.4 MB")),
                    AutomatedReply(senderID: omar.id, content: .text("Also, check out the food truck's new location. They moved closer to us."))
                ],
                automatedReplyCursor: 0
            ),

            // ───────────────────────────────────────
            // 35. Priya Sharma DM (running buddy / close friend)
            // ───────────────────────────────────────
            ChatThread(
                id: priyaThreadID,
                title: priya.name,
                avatar: priya.avatar,
                participantIDs: [priya.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~9 months back) ──
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -280, to: referenceNow), content: .text("Marathon training officially starts today! 18 weeks out. You in?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -280, to: referenceNow), content: .text("All in. Just downloaded the training plan. Week 1 looks manageable. Famous last words."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -275, to: referenceNow), content: .text("First long run done. 8 miles at an easy pace. My legs are already filing a complaint."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -274, to: referenceNow), content: .text("Same. My foam roller and I had a serious conversation this morning."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -260, to: referenceNow), content: .link(title: "Half marathon registration - Brooklyn", url: "https://race.example/brooklyn-half", description: "This one fills up fast. Registering now as a tune-up race for the full"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -259, to: referenceNow), content: .text("Registered! Starting corral B. Please tell me you're in B too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -259, to: referenceNow), content: .text("Corral B! We can pace together through Prospect Park and then I'll try not to die on the bridge."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -240, to: referenceNow), content: .text("Nutrition question: are you doing gels or real food for the long runs? I tried a gel yesterday and almost threw up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -239, to: referenceNow), content: .text("Dates and pretzels. Sounds weird, works great. My stomach can't handle the gels either."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -239, to: referenceNow), content: .text("Trying this immediately. Also, have you looked into electrolyte tabs? The Nuun ones are game changers in the heat."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -220, to: referenceNow), content: .text("TrailBlaze challenge alert: 100 miles this month. I'm at 42. You?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -219, to: referenceNow), content: .text("38 miles. That rainy week set me back but I'm catching up. Game on."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -200, to: referenceNow), content: .visual(trackLights, kind: .photo, caption: "Track workout at sunrise. Speed intervals are brutal but the light was worth the suffering."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -199, to: referenceNow), content: .text("That golden hour light on the track is unreal. Also, respect for doing intervals voluntarily."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -180, to: referenceNow), content: .text("Knee is feeling tight after yesterday's 14-miler. Icing and stretching but I might need to see the PT."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -179, to: referenceNow), content: .text("Don't push through it. A few rest days now is better than missing the race entirely. I can recommend my PT if you need one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -178, to: referenceNow), content: .text("You're right. Taking two days off and adding yoga this week for cross-training. Send me the PT info just in case."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -155, to: referenceNow), content: .text("Travel running update: did 6 miles along the Charles River in Boston this morning. Why doesn't every city have a river path this good?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -154, to: referenceNow), content: .text("Adding Boston to the run-while-traveling list. My Portland waterfront run last month was incredible too."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -130, to: referenceNow), content: .link(title: "Best running shoes 2026 - Runner's World", url: "https://runnersworld.example/best-shoes-2026", description: "The new Saucony Endorphin Pro is rated #1. Might be my next pair"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -129, to: referenceNow), content: .text("I've been eyeing those too. The carbon plate plus foam stack sounds perfect for race day."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -100, to: referenceNow), content: .text("Book club pick for this month: Endure by Alex Hutchinson. It's about the science of human performance limits. Feels on brand for us."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -99, to: referenceNow), content: .text("Love it. Downloading now. The audiobook version good for long runs?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -99, to: referenceNow), content: .text("Perfect for long runs. The narrator's pacing is great, no pun intended."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -70, to: referenceNow), content: .event(title: "Brooklyn Half Marathon", detail: "Sat Apr 12 · 7:00 AM · Grand Army Plaza"), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -69, to: referenceNow), content: .text("It's getting real. Taper week starts soon. Let's plan our pre-race dinner."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -40, to: referenceNow), content: .text("Career check-in: I'm thinking about going for the team lead position. The posting goes up next week."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -39, to: referenceNow), content: .text("You should absolutely go for it. Your project management skills are already team lead level. I'll be your reference anytime."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -39, to: referenceNow), content: .text("That means so much. We'll celebrate with a PR at the half marathon."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -10, to: referenceNow), content: .text("NEW PR! 1:42:15 on yesterday's long run simulation. I'm in the best shape of my life."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -9, to: referenceNow), content: .text("1:42?! That's incredible. You're going to crush the half. I hit 1:48 and was thrilled."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: priya.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Taper madness is real. I have all this energy and nowhere to put it. Three-mile easy run felt like a sprint."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("Same. I reorganized my entire closet yesterday just to burn energy. Taper brain is no joke."), delivery: .read, isStarred: false)
                ],
                unreadCount: 2,
                pinned: false,
                muted: false,
                subtitle: priya.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: priya.id, content: .text("Pasta dinner tomorrow night? Classic carb load. I found a place with amazing cacio e pepe.")),
                    AutomatedReply(senderID: priya.id, content: .event(title: "Pre-race pasta dinner", detail: "Fri Apr 11 · 7:00 PM · Lilia")),
                    AutomatedReply(senderID: priya.id, content: .text("Race day outfit is laid out. Bib pinned. Gels packed. LET'S GO."))
                ],
                automatedReplyCursor: 0
            ),

            // ───────────────────────────────────────
            // 36. Diego Martinez DM (outdoorsy friend / adventure buddy)
            // ───────────────────────────────────────
            ChatThread(
                id: diegoThreadID,
                title: diego.name,
                avatar: diego.avatar,
                participantIDs: [diego.id],
                isGroup: false,
                communityID: nil,
                messages: [
                    // ── Historical messages (~8 months back) ──
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -250, to: referenceNow), content: .text("Just got back from the Catskills. The Indian Head trail is no joke but the summit views are worth every step."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -249, to: referenceNow), content: .text("I've been wanting to do that one forever. How long was the round trip?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -249, to: referenceNow), content: .text("About 10 miles round trip with the side spur to Twin Mountain. Start early though, parking fills up by 7 AM."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -235, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Sunrise from the campsite this morning. First night testing the new tent."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -234, to: referenceNow), content: .text("That view is unreal. How's the new tent? I'm in the market for a lightweight one."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -234, to: referenceNow), content: .text("It's the Big Agnes Copper Spur. Under 3 pounds and sets up in five minutes. Highly recommend."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -215, to: referenceNow), content: .link(title: "Mountain biking trails near NYC", url: "https://trails.example/nyc-mtb", description: "Found some legit single track within an hour of the city. The Ringwood trails look amazing"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -214, to: referenceNow), content: .text("I didn't know there was decent mountain biking that close. Weekday ride sometime?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -214, to: referenceNow), content: .text("Next Friday? I can bring a spare helmet if you need one. The flow trails are perfect for getting back into it."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -213, to: referenceNow), content: .text("Friday works. I'll rent a bike from that shop in Jersey you mentioned. What time?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -195, to: referenceNow), content: .visual(marketPhoto, kind: .photo, caption: "Post-ride lunch at this farm stand we found. Best apple cider donuts I've ever had."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -194, to: referenceNow), content: .text("Those donuts were life-changing. We need to make that ride a monthly thing."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -175, to: referenceNow), content: .text("National park bucket list update: just booked Acadia for October. Bar Harbor in the fall is supposed to be incredible."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -174, to: referenceNow), content: .text("Acadia is on my list too! The Precipice Trail and Jordan Pond loop are must-dos. So jealous."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -174, to: referenceNow), content: .text("Come with! There's room in the cabin. The more the merrier for the dawn hike to Cadillac Mountain."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -173, to: referenceNow), content: .text("Let me check my calendar but I'm 90% yes. Cadillac Mountain at sunrise is a bucket list item."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -150, to: referenceNow), content: .visual(windowSeat, kind: .photo, caption: "Road trip snack game is strong. Six hours to the Adirondacks and we're only halfway through the trail mix."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -149, to: referenceNow), content: .text("Road trip snack quality is directly proportional to trip quality. That's just science."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -120, to: referenceNow), content: .text("Tried cooking over the campfire last night. Cast iron skillet, garlic butter trout, foil-wrapped potatoes. Tasted better than any restaurant."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -119, to: referenceNow), content: .text("You're making me hungry. The campfire cooking is genuinely my favorite part of camping."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -119, to: referenceNow), content: .text("Next trip I'm bringing the Dutch oven. Campfire chili that simmers for three hours while we hike."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -90, to: referenceNow), content: .link(title: "Leave No Trace principles refresher", url: "https://lnt.example/principles", description: "Sharing this because the trails have been getting trashed lately. We can all do better"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -89, to: referenceNow), content: .text("100% agree. I've started bringing an extra bag on every hike just for trail cleanup. It's shocking how much litter people leave."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -89, to: referenceNow), content: .text("Same here. Pack it in, pack it out. Plus the extra trash bag weighs nothing. No excuse."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -60, to: referenceNow), content: .visual(harborPhoto, kind: .photo, caption: "Golden hour at Harriman State Park. This is why I always carry the camera, even on short hikes."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -59, to: referenceNow), content: .text("You have such a good eye for light. That composition with the trail curving into the trees is beautiful."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -30, to: referenceNow), content: .text("Weekend warrior plan: Bear Mountain on Saturday, recovery brunch on Sunday. You free?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -29, to: referenceNow), content: .text("Absolutely. The Appalachian Trail section there is gorgeous this time of year. What time are we starting?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -29, to: referenceNow), content: .text("6:30 AM trailhead. I know it's early but the parking situation demands it. I'll drive."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -8, to: referenceNow), content: .visual(kitchenNotes, kind: .photo, caption: "New gear day. Picked up a Jetboil for quick summit coffee. No more lukewarm thermos coffee."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -7, to: referenceNow), content: .text("Summit coffee is a non-negotiable. The Jetboil is a smart move. Boils water in like two minutes."), delivery: .read, isStarred: true),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -3, to: referenceNow), content: .text("Planning a spring road trip. Shenandoah to Great Smoky Mountains, five days on the Blue Ridge Parkway. Want in?"), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: currentUserID, sentAt: adding(.day, -2, to: referenceNow), content: .text("That sounds incredible. When were you thinking? I need to block the time off now before my calendar fills up."), delivery: .read, isStarred: false),
                    ChatMessage(id: UUID(), senderID: diego.id, sentAt: adding(.day, -2, to: referenceNow), content: .text("Late April. The wildflowers along the parkway should be peaking. I'll put together a rough itinerary this week."), delivery: .read, isStarred: false)
                ],
                unreadCount: 1,
                pinned: false,
                muted: false,
                subtitle: diego.phoneNumber,
                automatedReplies: [
                    AutomatedReply(senderID: diego.id, content: .text("Itinerary draft is done. Five days, four campsites, two summit sunrises. Sending now.")),
                    AutomatedReply(senderID: diego.id, content: .link(title: "Blue Ridge Parkway spring guide", url: "https://nps.example/blueridge-spring", description: "The wildflower section is what sold me. Mile markers 300-400 are supposed to be peak bloom")),
                    AutomatedReply(senderID: diego.id, content: .text("Also found a farmhouse brewery near the Smokies entrance. Perfect rest day stop."))
                ],
                automatedReplyCursor: 0
            )
        ]

        communities = [
            Community(
                id: runningCommunityID,
                name: "Brooklyn Running Club",
                description: "Morning routes, pacer notes, and last-minute weather pivots.",
                avatar: AvatarSeed(topHex: 0x153D22, bottomHex: 0x32C866, initials: "BR", symbolName: "bolt.fill"),
                memberCount: 248,
                announcementThreadID: runningAnnouncementThreadID,
                groupThreadIDs: [runningGroupThreadID]
            ),
            Community(
                id: studioCommunityID,
                name: "Studio Ops Network",
                description: "Launch-day logistics, walkthrough details, and handoff threads.",
                avatar: AvatarSeed(topHex: 0x102744, bottomHex: 0x3A87FF, initials: "SO", symbolName: "shippingbox.fill"),
                memberCount: 118,
                announcementThreadID: studioAnnouncementThreadID,
                groupThreadIDs: [studioLaunchThreadID]
            )
        ]

        statuses = [
            StatusUpdate(id: UUID(), ownerID: maya.id, ownerName: maya.name, avatar: maya.avatar, postedAt: adding(.hour, -3, to: referenceNow), body: "Venue scouting is officially done.", media: harborPhoto, isViewed: false, isMine: false),
            StatusUpdate(id: UUID(), ownerID: theo.id, ownerName: theo.name, avatar: theo.avatar, postedAt: adding(.hour, -5, to: referenceNow), body: "Airport Wi-Fi beat me, but the reel is finally exported.", media: nil, isViewed: false, isMine: false),
            StatusUpdate(id: UUID(), ownerID: priya.id, ownerName: priya.name, avatar: priya.avatar, postedAt: adding(.hour, -8, to: referenceNow), body: "Cabin snacks sorted. The granola situation is under control.", media: kitchenNotes, isViewed: true, isMine: false),
            StatusUpdate(id: UUID(), ownerID: lena.id, ownerName: lena.name, avatar: lena.avatar, postedAt: adding(.hour, -10, to: referenceNow), body: "Lobby greens arrive before lunch tomorrow.", media: marketPhoto, isViewed: false, isMine: false),
            StatusUpdate(id: UUID(), ownerID: camille.id, ownerName: camille.name, avatar: camille.avatar, postedAt: adding(.hour, -13, to: referenceNow), body: "Saving a table for next week already.", media: nil, isViewed: true, isMine: false)
        ]

        channels = [
            Channel(
                id: UUID(),
                name: "QuickChat Tips",
                category: "Messaging",
                description: "Small features, privacy updates, and ways to keep busy chats under control.",
                followersLabel: "232M followers",
                avatar: AvatarSeed(topHex: 0x11A850, bottomHex: 0x38D766, initials: "WA", symbolName: "message.fill"),
                verified: true,
                isFollowed: true,
                posts: [
                    ChannelPost(id: UUID(), headline: "Turn short notes into text stickers", body: "Drop a phrase, style it, and share it back into a group without leaving the composer.", postedAt: adding(.day, -2, to: referenceNow), media: confettiGIF),
                    ChannelPost(id: UUID(), headline: "Locked chats now support custom passkeys", body: "Keep specific threads behind a second step while the rest of your inbox stays fast.", postedAt: adding(.day, -6, to: referenceNow), media: nil)
                ]
            ),
            Channel(
                id: UUID(),
                name: "City Briefing",
                category: "Local news",
                description: "Short commute notes, weather shifts, and local event roundups before 8 AM.",
                followersLabel: "845K followers",
                avatar: AvatarSeed(topHex: 0x1A2446, bottomHex: 0x4D6AF2, initials: "CB", symbolName: "newspaper.fill"),
                verified: true,
                isFollowed: false,
                posts: [
                    ChannelPost(id: UUID(), headline: "Rain clears by noon", body: "Two bridge closures remain, but bus lanes are moving normally.", postedAt: adding(.hour, -6, to: referenceNow), media: windowSeat)
                ]
            ),
            Channel(
                id: UUID(),
                name: "Trail Notes",
                category: "Outdoors",
                description: "Weekly route ideas, gear checks, and sunrise reports for runners and hikers.",
                followersLabel: "1.2M followers",
                avatar: AvatarSeed(topHex: 0x143321, bottomHex: 0x4DC86E, initials: "TN", symbolName: "map.fill"),
                verified: true,
                isFollowed: false,
                posts: [
                    ChannelPost(id: UUID(), headline: "Saturday ridge conditions", body: "Dry footing, cold start, and excellent visibility after 7 AM.", postedAt: adding(.hour, -9, to: referenceNow), media: trackLights)
                ]
            ),
            Channel(
                id: UUID(),
                name: "Kitchen Dispatch",
                category: "Food",
                description: "Fast dinner ideas, pantry saves, and the occasional indulgent dessert recipe.",
                followersLabel: "612K followers",
                avatar: AvatarSeed(topHex: 0x3C291A, bottomHex: 0xEFA15C, initials: "KD", symbolName: "fork.knife"),
                verified: false,
                isFollowed: false,
                posts: [
                    ChannelPost(id: UUID(), headline: "20-minute noodle bowl", body: "A broth shortcut that still tastes like you planned ahead.", postedAt: adding(.day, -1, to: referenceNow), media: kitchenNotes)
                ]
            ),
            Channel(
                id: UUID(),
                name: "Design Archive",
                category: "Creative work",
                description: "Mockups, mood boards, and references for teams shipping spaces people remember.",
                followersLabel: "428K followers",
                avatar: AvatarSeed(topHex: 0x2A2142, bottomHex: 0x7B62F2, initials: "DA", symbolName: "paintpalette.fill"),
                verified: true,
                isFollowed: false,
                posts: [
                    ChannelPost(id: UUID(), headline: "Three ways to keep a launch wall from feeling flat", body: "Use rhythm, one oversized focal element, and one line of softer lighting to keep the wall photographic from multiple angles.", postedAt: adding(.day, -3, to: referenceNow), media: moodBoard)
                ]
            )
        ]

        calls = [
            CallRecord(id: UUID(), title: maya.name, detail: "Quick venue sync", avatar: maya.avatar, timestamp: adding(.day, -1, to: referenceNow), mode: .voice, direction: .outgoing, duration: "14m", threadID: mayaThreadID),
            CallRecord(id: UUID(), title: "Studio Launch", detail: "Soft-open walkthrough", avatar: AvatarSeed(topHex: 0x0C3560, bottomHex: 0x236ED8, initials: "SL", symbolName: "person.3.fill"), timestamp: adding(.day, -2, to: referenceNow), mode: .video, direction: .outgoing, duration: "23m", threadID: studioLaunchThreadID),
            CallRecord(id: UUID(), title: theo.name, detail: "Missed voice call", avatar: theo.avatar, timestamp: adding(.hour, -19, to: referenceNow), mode: .voice, direction: .missed, duration: "0m", threadID: theoThreadID),
            CallRecord(id: UUID(), title: "Saturday Long Run", detail: "Group planning call", avatar: AvatarSeed(topHex: 0x0E355B, bottomHex: 0x31A1FF, initials: "LR", symbolName: "bolt.fill"), timestamp: adding(.day, -5, to: referenceNow), mode: .voice, direction: .incoming, duration: "18m", threadID: runningGroupThreadID),
            CallRecord(id: UUID(), title: lena.name, detail: "Dock timing update", avatar: lena.avatar, timestamp: adding(.hour, -7, to: referenceNow), mode: .voice, direction: .incoming, duration: "6m", threadID: lenaThreadID),
            CallRecord(id: UUID(), title: camille.name, detail: "Post-event dinner plans", avatar: camille.avatar, timestamp: adding(.day, -6, to: referenceNow), mode: .video, direction: .outgoing, duration: "12m", threadID: camilleThreadID)
        ]

        scheduledCalls = [
            ScheduledCall(id: UUID(), contactID: maya.id, title: maya.name, scheduledFor: adding(.day, 1, to: referenceNow), note: "Lock tea spot before venue dinner.", mode: .voice),
            ScheduledCall(id: UUID(), contactID: leo.id, title: leo.name, scheduledFor: adding(.day, 3, to: referenceNow), note: "Review opening sequence and staffing.", mode: .video),
            ScheduledCall(id: UUID(), contactID: lena.id, title: lena.name, scheduledFor: adding(.day, 2, to: referenceNow), note: "Confirm dock timing and floral placement.", mode: .voice)
        ]

        messageLists = [
            MessageListItem(id: UUID(), name: "Unread", summary: "6 chats need a reply"),
            MessageListItem(id: UUID(), name: "Launch Week", summary: "5 threads across ops and vendors"),
            MessageListItem(id: UUID(), name: "Travel Plans", summary: "Flights, hotel pins, and weekend trip details"),
            MessageListItem(id: UUID(), name: "Dinner & After-hours", summary: "Late reservations, social plans, and quick hangouts")
        ]

        broadcastLists = [
            BroadcastListItem(id: UUID(), name: "Weekend Dinner", memberIDs: [maya.id, theo.id, priya.id], lastSent: adding(.day, -8, to: referenceNow)),
            BroadcastListItem(id: UUID(), name: "Vendor Ping", memberIDs: [leo.id, nina.id, omar.id], lastSent: adding(.day, -3, to: referenceNow)),
            BroadcastListItem(id: UUID(), name: "Soft Open Guests", memberIDs: [maya.id, camille.id, lena.id, marcus.id], lastSent: adding(.day, -1, to: referenceNow))
        ]

        linkedDevices = [
            LinkedDevice(id: UUID(), name: "Jordan's MacBook Pro", lastSeen: "Active now", isActive: true),
            LinkedDevice(id: UUID(), name: "Jordan's iPad Air", lastSeen: "Last active yesterday", isActive: false),
            LinkedDevice(id: UUID(), name: "Jordan's Work Laptop", lastSeen: "Last active 2 hours ago", isActive: false)
        ]

        // Fix unread counts to match actual trailing incoming messages
        for i in chats.indices {
            var count = 0
            for message in chats[i].messages.reversed() {
                if message.senderID == currentUserID { break }
                count += 1
            }
            chats[i].unreadCount = count
        }
    }

    func sortedChats(filter: ChatFilter) -> [ChatThread] {
        chats
            .filter { thread in
                switch filter {
                case .all:
                    return !thread.archived
                case .unread:
                    return !thread.archived && thread.unreadCount > 0
                case .groups:
                    return !thread.archived && thread.isGroup
                case .archived:
                    return thread.archived
                }
            }
            .sorted { lhs, rhs in
                if lhs.pinned != rhs.pinned {
                    return lhs.pinned && !rhs.pinned
                }
                return lhs.lastActivity > rhs.lastActivity
            }
    }

    func thread(id: UUID) -> ChatThread? {
        chats.first { $0.id == id }
    }

    func threadTitle(for id: UUID) -> String {
        thread(id: id)?.title ?? "Chat"
    }

    func contact(id: UUID) -> Contact? {
        contacts.first { $0.id == id }
    }

    func contactName(id: UUID) -> String {
        if id == currentUserID {
            return profile.displayName
        }
        return contact(id: id)?.name ?? "Unknown"
    }

    func contactAvatar(id: UUID) -> AvatarSeed {
        if id == currentUserID {
            return profile.avatar
        }
        return contact(id: id)?.avatar ?? AvatarSeed(topHex: 0x2D2D2D, bottomHex: 0x4B4B4B, initials: "?", symbolName: "person.fill")
    }

    func senderAccent(for id: UUID) -> Color {
        contactAvatar(id: id).startColor
    }

    func openThread(_ threadID: UUID) {
        activeThreadID = threadID
        markThreadRead(threadID)
    }

    func closeThread(_ threadID: UUID) {
        if activeThreadID == threadID {
            activeThreadID = nil
        }
    }

    func markThreadRead(_ threadID: UUID) {
        updateThread(threadID) { thread in
            thread.unreadCount = 0
        }
    }

    func markAllChatsRead() {
        chats = chats.map { thread in
            var updated = thread
            updated.unreadCount = 0
            return updated
        }
        showToast(title: "All caught up", subtitle: "Every chat is marked as read.")
    }

    func preferredChannelID() -> UUID? {
        channels.first(where: { $0.isFollowed })?.id ?? channels.first?.id
    }

    func presentToast(title: String, subtitle: String) {
        showToast(title: title, subtitle: subtitle)
    }

    func ensureDirectThread(with contactID: UUID) -> UUID {
        if let existing = chats.first(where: { !$0.isGroup && Set($0.participantIDs) == Set([contactID]) }) {
            return existing.id
        }

        let created = ChatThread(
            id: UUID(),
            title: contactName(id: contactID),
            avatar: contactAvatar(id: contactID),
            participantIDs: [contactID],
            isGroup: false,
            communityID: nil,
            messages: [
                ChatMessage(id: UUID(), senderID: contactID, sentAt: Date(), content: .text("New thread opened. Drop what you need and I'll reply here."), delivery: .read, isStarred: false)
            ],
            unreadCount: 0,
            pinned: false,
            muted: false,
            subtitle: "new chat",
            automatedReplies: [
                AutomatedReply(senderID: contactID, content: .text("Perfect timing. I was about to message you too.")),
                AutomatedReply(senderID: contactID, content: .text("On it. I'll send over the details here."))
            ],
            automatedReplyCursor: 0
        )
        chats.insert(created, at: 0)
        return created.id
    }

    func sendText(_ text: String, to threadID: UUID, replyToID: UUID? = nil) {
        sendContent(.text(text), to: threadID, replyToID: replyToID)
    }

    func sendQuickAttachment(_ category: SearchCategory, to threadID: UUID) {
        let templateIndex = Int(Date().timeIntervalSince1970) % max(mediaTemplates.count, 1)
        let template = mediaTemplates[safe: templateIndex] ?? mediaTemplates[0]

        let content: MessageContent
        switch category {
        case .photos:
            content = .visual(template, kind: .photo, caption: template.subtitle)
        case .gifs:
            content = .visual(mediaTemplates[safe: 6] ?? template, kind: .gif, caption: "A tiny victory lap.")
        case .links:
            content = .link(title: "Venue pin", url: "https://maps.example/pin", description: "Main entrance and loading bay are on the same side.")
        case .videos:
            content = .visual(mediaTemplates[safe: 7] ?? template, kind: .video, caption: "Quick scan of the room.")
        case .documents:
            content = .document(name: "brief_notes.pdf", size: "1.1 MB")
        case .audio:
            content = .audio(duration: "0:19", transcript: "Recording a quick note while I walk between stops.")
        case .polls:
            content = .poll(question: "Which slot works best?", choices: [PollChoice(title: "4:00 PM", votes: 1), PollChoice(title: "5:30 PM", votes: 2), PollChoice(title: "Tomorrow morning", votes: 0)])
        case .events:
            content = .event(title: "Coffee check-in", detail: "Tomorrow 9:30 AM · Cedar Room")
        }
        sendContent(content, to: threadID)
    }

    func sendVisual(template: MediaTemplate, kind: VisualKind, caption: String, to threadID: UUID) {
        sendContent(.visual(template, kind: kind, caption: caption), to: threadID)
    }

    func sendCameraCapture(to threadID: UUID) {
        sendVisual(template: mediaTemplates[safe: 1] ?? mediaTemplates[0], kind: .photo, caption: "Shot this on the way.", to: threadID)
        showToast(title: "Photo sent", subtitle: "Your capture is now in the chat.")
    }

    func sendVoiceNote(to threadID: UUID) {
        sendContent(.audio(duration: "0:14", transcript: "Leaving you a quick note so I don't forget the details."), to: threadID)
    }

    private func sendContent(_ content: MessageContent, to threadID: UUID, replyToID: UUID? = nil) {
        let messageID = UUID()
        let outgoing = ChatMessage(id: messageID, senderID: currentUserID, sentAt: Date(), content: content, delivery: .sent, isStarred: false, replyToID: replyToID)
        updateThread(threadID) { thread in
            thread.messages.append(outgoing)
            thread.unreadCount = 0
        }
        scheduleDeliveryProgression(messageID: messageID, threadID: threadID)
        scheduleReply(for: threadID)
    }

    private func scheduleDeliveryProgression(messageID: UUID, threadID: UUID) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.updateMessageDelivery(messageID: messageID, threadID: threadID, state: .delivered)
        }
        guard profile.readReceiptsEnabled else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            self?.updateMessageDelivery(messageID: messageID, threadID: threadID, state: .read)
        }
    }

    private func updateMessageDelivery(messageID: UUID, threadID: UUID, state: DeliveryState) {
        updateThread(threadID) { thread in
            if let index = thread.messages.firstIndex(where: { $0.id == messageID }) {
                thread.messages[index].delivery = state
            }
        }
    }

    private func scheduleReply(for threadID: UUID) {
        replyWorkItems[threadID]?.cancel()
        replyRequestTokens[threadID] = nil

        guard let thread = thread(id: threadID), shouldAutoReply(to: thread) else {
            return
        }

        if thread.isGroup && thread.participantIDs.count > 1 {
            scheduleGroupReplies(for: threadID, thread: thread)
            return
        }

        if let replyGenerator,
           let senderID = replySenderID(for: thread) {
            let token = UUID()
            replyRequestTokens[threadID] = token

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.typingThreadIDs.insert(threadID)
            }

            let workItem = DispatchWorkItem { [weak self] in
                self?.requestGeneratedReply(for: threadID, senderID: senderID, token: token, generator: replyGenerator)
            }
            replyWorkItems[threadID] = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + replyDelay, execute: workItem)
            return
        }

        scheduleAutomatedReply(for: threadID)
    }

    private func scheduleGroupReplies(for threadID: UUID, thread: ChatThread) {
        let others = thread.participantIDs.filter { $0 != currentUserID }
        guard !others.isEmpty else { return }
        let replyCount = min(others.count, Int.random(in: 1...min(3, others.count)))
        let responders = Array(others.shuffled().prefix(replyCount))

        for (index, senderID) in responders.enumerated() {
            let baseDelay = replyDelay + Double(index) * Double.random(in: 1.5...3.0)

            DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay - 0.8) { [weak self] in
                self?.typingThreadIDs.insert(threadID)
            }

            if let replyGenerator {
                DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) { [weak self] in
                    guard let self = self else { return }
                    let senderName = self.contactName(id: senderID)
                    let senderBio = self.contact(id: senderID)?.about ?? thread.subtitle
                    let currentThread = self.thread(id: threadID)
                    let recentMessages = (currentThread?.messages ?? []).suffix(8).map {
                        GeneratedReplyContextMessage(
                            senderName: self.contactName(id: $0.senderID),
                            isCurrentUser: $0.senderID == self.currentUserID,
                            text: $0.content.previewText
                        )
                    }
                    replyGenerator.generateReply(
                        as: senderName,
                        bio: senderBio,
                        threadTitle: thread.title,
                        isGroupChat: true,
                        recentMessages: Array(recentMessages)
                    ) { [weak self] result in
                        DispatchQueue.main.async {
                            guard let self = self else { return }
                            self.typingThreadIDs.remove(threadID)
                            switch result {
                            case .success(let text):
                                self.appendIncomingReply(.text(text), from: senderID, to: threadID, advanceCursor: false)
                            case .failure:
                                self.deliverGroupFallbackReply(from: senderID, to: threadID)
                            }
                        }
                    }
                }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + baseDelay) { [weak self] in
                    guard let self = self else { return }
                    self.typingThreadIDs.remove(threadID)
                    self.deliverGroupFallbackReply(from: senderID, to: threadID)
                }
            }
        }
    }

    private func deliverGroupFallbackReply(from senderID: UUID, to threadID: UUID) {
        guard let thread = thread(id: threadID) else { return }
        let lastText = thread.messages.last?.content.previewText.lowercased() ?? ""
        let reply: String
        if lastText.contains("?") || lastText.contains("what") || lastText.contains("how") || lastText.contains("when") {
            reply = ["Hmm let me think about that", "Good question", "Not sure actually", "I think so but don't quote me", "Yeah I was wondering that too"].randomElement()!
        } else if lastText.contains("thanks") || lastText.contains("thank") {
            reply = ["No problem!", "Anytime!", "Of course!", "Happy to help"].randomElement()!
        } else if lastText.contains("lol") || lastText.contains("haha") || lastText.contains("😂") {
            reply = ["😂", "Hahaha", "lol seriously", "I can't 💀", "Dead 😭"].randomElement()!
        } else if lastText.contains("bye") || lastText.contains("later") || lastText.contains("gotta go") {
            reply = ["See you!", "Later!", "Talk soon!", "Bye!"].randomElement()!
        } else {
            reply = ["Yeah for sure", "That makes sense", "Totally", "Facts", "Right right", "Got it", "Fr", "100%"].randomElement()!
        }
        appendIncomingReply(.text(reply), from: senderID, to: threadID, advanceCursor: false)
    }

    private func shouldAutoReply(to thread: ChatThread) -> Bool {
        return true
    }

    private func replySenderID(for thread: ChatThread) -> UUID? {
        thread.automatedReplies[safe: thread.automatedReplyCursor]?.senderID ?? thread.participantIDs.first
    }

    private func requestGeneratedReply(for threadID: UUID, senderID: UUID, token: UUID, generator: ReplyGenerating) {
        guard replyRequestTokens[threadID] == token, let thread = thread(id: threadID) else {
            return
        }

        let senderName = contactName(id: senderID)
        let senderBio = contact(id: senderID)?.about ?? thread.subtitle
        let recentMessages = thread.messages.suffix(8).map {
            GeneratedReplyContextMessage(
                senderName: contactName(id: $0.senderID),
                isCurrentUser: $0.senderID == currentUserID,
                text: $0.content.previewText
            )
        }

        generator.generateReply(
            as: senderName,
            bio: senderBio,
            threadTitle: thread.title,
            isGroupChat: thread.isGroup,
            recentMessages: Array(recentMessages)
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self, self.replyRequestTokens[threadID] == token else { return }
                self.replyRequestTokens[threadID] = nil
                self.typingThreadIDs.remove(threadID)
                switch result {
                case .success(let text):
                    self.appendIncomingReply(.text(text), from: senderID, to: threadID, advanceCursor: true)
                case .failure:
                    self.scheduleAutomatedReply(for: threadID)
                }
            }
        }
    }

    private func scheduleAutomatedReply(for threadID: UUID) {
        guard let thread = thread(id: threadID) else { return }

        let senderID: UUID
        let replyContent: MessageContent

        if thread.automatedReplyCursor < thread.automatedReplies.count,
           let predefined = thread.automatedReplies[safe: thread.automatedReplyCursor] {
            senderID = predefined.senderID
            replyContent = predefined.content
        } else {
            guard let fallbackSenderID = thread.participantIDs.first else { return }
            senderID = fallbackSenderID
            let lastText = thread.messages.last?.content.previewText.lowercased() ?? ""
            let reply: String
            if lastText.contains("?") || lastText.contains("what") || lastText.contains("how") || lastText.contains("when") || lastText.contains("where") {
                reply = ["Hmm let me think about that", "Good question, I'll get back to you", "Not sure actually, let me check", "I think so but don't quote me on that"].randomElement()!
            } else if lastText.contains("thanks") || lastText.contains("thank") || lastText.contains("thx") {
                reply = ["No problem!", "Anytime!", "You're welcome", "Of course!"].randomElement()!
            } else if lastText.contains("lol") || lastText.contains("haha") || lastText.contains("funny") || lastText.contains("😂") {
                reply = ["😂", "Hahaha", "lol seriously", "I can't 💀"].randomElement()!
            } else if lastText.contains("sorry") || lastText.contains("bad") || lastText.contains("my fault") {
                reply = ["No worries at all", "It's all good!", "Don't worry about it", "Totally fine"].randomElement()!
            } else if lastText.contains("see you") || lastText.contains("bye") || lastText.contains("later") || lastText.contains("gotta go") {
                reply = ["See you!", "Later!", "Talk soon", "Catch you later!"].randomElement()!
            } else if lastText.contains("yes") || lastText.contains("yeah") || lastText.contains("sure") || lastText.contains("ok") {
                reply = ["Sounds good", "Perfect", "Great!", "Awesome"].randomElement()!
            } else {
                reply = ["Yeah for sure", "That makes sense", "I hear you", "Got it", "Totally", "Right right", "Makes sense", "Facts"].randomElement()!
            }
            replyContent = .text(reply)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.typingThreadIDs.insert(threadID)
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.typingThreadIDs.remove(threadID)
            self.appendIncomingReply(replyContent, from: senderID, to: threadID, advanceCursor: true)
        }
        replyWorkItems[threadID] = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + replyDelay, execute: workItem)
    }

    private func appendIncomingReply(_ content: MessageContent, from senderID: UUID, to threadID: UUID, advanceCursor: Bool) {
        let incoming = ChatMessage(id: UUID(), senderID: senderID, sentAt: Date(), content: content, delivery: .read, isStarred: false)
        updateThread(threadID) { updatedThread in
            updatedThread.messages.append(incoming)
            if advanceCursor, !updatedThread.automatedReplies.isEmpty {
                updatedThread.automatedReplyCursor += 1
            }
            if self.activeThreadID == threadID {
                updatedThread.unreadCount = 0
            } else {
                updatedThread.unreadCount += 1
            }
        }
    }

    func startCall(with contactID: UUID, mode: CallMode) {
        let title = contactName(id: contactID)
        let detail = mode == .video ? "Video call started" : "Voice call started"
        let threadID = chats.first(where: { !$0.isGroup && $0.participantIDs == [contactID] })?.id
        let record = CallRecord(id: UUID(), title: title, detail: detail, avatar: contactAvatar(id: contactID), timestamp: Date(), mode: mode, direction: .outgoing, duration: "0m", threadID: threadID)
        calls.insert(record, at: 0)
        showActiveCall(title: title, avatar: contactAvatar(id: contactID), mode: mode)
    }

    func startCall(for threadID: UUID, mode: CallMode) {
        guard let thread = thread(id: threadID) else { return }
        let detail = thread.isGroup ? "Group \(mode == .video ? "video" : "voice") call started" : "Call started from chat"
        let record = CallRecord(id: UUID(), title: thread.title, detail: detail, avatar: thread.avatar, timestamp: Date(), mode: mode, direction: .outgoing, duration: "0m", threadID: threadID)
        calls.insert(record, at: 0)
        showActiveCall(title: thread.title, avatar: thread.avatar, mode: mode)
    }

    private func showActiveCall(title: String, avatar: AvatarSeed, mode: CallMode) {
        let callInfo = ActiveCallInfo(id: UUID(), title: title, avatar: avatar, mode: mode, startedAt: Date())
        activeCall = callInfo
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            if self?.activeCall?.id == callInfo.id {
                self?.activeCall = nil
            }
        }
    }

    func scheduleCall(contactID: UUID?, date: Date, note: String, mode: CallMode) {
        let title = contactID.map(contactName(id:)) ?? "New call"
        let call = ScheduledCall(id: UUID(), contactID: contactID, title: title, scheduledFor: date, note: note, mode: mode)
        scheduledCalls.insert(call, at: 0)
        showToast(title: "Call scheduled", subtitle: "\(title) was added to your calls list.")
    }

    func placeManualCall(number: String, mode: CallMode) {
        let matchedContact = contacts.first { compactDigits($0.phoneNumber) == compactDigits(number) }
        let title = matchedContact?.name ?? number
        let avatar = matchedContact?.avatar ?? AvatarSeed(topHex: 0x2D2D2D, bottomHex: 0x5B5B5B, initials: "NU", symbolName: "phone.fill")
        let detail = matchedContact == nil ? "Manual dial" : "Dialed from keypad"
        let record = CallRecord(id: UUID(), title: title, detail: detail, avatar: avatar, timestamp: Date(), mode: mode, direction: .outgoing, duration: "0m", threadID: nil)
        calls.insert(record, at: 0)
        showActiveCall(title: title, avatar: avatar, mode: mode)
    }

    func toggleFavorite(contactID: UUID) {
        guard let index = contacts.firstIndex(where: { $0.id == contactID }) else { return }
        var updated = contacts[index]
        updated.isFavorite.toggle()
        contacts[index] = updated
    }

    func publishTextStatus(_ text: String) {
        let update = StatusUpdate(id: UUID(), ownerID: currentUserID, ownerName: profile.displayName, avatar: profile.avatar, postedAt: Date(), body: text, media: nil, isViewed: false, isMine: true)
        statuses.insert(update, at: 0)
        currentTab = .updates
        showToast(title: "Status shared", subtitle: "Your text update will disappear after 24 hours.")
    }

    func publishPhotoStatus(template: MediaTemplate, caption: String) {
        let update = StatusUpdate(id: UUID(), ownerID: currentUserID, ownerName: profile.displayName, avatar: profile.avatar, postedAt: Date(), body: caption, media: template, isViewed: false, isMine: true)
        statuses.insert(update, at: 0)
        currentTab = .updates
        showToast(title: "Status shared", subtitle: "Your new photo update is live.")
    }

    func markStatusViewed(_ statusID: UUID) {
        guard let index = statuses.firstIndex(where: { $0.id == statusID }) else { return }
        var updated = statuses[index]
        updated.isViewed = true
        statuses[index] = updated
    }

    func deleteMessage(messageID: UUID, in threadID: UUID) {
        updateThread(threadID) { thread in
            thread.messages.removeAll { $0.id == messageID }
        }
    }

    func deleteThread(_ threadID: UUID) {
        chats.removeAll { $0.id == threadID }
    }

    func archiveThread(_ threadID: UUID) {
        updateThread(threadID) { thread in
            thread.archived = true
        }
        showToast(title: "Chat archived", subtitle: "You can find it in the archived section.")
    }

    func unarchiveThread(_ threadID: UUID) {
        updateThread(threadID) { thread in
            thread.archived = false
        }
    }

    func toggleMute(threadID: UUID) {
        updateThread(threadID) { thread in
            thread.muted.toggle()
        }
    }

    func togglePin(threadID: UUID) {
        updateThread(threadID) { thread in
            thread.pinned.toggle()
        }
    }

    func toggleChannelFollow(_ channelID: UUID) {
        guard let index = channels.firstIndex(where: { $0.id == channelID }) else { return }
        var updated = channels[index]
        updated.isFollowed.toggle()
        channels[index] = updated
        let verb = updated.isFollowed ? "Following" : "Unfollowed"
        showToast(title: verb, subtitle: "\(updated.name) was updated.")
    }

    func createCommunity(name: String, description: String, selectedMemberIDs: [UUID]? = nil) -> UUID {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            showToast(title: "Invalid name", subtitle: "Community name cannot be empty.")
            return UUID()
        }
        let communityID = UUID()
        let candidateIDs = selectedMemberIDs ?? Array(contacts.filter(\.isFavorite).prefix(3).map(\.id))
        let memberIDs = candidateIDs.isEmpty ? Array(contacts.prefix(2).map(\.id)) : candidateIDs
        let announcementThreadID = UUID()
        let generalThreadID = UUID()

        let announcementThread = ChatThread(
            id: announcementThreadID,
            title: "\(trimmedName) Announcements",
            avatar: AvatarSeed(topHex: 0x1D3C24, bottomHex: 0x31B85E, initials: String(trimmedName.prefix(2)).uppercased(), symbolName: "megaphone.fill"),
            participantIDs: memberIDs,
            isGroup: true,
            communityID: communityID,
            messages: [
                ChatMessage(id: UUID(), senderID: currentUserID, sentAt: Date(), content: .text("Welcome to \(trimmedName). Important updates will land here."), delivery: .read, isStarred: false)
            ],
            unreadCount: 0,
            pinned: false,
            muted: false,
            subtitle: "Announcements only",
            automatedReplies: [],
            automatedReplyCursor: 0
        )

        let generalThread = ChatThread(
            id: generalThreadID,
            title: "General",
            avatar: AvatarSeed(topHex: 0x153149, bottomHex: 0x4E97FF, initials: "GE", symbolName: "message.fill"),
            participantIDs: memberIDs,
            isGroup: true,
            communityID: communityID,
            messages: [
                ChatMessage(id: UUID(), senderID: currentUserID, sentAt: Date(), content: .text("Say hi and drop the kind of updates you want this community to carry."), delivery: .read, isStarred: false)
            ],
            unreadCount: 0,
            pinned: false,
            muted: false,
            subtitle: "Open discussion",
            automatedReplies: memberIDs.prefix(1).map { AutomatedReply(senderID: $0, content: .text("Happy to be here. I'll share notes once the week gets moving.")) },
            automatedReplyCursor: 0
        )

        chats.insert(contentsOf: [generalThread, announcementThread], at: 0)
        let community = Community(id: communityID, name: trimmedName, description: description, avatar: AvatarSeed(topHex: 0x163B27, bottomHex: 0x39BF6D, initials: String(trimmedName.prefix(2)).uppercased(), symbolName: "person.3.fill"), memberCount: memberIDs.count + 1, announcementThreadID: announcementThreadID, groupThreadIDs: [generalThreadID])
        communities.insert(community, at: 0)
        currentTab = .communities
        showToast(title: "Community created", subtitle: "\(trimmedName) is ready to use.")
        return communityID
    }

    func addGroup(to communityID: UUID, name: String) {
        guard let communityIndex = communities.firstIndex(where: { $0.id == communityID }) else { return }
        let memberIDs = Array(contacts.prefix(4).map(\.id))
        let thread = ChatThread(
            id: UUID(),
            title: name,
            avatar: AvatarSeed(topHex: 0x163149, bottomHex: 0x4B90FF, initials: String(name.prefix(2)).uppercased(), symbolName: "person.3.fill"),
            participantIDs: memberIDs,
            isGroup: true,
            communityID: communityID,
            messages: [
                ChatMessage(id: UUID(), senderID: currentUserID, sentAt: Date(), content: .text("Welcome to \(name)."), delivery: .read, isStarred: false)
            ],
            unreadCount: 0,
            pinned: false,
            muted: false,
            subtitle: "New group",
            automatedReplies: memberIDs.prefix(1).map { AutomatedReply(senderID: $0, content: .text("First note landed. I'm in.")) },
            automatedReplyCursor: 0
        )
        chats.insert(thread, at: 0)
        var community = communities[communityIndex]
        community.groupThreadIDs.append(thread.id)
        community.memberCount += max(memberIDs.count - 1, 0)
        communities[communityIndex] = community
        showToast(title: "Group added", subtitle: "\(name) was created.")
    }

    func updateProfile(name: String, headline: String, avatar: AvatarSeed) {
        var updated = profile
        updated.displayName = name
        updated.headline = headline
        updated.avatar = avatar
        profile = updated
        showToast(title: "Profile updated", subtitle: "Your details are saved.")
    }

    func addRecoveryEmail(_ email: String) {
        var updated = profile
        updated.recoveryEmail = email
        updated.verifyEmailBannerVisible = false
        profile = updated
        showToast(title: "Email added", subtitle: "You can recover your account with \(email).")
    }

    func dismissVerifyEmailBanner() {
        var updated = profile
        updated.verifyEmailBannerVisible = false
        profile = updated
    }

    func toggleReadReceipts() {
        var updated = profile
        updated.readReceiptsEnabled.toggle()
        profile = updated
    }

    func toggleLockedChats() {
        var updated = profile
        updated.lockedChatsEnabled.toggle()
        profile = updated
    }

    func toggleDisappearingMessages() {
        var updated = profile
        updated.disappearingMessagesEnabled.toggle()
        profile = updated
    }

    func toggleAutoDownloadOnWiFi() {
        var updated = profile
        updated.autoDownloadOnWiFi.toggle()
        profile = updated
    }

    func addList(named name: String) {
        messageLists.insert(MessageListItem(id: UUID(), name: name, summary: "New custom list"), at: 0)
        showToast(title: "List created", subtitle: "\(name) is now available under Lists.")
    }

    func addBroadcast(named name: String) {
        let members = contacts.filter(\.isFavorite).map(\.id)
        broadcastLists.insert(BroadcastListItem(id: UUID(), name: name, memberIDs: members, lastSent: Date()), at: 0)
        showToast(title: "Broadcast created", subtitle: "\(name) is ready to send.")
    }

    func addLinkedDevice(named name: String) {
        linkedDevices.insert(LinkedDevice(id: UUID(), name: name, lastSeen: "Linked just now", isActive: true), at: 0)
        showToast(title: "Device linked", subtitle: "\(name) can now use QuickChat.")
    }

    func removeLinkedDevice(_ deviceID: UUID) {
        linkedDevices.removeAll { $0.id == deviceID }
        showToast(title: "Device removed", subtitle: "That device is no longer linked.")
    }

    func toggleStar(messageID: UUID, in threadID: UUID) {
        updateThread(threadID) { thread in
            guard let index = thread.messages.firstIndex(where: { $0.id == messageID }) else { return }
            thread.messages[index].isStarred.toggle()
        }
    }

    func toggleHeart(messageID: UUID, in threadID: UUID) {
        updateThread(threadID) { thread in
            guard let index = thread.messages.firstIndex(where: { $0.id == messageID }) else { return }
            thread.messages[index].hearted.toggle()
        }
    }

    func message(id messageID: UUID, in threadID: UUID) -> ChatMessage? {
        thread(id: threadID)?.messages.first(where: { $0.id == messageID })
    }

    func starredMessages() -> [(thread: ChatThread, message: ChatMessage)] {
        chats.flatMap { thread in
            thread.messages.filter(\.isStarred).map { (thread, $0) }
        }
        .sorted { $0.message.sentAt > $1.message.sentAt }
    }

    func searchHits(query: String) -> [SearchHit] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return [] }
        let queryWords = normalized.split(separator: " ").map(String.init)

        return chats.flatMap { thread in
            thread.messages.compactMap { message in
                let fields = [thread.title, message.content.previewText, contactName(id: message.senderID)]
                let haystack = fields.joined(separator: " ").lowercased()
                let haystackWords = haystack.split(whereSeparator: { !$0.isLetter && !$0.isNumber }).map(String.init)
                let allWordsMatch = queryWords.allSatisfy { qw in
                    haystackWords.contains { hw in hw.hasPrefix(qw) }
                }
                guard allWordsMatch else { return nil }
                return SearchHit(threadID: thread.id, threadTitle: thread.title, message: message)
            }
        }
        .sorted { $0.message.sentAt > $1.message.sentAt }
    }

    func hits(for category: SearchCategory) -> [SearchHit] {
        chats.flatMap { thread in
            thread.messages.compactMap { message in
                guard message.content.searchCategory == category else { return nil }
                return SearchHit(threadID: thread.id, threadTitle: thread.title, message: message)
            }
        }
        .sorted { $0.message.sentAt > $1.message.sentAt }
    }

    func messageItems(for threadID: UUID) -> [MessageRowItem] {
        guard let thread = thread(id: threadID) else { return [] }
        var result: [MessageRowItem] = []
        var lastDay: String?
        for message in thread.messages {
            let dayLabel = DateFormats.messageDay.string(from: message.sentAt)
            if dayLabel != lastDay {
                result.append(.dateMarker(dayLabel))
                lastDay = dayLabel
            }
            result.append(.message(message))
        }
        return result
    }

    func sharedMediaCount(for threadID: UUID) -> Int {
        thread(id: threadID)?.messages.filter { $0.content.searchCategory == .photos || $0.content.searchCategory == .videos || $0.content.searchCategory == .gifs }.count ?? 0
    }

    func compactDigits(_ value: String) -> String {
        value.filter(\.isNumber)
    }

    private func updateThread(_ threadID: UUID, update: (inout ChatThread) -> Void) {
        guard let index = chats.firstIndex(where: { $0.id == threadID }) else { return }
        var thread = chats[index]
        update(&thread)
        chats[index] = thread
    }

    private func showToast(title: String, subtitle: String) {
        toastWorkItem?.cancel()
        let banner = ToastBanner(title: title, subtitle: subtitle)
        toast = banner
        let workItem = DispatchWorkItem { [weak self] in
            guard self?.toast == banner else { return }
            self?.toast = nil
        }
        toastWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4, execute: workItem)
    }

    private func adding(_ component: Calendar.Component, _ value: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: component, value: value, to: date) ?? date
    }
}

typealias WhatsAppStore = MessagesStore

final class OpenAIReplySettings {
    static let shared = OpenAIReplySettings()

    private init() {}

    func validatedAPIKey() -> String? {
        let candidate = keyFromEnvironment() ?? keyFromInfoPlist() ?? keyFromEnvFile() ?? keyFromUserDefaults()
        guard let rawKey = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !rawKey.isEmpty else {
            return nil
        }
        return rawKey
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

final class OpenAIReplyGenerator: ReplyGenerating {
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
    private let apiKey: String

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    static func makeIfConfigured() -> OpenAIReplyGenerator? {
        guard let apiKey = OpenAIReplySettings.shared.validatedAPIKey() else {
            return nil
        }
        return OpenAIReplyGenerator(apiKey: apiKey)
    }

    func generateReply(
        as senderName: String,
        bio: String,
        threadTitle: String,
        isGroupChat: Bool,
        recentMessages: [GeneratedReplyContextMessage],
        completion: @escaping (Result<String, GeneratedReplyError>) -> Void
    ) {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            completion(.failure(GeneratedReplyError(message: "Invalid OpenAI endpoint.")))
            return
        }

        let transcript = recentMessages.map { message in
            "\(message.senderName): \(message.text)"
        }
        .joined(separator: "\n")

        let systemPrompt = """
        You are simulating a QuickChat reply from \(senderName).
        Bio: \(bio)
        Conversation: \(isGroupChat ? "group chat" : "direct chat") named "\(threadTitle)".
        Reply like a real person texting on a phone.
        Keep it concise, natural, and specific to the conversation.
        Use 1 to 3 short sentences.
        Never mention being an AI, assistant, or language model.
        Return only the message text.
        """

        let userPrompt = """
        Recent conversation, oldest to newest:
        \(transcript)

        Write \(senderName)'s next reply.
        """

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "temperature": 0.8,
            "max_tokens": 120
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            completion(.failure(GeneratedReplyError(message: "Failed to encode request payload.")))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = bodyData

        session.dataTask(with: request) { data, _, error in
            if let error {
                completion(.failure(GeneratedReplyError(message: "Network error: \(error.localizedDescription)")))
                return
            }
            guard let data,
                  let decoded = try? JSONDecoder().decode(ChatResponse.self, from: data),
                  let reply = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
                  !reply.isEmpty else {
                completion(.failure(GeneratedReplyError(message: "OpenAI response was empty.")))
                return
            }
            completion(.success(reply))
        }.resume()
    }
}

private enum AppTheme {
    static let background = Color(hex: 0x020405)
    static let surface = Color(hex: 0x111416)
    static let elevated = Color(hex: 0x1A1F22)
    static let separator = Color.white.opacity(0.08)
    static let accent = Color(hex: 0x25D366)
    static let accentDeep = Color(hex: 0x0B6E58)
    static let secondaryText = Color(hex: 0x8C9297)
    static let tertiaryText = Color(hex: 0x657076)
    static let incomingBubble = Color(hex: 0x232729)
    static let outgoingBubble = Color(hex: 0x114B3A)
    static let searchFill = Color(hex: 0x232528)
    static let error = Color(hex: 0xFF6B6B)
}

private enum DateFormats {
    static let chatListTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()

    static let chatListDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d/yy"
        return formatter
    }()

    static let messageDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }()

    static let callSchedule: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    static let messageTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
}

private extension AvatarSeed {
    var startColor: Color { Color(hex: topHex) }
    var endColor: Color { Color(hex: bottomHex) }
}

private extension ChatThread {
    func preview(currentUserID: UUID) -> String {
        guard let message = lastMessage else { return "No messages yet" }
        if message.senderID == currentUserID {
            return "You: \(message.content.previewText)"
        }
        return message.content.previewText
    }
}

private extension Date {
    func listTimestamp() -> String {
        if Calendar.current.isDateInToday(self) {
            return DateFormats.chatListTime.string(from: self)
        }
        if Calendar.current.isDateInYesterday(self) {
            return "Yesterday"
        }
        return DateFormats.chatListDay.string(from: self)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private extension String {
    var accessibilitySlug: String {
        let mapped = lowercased().map { character -> Character in
            character.isLetter || character.isNumber ? character : "_"
        }
        let collapsed = String(mapped).replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

private extension Color {
    init(hex: Int) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

struct MessagesRootView: View {
    @EnvironmentObject private var store: MessagesStore

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.edgesIgnoringSafeArea(.all)

            tabView(for: .updates) {
                NavigationView {
                    UpdatesView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            tabView(for: .calls) {
                NavigationView {
                    CallsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            tabView(for: .communities) {
                NavigationView {
                    CommunitiesView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            tabView(for: .chats) {
                NavigationView {
                    ChatsView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            tabView(for: .you) {
                NavigationView {
                    YouView()
                }
                .navigationViewStyle(StackNavigationViewStyle())
            }

            VStack(spacing: 0) {
                if let toast = store.toast {
                    ToastView(toast: toast)
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                        .transition(.opacity)
                }
                if store.activeThreadID == nil {
                    BottomTabBar(selection: $store.currentTab)
                }
            }

            if store.activeCall != nil {
                CallingOverlayView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: store.activeCall != nil)
    }

    private func tabView<Content: View>(for tab: WhatsAppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(store.currentTab == tab ? 1 : 0)
            .allowsHitTesting(store.currentTab == tab)
            .accessibility(hidden: store.currentTab != tab)
    }
}

typealias WhatsAppRootView = MessagesRootView

private struct BottomTabBar: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Binding var selection: WhatsAppTab

    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .updates, label: "Updates", icon: "circle")
            tabButton(tab: .calls, label: "Calls", icon: "phone")
            tabButton(tab: .communities, label: "Groups", icon: "person.3")
            tabButton(tab: .chats, label: "QuickChat", icon: "message.fill", badge: totalUnreadCount())
            tabButton(tab: .you, label: "Me", icon: "person.crop.circle")
        }
        .padding(.top, 12)
        .padding(.bottom, max(12, AppLayout.bottomInset))
        .background(
            BlurView(style: .dark)
                .overlay(Color.black.opacity(0.55))
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(tab: WhatsAppTab, label: String, icon: String, badge: Int? = nil) -> some View {
        Button(action: {
            selection = tab
        }) {
            VStack(spacing: 7) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 25, weight: selection == tab ? .semibold : .regular))
                        .foregroundColor(selection == tab ? .white : AppTheme.secondaryText)
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(AppTheme.accent))
                            .offset(x: 14, y: -8)
                    }
                }
                Text(label)
                    .font(.system(size: 12, weight: selection == tab ? .semibold : .regular))
                    .foregroundColor(selection == tab ? .white : AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(identifier: "tab_\(tab.rawValue)")
    }

    private func totalUnreadCount() -> Int {
        store.chats.reduce(0) { $0 + $1.unreadCount }
    }
}

private struct ToastView: View {
    let toast: ToastBanner

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.accent)
                .font(.system(size: 18, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(toast.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(toast.subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface.opacity(0.96))
        )
        .accessibilityElement(children: .combine)
        .accessibility(label: Text("\(toast.title). \(toast.subtitle)"))
        .accessibility(identifier: "toast_banner")
    }
}

private struct CallingOverlayView: View {
    @EnvironmentObject private var store: WhatsAppStore

    var body: some View {
        if let call = store.activeCall {
            ZStack {
                Color.black.opacity(0.92).edgesIgnoringSafeArea(.all)
                VStack(spacing: 24) {
                    Spacer()
                    AvatarView(avatar: call.avatar, size: 100)
                    Text(call.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text(call.mode == .video ? "Video calling..." : "Calling...")
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.secondaryText)
                    Spacer()
                    Button(action: {
                        store.activeCall = nil
                    }) {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .frame(width: 72, height: 72)
                            .background(Circle().fill(Color.red))
                    }
                    .padding(.bottom, 60)
                }
            }
            .accessibility(identifier: "calling_overlay")
        }
    }
}

struct ChatsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @State private var filter: ChatFilter = .all
    @State private var showingMenu = false
    @State private var showingCompose = false
    @State private var showingQuickCapture = false
    @State private var showingSearch = false
    @State private var selectedThreadID: UUID?

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        searchButton
                        filterRow
                        threadList
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 120)
                }
            }

            NavigationLink(destination: selectedThreadDestination(), isActive: selectedThreadBinding) {
                EmptyView()
            }
            .hidden()

            NavigationLink(destination: SearchHubView().navigationBarHidden(true), isActive: $showingSearch) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCompose) {
            NewChatSheet { contactID in
                let threadID = store.ensureDirectThread(with: contactID)
                showingCompose = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    selectedThreadID = threadID
                }
            }
            .environmentObject(store)
        }
        .sheet(isPresented: $showingQuickCapture) {
            QuickCaptureSheet()
                .environmentObject(store)
        }
        .actionSheet(isPresented: $showingMenu) {
            ActionSheet(
                title: Text("Chats"),
                buttons: [
                    .default(Text("Mark all read")) { store.markAllChatsRead() },
                    .default(Text("Open profile")) { store.currentTab = .you },
                    .cancel()
                ]
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                CircleIconButton(icon: "ellipsis", identifier: "chats_more_button") {
                    showingMenu = true
                }
                Spacer()
                HStack(spacing: 14) {
                    CircleIconButton(icon: "camera.fill", identifier: "chats_camera_button") {
                        showingQuickCapture = true
                    }
                    CircleIconButton(icon: "plus", fill: AppTheme.accent, iconColor: .black, identifier: "chats_new_button") {
                        showingCompose = true
                    }
                }
            }

            Text("Chats")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 18)
        .padding(.top, AppLayout.topInset + 8)
        .padding(.bottom, 10)
    }

    private var searchButton: some View {
        Button(action: {
            showingSearch = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundColor(AppTheme.secondaryText)
                Text("Ask Meta AI or Search")
                    .font(.system(size: 19))
                    .foregroundColor(AppTheme.secondaryText)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.searchFill)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(identifier: "chat_search_trigger")
    }

    private var filterRow: some View {
        HStack(spacing: 10) {
            ForEach(ChatFilter.allCases, id: \.rawValue) { entry in
                Button(action: {
                    filter = entry
                }) {
                    Text(entry.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(filter == entry ? .black : AppTheme.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(filter == entry ? AppTheme.accent : AppTheme.surface))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var threadList: some View {
        let threads = store.sortedChats(filter: filter)
        return VStack(spacing: 0) {
            if threads.isEmpty && filter == .archived {
                VStack(spacing: 14) {
                    Image(systemName: "archivebox")
                        .font(.system(size: 42))
                        .foregroundColor(AppTheme.tertiaryText)
                    Text("No archived chats")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    Text("Long-press a chat and choose Archive to move it here.")
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.tertiaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
            }
            ForEach(threads) { thread in
                Button(action: {
                    selectedThreadID = thread.id
                }) {
                    ChatThreadRow(thread: thread)
                        .environmentObject(store)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button(action: { store.togglePin(threadID: thread.id) }) {
                        Text(thread.pinned ? "Unpin" : "Pin")
                        Image(systemName: thread.pinned ? "pin.slash" : "pin")
                    }
                    Button(action: { store.toggleMute(threadID: thread.id) }) {
                        Text(thread.muted ? "Unmute" : "Mute")
                        Image(systemName: thread.muted ? "bell" : "bell.slash")
                    }
                    Button(action: {
                        if thread.archived {
                            store.unarchiveThread(thread.id)
                        } else {
                            store.archiveThread(thread.id)
                        }
                    }) {
                        Text(thread.archived ? "Unarchive" : "Archive")
                        Image(systemName: thread.archived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Button(action: { store.deleteThread(thread.id) }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                }
                .accessibility(label: Text(thread.title))
                .accessibility(value: Text(thread.preview(currentUserID: store.currentUserID)))
                .accessibility(identifier: "chat_row_\(thread.id.uuidString)")

                Divider()
                    .background(AppTheme.separator)
                    .padding(.leading, 72)
            }
        }
    }

    private func selectedThreadDestination() -> AnyView {
        guard let selectedThreadID = selectedThreadID else {
            return AnyView(EmptyView())
        }
        return AnyView(ChatThreadView(threadID: selectedThreadID).navigationBarHidden(true))
    }

    private var selectedThreadBinding: Binding<Bool> {
        Binding<Bool>(
            get: { selectedThreadID != nil },
            set: { isActive in
                if !isActive {
                    selectedThreadID = nil
                }
            }
        )
    }
}

private struct ChatThreadRow: View {
    @EnvironmentObject private var store: WhatsAppStore
    let thread: ChatThread

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarView(avatar: thread.avatar, size: 56)
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top) {
                    Text(thread.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(thread.lastActivity.listTimestamp())
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(thread.unreadCount > 0 ? AppTheme.accent : AppTheme.secondaryText)
                }

                HStack(alignment: .center, spacing: 7) {
                    if let lastMessage = thread.lastMessage, lastMessage.senderID == store.currentUserID {
                        Image(systemName: lastMessage.delivery.iconName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(lastMessage.delivery == .read ? AppTheme.accent : AppTheme.secondaryText)
                    }

                    Text(thread.preview(currentUserID: store.currentUserID))
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)

                    Spacer(minLength: 0)
                }

                if thread.pinned || thread.muted {
                    HStack(spacing: 10) {
                        if thread.pinned {
                            LabelText(icon: "pin.fill", text: "Pinned")
                        }
                        if thread.muted {
                            LabelText(icon: "bell.slash.fill", text: "Muted")
                        }
                    }
                }
            }

            if thread.unreadCount > 0 {
                Text("\(thread.unreadCount)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(AppTheme.accent))
                    .padding(.top, 34)
            }
        }
        .padding(.vertical, 16)
    }
}

struct SearchHubView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var query = ""

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            ForEach(SearchCategory.allCases) { category in
                                NavigationLink(destination: SearchCategoryResultsView(category: category).navigationBarHidden(true)) {
                                    SearchCategoryRow(category: category)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        } else {
                            searchResults
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.secondaryText)
                TextField("Ask Meta AI or Search", text: $query)
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .accentColor(AppTheme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.searchFill))
        }
        .padding(.horizontal, 18)
        .padding(.top, AppLayout.topInset + 8)
        .padding(.bottom, 10)
    }

    private var searchResults: some View {
        let hits = store.searchHits(query: query)
        return VStack(alignment: .leading, spacing: 18) {
            if hits.isEmpty {
                EmptyStateCard(title: "No matches yet", subtitle: "Try a name, link title, or message snippet.")
            } else {
                Text("QuickChat")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundColor(.white)

                ForEach(hits) { hit in
                    NavigationLink(destination: ChatThreadView(threadID: hit.threadID).navigationBarHidden(true)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(hit.threadTitle)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text(hit.message.content.previewText)
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.secondaryText)
                                .lineLimit(2)
                            Text(DateFormats.messageDay.string(from: hit.message.sentAt))
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.tertiaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

private struct SearchCategoryRow: View {
    let category: SearchCategory

    var body: some View {
        HStack(spacing: 18) {
            Image(systemName: category.symbolName)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(AppTheme.accent)
                .frame(width: 42)
            Text(category.title)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "arrow.up.left.circle")
                .font(.system(size: 22))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.vertical, 14)
        .overlay(Divider().background(AppTheme.separator), alignment: .bottom)
    }
}

struct SearchCategoryResultsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let category: SearchCategory

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    Text(category.title)
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, AppLayout.topInset + 8)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        let hits = store.hits(for: category)
                        if hits.isEmpty {
                            EmptyStateCard(title: "Nothing shared here yet", subtitle: "This category will fill up as chats and communities use it.")
                        } else {
                            ForEach(hits) { hit in
                                NavigationLink(destination: ChatThreadView(threadID: hit.threadID).navigationBarHidden(true)) {
                                    SearchResultRow(hit: hit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct SearchResultRow: View {
    let hit: SearchHit

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hit.threadTitle)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(.white)
            Text(hit.message.content.previewText)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
                .lineLimit(3)
            Text(hit.message.sentAt.listTimestamp())
                .font(.system(size: 13))
                .foregroundColor(AppTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
    }
}

struct ChatThreadView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let threadID: UUID
    @State private var draft = ""
    @State private var showingAttachmentSheet = false
    @State private var showingInfoSheet = false
    @State private var keyboardInset: CGFloat = 0
    @State private var replyingToMessage: ChatMessage?

    private var thread: ChatThread? {
        store.thread(id: threadID)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ChatWallpaper()
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                header
                Divider().background(AppTheme.separator)
                messageList
                composer
            }
            .padding(.bottom, keyboardInset)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $showingAttachmentSheet) {
            AttachmentPickerSheet(threadID: threadID)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingInfoSheet) {
            ChatInfoSheet(threadID: threadID)
                .environmentObject(store)
        }
        .onAppear {
            store.openThread(threadID)
        }
        .onDisappear {
            store.closeThread(threadID)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { notification in
            guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let screenHeight = UIScreen.main.bounds.height
            let overlap = max(0, screenHeight - frame.minY - AppLayout.bottomInset)
            keyboardInset = overlap
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 28, weight: .medium))
                    if let unreadCount = thread?.unreadCount, unreadCount > 0 {
                        Text("\(min(unreadCount, 99))")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibility(identifier: "chat_back_button")

            if let thread = thread {
                AvatarView(avatar: thread.avatar, size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .truncationMode(.tail)
                    if store.profile.disappearingMessagesEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 12))
                            Text("Disappearing messages on")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(AppTheme.accent.opacity(0.8))
                        .lineLimit(1)
                    } else {
                        Text(thread.subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
                .layoutPriority(1)
            }

            Spacer(minLength: 8)

            HStack(spacing: 14) {
                CircleIconButton(icon: "video", size: 22, fill: .clear, identifier: "chat_video_button") {
                    store.startCall(for: threadID, mode: .video)
                }
                CircleIconButton(icon: "phone", size: 21, fill: .clear, identifier: "chat_call_button") {
                    store.startCall(for: threadID, mode: .voice)
                }
                CircleIconButton(icon: "ellipsis", size: 19, fill: .clear, identifier: "chat_info_button") {
                    showingInfoSheet = true
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, AppLayout.topInset + 6)
        .padding(.bottom, 12)
        .background(Color.black.opacity(0.66))
    }

    private var messageList: some View {
        let items = store.messageItems(for: threadID)
        if items.isEmpty {
            return AnyView(
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.tertiaryText)
                    Text("No messages yet")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText)
                    Text("Send a message to start the conversation.")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.tertiaryText)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            )
        }
        if #available(iOS 14.0, *) {
            return AnyView(scrollReaderMessageList(items: items))
        } else {
            return AnyView(rotatedMessageList(items: items))
        }
    }

    @available(iOS 14.0, *)
    private func scrollReaderMessageList(items: [MessageRowItem]) -> some View {
        let isTyping = store.typingThreadIDs.contains(threadID)
        return ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        Group {
                            switch item {
                            case .dateMarker(let label):
                                DateMarkerView(label: label)
                            case .message(let message):
                                MessageBubbleView(threadID: threadID, message: message, onReply: {
                                    replyingToMessage = message
                                })
                                    .environmentObject(store)
                            }
                        }
                        .id(item.id)
                    }
                    if isTyping {
                        TypingIndicatorView()
                            .id("typing-indicator")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 16)
                .padding(.bottom, 12)
            }
            .onAppear {
                if let lastItem = items.last {
                    proxy.scrollTo(lastItem.id, anchor: .bottom)
                }
            }
            .onChange(of: items.count) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    let latest = store.messageItems(for: threadID)
                    if let lastItem = latest.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastItem.id, anchor: .bottom)
                        }
                    }
                }
            }
            .onChange(of: isTyping) { typing in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    if typing {
                        withAnimation(.easeOut(duration: 0.2)) {
                            proxy.scrollTo("typing-indicator", anchor: .bottom)
                        }
                    } else {
                        let latest = store.messageItems(for: threadID)
                        if let lastItem = latest.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastItem.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
    }

    private func rotatedMessageList(items: [MessageRowItem]) -> some View {
        let reversed = Array(items.reversed())
        let isTyping = store.typingThreadIDs.contains(threadID)
        return ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if isTyping {
                    TypingIndicatorView()
                        .rotationEffect(.degrees(180))
                }
                ForEach(reversed) { item in
                    Group {
                        switch item {
                        case .dateMarker(let label):
                            DateMarkerView(label: label)
                        case .message(let message):
                            MessageBubbleView(threadID: threadID, message: message, onReply: {
                                replyingToMessage = message
                            })
                                .environmentObject(store)
                        }
                    }
                    .rotationEffect(.degrees(180))
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .rotationEffect(.degrees(180))
        }
    }

    private var composer: some View {
        VStack(spacing: 0) {
            if let replying = replyingToMessage {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.accent)
                        .frame(width: 4)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.contactName(id: replying.senderID))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                        Text(replying.content.previewText)
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(1)
                    }
                    Spacer()
                    Button(action: { replyingToMessage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppTheme.surface.opacity(0.95))
            }

            HStack(alignment: .center, spacing: 10) {
            Button(action: {
                showingAttachmentSheet = true
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 25, weight: .regular))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())

            HStack(spacing: 8) {
                ChatComposerTextField(text: $draft, placeholder: "Message", onReturn: sendDraft)
                    .frame(maxWidth: .infinity, minHeight: 28, maxHeight: 28, alignment: .leading)
                    .layoutPriority(1)

                if draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button(action: {
                        store.sendCameraCapture(to: threadID)
                    }) {
                        Image(systemName: "camera")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibility(identifier: "chat_quick_camera_button")

                    Button(action: {
                        store.sendVoiceNote(to: threadID)
                    }) {
                        Image(systemName: "mic")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibility(identifier: "chat_voice_note_button")
                } else {
                    Button(action: sendDraft) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(AppTheme.accent))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibility(identifier: "chat_send_button")
                }
            }
            .padding(.horizontal, 13)
            .frame(minHeight: 48)
            .background(Capsule().fill(AppTheme.surface.opacity(0.98)))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, max(10, AppLayout.bottomInset))
        .background(Color.black.opacity(0.68))
        }
    }

    private func sendDraft() {
        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let capped = String(trimmed.prefix(5000))
        draft = ""
        store.sendText(capped, to: threadID, replyToID: replyingToMessage?.id)
        replyingToMessage = nil
    }
}

private struct ChatComposerTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onReturn: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onReturn: onReturn)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange(_:)), for: .editingChanged)
        textField.textColor = .white
        textField.tintColor = UIColor(red: 37.0 / 255.0, green: 211.0 / 255.0, blue: 102.0 / 255.0, alpha: 1)
        textField.font = UIFont.systemFont(ofSize: 16)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(white: 0.56, alpha: 1)]
        )
        textField.returnKeyType = .send
        textField.autocorrectionType = .yes
        textField.accessibilityIdentifier = "chat_compose_field"
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        private var text: Binding<String>
        private let onReturn: () -> Void

        init(text: Binding<String>, onReturn: @escaping () -> Void) {
            self.text = text
            self.onReturn = onReturn
        }

        @objc func textDidChange(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onReturn()
            return false
        }
    }
}

private struct DateMarkerView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 13)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.55)))
    }
}

private struct TypingIndicatorView: View {
    @State private var phase: Int = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(AppTheme.secondaryText)
                        .frame(width: 8, height: 8)
                        .scaleEffect(phase == index ? 1.35 : 0.85)
                        .opacity(phase == index ? 1.0 : 0.45)
                        .animation(.easeInOut(duration: 0.3), value: phase)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.incomingBubble)
            )
            Spacer()
        }
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

private struct MessageBubbleView: View {
    @EnvironmentObject private var store: WhatsAppStore
    let threadID: UUID
    let message: ChatMessage
    var onReply: (() -> Void)?

    private var isOutgoing: Bool {
        message.senderID == store.currentUserID
    }

    private var thread: ChatThread? {
        store.thread(id: threadID)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isOutgoing {
                AvatarView(avatar: store.contactAvatar(id: message.senderID), size: 30)
            }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    if let thread = thread, thread.isGroup, !isOutgoing {
                        Text(store.contactName(id: message.senderID))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(store.senderAccent(for: message.senderID))
                    }

                    if let replyToID = message.replyToID,
                       let repliedMessage = store.message(id: replyToID, in: threadID) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.contactName(id: repliedMessage.senderID))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.accent)
                            Text(repliedMessage.content.previewText)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.08)))
                    }

                    MessageContentView(content: message.content)

                    HStack(spacing: 6) {
                        Spacer()
                        if message.isStarred {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                        Text(DateFormats.messageTime.string(from: message.sentAt))
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.secondaryText)
                        if isOutgoing {
                            Image(systemName: message.delivery.iconName)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(message.delivery == .read ? AppTheme.accent : AppTheme.secondaryText)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isOutgoing ? AppTheme.outgoingBubble : AppTheme.incomingBubble)
                )
                .frame(maxWidth: min(UIScreen.main.bounds.width * 0.7, 400), alignment: .leading)
                .onTapGesture(count: 2) {
                    store.toggleHeart(messageID: message.id, in: threadID)
                }
                .contextMenu {
                    if let onReply = onReply {
                        Button(action: onReply) {
                            Text("Reply")
                            Image(systemName: "arrowshape.turn.up.left")
                        }
                    }
                    Button(action: {
                        store.toggleStar(messageID: message.id, in: threadID)
                    }) {
                        Text(message.isStarred ? "Remove star" : "Star")
                        Image(systemName: message.isStarred ? "star.slash" : "star")
                    }
                    Button(action: {
                        UIPasteboard.general.string = message.content.previewText
                    }) {
                        Text("Copy")
                        Image(systemName: "doc.on.doc")
                    }
                    Button(action: {
                        store.deleteMessage(messageID: message.id, in: threadID)
                    }) {
                        Text("Delete")
                        Image(systemName: "trash")
                    }
                }

                if message.hearted {
                    Text("\u{2764}\u{FE0F}")
                        .font(.system(size: 16))
                        .padding(4)
                        .background(Circle().fill(AppTheme.surface))
                        .offset(y: -6)
                }
            }
            .frame(maxWidth: .infinity, alignment: isOutgoing ? .trailing : .leading)

            if isOutgoing {
                EmptyView()
            }
        }
    }
}

private struct MessageContentView: View {
    let content: MessageContent

    var body: some View {
        switch content {
        case .text(let value):
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(.white)
        case .visual(let template, let kind, let caption):
            let accessibilityTitle = caption.isEmpty ? template.title : caption
            VStack(alignment: .leading, spacing: 10) {
                MediaCard(template: template, badge: kind.rawValue.uppercased(), compact: true)
                if !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibility(label: Text(accessibilityTitle))
            .accessibility(identifier: "visual_message_card_\(accessibilityTitle.accessibilitySlug)")
        case .link(let title, let url, let description):
            Button(action: {
                if let linkURL = URL(string: url) {
                    UIApplication.shared.open(linkURL)
                }
            }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(url)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                        .underline()
                }
            }
            .buttonStyle(PlainButtonStyle())
        case .document(let name, let size):
            HStack(spacing: 10) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Text(size)
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        case .audio(let duration, let transcript):
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.35))
                        .frame(width: 110, height: 6)
                    Text(duration)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText)
                }
                Text(transcript)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
            }
        case .poll(let question, let choices):
            VStack(alignment: .leading, spacing: 8) {
                Text(question)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                let totalVotes = choices.map(\.votes).reduce(0, +)
                let maxVotes = choices.map(\.votes).max() ?? 0
                if totalVotes == 0 {
                    ForEach(choices) { choice in
                        HStack {
                            Text(choice.title)
                                .font(.system(size: 13))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    Text("No votes yet")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.tertiaryText)
                } else {
                    ForEach(choices) { choice in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(choice.title)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(choice.votes)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Color.white.opacity(0.08))
                                    if choice.votes > 0 {
                                        Capsule().fill(AppTheme.accent.opacity(0.6))
                                            .frame(width: geometry.size.width * CGFloat(choice.votes) / CGFloat(maxVotes))
                                    }
                                }
                            }
                            .frame(height: 6)
                        }
                    }
                }
            }
            .frame(width: 210)
        case .event(let title, let detail):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accent)
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }
}

private struct AttachmentPickerSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let threadID: UUID

    var body: some View {
        NavigationView {
            List {
                ForEach(SearchCategory.allCases) { category in
                    Button(action: {
                        store.sendQuickAttachment(category, to: threadID)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 16) {
                            Image(systemName: category.symbolName)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 28)
                            Text(category.title)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(AppTheme.background)
                }
            }
            .navigationBarTitle("Share", displayMode: .inline)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        }
        .accentColor(AppTheme.accent)
    }
}

private struct ChatInfoSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let threadID: UUID
    @State private var newGroupName = ""

    private var canAddGroup: Bool {
        !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        let thread = store.thread(id: threadID)
        let community = store.communities.first(where: { $0.id == thread?.communityID })

        return NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    if let thread = thread {
                        HStack(spacing: 14) {
                            AvatarView(avatar: thread.avatar, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(thread.title)
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(.white)
                                Text(thread.isGroup ? thread.subtitle : "Direct chat")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }

                        detailRow(title: "Shared media", value: "\(store.sharedMediaCount(for: threadID)) items")
                        ToggleRow(title: "Pinned", isOn: thread.pinned) {
                            store.togglePin(threadID: threadID)
                        }
                        ToggleRow(title: "Muted", isOn: thread.muted) {
                            store.toggleMute(threadID: threadID)
                        }

                        Button(action: {
                            if thread.archived {
                                store.unarchiveThread(threadID)
                            } else {
                                store.archiveThread(threadID)
                            }
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            HStack {
                                Text(thread.archived ? "Unarchive" : "Archive")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: thread.archived ? "tray.and.arrow.up" : "archivebox")
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.surface))
                        }
                        .buttonStyle(PlainButtonStyle())

                        if let community = community {
                            detailRow(title: "Community", value: community.name)
                            HStack(spacing: 10) {
                                TextField("New group name", text: $newGroupName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("Add") {
                                    let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    guard !trimmed.isEmpty else { return }
                                    store.addGroup(to: community.id, name: trimmed)
                                    newGroupName = ""
                                }
                                .foregroundColor(canAddGroup ? .black : AppTheme.secondaryText)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Capsule().fill(canAddGroup ? AppTheme.accent : AppTheme.surface))
                                .disabled(!canAddGroup)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Chat info", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .accentColor(AppTheme.accent)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(AppTheme.surface))
    }
}

struct UpdatesView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @State private var showingMenu = false
    @State private var showingTextComposer = false
    @State private var showingPhotoComposer = false
    @State private var selectedChannelID: UUID?

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    statusSection
                    channelsSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }

            NavigationLink(destination: selectedChannelDestination(), isActive: selectedChannelBinding) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingTextComposer) {
            TextStatusComposer()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingPhotoComposer) {
            PhotoStatusComposer()
                .environmentObject(store)
        }
        .actionSheet(isPresented: $showingMenu) {
            ActionSheet(title: Text("Updates"), buttons: [
                .default(Text("Open profile")) { store.currentTab = .you },
                .default(Text("Open followed channel")) { selectedChannelID = store.preferredChannelID() },
                .default(Text("Create text status")) { showingTextComposer = true },
                .cancel()
            ])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                CircleIconButton(icon: "ellipsis", identifier: "updates_more_button") {
                    showingMenu = true
                }
                Spacer()
            }

            Text("Updates")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, AppLayout.topInset + 8)
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Status")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 14) {
                Button(action: { showingTextComposer = true }) {
                    HStack(spacing: 14) {
                        AvatarView(avatar: store.profile.avatar, size: 72)
                            .overlay(
                                Circle()
                                    .fill(AppTheme.accent)
                                    .frame(width: 30, height: 30)
                                    .overlay(Image(systemName: "plus").font(.system(size: 18, weight: .bold)).foregroundColor(.black))
                                    .offset(x: 26, y: 26)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Add status")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Disappears after 24 hours")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibility(identifier: "status_add_row_button")
                Spacer()
                HStack(spacing: 12) {
                    CircleIconButton(icon: "camera.fill", identifier: "status_add_photo_button") {
                        showingPhotoComposer = true
                    }
                    CircleIconButton(icon: "square.and.pencil", identifier: "status_add_text_button") {
                        showingTextComposer = true
                    }
                }
            }

            if !store.statuses.isEmpty {
                Text("Recent updates")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppTheme.secondaryText)

                ForEach(store.statuses) { status in
                    NavigationLink(destination: StatusDetailView(statusID: status.id).navigationBarHidden(true)) {
                        HStack(spacing: 14) {
                            AvatarView(avatar: status.isMine ? store.profile.avatar : status.avatar, size: 64)
                                .overlay(Circle().stroke(status.isViewed ? AppTheme.surface : AppTheme.accent, lineWidth: 3))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(status.ownerName)
                                    .font(.system(size: 23, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(status.body)
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.secondaryText)
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var channelsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Channels")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Stay updated on the topics that matter to you. Follow channels to pull them into Updates.")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.secondaryText)

            Text("Find channels to follow")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            VStack(spacing: 0) {
                ForEach(store.channels) { channel in
                    ChannelRow(channel: channel, openDetail: {
                        selectedChannelID = channel.id
                    })
                    .environmentObject(store)

                    Divider()
                        .background(AppTheme.separator)
                        .padding(.leading, 74)
                }
            }
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AppTheme.surface.opacity(0.75)))
        }
    }

    private func selectedChannelDestination() -> AnyView {
        guard let selectedChannelID = selectedChannelID else { return AnyView(EmptyView()) }
        return AnyView(ChannelDetailView(channelID: selectedChannelID).navigationBarHidden(true))
    }

    private var selectedChannelBinding: Binding<Bool> {
        Binding(
            get: { selectedChannelID != nil },
            set: { value in
                if !value {
                    selectedChannelID = nil
                }
            }
        )
    }
}

private struct ChannelRow: View {
    @EnvironmentObject private var store: WhatsAppStore
    let channel: Channel
    let openDetail: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: openDetail) {
                HStack(spacing: 14) {
                    AvatarView(avatar: channel.avatar, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text(channel.name)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            if channel.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        Text(channel.followersLabel)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                store.toggleChannelFollow(channel.id)
            }) {
                Text(channel.isFollowed ? "Following" : "Follow")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(channel.isFollowed ? AppTheme.accent : .black)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(channel.isFollowed ? AppTheme.surface : AppTheme.accent))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct StatusDetailView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let statusID: UUID

    var body: some View {
        let status = store.statuses.first { $0.id == statusID }
        return ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            if let status = status {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.top, AppLayout.topInset + 8)

                    HStack(spacing: 14) {
                        AvatarView(avatar: status.isMine ? store.profile.avatar : status.avatar, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(status.ownerName)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                            Text(status.postedAt.listTimestamp())
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    if let media = status.media {
                        MediaCard(template: media, badge: "STATUS", compact: false)
                    }

                    Text(status.body)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)

                    Button(action: {
                        store.markStatusViewed(statusID)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Mark viewed")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.accent))
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            store.markStatusViewed(statusID)
        }
    }
}

struct ChannelDetailView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let channelID: UUID

    var body: some View {
        let channel = store.channels.first { $0.id == channelID }
        return ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            if let channel = channel {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Button(action: {
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.top, AppLayout.topInset + 8)

                        HStack(spacing: 16) {
                            AvatarView(avatar: channel.avatar, size: 70)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(channel.name)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                Text(channel.followersLabel)
                                    .font(.system(size: 17))
                                    .foregroundColor(AppTheme.secondaryText)
                                Text(channel.category)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                            }
                        }

                        Text(channel.description)
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.secondaryText)

                        Button(action: {
                            store.toggleChannelFollow(channel.id)
                        }) {
                            Text(channel.isFollowed ? "Following" : "Follow channel")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(channel.isFollowed ? AppTheme.accent : .black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(channel.isFollowed ? AppTheme.surface : AppTheme.accent))
                        }

                        ForEach(channel.posts) { post in
                            VStack(alignment: .leading, spacing: 14) {
                                if let media = post.media {
                                    MediaCard(template: media, badge: "POST", compact: false)
                                }
                                Text(post.headline)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                                Text(post.body)
                                    .font(.system(size: 17))
                                    .foregroundColor(AppTheme.secondaryText)
                                Text(DateFormats.messageDay.string(from: post.postedAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.tertiaryText)
                            }
                            .padding(18)
                            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AppTheme.surface))
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct TextStatusComposer: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var text = ""

    private var canPost: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Share a quick update")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                TextField("What's new?", text: $text)
                    .font(.system(size: 20))
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    store.publishTextStatus(trimmed)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Post update")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canPost ? AppTheme.accent : AppTheme.surface))
                }
                .disabled(!canPost)
                .accessibility(identifier: "status_post_button")
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Text status", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct PhotoStatusComposer: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedIndex = 0
    @State private var caption = ""

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Pick a photo style")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                TabView(selection: $selectedIndex) {
                    ForEach(Array(store.mediaTemplates.enumerated()), id: \.offset) { index, template in
                        MediaCard(template: template, badge: "PHOTO", compact: false)
                            .tag(index)
                            .padding(.horizontal, 4)
                    }
                }
                .frame(height: 250)

                TextField("Caption", text: $caption)
                    .font(.system(size: 18))
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    store.publishPhotoStatus(template: store.mediaTemplates[selectedIndex], caption: caption.isEmpty ? store.mediaTemplates[selectedIndex].subtitle : caption)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Post photo update")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.accent))
                }
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Photo status", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

struct CallsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @State private var showingMenu = false
    @State private var showingNewCallSheet = false
    @State private var showingScheduleSheet = false
    @State private var showingKeypadSheet = false
    @State private var showingFavoritesSheet = false

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    shortcuts
                    if !store.scheduledCalls.isEmpty {
                        scheduledSection
                    }
                    favoritesSection
                    recentSection
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingNewCallSheet) {
            NewCallSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingScheduleSheet) {
            ScheduleCallSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingKeypadSheet) {
            KeypadSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingFavoritesSheet) {
            ManageFavoritesSheet()
                .environmentObject(store)
        }
        .actionSheet(isPresented: $showingMenu) {
            ActionSheet(title: Text("Calls"), buttons: [
                .default(Text("Start new call")) { showingNewCallSheet = true },
                .default(Text("Schedule a call")) { showingScheduleSheet = true },
                .default(Text("Manage favorites")) { showingFavoritesSheet = true },
                .cancel()
            ])
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                CircleIconButton(icon: "ellipsis", identifier: "calls_more_button") {
                    showingMenu = true
                }
                Spacer()
                CircleIconButton(icon: "plus", fill: AppTheme.accent, iconColor: .black, identifier: "calls_new_button") {
                    showingNewCallSheet = true
                }
            }
            Text("Calls")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, AppLayout.topInset + 8)
    }

    private var shortcuts: some View {
        HStack(spacing: 14) {
            CallShortcut(icon: "phone", title: "Call") {
                showingNewCallSheet = true
            }
            CallShortcut(icon: "calendar", title: "Schedule") {
                showingScheduleSheet = true
            }
            CallShortcut(icon: "circle.grid.3x3.fill", title: "Keypad") {
                showingKeypadSheet = true
            }
            CallShortcut(icon: "heart", title: "Favorites") {
                showingFavoritesSheet = true
            }
        }
    }

    private var scheduledSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Scheduled")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            ForEach(store.scheduledCalls) { call in
                VStack(alignment: .leading, spacing: 6) {
                    Text(call.title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Text(DateFormats.callSchedule.string(from: call.scheduledFor))
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.secondaryText)
                    Text(call.note)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.tertiaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Favorites")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(store.contacts.filter(\.isFavorite)) { contact in
                        VStack(spacing: 10) {
                            AvatarView(avatar: contact.avatar, size: 62)
                            Text(contact.name.components(separatedBy: " ").first ?? contact.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            HStack(spacing: 10) {
                                Button(action: {
                                    store.startCall(with: contact.id, mode: .voice)
                                }) {
                                    Image(systemName: "phone.fill")
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Circle().fill(AppTheme.accent))
                                }
                                .buttonStyle(PlainButtonStyle())

                                Button(action: {
                                    store.startCall(with: contact.id, mode: .video)
                                }) {
                                    Image(systemName: "video.fill")
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Circle().fill(AppTheme.accent))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .frame(width: 108)
                    }
                }
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)

            ForEach(store.calls) { call in
                HStack(spacing: 14) {
                    AvatarView(avatar: call.avatar, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(call.title)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                        HStack(spacing: 8) {
                            Image(systemName: call.mode.symbolName)
                                .foregroundColor(call.direction.tint)
                            Text(call.direction.label)
                                .font(.system(size: 16))
                                .foregroundColor(call.direction.tint)
                            Text("· \(call.duration)")
                                .font(.system(size: 16))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    Spacer()
                    HStack(spacing: 10) {
                        Text(call.timestamp.listTimestamp())
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.secondaryText)
                        Button(action: {
                            if let tid = call.threadID {
                                store.startCall(for: tid, mode: call.mode)
                            } else {
                                store.placeManualCall(number: call.title, mode: call.mode)
                            }
                        }) {
                            Image(systemName: call.mode.symbolName)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppTheme.accent)
                                .frame(width: 38, height: 38)
                                .background(Circle().fill(AppTheme.surface))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibility(identifier: "recent_call_callback_\(call.id.uuidString.prefix(8))")
                    }
                }
                .padding(.vertical, 10)
            }
        }
    }
}

private struct CallShortcut: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(AppTheme.surface))
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct NewCallSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        AvatarView(avatar: contact.avatar, size: 48)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(contact.name)
                                .foregroundColor(.white)
                            Text(contact.about)
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        Spacer()
                        HStack(spacing: 14) {
                            Button(action: {
                                store.startCall(with: contact.id, mode: .voice)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(AppTheme.accent)
                            }
                            Button(action: {
                                store.startCall(with: contact.id, mode: .video)
                                presentationMode.wrappedValue.dismiss()
                            }) {
                                Image(systemName: "video.fill")
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                    .listRowBackground(AppTheme.background)
                }
            }
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("New call", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct ScheduleCallSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedContactID: UUID?
    @State private var mode: CallMode = .voice
    @State private var date = Date().addingTimeInterval(3600)
    @State private var note = "Quick check-in"

    private var canSchedule: Bool {
        selectedContactID != nil
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Contact", selection: $selectedContactID) {
                    Text("Choose a contact").tag(UUID?.none)
                    ForEach(store.contacts) { contact in
                        Text(contact.name).tag(Optional(contact.id))
                    }
                }

                HStack(spacing: 0) {
                    Button(action: { mode = .voice }) {
                        Text("Voice")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(mode == .voice ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(mode == .voice ? AppTheme.accent : AppTheme.surface))
                    }
                    .buttonStyle(PlainButtonStyle())
                    Button(action: { mode = .video }) {
                        Text("Video")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(mode == .video ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(mode == .video ? AppTheme.accent : AppTheme.surface))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                DatePicker("When", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .colorScheme(.dark)

                TextField("Note", text: $note)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Spacer()

                Button(action: {
                    store.scheduleCall(contactID: selectedContactID, date: date, note: note, mode: mode)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Schedule call")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canSchedule ? AppTheme.accent : AppTheme.surface))
                }
                .disabled(!canSchedule)
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Schedule", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct KeypadSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var number = ""

    private let digits: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"]
    ]

    private var canCall: Bool {
        number.filter(\.isNumber).count >= 3
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                Text(number.isEmpty ? "Enter a number" : number)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))

                VStack(spacing: 12) {
                    ForEach(digits, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row, id: \.self) { digit in
                                Button(action: { number.append(digit) }) {
                                    Text(digit)
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity, minHeight: 68)
                                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button(action: {
                        guard !number.isEmpty else { return }
                        store.placeManualCall(number: number, mode: .voice)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Call")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canCall ? .black : AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canCall ? AppTheme.accent : AppTheme.surface))
                    }
                    .disabled(!canCall)

                    Button(action: {
                        guard !number.isEmpty else { return }
                        store.placeManualCall(number: number, mode: .video)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Video")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(canCall ? .white : AppTheme.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    }
                    .disabled(!canCall)
                }

                Button(action: {
                    guard !number.isEmpty else { return }
                    number.removeLast()
                }) {
                    Text("Delete")
                        .foregroundColor(!number.isEmpty ? AppTheme.secondaryText : AppTheme.tertiaryText)
                }
                .disabled(number.isEmpty)
                .buttonStyle(PlainButtonStyle())
                .accessibility(identifier: "keypad_delete_button")

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Keypad", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct ManageFavoritesSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            List {
                ForEach(store.contacts) { contact in
                    Button(action: {
                        store.toggleFavorite(contactID: contact.id)
                    }) {
                        HStack {
                            AvatarView(avatar: contact.avatar, size: 48)
                            Text(contact.name)
                                .foregroundColor(.white)
                            Spacer()
                            Image(systemName: contact.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(contact.isFavorite ? AppTheme.accent : AppTheme.secondaryText)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(AppTheme.background)
                }
            }
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Favorites", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

struct CommunitiesView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @State private var showingCommunitySheet = false

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    introCard
                    communityList
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 120)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCommunitySheet) {
            NewCommunitySheet()
                .environmentObject(store)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                CircleIconButton(icon: "plus", fill: AppTheme.accent, iconColor: .black, identifier: "community_new_button") {
                    showingCommunitySheet = true
                }
            }
            Text("Communities")
                .font(.system(size: 54, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.top, AppLayout.topInset + 8)
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            MediaCard(template: store.mediaTemplates[2], badge: "COMMUNITY", compact: false)
            Text("Stay connected with communities")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Text("Communities keep announcements and topic-based groups in one place so users can move between big updates and working chats without losing context.")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.secondaryText)

            Button(action: {
                showingCommunitySheet = true
            }) {
                Text("New community")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppTheme.accent))
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(AppTheme.surface))
    }

    private var communityList: some View {
        VStack(spacing: 16) {
            ForEach(store.communities) { community in
                NavigationLink(destination: CommunityDetailView(communityID: community.id).navigationBarHidden(true)) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(spacing: 14) {
                            AvatarView(avatar: community.avatar, size: 64)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(community.name)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("\(community.memberCount) members")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                        }

                        Text(community.description)
                            .font(.system(size: 17))
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AppTheme.surface))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}

private struct NewCommunitySheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var name = ""
    @State private var description = ""
    @State private var selectedContactIDs: Set<UUID> = []

    private var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedContactIDs.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Create a community")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    TextField("Community name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .accessibility(identifier: "community_name_field")
                    TextField("Description", text: $description)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Text("Add members (\(selectedContactIDs.count) selected)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.top, 4)

                    ForEach(store.contacts) { contact in
                        Button(action: {
                            if selectedContactIDs.contains(contact.id) {
                                selectedContactIDs.remove(contact.id)
                            } else {
                                selectedContactIDs.insert(contact.id)
                            }
                        }) {
                            HStack(spacing: 12) {
                                AvatarView(avatar: contact.avatar, size: 40)
                                Text(contact.name)
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: selectedContactIDs.contains(contact.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 22))
                                    .foregroundColor(selectedContactIDs.contains(contact.id) ? AppTheme.accent : AppTheme.secondaryText)
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    Button(action: {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        _ = store.createCommunity(name: trimmed, description: description.isEmpty ? "A new topic-based space." : description, selectedMemberIDs: Array(selectedContactIDs))
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Create community")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canCreate ? AppTheme.accent : AppTheme.surface))
                    }
                    .disabled(!canCreate)
                    .accessibility(identifier: "community_create_button")
                }
                .padding(20)
                .padding(.bottom, 40)
            }
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("New community", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

struct CommunityDetailView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let communityID: UUID

    var body: some View {
        let community = store.communities.first { $0.id == communityID }

        return ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            if let community = community {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.top, AppLayout.topInset + 8)

                        HStack(spacing: 14) {
                            AvatarView(avatar: community.avatar, size: 72)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(community.name)
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                                Text("\(community.memberCount) members")
                                    .font(.system(size: 17))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }

                        Text(community.description)
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.secondaryText)

                        Text("Announcement space")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        NavigationLink(destination: ChatThreadView(threadID: community.announcementThreadID).navigationBarHidden(true)) {
                            CommunityThreadCard(thread: store.thread(id: community.announcementThreadID))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("Groups")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)

                        ForEach(community.groupThreadIDs, id: \.self) { groupID in
                            NavigationLink(destination: ChatThreadView(threadID: groupID).navigationBarHidden(true)) {
                                CommunityThreadCard(thread: store.thread(id: groupID))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 80)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct CommunityThreadCard: View {
    let thread: ChatThread?

    var body: some View {
        HStack(spacing: 14) {
            if let thread = thread {
                AvatarView(avatar: thread.avatar, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                    Text(thread.lastMessage?.content.previewText ?? "No messages yet")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)
                }
                Spacer()
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(AppTheme.surface))
    }
}

struct YouView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @State private var showingEmailSheet = false
    @State private var showingSearchSheet = false
    @State private var showingQRSheet = false
    @State private var emailText = ""

    private var canSaveEmail: Bool {
        !emailText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                profileCard
                if store.profile.verifyEmailBannerVisible {
                    emailBanner
                }
                settingsSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 120)
        }
        .background(AppTheme.background.edgesIgnoringSafeArea(.all))
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEmailSheet) {
            NavigationView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add a recovery email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    TextField("name@example.com", text: $emailText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                    Spacer()
                    Button(action: {
                        let trimmed = emailText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addRecoveryEmail(trimmed)
                        showingEmailSheet = false
                    }) {
                        Text("Save email")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canSaveEmail ? AppTheme.accent : AppTheme.surface))
                    }
                    .disabled(!canSaveEmail)
                }
                .padding(20)
                .background(AppTheme.background.edgesIgnoringSafeArea(.all))
                .navigationBarTitle("Recovery email", displayMode: .inline)
                .navigationBarItems(trailing: Button("Close") { showingEmailSheet = false })
            }
            .accentColor(AppTheme.accent)
        }
        .sheet(isPresented: $showingSearchSheet) {
            ProfileSearchSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $showingQRSheet) {
            ProfileQRCodeSheet()
                .environmentObject(store)
        }
    }

    private var header: some View {
        HStack {
            CircleIconButton(icon: "magnifyingglass", identifier: "profile_search_button") {
                showingSearchSheet = true
            }
            Spacer()
            CircleIconButton(icon: "viewfinder", identifier: "profile_qr_button") {
                showingQRSheet = true
            }
        }
        .padding(.top, AppLayout.topInset + 8)
    }

    private var profileCard: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .top) {
                AvatarView(avatar: store.profile.avatar, size: 128)
                Text("Hey there! I am using QuickChat.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(AppTheme.incomingBubble))
                    .offset(y: -48)
            }
            .padding(.top, 52)

            Text(store.profile.displayName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)

            Text(store.profile.headline)
                .font(.system(size: 18))
                .foregroundColor(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var emailBanner: some View {
        HStack(spacing: 14) {
            Image(systemName: "shield.fill")
                .font(.system(size: 30))
                .foregroundColor(AppTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Verify with email")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text("Use email to log in or if you need to recover your account.")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
                Button("Add email") {
                    showingEmailSheet = true
                }
                .foregroundColor(AppTheme.accent)
            }
            Spacer()
            Button(action: {
                store.dismissVerifyEmailBanner()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(AppTheme.surface))
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(AppTheme.secondaryText)

            VStack(spacing: 0) {
                NavigationLink(destination: AvatarSettingsView().navigationBarHidden(true)) {
                    SettingsRow(icon: "person.crop.circle", title: "Avatar")
                }
                NavigationLink(destination: ListsView().navigationBarHidden(true)) {
                    SettingsRow(icon: "list.bullet", title: "Lists")
                }
                NavigationLink(destination: BroadcastsView().navigationBarHidden(true)) {
                    SettingsRow(icon: "megaphone", title: "Message lists")
                }
                NavigationLink(destination: StarredMessagesView().navigationBarHidden(true)) {
                    SettingsRow(icon: "star", title: "Starred")
                }
                NavigationLink(destination: LinkedDevicesView().navigationBarHidden(true)) {
                    SettingsRow(icon: "desktopcomputer", title: "Linked devices")
                }
                NavigationLink(destination: AccountSettingsView().navigationBarHidden(true)) {
                    SettingsRow(icon: "key.fill", title: "Account")
                }
                NavigationLink(destination: PrivacySettingsView().navigationBarHidden(true)) {
                    SettingsRow(icon: "hand.raised.fill", title: "Privacy")
                }
                NavigationLink(destination: StorageDataView().navigationBarHidden(true)) {
                    SettingsRow(icon: "chart.pie.fill", title: "Storage and data")
                }
            }
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(AppTheme.surface))
        }
    }
}

private struct ProfileSearchSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var query = ""

    private var results: [ProfileSettingsRoute] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if normalized.isEmpty {
            return ProfileSettingsRoute.allCases
        }
        return ProfileSettingsRoute.allCases.filter {
            $0.title.lowercased().contains(normalized) || $0.subtitle.lowercased().contains(normalized)
        }
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.secondaryText)
                    TextField("Search settings", text: $query)
                        .foregroundColor(.white)
                        .accentColor(AppTheme.accent)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(results) { route in
                            NavigationLink(destination: destinationView(for: route).navigationBarHidden(true)) {
                                HStack(spacing: 14) {
                                    Image(systemName: route.icon)
                                        .font(.system(size: 18))
                                        .foregroundColor(AppTheme.accent)
                                        .frame(width: 24)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(route.title)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text(route.subtitle)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                                .padding(16)
                                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        if results.isEmpty {
                            EmptyStateCard(title: "No settings found", subtitle: "Try searching for privacy, storage, lists, or devices.")
                        }
                    }
                }
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Search settings", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }

    private func destinationView(for route: ProfileSettingsRoute) -> AnyView {
        switch route {
        case .avatar:
            return AnyView(AvatarSettingsView())
        case .lists:
            return AnyView(ListsView())
        case .broadcasts:
            return AnyView(BroadcastsView())
        case .starred:
            return AnyView(StarredMessagesView())
        case .linkedDevices:
            return AnyView(LinkedDevicesView())
        case .account:
            return AnyView(AccountSettingsView())
        case .privacy:
            return AnyView(PrivacySettingsView())
        case .storage:
            return AnyView(StorageDataView())
        }
    }
}

private struct ProfileQRCodeSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var copiedStatus: String?
    private let context = CIContext(options: nil)

    var body: some View {
        NavigationView {
            VStack(spacing: 22) {
                VStack(spacing: 14) {
                    AvatarView(avatar: store.profile.avatar, size: 82)
                    Text(store.profile.displayName)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    Text(store.profile.phoneNumber)
                        .font(.system(size: 17))
                        .foregroundColor(AppTheme.secondaryText)
                }

                if let image = qrImage(from: qrPayload()) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 260, height: 260)
                        .padding(18)
                        .background(RoundedRectangle(cornerRadius: 28, style: .continuous).fill(Color.white))
                }

                Text("Share this code so someone can start a chat with you without typing the number.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Button(action: {
                        UIPasteboard.general.string = store.profile.phoneNumber
                        copiedStatus = "Phone number copied."
                        store.presentToast(title: "Phone copied", subtitle: "Your QuickChat number is on the clipboard.")
                    }) {
                        Text("Copy phone number")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.accent))
                    }

                    Button(action: {
                        UIPasteboard.general.string = "messages-contact://\(store.compactDigits(store.profile.phoneNumber))"
                        copiedStatus = "Chat link copied."
                        store.presentToast(title: "Link copied", subtitle: "A shareable chat link is on the clipboard.")
                    }) {
                        Text("Copy chat link")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    }
                }

                if let copiedStatus = copiedStatus {
                    Text(copiedStatus)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppTheme.accent)
                }

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Your QR code", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }

    private func qrPayload() -> String {
        "messages-contact://\(store.compactDigits(store.profile.phoneNumber))|\(store.profile.displayName)"
    }

    private func qrImage(from string: String) -> UIImage? {
        guard let data = string.data(using: .ascii),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = context.createCGImage(output, from: output.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

private struct AvatarSettingsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var displayName = ""
    @State private var headline = ""
    @State private var selectedAvatarIndex = 0

    private let avatars = [
        AvatarSeed(topHex: 0x045A5C, bottomHex: 0x0A7F77, initials: "JA", symbolName: "person.fill"),
        AvatarSeed(topHex: 0x42251E, bottomHex: 0xEA8C68, initials: "JA", symbolName: "sun.max.fill"),
        AvatarSeed(topHex: 0x17243C, bottomHex: 0x5A80F4, initials: "JA", symbolName: "star.fill"),
        AvatarSeed(topHex: 0x1E3323, bottomHex: 0x52C56F, initials: "JA", symbolName: "leaf.fill")
    ]

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 18) {
                DetailHeader(title: "Avatar") {
                    presentationMode.wrappedValue.dismiss()
                }

                HStack(spacing: 14) {
                    ForEach(Array(avatars.enumerated()), id: \.offset) { index, avatar in
                        Button(action: { selectedAvatarIndex = index }) {
                            AvatarView(avatar: avatar, size: 64)
                                .overlay(Circle().stroke(index == selectedAvatarIndex ? AppTheme.accent : .clear, lineWidth: 3))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                TextField("Display name", text: $displayName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                TextField("Headline", text: $headline)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button(action: {
                    var chosenAvatar = avatars[selectedAvatarIndex]
                    let nameWords = displayName.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: " ")
                    let initials = nameWords.prefix(2).map { String($0.prefix(1)).uppercased() }.joined()
                    chosenAvatar.initials = initials.isEmpty ? "?" : initials
                    store.updateProfile(name: displayName, headline: headline, avatar: chosenAvatar)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canSave ? AppTheme.accent : AppTheme.surface))
                }
                .disabled(!canSave)

                Spacer()
            }
            .padding(20)
        }
        .navigationBarHidden(true)
        .onAppear {
            displayName = store.profile.displayName
            headline = store.profile.headline
        }
    }
}

private struct ListsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingCreate = false
    @State private var listName = ""
    @State private var selectedListID: UUID?

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Lists") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    ForEach(store.messageLists) { list in
                        Button(action: {
                            selectedListID = selectedListID == list.id ? nil : list.id
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(list.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(list.summary)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.secondaryText)
                                if selectedListID == list.id {
                                    Text("Tap to view list details")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.accent)
                                        .padding(.top, 4)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(selectedListID == list.id ? AppTheme.surface.opacity(1.2) : AppTheme.surface))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    Button("Create list") {
                        showingCreate = true
                    }
                    .foregroundColor(AppTheme.accent)
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreate) {
            NewNamedItemSheet(title: "New list", placeholder: "List name") { value in
                store.addList(named: value)
            }
        }
    }
}

private struct BroadcastsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingCreate = false

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Message lists") {
                        presentationMode.wrappedValue.dismiss()
                    }

                    ForEach(store.broadcastLists) { list in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(list.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(list.memberIDs.count) recipients · last sent \(list.lastSent.listTimestamp())")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    }

                    Button("New broadcast") {
                        showingCreate = true
                    }
                    .foregroundColor(AppTheme.accent)
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreate) {
            NewNamedItemSheet(title: "New broadcast", placeholder: "Broadcast name") { value in
                store.addBroadcast(named: value)
            }
        }
    }
}

private struct StarredMessagesView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        let starred = store.starredMessages()
        return ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Starred") {
                        presentationMode.wrappedValue.dismiss()
                    }

                    if starred.isEmpty {
                        EmptyStateCard(title: "No starred messages", subtitle: "Long-press any message bubble in chat and star it here.")
                    } else {
                        ForEach(starred, id: \.message.id) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.thread.title)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppTheme.accent)
                                Text(item.message.content.previewText)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                Text(DateFormats.messageDay.string(from: item.message.sentAt))
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct LinkedDevicesView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingAddDevice = false

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Linked devices") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    ForEach(store.linkedDevices) { device in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(device.name)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                Text(device.lastSeen)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                            Spacer()
                            Button(device.isActive ? "Remove" : "Unlink") {
                                store.removeLinkedDevice(device.id)
                            }
                            .foregroundColor(AppTheme.error)
                        }
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
                    }

                    Button("Link a device") {
                        showingAddDevice = true
                    }
                    .foregroundColor(AppTheme.accent)
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAddDevice) {
            NewNamedItemSheet(title: "Link device", placeholder: "Device name") { value in
                store.addLinkedDevice(named: value)
            }
        }
    }
}

private struct AccountSettingsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var showingEmailSheet = false
    @State private var emailText = ""

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Account") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    detailCard(title: "Phone", value: store.profile.phoneNumber)
                    detailCard(title: "Recovery email", value: store.profile.recoveryEmail ?? "Not added")
                    detailCard(title: "Passkeys", value: "Enabled on this device")
                    detailCard(title: "Backup", value: "Encrypted nightly over Wi-Fi")

                    Button(store.profile.recoveryEmail == nil ? "Add recovery email" : "Update recovery email") {
                        showingEmailSheet = true
                    }
                    .foregroundColor(AppTheme.accent)
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEmailSheet) {
            NewNamedItemSheet(title: "Recovery email", placeholder: "name@example.com") { value in
                store.addRecoveryEmail(value)
            }
        }
    }

    private func detailCard(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
    }
}

private struct PrivacySettingsView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Privacy") {
                        presentationMode.wrappedValue.dismiss()
                    }

                    ToggleRow(title: "Read receipts", isOn: store.profile.readReceiptsEnabled) {
                        store.toggleReadReceipts()
                    }
                    ToggleRow(title: "Locked chats", isOn: store.profile.lockedChatsEnabled) {
                        store.toggleLockedChats()
                    }
                    ToggleRow(title: "Disappearing messages", isOn: store.profile.disappearingMessagesEnabled) {
                        store.toggleDisappearingMessages()
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct StorageDataView: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            AppTheme.background.edgesIgnoringSafeArea(.all)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    DetailHeader(title: "Storage and data") {
                        presentationMode.wrappedValue.dismiss()
                    }

                    UsageBar(title: "Photos & videos", percent: 0.46, tint: AppTheme.accent)
                    UsageBar(title: "Audio", percent: 0.18, tint: .blue)
                    UsageBar(title: "Documents", percent: 0.11, tint: .orange)
                    UsageBar(title: "Chats", percent: 0.25, tint: .purple)

                    ToggleRow(title: "Auto-download on Wi-Fi", isOn: store.profile.autoDownloadOnWiFi) {
                        store.toggleAutoDownloadOnWiFi()
                    }
                }
                .padding(20)
                .padding(.bottom, 100)
            }
        }
        .navigationBarHidden(true)
    }
}

private struct PageStyleModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 14.0, *) {
            content.tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        } else {
            content
        }
    }
}

private struct QuickCaptureSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedContactID: UUID?
    @State private var selectedTemplate = 0

    private var canSend: Bool {
        selectedContactID != nil
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                Picker("Send to", selection: $selectedContactID) {
                    Text("Choose a contact").tag(UUID?.none)
                    ForEach(store.contacts) { contact in
                        Text(contact.name).tag(Optional(contact.id))
                    }
                }

                TabView(selection: $selectedTemplate) {
                    ForEach(Array(store.mediaTemplates.enumerated()), id: \.offset) { index, template in
                        MediaCard(template: template, badge: "CAMERA", compact: false)
                            .tag(index)
                    }
                }
                .modifier(PageStyleModifier())
                .frame(height: 250)

                Button(action: {
                    guard let selectedContactID = selectedContactID else { return }
                    let threadID = store.ensureDirectThread(with: selectedContactID)
                    let template = store.mediaTemplates[selectedTemplate]
                    store.sendVisual(template: template, kind: .photo, caption: template.subtitle, to: threadID)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Send photo")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canSend ? AppTheme.accent : AppTheme.surface))
                }
                .disabled(!canSend)

                Spacer()
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("Quick capture", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct NewChatSheet: View {
    @EnvironmentObject private var store: WhatsAppStore
    @Environment(\.presentationMode) private var presentationMode
    let onSelectContact: (UUID) -> Void

    var body: some View {
        NavigationView {
            List {
                ForEach(store.contacts) { contact in
                    Button(action: {
                        onSelectContact(contact.id)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 14) {
                            AvatarView(avatar: contact.avatar, size: 48)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(contact.name)
                                    .foregroundColor(.white)
                                Text(contact.about)
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .listRowBackground(AppTheme.background)
                }
            }
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle("New chat", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct EmptyStateCard: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
                .frame(width: 28)
            Text(title)
                .font(.system(size: 18))
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(AppTheme.surface)
        .overlay(Divider().background(AppTheme.separator), alignment: .bottom)
    }
}

private struct DetailHeader: View {
    let title: String
    let back: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: back) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.top, AppLayout.topInset + 4)
        .padding(.bottom, 8)
    }
}

private struct ToggleRow: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: action) {
                Capsule()
                    .fill(isOn ? AppTheme.accent : AppTheme.surface)
                    .frame(width: 56, height: 32)
                    .overlay(
                        Circle()
                            .fill(isOn ? Color.black : AppTheme.secondaryText)
                            .frame(width: 24, height: 24)
                            .offset(x: isOn ? 12 : -12)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.surface))
    }
}

private struct UsageBar: View {
    let title: String
    let percent: CGFloat
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(percent * 100))%")
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.secondaryText)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppTheme.surface)
                    Capsule().fill(tint).frame(width: geometry.size.width * percent)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.elevated))
    }
}

private struct NewNamedItemSheet: View {
    @Environment(\.presentationMode) private var presentationMode
    let title: String
    let placeholder: String
    let onCreate: (String) -> Void
    @State private var value = ""

    private var canCreate: Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                TextField(placeholder, text: $value)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Spacer()
                Button(action: {
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    onCreate(trimmed)
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Create")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(canCreate ? AppTheme.accent : AppTheme.surface))
                }
                .disabled(!canCreate)
            }
            .padding(20)
            .background(AppTheme.background.edgesIgnoringSafeArea(.all))
            .navigationBarTitle(Text(title), displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") { presentationMode.wrappedValue.dismiss() })
        }
        .accentColor(AppTheme.accent)
    }
}

private struct AvatarView: View {
    let avatar: AvatarSeed
    let size: CGFloat

    private var faceImage: UIImage? {
        guard let name = avatar.name, !name.isEmpty else { return nil }
        let assetName = FaceAssetResolver.assetName(prefix: "msg_face_", key: name)
        return UIImage(named: assetName)
    }

    var body: some View {
        if let face = faceImage {
            Image(uiImage: face)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [avatar.startColor, avatar.endColor]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    Group {
                        if let symbolName = avatar.symbolName {
                            Image(systemName: symbolName)
                                .font(.system(size: size * 0.34, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.92))
                        } else {
                            Text(avatar.initials)
                                .font(.system(size: size * 0.28, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                )
        }
    }
}

private struct CircleIconButton: View {
    let icon: String
    var size: CGFloat = 20
    var fill: Color = AppTheme.surface
    var iconColor: Color = .white
    var identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 54, height: 54)
                .background(Circle().fill(fill))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(identifier: identifier)
    }
}

private struct LabelText: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(AppTheme.tertiaryText)
    }
}

private struct MediaCard: View {
    let template: MediaTemplate
    let badge: String
    let compact: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: compact ? 16 : 28, style: .continuous)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: template.topHex), Color(hex: template.bottomHex)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(alignment: .leading, spacing: compact ? 8 : 12) {
                HStack {
                    Text(badge)
                        .font(.system(size: compact ? 11 : 13, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.8))
                        .padding(.horizontal, compact ? 8 : 10)
                        .padding(.vertical, compact ? 4 : 5)
                        .background(Capsule().fill(Color(hex: template.accentHex)))
                    Spacer()
                    Image(systemName: template.symbolName)
                        .font(.system(size: compact ? 22 : 30, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.88))
                }
                Spacer()
                Text(template.title)
                    .font(.system(size: compact ? 17 : 26, weight: .bold))
                    .foregroundColor(.white)
                Text(template.subtitle)
                    .font(.system(size: compact ? 13 : 16))
                    .foregroundColor(Color.white.opacity(0.82))
                    .lineLimit(compact ? 2 : 3)
            }
            .padding(compact ? 14 : 20)
        }
        .frame(height: compact ? 122 : 220)
    }
}

private struct ChatWallpaper: View {
    private let symbols = ["paperclip", "camera", "calendar", "bubble.left", "waveform", "heart", "star", "leaf", "doc", "airplane"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: 0x050607), Color(hex: 0x0A0C0E)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                ForEach(0..<symbols.count, id: \.self) { index in
                    Image(systemName: symbols[index])
                        .font(.system(size: CGFloat(22 + (index % 4) * 6), weight: .regular))
                        .foregroundColor(Color.white.opacity(0.06))
                        .position(
                            x: geometry.size.width * CGFloat((index % 4) + 1) / 5.0,
                            y: geometry.size.height * CGFloat((index / 2) + 1) / 6.0
                        )
                }
            }
        }
    }
}

private struct BlurView: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

private enum AppLayout {
    static var topInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.top ?? 20
    }

    static var bottomInset: CGFloat {
        UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 10
    }
}
