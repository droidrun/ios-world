import SwiftUI
import UIKit

enum LockedInTheme {
    // LockedIn brand colors
    static let linkedInBlue = Color(hex: 0x0A66C2)
    static let linkedInDarkBlue = Color(hex: 0x004182)
    static let linkedInLightBlue = Color(hex: 0x70B5F9)

    // Background colors
    static let background = Color(hex: 0xF4F2EE)
    static let cardBackground = Color.white
    static let separator = Color(hex: 0xE0E0E0)

    // Text colors
    static let primaryText = Color(hex: 0x191919)
    static let secondaryText = Color(hex: 0x666666)
    static let tertiaryText = Color(hex: 0x999999)

    // Action colors
    static let actionText = Color(hex: 0x666666)
    static let likedBlue = Color(hex: 0x0A66C2)
    static let greenButton = Color(hex: 0x057642)

    // Tab bar
    static let tabBarBackground = Color.white
    static let tabBarActive = Color(hex: 0x191919)
    static let tabBarInactive = Color(hex: 0x666666)

    // Notification badge
    static let notificationBadge = Color(hex: 0xCC1016)
    static let premiumGold = Color(hex: 0xC37D16)
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    init(hexString: String) {
        let hex = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
        let value = UInt32(hex, radix: 16) ?? 0
        self.init(hex: value)
    }
}

/// Deterministic, gender-aware face asset lookup.
///
/// Goals:
/// 1. The same persona key maps to the same face image across runs AND across apps
///    (the chat/social/fitness/payments clones all use the same logic via
///    mirrored copies of this resolver).
/// 2. A persona with a clearly feminine first name gets a feminine-presenting face;
///    a clearly masculine first name gets a masculine-presenting face. Ambiguous /
///    unknown first names fall back to the full pool of 97 faces.
///
/// Implementation notes:
/// - The face-slot gender pools below are derived from a visual audit of the 97
///   shared face images (see `assets/face_01..97.jpg`). Slots with no clear human
///   face (landscape, glyph, etc.) are placed in the NEUTRAL pool, available to
///   both pools via the fallback path.
/// - The FNV-1a 64-bit hash on the lowercased full key drives selection, so two
///   keys that differ only in case or whitespace still collide intentionally.
enum FaceAssetResolver {
    // MARK: - Face gender pools (1...97)
    //
    // F_SLOTS: slots whose image reads clearly feminine-presenting.
    // M_SLOTS: slots whose image reads clearly masculine-presenting.
    // Slots 26, 28, 56, 65, 81 are neutral (no clear portrait) and intentionally
    // belong to BOTH pools as a safe fallback for either persona gender.
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

    // MARK: - Name → gender classification
    //
    // First names curated from the personas used across the clone apps. Kept
    // deliberately small & high-precision: ambiguous / unisex names (Jordan,
    // Riley, Morgan, Jules, Kai, Sasha, Quinn, Rowan, Blair, Alex, Avery, Sam,
    // Micah, Taylor, Casey, etc.) are intentionally NOT listed so they fall
    // back to the full 97-slot pool.
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

    // MARK: - Public API

    /// Returns a face-slot index in 1...97 for the given key, choosing from the
    /// feminine pool for feminine-named keys, the masculine pool for masculine-named
    /// keys, and the full 97-slot pool otherwise. Deterministic across runs & apps.
    static func index(for key: String, poolSize: Int = 97) -> Int {
        let hash = fnv1a64(key.lowercased())
        // Gendered pool selection only applies for the canonical 97-slot asset catalog.
        if poolSize == 97 {
            switch genderOfKey(key) {
            case .feminine:
                let pool = feminineSlots
                return pool[Int(hash % UInt64(pool.count))]
            case .masculine:
                let pool = masculineSlots
                return pool[Int(hash % UInt64(pool.count))]
            case .neutral:
                break
            }
        }
        return Int(hash % UInt64(poolSize)) + 1
    }

    /// Returns an asset catalog name like "cp_face_07".
    static func assetName(prefix: String, key: String, poolSize: Int = 97) -> String {
        let idx = index(for: key, poolSize: poolSize)
        return String(format: "\(prefix)%02d", idx)
    }

    // MARK: - Internals

    enum PersonaGender {
        case feminine
        case masculine
        case neutral
    }

    static func genderOfKey(_ key: String) -> PersonaGender {
        // Take the first alphabetic token: "Petra Johansson" → "petra",
        // "Dr. Ava Torres" → "ava" is handled by skipping pure-punctuation tokens.
        let lower = key.lowercased()
        let tokens = lower.split(whereSeparator: { !$0.isLetter })
        for token in tokens {
            let candidate = String(token)
            if feminineFirstNames.contains(candidate) { return .feminine }
            if masculineFirstNames.contains(candidate) { return .masculine }
        }
        return .neutral
    }

    private static func fnv1a64(_ s: String) -> UInt64 {
        var hash: UInt64 = 14695981039346656037
        for byte in s.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1099511628211
        }
        return hash
    }
}

struct AvatarView: View {
    var name: String? = nil
    let initials: String
    let topHex: String
    let bottomHex: String
    let size: CGFloat
    var showBorder: Bool = false
    var showOpenToWork: Bool = false

    private var faceAssetName: String {
        let key = name ?? initials
        return FaceAssetResolver.assetName(prefix: "cp_face_", key: key)
    }

    var body: some View {
        ZStack {
            if let uiImage = UIImage(named: faceAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [Color(hexString: topHex), Color(hexString: bottomHex)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Text(initials)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            if showBorder {
                Circle().stroke(Color.white, lineWidth: 2)
            }
        }
        .overlay(alignment: .bottom) {
            if showOpenToWork && size >= 40 {
                Text("#OpenToWork")
                    .font(.system(size: max(6, size * 0.14), weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: size + 4)
                    .padding(.vertical, 1)
                    .background(Color(hex: 0x01754F))
                    .clipShape(Capsule())
                    .offset(y: size * 0.12)
            }
        }
    }
}

struct CompanyLogoView: View {
    let initials: String
    let topHex: String
    let bottomHex: String
    let size: CGFloat

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hexString: topHex), Color(hexString: bottomHex)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(initials)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
    }
}

struct LockedInButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

// MARK: - Time Formatting

extension Date {
    func linkedInTimeAgo() -> String {
        let now = Date()
        let interval = now.timeIntervalSince(self)

        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        if interval < 604800 { return "\(Int(interval / 86400))d" }
        if interval < 2592000 { return "\(Int(interval / 604800))w" }
        return "\(Int(interval / 2592000))mo"
    }
}

// MARK: - Reaction Count Formatting

extension Int {
    func abbreviatedString() -> String {
        if self < 1000 { return "\(self)" }
        if self < 10000 { return String(format: "%.1fK", Double(self) / 1000.0) }
        if self < 1000000 { return "\(self / 1000)K" }
        return String(format: "%.1fM", Double(self) / 1000000.0)
    }
}
