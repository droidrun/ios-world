import Foundation

enum AccessibilityID {
    static func slug(_ text: String) -> String {
        let lowered = text.lowercased()
        let sanitized = lowered.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "_"
        }
        let raw = String(sanitized)
        let collapsed = raw.replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    static func meal(_ mealType: MealType) -> String {
        mealType.accessibilitySlug
    }
}
