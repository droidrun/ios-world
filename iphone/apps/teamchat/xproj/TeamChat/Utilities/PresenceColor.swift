import SwiftUI
import UIKit

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

struct TeamChatUserAvatar: View {
    let displayName: String
    let fallbackInitials: String
    let size: CGFloat
    var cornerRadius: CGFloat = 14

    private var faceAssetName: String {
        FaceAssetResolver.assetName(prefix: "tc_face_", key: displayName)
    }

    var body: some View {
        Group {
            if let uiImage = UIImage(named: faceAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(TeamChatPalette.surface)
                    .frame(width: size, height: size)
                    .overlay {
                        Text(fallbackInitials)
                            .font(.system(size: size * 0.32, weight: .semibold))
                            .foregroundStyle(.white)
                    }
            }
        }
    }
}

extension PresenceState {
    var color: Color {
        switch self {
        case .active:
            return Color(red: 0.37, green: 0.77, blue: 0.59)
        case .away:
            return Color(red: 0.82, green: 0.72, blue: 0.41)
        case .doNotDisturb:
            return Color(red: 0.86, green: 0.33, blue: 0.40)
        case .offline:
            return Color.white.opacity(0.35)
        }
    }
}

enum TeamChatPalette {
    static let header = Color(red: 0.30, green: 0.07, blue: 0.35)
    static let screen = Color(red: 0.09, green: 0.11, blue: 0.16)
    static let card = Color(red: 0.12, green: 0.15, blue: 0.21)
    static let row = Color(red: 0.11, green: 0.14, blue: 0.20)
    static let surface = Color(red: 0.14, green: 0.17, blue: 0.24)
    static let divider = Color.white.opacity(0.08)
    static let subtleText = Color.white.opacity(0.62)
    static let secondaryText = Color.white.opacity(0.78)
    static let accent = Color(red: 0.83, green: 0.66, blue: 0.94)
    static let unreadBadge = Color(red: 0.27, green: 0.33, blue: 0.46)
    static let avatarRing = Color(red: 0.42, green: 0.16, blue: 0.53)
    static let tabBar = Color(red: 0.16, green: 0.19, blue: 0.25).opacity(0.97)
}

enum TeamChatMetrics {
    static let pagePadding: CGFloat = 12
    static let pageBottomPadding: CGFloat = 28
    static let sectionSpacing: CGFloat = 12
    static let cardCornerRadius: CGFloat = 14
    static let chipCornerRadius: CGFloat = 12
    static let headerHorizontalPadding: CGFloat = 16
    static let headerTopPadding: CGFloat = 8
    static let headerBottomPadding: CGFloat = 10
    static let headerTitleSize: CGFloat = 38
    static let headerProfileIconSize: CGFloat = 34
    static let floatingButtonSize: CGFloat = 60
    static let floatingButtonTrailingPadding: CGFloat = 18
    static let floatingButtonBottomPadding: CGFloat = 82
    static let bottomChromeInset: CGFloat = 90
    static let bottomChromeHorizontalPadding: CGFloat = 12
    static let bottomChromeBottomPadding: CGFloat = 8
    static let bottomSearchButtonSize: CGFloat = 64
}
