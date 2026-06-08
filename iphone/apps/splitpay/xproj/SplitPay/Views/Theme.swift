import SwiftUI

enum SplitPayTheme {
    static let accent = Color(red: 0.05, green: 0.47, blue: 0.94)
    static let accentDark = Color(red: 0.02, green: 0.26, blue: 0.61)
    static let accentLight = Color(red: 0.88, green: 0.94, blue: 1.0)
    static let background = Color(red: 0.97, green: 0.97, blue: 0.98)
    static let card = Color.white
    static let cardSecondary = Color(red: 0.94, green: 0.95, blue: 0.97)
    static let border = Color.black.opacity(0.08)
    static let textPrimary = Color(red: 0.17, green: 0.18, blue: 0.22)
    static let textSecondary = Color(red: 0.43, green: 0.45, blue: 0.50)
    static let iconSecondary = Color(red: 0.57, green: 0.59, blue: 0.63)
    static let success = Color(red: 0.18, green: 0.66, blue: 0.39)

    static func titleFont(size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    static func bodyFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
}

struct CardSurface: View {
    var radius: CGFloat = 22

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(SplitPayTheme.card)
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(SplitPayTheme.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
    }
}

/// Deterministic, gender-aware face asset lookup (mirrored across the chat / social / fitness / payments clones,
/// — keep implementations in sync). See
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

private enum SplitPayFaceResolver {
    static func assetName(for key: String) -> String {
        FaceAssetResolver.assetName(prefix: "sp_face_", key: key)
    }
}

struct SplitPayAvatarView: View {
    let user: User
    let size: CGFloat

    private var faceAssetName: String {
        SplitPayFaceResolver.assetName(for: user.displayName)
    }

    var body: some View {
        ZStack {
            if user.isBusiness {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(avatarGradient)
                Image(systemName: businessSymbol)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(Color.white)
            } else if let uiImage = UIImage(named: faceAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(avatarGradient)
                Text(user.initials)
                    .font(.system(size: size * 0.34, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
        .frame(width: size, height: size)
        .overlay {
            if user.isYou {
                Circle()
                    .stroke(Color.white, lineWidth: max(2, size * 0.05))
            }
        }
    }

    private var avatarGradient: LinearGradient {
        let palettes: [[Color]] = [
            [Color(red: 0.26, green: 0.53, blue: 0.96), Color(red: 0.18, green: 0.72, blue: 0.94)],
            [Color(red: 0.97, green: 0.49, blue: 0.31), Color(red: 0.91, green: 0.25, blue: 0.39)],
            [Color(red: 0.45, green: 0.36, blue: 0.92), Color(red: 0.20, green: 0.31, blue: 0.86)],
            [Color(red: 0.19, green: 0.71, blue: 0.55), Color(red: 0.16, green: 0.54, blue: 0.45)],
            [Color(red: 0.95, green: 0.67, blue: 0.23), Color(red: 0.92, green: 0.47, blue: 0.24)]
        ]
        let palette = palettes[abs(user.avatarSeed.hashValue) % palettes.count]
        return LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var businessSymbol: String {
        if user.displayName.contains("QuickBite") {
            return "fork.knife.circle.fill"
        }
        if user.displayName.contains("SplitPay") {
            return "v.circle.fill"
        }
        return "building.2.crop.circle.fill"
    }
}

struct SplitPayPrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 18, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(SplitPayTheme.accent)
                )
        }
        .buttonStyle(.plain)
    }
}

struct SplitPaySecondaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(SplitPayTheme.titleFont(size: 18, weight: .semibold))
                .foregroundStyle(SplitPayTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(SplitPayTheme.accent, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(Color.white)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

extension User {
    var initials: String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first.map(String.init) }.joined()
        return letters.isEmpty ? "?" : letters
    }

    var isBusiness: Bool {
        avatarSeed.contains("business") || displayName.contains("LLC") || username == "doordash"
    }
}

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
