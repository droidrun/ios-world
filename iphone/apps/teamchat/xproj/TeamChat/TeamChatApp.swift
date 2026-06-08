import SwiftUI
import UIKit
import CoreText
import CoreGraphics
import os

private let emojiFixLog = OSLog(subsystem: "com.iosworld.teamchat", category: "emojifix")

// Cached emoji font, populated at app init via the CGFont workaround.
enum TeamChatEmoji {
    static var font: UIFont? = nil
}

/// Renders an emoji using the manually-bootstrapped Apple Color Emoji
/// font from `TeamChatEmoji.font` so it works on the iOS 26.3 simulator
/// (whose font registry points the system AppleColorEmoji at a missing
/// path). On real devices and other runtimes, falls back to plain Text.
struct EmojiText: View {
    let text: String
    let pointSize: CGFloat

    init(_ text: String, pointSize: CGFloat = 14) {
        self.text = text
        self.pointSize = pointSize
    }

    var body: some View {
        if let baseFont = TeamChatEmoji.font {
            _EmojiUILabel(text: text, font: baseFont.withSize(pointSize))
                .frame(width: pointSize * 1.4, height: pointSize * 1.4)
        } else {
            Text(text).font(.system(size: pointSize))
        }
    }
}

private struct _EmojiUILabel: UIViewRepresentable {
    let text: String
    let font: UIFont
    func makeUIView(context: Context) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = font
        l.textAlignment = .center
        l.backgroundColor = .clear
        return l
    }
    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.text = text
        uiView.font = font
    }
}

@main
struct TeamChatApp: App {
    @StateObject private var store = WorkspaceStore()

    init() {
        TeamChatApp.bootstrapEmojiFont()
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(store: store)
        }
    }

    // The iOS 26.3 simulator ships a broken font registry that points
    // AppleColorEmoji at Core/AppleColorEmoji.ttc (missing on disk; the
    // real file is CoreAddition/AppleColorEmoji-160px.ttc). The registry
    // refuses re-registration because the postscript name is "already
    // registered". Workaround: load the font bytes via CGDataProvider
    // and bridge through CTFontCreateWithGraphicsFont — this bypasses
    // the registry's URL lookup entirely.
    private static func bootstrapEmojiFont() {
        #if targetEnvironment(simulator)
        os_log("emojifix: bootstrap start", log: emojiFixLog, type: .default)
        let candidates = [
            "/System/Library/Fonts/Apple Color Emoji.ttc",
            "/System/Library/Fonts/CoreAddition/AppleColorEmoji-160px.ttc",
        ]
        for path in candidates where FileManager.default.fileExists(atPath: path) {
            guard let provider = CGDataProvider(filename: path) else {
                os_log("emojifix: data-provider failed for %{public}@",
                       log: emojiFixLog, type: .error, path)
                continue
            }
            guard let cgFont = CGFont(provider) else {
                os_log("emojifix: CGFont init failed for %{public}@",
                       log: emojiFixLog, type: .error, path)
                continue
            }
            let ctFont = CTFontCreateWithGraphicsFont(cgFont, 28, nil, nil)
            // Bridge CTFont to UIFont (toll-free).
            let bridged = ctFont as UIFont
            TeamChatEmoji.font = bridged
            os_log("emojifix: cached emoji font from %{public}@: %{public}@",
                   log: emojiFixLog, type: .default, path,
                   String(describing: bridged))
            return
        }
        os_log("emojifix: no candidate font file found", log: emojiFixLog, type: .error)
        #endif
    }
}
