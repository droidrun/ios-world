import Foundation

enum AccessibilityID {
    static func slug(_ text: String) -> String {
        let lowered = text.lowercased()
        let transformed = lowered.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "_"
        }
        let value = String(transformed)
        let collapsed = value.replacingOccurrences(of: "__+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    static func productRow(_ productID: String) -> String {
        "product_row_\(productID)"
    }

    static func searchSuggestionRow(_ text: String) -> String {
        "search_suggestion_row_\(slug(text))"
    }

    static func categoryTile(_ categoryID: String) -> String {
        "category_tile_\(slug(categoryID))"
    }

    static func addToCart(_ productID: String) -> String {
        "add_to_cart_\(productID)"
    }

    static func buyNow(_ productID: String) -> String {
        "buy_now_\(productID)"
    }

    static func saveItem(_ productID: String) -> String {
        "save_item_\(productID)"
    }

    static func priceLabel(_ value: String) -> String {
        "price_label_\(slug(value))"
    }
}
