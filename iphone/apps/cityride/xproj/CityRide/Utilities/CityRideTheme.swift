import SwiftUI
import UIKit

/// Deterministic, gender-aware face asset lookup (mirrored across the other clones,
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

/// Renders a driver face avatar (gender-aware, deterministic by name).
struct CityRideDriverAvatar: View {
    let driverName: String
    let size: CGFloat

    private var faceAssetName: String {
        FaceAssetResolver.assetName(prefix: "cr_face_", key: driverName)
    }

    var body: some View {
        Group {
            if let uiImage = UIImage(named: faceAssetName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle().fill(CityRideTheme.card)
                    .overlay(
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: size * 0.6))
                            .foregroundColor(CityRideTheme.muted)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

enum CityRideTheme {
    static let background = Color(red: 0.05, green: 0.05, blue: 0.06)
    static let panel = Color(red: 0.09, green: 0.10, blue: 0.11)
    static let card = Color(red: 0.12, green: 0.13, blue: 0.15)
    static let cardBorder = Color.white.opacity(0.08)
    static let muted = Color(red: 0.67, green: 0.68, blue: 0.71)
    static let accent = Color(red: 0.17, green: 0.44, blue: 0.96)
    static let success = Color(red: 0.22, green: 0.69, blue: 0.45)

    static let mapStart = Color(red: 0.20, green: 0.23, blue: 0.29)
    static let mapEnd = Color(red: 0.17, green: 0.19, blue: 0.25)
}

struct CityRideCardModifier: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(CityRideTheme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(CityRideTheme.cardBorder, lineWidth: 1)
            )
    }
}

extension View {
    func uberCard(radius: CGFloat = 18) -> some View {
        modifier(CityRideCardModifier(radius: radius))
    }
}
