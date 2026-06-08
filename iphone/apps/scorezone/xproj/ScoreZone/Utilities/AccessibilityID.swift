import Foundation

enum AccessibilityID {
    static func slug(_ text: String) -> String {
        let lowered = text.lowercased()
        let allowed = lowered.map { char -> Character in
            if char.isLetter || char.isNumber { return char }
            return "_"
        }
        let raw = String(allowed)
        let collapsed = raw.replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}
