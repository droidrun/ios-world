import Foundation

enum AccessibilityID {
    static func slug(_ text: String) -> String {
        let lowered = text.lowercased()
        let raw = lowered.map { character -> Character in
            if character.isLetter || character.isNumber {
                return character
            }
            return "_"
        }
        let collapsed = String(raw).replacingOccurrences(of: "_+", with: "_", options: .regularExpression)
        return collapsed.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }

    static func storeCard(_ storeID: String) -> String { "store_card_\(slug(storeID))" }
    static func categoryTile(_ categoryID: String) -> String { "category_tile_\(slug(categoryID))" }
    static func productRow(_ productID: String) -> String { "product_row_\(slug(productID))" }
    static func addToCart(_ productID: String) -> String { "add_to_cart_\(slug(productID))" }
    static func cartIncrement(_ productID: String) -> String { "cart_quantity_increment_\(slug(productID))" }
    static func cartDecrement(_ productID: String) -> String { "cart_quantity_decrement_\(slug(productID))" }
    static func cartRemove(_ productID: String) -> String { "cart_remove_\(slug(productID))" }
    static func substitutionSelector(_ productID: String) -> String { "substitution_selector_\(slug(productID))" }
    static func deliverySlotRow(_ slotID: String) -> String { "delivery_slot_row_\(slug(slotID))" }
    static func orderStatusChip(_ status: OrderStatus) -> String { "order_status_chip_\(slug(status.rawValue))" }
    static func priceLabel(_ key: String) -> String { "price_label_\(slug(key))" }

    // Search
    static func searchField() -> String { "search_text_field" }
    static func searchResultCard(_ productID: String) -> String { "search_result_\(slug(productID))" }
    static func filterChip(_ filterName: String) -> String { "filter_chip_\(slug(filterName))" }
    static func sortOption(_ sortName: String) -> String { "sort_option_\(slug(sortName))" }

    // Cart & Checkout
    static func cartItemNote(_ productID: String) -> String { "cart_item_note_\(slug(productID))" }
    static func tipPercentButton(_ pct: Int) -> String { "tip_\(pct)_percent" }
    static func deliveryInstructionChip(_ label: String) -> String { "delivery_instruction_\(slug(label))" }

    // Orders
    static func orderCard(_ orderID: String) -> String { "order_card_\(slug(orderID))" }
    static func orderAction(_ action: String, orderID: String) -> String { "\(slug(action))_\(slug(orderID))" }
    static func ratingButton(_ stars: Int) -> String { "rating_\(stars)_stars" }

    // Account
    static func accountSection(_ section: String) -> String { "account_section_\(slug(section))" }
    static func savedStoreRow(_ storeID: String) -> String { "saved_store_\(slug(storeID))" }
}
