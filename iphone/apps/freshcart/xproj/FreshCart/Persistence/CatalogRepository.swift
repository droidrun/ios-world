import Foundation

protocol CatalogRepository {
    func loadCatalog() throws -> CatalogData
}

enum CatalogRepositoryError: LocalizedError {
    case snapshotNotFound
    case invalidSnapshot(String)

    var errorDescription: String? {
        switch self {
        case .snapshotNotFound:
            return "Snapshot data unavailable. Add catalog_snapshot.json to Resources or Documents."
        case .invalidSnapshot(let detail):
            return "Invalid snapshot file: \(detail)"
        }
    }
}

struct SeededCatalogRepository: CatalogRepository {
    func loadCatalog() throws -> CatalogData {
        SeedFixtures.catalogData
    }

    static func initialState() -> FreshCartState {
        SeedFixtures.initialState()
    }

    static var deliverySlots: [DeliverySlot] {
        SeedFixtures.deliverySlots
    }

    static var pickupSlots: [DeliverySlot] {
        SeedFixtures.pickupSlots
    }

    static var popularSearches: [String] {
        SeedFixtures.popularSearches
    }
}

struct SnapshotCatalogRepository: CatalogRepository {
    let persistence: AppPersistence

    init(persistence: AppPersistence = AppPersistence()) {
        self.persistence = persistence
    }

    func loadCatalog() throws -> CatalogData {
        if let data = persistence.readSandboxSnapshotData() {
            return try decode(data)
        }

        guard let url = Bundle.main.url(forResource: "catalog_snapshot", withExtension: "json") else {
            return SeedFixtures.snapshotCatalogData
        }

        do {
            let data = try Data(contentsOf: url)
            return try decode(data)
        } catch let error as CatalogRepositoryError {
            throw error
        } catch {
            throw CatalogRepositoryError.invalidSnapshot(error.localizedDescription)
        }
    }

    private func decode(_ data: Data) throws -> CatalogData {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let decoded = try decoder.decode(CatalogData.self, from: data)
            let seededStoreIDs = Set(SeedFixtures.snapshotCatalogData.stores.map(\.id))
            let decodedStoreIDs = Set(decoded.stores.map(\.id))
            guard decoded.stores.contains(where: { $0.id == "costco" }),
                  decodedStoreIDs.isSuperset(of: seededStoreIDs),
                  decoded.products.count >= SeedFixtures.snapshotCatalogData.products.count else {
                return SeedFixtures.snapshotCatalogData
            }
            return decoded
        } catch {
            return SeedFixtures.snapshotCatalogData
        }
    }
}

private enum SeedFixtures {
    private static let formatter = ISO8601DateFormatter()

    static let metadata = CatalogSnapshotMetadata(
        providerLabel: "FreshCart Default",
        sourceType: .seeded,
        snapshotTimestamp: Date(),
        lastUpdated: Date()
    )

    static let snapshotMetadata = CatalogSnapshotMetadata(
        providerLabel: "FreshCart Snapshot",
        sourceType: .snapshot,
        snapshotTimestamp: Date(),
        lastUpdated: Date()
    )

    static let stores: [Store] = [
        Store(id: "costco", storeName: "Costco", tagline: "Warehouse favorites and member pricing", addressLine: "1420 Westgate Center Dr", etaText: "By 5:30pm", distanceMiles: 2.1, supportsDelivery: true, supportsPickup: false, deliveryFee: 3.99, pickupFee: 0, accentColorHex: "#0B67B0"),
        Store(id: "petco", storeName: "Petco", tagline: "Pet food and supplies", addressLine: "220 Riverfront Ave", etaText: "By 5:00pm", distanceMiles: 1.9, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#0F376E"),
        Store(id: "aldi", storeName: "ALDI", tagline: "Low prices on weekly staples", addressLine: "510 Lakeview Pkwy", etaText: "By 5:00pm", distanceMiles: 2.7, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#163D9A"),
        Store(id: "giant_eagle", storeName: "Giant Eagle", tagline: "Neighborhood grocery delivery", addressLine: "88 Market Square", etaText: "By 5:00pm", distanceMiles: 1.4, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#BA2A32"),
        Store(id: "target", storeName: "Target", tagline: "Everyday essentials and home", addressLine: "760 Southport Ave", etaText: "By 5:00pm", distanceMiles: 3.1, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#CC2430"),
        Store(id: "market_district", storeName: "Market District", tagline: "Prepared foods and pantry", addressLine: "41 Foundry St", etaText: "By 5:00pm", distanceMiles: 2.0, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#6A302A"),
        Store(id: "panera", storeName: "Panera Bread", tagline: "Soups, salads, and sandwiches", addressLine: "1260 Oak Brook Blvd", etaText: "By 4:45pm", distanceMiles: 2.3, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#5B4028"),
        Store(id: "chipotle", storeName: "Chipotle", tagline: "Bowls, burritos, and sides", addressLine: "930 State Line Rd", etaText: "By 4:40pm", distanceMiles: 1.7, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#8F1E13"),
        Store(id: "cvs", storeName: "CVS", tagline: "Pharmacy and convenience", addressLine: "1400 Mason St", etaText: "By 5:00pm", distanceMiles: 1.5, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#D32C2C"),
        Store(id: "lowes", storeName: "Lowe's", tagline: "Home improvement", addressLine: "980 Harbor Industrial Rd", etaText: "By 6:00pm", distanceMiles: 4.2, supportsDelivery: true, supportsPickup: true, deliveryFee: 4.99, pickupFee: 0, accentColorHex: "#06297F"),
        Store(id: "dollar_tree", storeName: "Dollar Tree", tagline: "Low-cost household basics", addressLine: "311 Ashland Commons", etaText: "By 5:30pm", distanceMiles: 2.4, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#0B9635"),
        Store(id: "michaels", storeName: "Michaels", tagline: "Crafts and seasonal supplies", addressLine: "744 Orchard Loop", etaText: "By 6:15pm", distanceMiles: 3.4, supportsDelivery: true, supportsPickup: true, deliveryFee: 3.99, pickupFee: 0, accentColorHex: "#D92B39"),
        Store(id: "family_dollar", storeName: "Family Dollar", tagline: "Quick everyday essentials", addressLine: "520 Brighton Plaza", etaText: "By 5:00pm", distanceMiles: 2.9, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.49, pickupFee: 0, accentColorHex: "#F36D1B"),
        Store(id: "walmart", storeName: "Walmart", tagline: "Save money. Live better.", addressLine: "7325 S Cass Ave", etaText: "By 5:15pm", distanceMiles: 3.6, supportsDelivery: true, supportsPickup: true, deliveryFee: 3.99, pickupFee: 0, accentColorHex: "#0071CE"),
        Store(id: "whole_foods", storeName: "Natural Foods Market", tagline: "Quality natural and organic", addressLine: "1640 Chicago Ave", etaText: "By 5:30pm", distanceMiles: 4.8, supportsDelivery: true, supportsPickup: true, deliveryFee: 3.99, pickupFee: 0, accentColorHex: "#00674B"),
        Store(id: "trader_joes", storeName: "Trader Joe's", tagline: "Your neighborhood grocery store", addressLine: "44 W Ogden Ave", etaText: "By 5:00pm", distanceMiles: 2.5, supportsDelivery: true, supportsPickup: false, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#C8102E"),
        Store(id: "walgreens", storeName: "Walgreens", tagline: "Pharmacy and everyday essentials", addressLine: "901 S La Grange Rd", etaText: "By 4:45pm", distanceMiles: 1.2, supportsDelivery: true, supportsPickup: true, deliveryFee: 1.99, pickupFee: 0, accentColorHex: "#E31937"),
        Store(id: "jewel_osco", storeName: "Jewel-Osco", tagline: "Chicago's neighborhood grocer", addressLine: "1177 Ogden Ave", etaText: "By 5:00pm", distanceMiles: 1.8, supportsDelivery: true, supportsPickup: true, deliveryFee: 2.99, pickupFee: 0, accentColorHex: "#D71920"),
        Store(id: "sprouts", storeName: "Sprouts", tagline: "Healthy living for less", addressLine: "630 Roosevelt Rd", etaText: "By 5:30pm", distanceMiles: 5.1, supportsDelivery: true, supportsPickup: true, deliveryFee: 3.99, pickupFee: 0, accentColorHex: "#6B8E23"),
        Store(id: "sams_club", storeName: "Sam's Club", tagline: "Members save on bulk buys", addressLine: "450 E North Ave", etaText: "By 6:00pm", distanceMiles: 6.2, supportsDelivery: true, supportsPickup: false, deliveryFee: 4.99, pickupFee: 0, accentColorHex: "#0060A9")
    ]

    static let categories: [ProductCategory] = [
        ProductCategory(id: "produce", name: "Produce", systemImage: "leaf.fill", displayOrder: 0),
        ProductCategory(id: "dairy_eggs", name: "Dairy & Eggs", systemImage: "takeoutbag.and.cup.and.straw.fill", displayOrder: 1),
        ProductCategory(id: "meat_seafood", name: "Meat & Seafood", systemImage: "fish.fill", displayOrder: 2),
        ProductCategory(id: "prepared", name: "Prepared Meals", systemImage: "fork.knife", displayOrder: 3),
        ProductCategory(id: "frozen", name: "Frozen", systemImage: "snowflake", displayOrder: 4),
        ProductCategory(id: "bakery", name: "Bakery", systemImage: "birthday.cake.fill", displayOrder: 5),
        ProductCategory(id: "pantry", name: "Pantry", systemImage: "cabinet.fill", displayOrder: 6),
        ProductCategory(id: "beverages", name: "Beverages", systemImage: "waterbottle.fill", displayOrder: 7),
        ProductCategory(id: "household", name: "Household", systemImage: "house.fill", displayOrder: 8),
        ProductCategory(id: "pet", name: "Pet", systemImage: "pawprint.fill", displayOrder: 9),
        ProductCategory(id: "retail", name: "Retail", systemImage: "bag.fill", displayOrder: 10)
    ]

    static let products: [Product] = [
        product(id: "grapes_001", storeID: "costco", name: "Green Seedless Grapes, 3 lbs", brand: "Kirkland Signature", category: "produce", size: "3 lb bowl", price: 9.82, unitPrice: "$3.27 / lb", tags: ["Gluten-Free", "Vegan"], recommended: true, buyAgain: true),
        product(id: "strawberries_002", storeID: "costco", name: "Organic Strawberries, 2 lbs", brand: "Kirkland Signature", category: "produce", size: "2 lb bowl", price: 11.18, unitPrice: "$5.59 / lb", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true, recommended: true),
        product(id: "blueberries_003", storeID: "costco", name: "Blueberries, 18 oz", brand: "Kirkland Signature", category: "produce", size: "18 oz bowl", price: 8.70, unitPrice: "$0.48 / oz", tags: ["Gluten-Free", "Vegan"], recommended: true),
        product(id: "raspberries_004", storeID: "costco", name: "Raspberries, 12 oz", brand: "Driscoll's", category: "produce", size: "12 oz bowl", price: 6.49, unitPrice: "$0.54 / oz", tags: ["Gluten-Free", "Vegan"]),
        product(id: "salmon_fresh_005", storeID: "costco", name: "Kirkland Signature Fresh Farmed Atlantic Salmon Fillet", brand: "Kirkland Signature", category: "meat_seafood", size: "About 3.11 lb / package", price: 42.45, unitPrice: "$13.67 / lb", tags: ["Gluten-Free"], recommended: true),
        product(id: "salmon_sockeye_006", storeID: "costco", name: "Kirkland Signature Wild Sockeye Salmon Fillet", brand: "Kirkland Signature", category: "meat_seafood", size: "About 2.0 lb / package", price: 34.80, unitPrice: "$17.40 / lb", recommended: true),
        product(id: "salmon_milano_007", storeID: "costco", name: "Kirkland Signature Salmon Milano with Basil Pesto Butter", brand: "Kirkland Signature", category: "meat_seafood", size: "About 1.8 lb / package", price: 29.09, unitPrice: "$16.16 / lb", recommended: true),
        product(id: "salmon_frozen_008", storeID: "costco", name: "Kirkland Signature Farmed Atlantic Salmon, 6 oz - 8 oz", brand: "Kirkland Signature", category: "frozen", size: "48 oz", price: 42.28, unitPrice: "$0.88 / oz", buyAgain: true),
        product(id: "madegood_009", storeID: "costco", name: "MadeGood Organic Granola Minis Variety Pack", brand: "MadeGood", category: "pantry", size: "12 ct", price: 9.94, unitPrice: "12 ct", saleLabel: "$4 off; limit 5", tags: ["Nut Free", "Organic"], isOrganic: true, recommended: true),
        product(id: "annies_010", storeID: "costco", name: "Organic Cinnamon Rolls, 3 x 17.5 oz", brand: "Annie's", category: "bakery", size: "17.5 oz", price: 13.67, unitPrice: "17.5 oz", saleLabel: "$4.50 off", tags: ["Organic"], isOrganic: true, recommended: true),
        product(id: "nuggets_011", storeID: "costco", name: "Perdue Panko Breaded Chicken Breast Nuggets", brand: "Perdue", category: "frozen", size: "64 oz", price: 12.30, unitPrice: "64 oz", saleLabel: "$4 off", recommended: true),
        product(id: "hamantaschen_012", storeID: "costco", name: "Hamantaschen", brand: "Mishpacha Bakery", category: "bakery", size: "16 oz", price: 8.99, unitPrice: "$0.56 / oz"),
        product(id: "salted_caramel_013", storeID: "costco", name: "Salted Caramel Cake", brand: "Costco Bakery", category: "bakery", size: "1 cake", price: 14.99, unitPrice: "1 cake"),
        product(id: "toilet_paper_014", storeID: "costco", name: "Toilet Paper", brand: "Kirkland Signature", category: "household", size: "30 rolls", price: 24.99, unitPrice: "$0.83 / roll", buyAgain: true),
        product(id: "paper_towels_015", storeID: "costco", name: "Paper Towels", brand: "Kirkland Signature", category: "household", size: "12 x 160 sheets", price: 22.49, unitPrice: "$1.87 / roll", buyAgain: true),
        product(id: "dog_food_016", storeID: "costco", name: "Adult Dog Food", brand: "Kirkland Signature", category: "pet", size: "40 lb", price: 39.99, unitPrice: "$1.00 / lb"),
        product(id: "laundry_017", storeID: "costco", name: "Laundry Detergent", brand: "Kirkland Signature", category: "household", size: "146 loads", price: 18.99, unitPrice: "$0.13 / load", buyAgain: true),
        product(id: "eggs_018", storeID: "costco", name: "Eggs", brand: "Kirkland Signature", category: "dairy_eggs", size: "24 ct", price: 6.79, unitPrice: "$0.28 each", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "water_019", storeID: "costco", name: "Purified Water", brand: "Kirkland Signature", category: "beverages", size: "40 x 16.9 fl oz", price: 4.99, unitPrice: "$0.12 / bottle", buyAgain: true),
        product(id: "milk_020", storeID: "costco", name: "Whole Milk", brand: "Kirkland Signature", category: "dairy_eggs", size: "1 gal", price: 3.89, unitPrice: "$3.89 / gal", buyAgain: true),
        product(id: "protein_bites_021", storeID: "costco", name: "Frozen Chicken Breast Bites", brand: "Just Bare", category: "frozen", size: "4 lb", price: 17.99, unitPrice: "$4.50 / lb"),
        product(id: "hydration_022", storeID: "costco", name: "Electrolyte Water Variety Pack", brand: "Liquid I.V.", category: "beverages", size: "16 ct", price: 24.99, unitPrice: "$1.56 each"),
        product(id: "croissants_023", storeID: "costco", name: "Butter Croissants", brand: "Costco Bakery", category: "bakery", size: "12 ct", price: 7.99, unitPrice: "$0.67 each", recommended: true),
        product(id: "caesar_salad_024", storeID: "costco", name: "Caesar Salad Kit", brand: "Taylor Farms", category: "produce", size: "24 oz", price: 6.49, unitPrice: "$0.27 / oz"),
        product(id: "spinach_025", storeID: "costco", name: "Baby Spinach", brand: "Earthbound Farm", category: "produce", size: "16 oz", price: 5.99, unitPrice: "$0.37 / oz", tags: ["Gluten-Free", "Vegan"]),
        product(id: "avocados_026", storeID: "costco", name: "Hass Avocados", brand: "Kirkland Signature", category: "produce", size: "6 ct", price: 8.49, unitPrice: "$1.42 each", tags: ["Gluten-Free", "Vegan"]),
        product(id: "sparkling_water_027", storeID: "costco", name: "Sparkling Water Variety Pack", brand: "LaCroix", category: "beverages", size: "24 ct", price: 11.99, unitPrice: "$0.50 each", tags: ["Gluten-Free", "Vegan", "Sugar-Free"], buyAgain: true),
        product(id: "protein_shakes_028", storeID: "costco", name: "Chocolate Protein Shakes", brand: "Fairlife", category: "beverages", size: "18 ct", price: 31.99, unitPrice: "$1.78 each"),
        product(id: "paper_plates_029", storeID: "costco", name: "Paper Plates", brand: "Kirkland Signature", category: "household", size: "186 ct", price: 19.99, unitPrice: "$0.11 each"),
        product(id: "trash_bags_030", storeID: "costco", name: "Kitchen Trash Bags", brand: "Kirkland Signature", category: "household", size: "200 ct", price: 19.49, unitPrice: "$0.10 each"),
        product(id: "coffee_031", storeID: "costco", name: "Cold Brew Coffee", brand: "Kirkland Signature", category: "beverages", size: "2 x 48 fl oz", price: 9.99, unitPrice: "$0.10 / fl oz"),
        product(id: "yogurt_032", storeID: "costco", name: "Greek Yogurt Cups", brand: "Chobani", category: "dairy_eggs", size: "20 ct", price: 15.99, unitPrice: "$0.80 each", tags: ["Gluten-Free"]),
        product(id: "rotisserie_033", storeID: "costco", name: "Seasoned Rotisserie Chicken", brand: "Costco Deli", category: "meat_seafood", size: "1 ct", price: 6.99, unitPrice: "$6.99 each", recommended: true),
        product(id: "bagels_034", storeID: "costco", name: "Everything Bagels", brand: "Costco Bakery", category: "bakery", size: "12 ct", price: 7.49, unitPrice: "$0.62 each"),
        product(id: "tissues_035", storeID: "costco", name: "Ultra Soft Facial Tissues", brand: "Kirkland Signature", category: "household", size: "10 cube boxes", price: 18.49, unitPrice: "$1.85 each", buyAgain: true),
        product(id: "dog_treats_101", storeID: "petco", name: "Biscuit Dog Treats", brand: "Good Lovin'", category: "pet", size: "24 oz", price: 9.99, unitPrice: "$0.42 / oz"),
        product(id: "cat_litter_104", storeID: "petco", name: "Clumping Cat Litter", brand: "So Phresh", category: "pet", size: "35 lb", price: 17.99, unitPrice: "$0.51 / lb"),
        product(id: "pet_food_123", storeID: "petco", name: "Salmon & Brown Rice Dog Food", brand: "WholeHearted", category: "pet", size: "24 lb", price: 34.99, unitPrice: "$1.46 / lb", recommended: true),
        product(id: "cat_treats_124", storeID: "petco", name: "Crunchy Cat Treats", brand: "Temptations", category: "pet", size: "16 oz", price: 8.49, unitPrice: "$0.53 / oz"),
        product(id: "pet_toy_125", storeID: "petco", name: "Plush Rope Toy", brand: "Leaps & Bounds", category: "pet", size: "1 ct", price: 6.99, unitPrice: "$6.99 each"),
        product(id: "puppy_pads_126", storeID: "petco", name: "Training Puppy Pads", brand: "So Phresh", category: "pet", size: "50 ct", price: 19.99, unitPrice: "$0.40 each", buyAgain: true),
        product(id: "cat_litter_mat_127", storeID: "petco", name: "Cat Litter Trapping Mat", brand: "EveryYay", category: "pet", size: "1 ct", price: 14.99, unitPrice: "$14.99 each"),
        product(id: "bananas_102", storeID: "aldi", name: "Organic Bananas", brand: "Simply Nature", category: "produce", size: "1 bunch", price: 2.19, unitPrice: "$0.36 each", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "eggs_105", storeID: "aldi", name: "Large Eggs", brand: "Goldhen", category: "dairy_eggs", size: "12 ct", price: 3.49, unitPrice: "$0.29 each", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "aldi_spinach_108", storeID: "aldi", name: "Baby Spinach", brand: "Simply Nature", category: "produce", size: "10 oz", price: 3.29, unitPrice: "$0.33 / oz", tags: ["Organic"], isOrganic: true, recommended: true),
        product(id: "aldi_salad_109", storeID: "aldi", name: "Chopped Caesar Salad Kit", brand: "Little Salad Bar", category: "produce", size: "11.3 oz", price: 3.79, unitPrice: "$0.34 / oz"),
        product(id: "aldi_bread_110", storeID: "aldi", name: "Sourdough Bread", brand: "Specially Selected", category: "bakery", size: "24 oz", price: 4.29, unitPrice: "$0.18 / oz"),
        product(id: "aldi_pasta_111", storeID: "aldi", name: "Bronze Cut Penne", brand: "Reggano", category: "pantry", size: "16 oz", price: 1.99, unitPrice: "$0.12 / oz"),
        product(id: "aldi_sauce_112", storeID: "aldi", name: "Premium Marinara", brand: "Specially Selected", category: "pantry", size: "24 oz", price: 3.49, unitPrice: "$0.15 / oz", recommended: true),
        product(id: "aldi_yogurt_113", storeID: "aldi", name: "Greek Yogurt", brand: "Friendly Farms", category: "dairy_eggs", size: "32 oz", price: 4.59, unitPrice: "$0.14 / oz", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "aldi_sparkling_114", storeID: "aldi", name: "Sparkling Water Variety Pack", brand: "Belle Vie", category: "beverages", size: "12 ct", price: 4.99, unitPrice: "$0.42 each", tags: ["Gluten-Free", "Vegan", "Sugar-Free"]),
        product(id: "aldi_chicken_115", storeID: "aldi", name: "Breaded Chicken Breast Fillets", brand: "Kirkwood", category: "frozen", size: "24 oz", price: 8.99, unitPrice: "$0.37 / oz"),
        product(id: "aldi_avocados_116", storeID: "aldi", name: "Hass Avocados", brand: "Nature's Nectar", category: "produce", size: "4 ct", price: 3.99, unitPrice: "$1.00 each"),
        product(id: "aldi_blueberries_117", storeID: "aldi", name: "Blueberries", brand: "Berryhill", category: "produce", size: "11 oz", price: 3.69, unitPrice: "$0.34 / oz"),
        product(id: "aldi_cheese_118", storeID: "aldi", name: "Shredded Mexican Cheese", brand: "Happy Farms", category: "dairy_eggs", size: "8 oz", price: 2.49, unitPrice: "$0.31 / oz", buyAgain: true),
        product(id: "aldi_peanut_butter_119", storeID: "aldi", name: "Creamy Peanut Butter", brand: "Peanut Delight", category: "pantry", size: "18 oz", price: 2.35, unitPrice: "$0.13 / oz"),
        product(id: "cleaner_103", storeID: "target", name: "Multi-Surface Cleaner", brand: "up&up", category: "household", size: "28 fl oz", price: 4.49, unitPrice: "$0.16 / fl oz"),
        product(id: "storage_bins_106", storeID: "target", name: "Storage Bins, 4 Pack", brand: "Brightroom", category: "retail", size: "4 ct", price: 18.99, unitPrice: "$4.75 each"),
        product(id: "target_paper_towels_117", storeID: "target", name: "Paper Towels", brand: "up&up", category: "household", size: "6 mega rolls", price: 8.99, unitPrice: "$1.50 / roll", buyAgain: true),
        product(id: "target_laundry_118", storeID: "target", name: "Laundry Detergent Pods", brand: "Tide", category: "household", size: "42 ct", price: 13.49, unitPrice: "$0.32 each", recommended: true),
        product(id: "target_soap_119", storeID: "target", name: "Foaming Hand Soap", brand: "Everspring", category: "household", size: "10 fl oz", price: 3.99, unitPrice: "$0.40 / fl oz"),
        product(id: "target_snackbars_120", storeID: "target", name: "Chocolate Chip Snack Bars", brand: "Good & Gather", category: "pantry", size: "12 ct", price: 5.49, unitPrice: "$0.46 each"),
        product(id: "target_candle_121", storeID: "target", name: "Sea Salt Soy Candle", brand: "Threshold", category: "retail", size: "14 oz", price: 11.99, unitPrice: "$0.86 / oz"),
        product(id: "target_blanket_122", storeID: "target", name: "Cozy Throw Blanket", brand: "Room Essentials", category: "retail", size: "50 x 60 in", price: 14.99, unitPrice: "$14.99 each"),
        product(id: "target_dish_soap_123", storeID: "target", name: "Lemon Dish Soap", brand: "Everspring", category: "household", size: "24 fl oz", price: 3.79, unitPrice: "$0.16 / fl oz"),
        product(id: "target_tissues_124", storeID: "target", name: "Facial Tissues", brand: "up&up", category: "household", size: "4 cube boxes", price: 5.99, unitPrice: "$1.50 each"),
        product(id: "target_sparkling_125", storeID: "target", name: "Sparkling Water", brand: "Good & Gather", category: "beverages", size: "8 ct", price: 4.29, unitPrice: "$0.54 each", tags: ["Gluten-Free", "Vegan", "Sugar-Free"]),
        product(id: "giant_oranges_129", storeID: "giant_eagle", name: "Navel Oranges", brand: "Giant Eagle", category: "produce", size: "3 lb bag", price: 5.99, unitPrice: "$2.00 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "giant_rotisserie_130", storeID: "giant_eagle", name: "Rotisserie Chicken", brand: "Giant Eagle", category: "meat_seafood", size: "1 ct", price: 8.99, unitPrice: "$8.99 each", recommended: true),
        product(id: "giant_milk_207", storeID: "giant_eagle", name: "Whole Milk", brand: "Giant Eagle", category: "dairy_eggs", size: "1 gal", price: 4.29, unitPrice: "$4.29 / gal", buyAgain: true),
        product(id: "giant_eggs_208", storeID: "giant_eagle", name: "Grade A Large Eggs", brand: "Giant Eagle", category: "dairy_eggs", size: "12 ct", price: 3.79, unitPrice: "$0.32 each"),
        product(id: "giant_bread_209", storeID: "giant_eagle", name: "Italian Bread Loaf", brand: "Market District Bakery", category: "bakery", size: "20 oz", price: 3.99, unitPrice: "$0.20 / oz"),
        product(id: "giant_yogurt_210", storeID: "giant_eagle", name: "Vanilla Greek Yogurt", brand: "Oikos", category: "dairy_eggs", size: "32 oz", price: 5.69, unitPrice: "$0.18 / oz", tags: ["Gluten-Free"]),
        product(id: "giant_salad_211", storeID: "giant_eagle", name: "Southwest Chopped Salad Kit", brand: "Taylor Farms", category: "produce", size: "12.8 oz", price: 4.49, unitPrice: "$0.35 / oz", recommended: true),
        product(id: "giant_pasta_212", storeID: "giant_eagle", name: "Penne Rigate Pasta", brand: "Barilla", category: "pantry", size: "16 oz", price: 2.19, unitPrice: "$0.14 / oz"),
        product(id: "giant_chicken_213", storeID: "giant_eagle", name: "Boneless Skinless Chicken Thighs", brand: "Giant Eagle", category: "meat_seafood", size: "1.8 lb pack", price: 9.49, unitPrice: "$5.27 / lb"),
        product(id: "giant_juice_214", storeID: "giant_eagle", name: "Orange Juice", brand: "Simply", category: "beverages", size: "52 fl oz", price: 4.89, unitPrice: "$0.09 / fl oz"),
        product(id: "giant_paper_towels_215", storeID: "giant_eagle", name: "Select-A-Size Paper Towels", brand: "Bounty", category: "household", size: "6 double rolls", price: 11.49, unitPrice: "$1.92 / roll", buyAgain: true),
        product(id: "market_sushi_201", storeID: "market_district", name: "Spicy Salmon Sushi Roll", brand: "Market District", category: "prepared", size: "8 ct", price: 11.99, unitPrice: "$1.50 each", recommended: true),
        product(id: "market_chicken_salad_202", storeID: "market_district", name: "Harvest Chicken Salad Bowl", brand: "Market District", category: "prepared", size: "1 bowl", price: 10.49, unitPrice: "$10.49 each"),
        product(id: "market_bread_203", storeID: "market_district", name: "Rustic Bread Loaf", brand: "Market District Bakery", category: "bakery", size: "18 oz", price: 4.79, unitPrice: "$0.27 / oz"),
        product(id: "market_pasta_salad_204", storeID: "market_district", name: "Mediterranean Pasta Salad", brand: "Market District", category: "prepared", size: "20 oz", price: 7.99, unitPrice: "$0.40 / oz"),
        product(id: "market_cold_brew_205", storeID: "market_district", name: "Vanilla Cold Brew", brand: "La Colombe", category: "beverages", size: "42 fl oz", price: 6.99, unitPrice: "$0.17 / fl oz", buyAgain: true),
        product(id: "market_olive_oil_206", storeID: "market_district", name: "Extra Virgin Olive Oil", brand: "DeLallo", category: "pantry", size: "25 fl oz", price: 13.49, unitPrice: "$0.54 / fl oz"),
        product(id: "market_soup_216", storeID: "market_district", name: "Tomato Basil Soup", brand: "Market District", category: "prepared", size: "16 oz", price: 6.79, unitPrice: "$0.42 / oz"),
        product(id: "market_ravioli_217", storeID: "market_district", name: "Cheese Ravioli", brand: "Rana", category: "prepared", size: "20 oz", price: 8.49, unitPrice: "$0.42 / oz"),
        product(id: "market_tiramisu_218", storeID: "market_district", name: "Classic Tiramisu Slice", brand: "Market District Bakery", category: "bakery", size: "1 slice", price: 5.29, unitPrice: "$5.29 each"),
        product(id: "panera_soup_131", storeID: "panera", name: "Broccoli Cheddar Soup", brand: "Panera Bread", category: "prepared", size: "16 oz bowl", price: 8.79, unitPrice: "$0.55 / oz", recommended: true),
        product(id: "panera_salad_132", storeID: "panera", name: "Green Goddess Cobb Salad", brand: "Panera Bread", category: "prepared", size: "1 bowl", price: 12.49, unitPrice: "$12.49 each"),
        product(id: "panera_sandwich_133", storeID: "panera", name: "Toasted Frontega Chicken Sandwich", brand: "Panera Bread", category: "prepared", size: "1 sandwich", price: 13.29, unitPrice: "$13.29 each", buyAgain: true),
        product(id: "panera_pastry_134", storeID: "panera", name: "Chocolate Croissant", brand: "Panera Bread", category: "bakery", size: "1 pastry", price: 4.29, unitPrice: "$4.29 each"),
        product(id: "panera_tea_135", storeID: "panera", name: "Passion Papaya Iced Tea", brand: "Panera Bread", category: "beverages", size: "20 fl oz", price: 3.99, unitPrice: "$0.20 / fl oz"),
        product(id: "panera_mac_136", storeID: "panera", name: "Mac & Cheese", brand: "Panera Bread", category: "prepared", size: "1 bowl", price: 9.49, unitPrice: "$9.49 each", recommended: true),
        product(id: "panera_baguette_137", storeID: "panera", name: "French Baguette", brand: "Panera Bread", category: "bakery", size: "1 loaf", price: 2.19, unitPrice: "$2.19 each"),
        product(id: "panera_cookie_138", storeID: "panera", name: "Kitchen Sink Cookie", brand: "Panera Bread", category: "bakery", size: "1 cookie", price: 4.49, unitPrice: "$4.49 each"),
        product(id: "chipotle_bowl_136", storeID: "chipotle", name: "Chicken Burrito Bowl", brand: "Chipotle", category: "prepared", size: "1 bowl", price: 12.85, unitPrice: "$12.85 each", recommended: true, buyAgain: true),
        product(id: "chipotle_burrito_137", storeID: "chipotle", name: "Steak Burrito", brand: "Chipotle", category: "prepared", size: "1 burrito", price: 13.65, unitPrice: "$13.65 each"),
        product(id: "chipotle_chips_138", storeID: "chipotle", name: "Chips & Guacamole", brand: "Chipotle", category: "prepared", size: "1 order", price: 5.90, unitPrice: "$5.90 each"),
        product(id: "chipotle_queso_139", storeID: "chipotle", name: "Queso Blanco", brand: "Chipotle", category: "prepared", size: "4 oz", price: 2.95, unitPrice: "$0.74 / oz"),
        product(id: "chipotle_drink_140", storeID: "chipotle", name: "Mexican Coca-Cola", brand: "Chipotle", category: "beverages", size: "12 fl oz", price: 3.45, unitPrice: "$0.29 / fl oz"),
        product(id: "chipotle_veggie_141", storeID: "chipotle", name: "Veggie Burrito Bowl", brand: "Chipotle", category: "prepared", size: "1 bowl", price: 11.85, unitPrice: "$11.85 each"),
        product(id: "chipotle_salad_142", storeID: "chipotle", name: "Chicken Salad Bowl", brand: "Chipotle", category: "prepared", size: "1 salad", price: 12.85, unitPrice: "$12.85 each"),
        product(id: "chipotle_sprite_143", storeID: "chipotle", name: "Mexican Sprite", brand: "Chipotle", category: "beverages", size: "12 fl oz", price: 3.45, unitPrice: "$0.29 / fl oz"),
        product(id: "vitamins_107", storeID: "cvs", name: "Daily Multivitamins", brand: "CVS Health", category: "retail", size: "120 ct", price: 12.99, unitPrice: "$0.11 each"),
        product(id: "cvs_pain_relief_127", storeID: "cvs", name: "Pain Relief Caplets", brand: "Advil", category: "retail", size: "80 ct", price: 13.99, unitPrice: "$0.17 each"),
        product(id: "cvs_cough_drops_128", storeID: "cvs", name: "Honey Lemon Cough Drops", brand: "Ricola", category: "retail", size: "19 ct", price: 3.99, unitPrice: "$0.21 each"),
        product(id: "cvs_batteries_213", storeID: "cvs", name: "AA Alkaline Batteries", brand: "Duracell", category: "retail", size: "8 ct", price: 11.49, unitPrice: "$1.44 each", buyAgain: true),
        product(id: "cvs_toothpaste_214", storeID: "cvs", name: "Whitening Toothpaste", brand: "Crest", category: "retail", size: "5.7 oz", price: 5.99, unitPrice: "$1.05 / oz"),
        product(id: "cvs_bandages_215", storeID: "cvs", name: "Flexible Fabric Bandages", brand: "Band-Aid", category: "retail", size: "100 ct", price: 8.79, unitPrice: "$0.09 each"),
        product(id: "cvs_tissues_216", storeID: "cvs", name: "Soft Facial Tissues", brand: "Kleenex", category: "household", size: "4 cube boxes", price: 7.49, unitPrice: "$1.87 each"),
        product(id: "cvs_shampoo_217", storeID: "cvs", name: "Moisture Repair Shampoo", brand: "Pantene", category: "retail", size: "17.9 fl oz", price: 7.99, unitPrice: "$0.45 / fl oz"),
        product(id: "cvs_allergy_218", storeID: "cvs", name: "24 Hour Allergy Relief", brand: "Zyrtec", category: "retail", size: "30 ct", price: 18.99, unitPrice: "$0.63 each", recommended: true),
        product(id: "cvs_handsoap_219", storeID: "cvs", name: "Hydrating Hand Soap", brand: "Softsoap", category: "household", size: "11.25 fl oz", price: 3.49, unitPrice: "$0.31 / fl oz"),
        product(id: "lowes_bulbs_218", storeID: "lowes", name: "LED Light Bulbs Soft White", brand: "GE", category: "retail", size: "4 ct", price: 9.98, unitPrice: "$2.50 each", buyAgain: true),
        product(id: "lowes_drill_219", storeID: "lowes", name: "Power Drill Driver Kit", brand: "Kobalt", category: "retail", size: "1 kit", price: 79.00, unitPrice: "$79.00 each", recommended: true),
        product(id: "lowes_tote_220", storeID: "lowes", name: "Heavy Duty Storage Tote", brand: "Project Source", category: "retail", size: "27 gal", price: 11.98, unitPrice: "$11.98 each"),
        product(id: "lowes_paint_221", storeID: "lowes", name: "Interior Paint Sample", brand: "HGTV Home", category: "retail", size: "1 qt", price: 5.48, unitPrice: "$5.48 / qt"),
        product(id: "lowes_planter_222", storeID: "lowes", name: "Ceramic Planter Pot", brand: "Style Selections", category: "retail", size: "12 in", price: 16.99, unitPrice: "$16.99 each"),
        product(id: "lowes_gloves_223", storeID: "lowes", name: "Work Gloves", brand: "Blue Hawk", category: "retail", size: "1 pair", price: 8.49, unitPrice: "$8.49 each"),
        product(id: "lowes_soil_224", storeID: "lowes", name: "Potting Mix", brand: "Miracle-Gro", category: "retail", size: "1 cu ft", price: 8.98, unitPrice: "$8.98 each"),
        product(id: "lowes_hose_225", storeID: "lowes", name: "Garden Hose Nozzle", brand: "Melnor", category: "retail", size: "1 ct", price: 12.98, unitPrice: "$12.98 each"),
        product(id: "dollar_tree_plates_224", storeID: "dollar_tree", name: "Paper Plates", brand: "Dollar Tree", category: "household", size: "20 ct", price: 1.25, unitPrice: "$0.06 each"),
        product(id: "dollar_tree_detergent_225", storeID: "dollar_tree", name: "Laundry Detergent", brand: "LA's Totally Awesome", category: "household", size: "32 fl oz", price: 1.25, unitPrice: "$0.04 / fl oz", buyAgain: true),
        product(id: "dollar_tree_snacks_226", storeID: "dollar_tree", name: "Chocolate Sandwich Cookies", brand: "Benton's", category: "pantry", size: "14 oz", price: 1.25, unitPrice: "$0.09 / oz"),
        product(id: "dollar_tree_soda_227", storeID: "dollar_tree", name: "Cola Soda", brand: "Stars & Stripes", category: "beverages", size: "2 L", price: 1.25, unitPrice: "$0.63 / L"),
        product(id: "dollar_tree_cleaner_228", storeID: "dollar_tree", name: "All Purpose Cleaner", brand: "Totally Awesome", category: "household", size: "20 fl oz", price: 1.25, unitPrice: "$0.06 / fl oz", recommended: true),
        product(id: "dollar_tree_bags_229", storeID: "dollar_tree", name: "Tall Kitchen Trash Bags", brand: "Dollar Tree", category: "household", size: "12 ct", price: 1.25, unitPrice: "$0.10 each"),
        product(id: "dollar_tree_sponges_230", storeID: "dollar_tree", name: "Kitchen Sponges", brand: "Scrub Buddies", category: "household", size: "6 ct", price: 1.25, unitPrice: "$0.21 each"),
        product(id: "dollar_tree_foil_231", storeID: "dollar_tree", name: "Foil Baking Pans", brand: "Dollar Tree", category: "household", size: "3 ct", price: 1.25, unitPrice: "$0.42 each"),
        product(id: "michaels_paint_230", storeID: "michaels", name: "Acrylic Paint Set", brand: "Artist's Loft", category: "retail", size: "12 ct", price: 12.99, unitPrice: "$1.08 each", recommended: true),
        product(id: "michaels_sketchbook_231", storeID: "michaels", name: "Hardbound Sketchbook", brand: "Artist's Loft", category: "retail", size: "1 book", price: 9.99, unitPrice: "$9.99 each"),
        product(id: "michaels_glue_232", storeID: "michaels", name: "Hot Glue Sticks", brand: "Creatology", category: "retail", size: "24 ct", price: 6.99, unitPrice: "$0.29 each"),
        product(id: "michaels_yarn_233", storeID: "michaels", name: "Soft Yarn Skein", brand: "Loops & Threads", category: "retail", size: "1 skein", price: 5.99, unitPrice: "$5.99 each", buyAgain: true),
        product(id: "michaels_frame_234", storeID: "michaels", name: "Gallery Wall Frame", brand: "Studio Decor", category: "retail", size: "11 x 14 in", price: 14.99, unitPrice: "$14.99 each"),
        product(id: "michaels_wreath_235", storeID: "michaels", name: "Seasonal Door Wreath", brand: "Ashland", category: "retail", size: "18 in", price: 24.99, unitPrice: "$24.99 each"),
        product(id: "michaels_canvas_236", storeID: "michaels", name: "Canvas Value Pack", brand: "Artist's Loft", category: "retail", size: "5 ct", price: 14.99, unitPrice: "$3.00 each"),
        product(id: "michaels_markers_237", storeID: "michaels", name: "Dual Tip Brush Markers", brand: "Artist's Loft", category: "retail", size: "12 ct", price: 11.99, unitPrice: "$1.00 each"),
        product(id: "family_dollar_cereal_236", storeID: "family_dollar", name: "Honey Oat Cereal", brand: "General Mills", category: "pantry", size: "18 oz", price: 4.95, unitPrice: "$0.28 / oz"),
        product(id: "family_dollar_juice_237", storeID: "family_dollar", name: "Apple Juice", brand: "Minute Maid", category: "beverages", size: "59 fl oz", price: 3.75, unitPrice: "$0.06 / fl oz"),
        product(id: "family_dollar_paper_towels_238", storeID: "family_dollar", name: "Paper Towels", brand: "Bounty Essentials", category: "household", size: "4 ct", price: 5.25, unitPrice: "$1.31 each", buyAgain: true),
        product(id: "family_dollar_toothpaste_239", storeID: "family_dollar", name: "Cavity Protection Toothpaste", brand: "Colgate", category: "retail", size: "6 oz", price: 2.95, unitPrice: "$0.49 / oz"),
        product(id: "family_dollar_trash_bags_240", storeID: "family_dollar", name: "Kitchen Trash Bags", brand: "Glad", category: "household", size: "20 ct", price: 4.50, unitPrice: "$0.23 each"),
        product(id: "family_dollar_detergent_241", storeID: "family_dollar", name: "Liquid Laundry Detergent", brand: "Purex", category: "household", size: "75 fl oz", price: 8.95, unitPrice: "$0.12 / fl oz", recommended: true),
        product(id: "family_dollar_soap_242", storeID: "family_dollar", name: "Antibacterial Dish Soap", brand: "Ajax", category: "household", size: "28 fl oz", price: 3.35, unitPrice: "$0.12 / fl oz"),
        product(id: "family_dollar_diapers_243", storeID: "family_dollar", name: "Toddler Diapers", brand: "Pampers", category: "retail", size: "22 ct", price: 12.95, unitPrice: "$0.59 each"),

        // Walmart
        product(id: "walmart_milk_301", storeID: "walmart", name: "Great Value Whole Milk", brand: "Great Value", category: "dairy_eggs", size: "1 gal", price: 3.36, unitPrice: "$3.36 / gal", buyAgain: true),
        product(id: "walmart_bread_302", storeID: "walmart", name: "Sara Lee Honey Wheat Bread", brand: "Sara Lee", category: "bakery", size: "20 oz", price: 3.98, unitPrice: "$0.20 / oz"),
        product(id: "walmart_chicken_303", storeID: "walmart", name: "Boneless Skinless Chicken Breasts", brand: "Great Value", category: "meat_seafood", size: "3 lb bag", price: 9.97, unitPrice: "$3.32 / lb", tags: ["Gluten-Free"], recommended: true),
        product(id: "walmart_bananas_304", storeID: "walmart", name: "Bananas", brand: "Fresh", category: "produce", size: "1 bunch", price: 1.58, unitPrice: "$0.27 each", tags: ["Gluten-Free", "Vegan"]),
        product(id: "walmart_eggs_305", storeID: "walmart", name: "Great Value Large White Eggs", brand: "Great Value", category: "dairy_eggs", size: "18 ct", price: 4.48, unitPrice: "$0.25 each", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "walmart_rice_306", storeID: "walmart", name: "Long Grain White Rice", brand: "Great Value", category: "pantry", size: "5 lb bag", price: 3.74, unitPrice: "$0.75 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "walmart_water_307", storeID: "walmart", name: "Purified Drinking Water", brand: "Great Value", category: "beverages", size: "24 x 16.9 fl oz", price: 3.48, unitPrice: "$0.15 each", buyAgain: true),
        product(id: "walmart_cereal_308", storeID: "walmart", name: "Honey Nut Cheerios", brand: "General Mills", category: "pantry", size: "15.4 oz", price: 4.98, unitPrice: "$0.32 / oz"),
        product(id: "walmart_detergent_309", storeID: "walmart", name: "Liquid Laundry Detergent", brand: "Tide", category: "household", size: "92 fl oz", price: 12.97, unitPrice: "$0.14 / load", recommended: true),
        product(id: "walmart_chips_310", storeID: "walmart", name: "Classic Potato Chips", brand: "Lay's", category: "pantry", size: "10 oz", price: 4.78, unitPrice: "$0.48 / oz"),

        // Whole Foods
        product(id: "wf_salmon_401", storeID: "whole_foods", name: "Wild Caught Sockeye Salmon", brand: "365 by Whole Foods", category: "meat_seafood", size: "12 oz", price: 14.99, unitPrice: "$1.25 / oz", tags: ["Gluten-Free"], recommended: true),
        product(id: "wf_avocado_402", storeID: "whole_foods", name: "Organic Hass Avocados", brand: "Natural Foods Market", category: "produce", size: "4 ct", price: 5.99, unitPrice: "$1.50 each", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "wf_kale_403", storeID: "whole_foods", name: "Organic Baby Kale", brand: "365 by Whole Foods", category: "produce", size: "5 oz", price: 3.49, unitPrice: "$0.70 / oz", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "wf_kombucha_404", storeID: "whole_foods", name: "Ginger Lemon Kombucha", brand: "GT's", category: "beverages", size: "16 fl oz", price: 4.29, unitPrice: "$0.27 / fl oz", tags: ["Gluten-Free", "Vegan"]),
        product(id: "wf_granola_405", storeID: "whole_foods", name: "Maple Pecan Granola", brand: "Bear Naked", category: "pantry", size: "12 oz", price: 5.99, unitPrice: "$0.50 / oz"),
        product(id: "wf_yogurt_406", storeID: "whole_foods", name: "Organic Whole Milk Yogurt", brand: "Stonyfield", category: "dairy_eggs", size: "32 oz", price: 5.49, unitPrice: "$0.17 / oz", tags: ["Organic"], isOrganic: true, buyAgain: true),
        product(id: "wf_sourdough_407", storeID: "whole_foods", name: "Artisan Sourdough Loaf", brand: "Whole Foods Bakery", category: "bakery", size: "1 loaf", price: 5.99, unitPrice: "$5.99 each"),
        product(id: "wf_pasta_408", storeID: "whole_foods", name: "Organic Penne Rigate", brand: "365 by Whole Foods", category: "pantry", size: "16 oz", price: 2.49, unitPrice: "$0.16 / oz", tags: ["Organic"], isOrganic: true),

        // Trader Joe's
        product(id: "tj_mandarin_501", storeID: "trader_joes", name: "Mandarin Orange Chicken", brand: "Trader Joe's", category: "frozen", size: "22 oz", price: 5.49, unitPrice: "$0.25 / oz", recommended: true, buyAgain: true),
        product(id: "tj_cauliflower_502", storeID: "trader_joes", name: "Cauliflower Gnocchi", brand: "Trader Joe's", category: "frozen", size: "12 oz", price: 3.49, unitPrice: "$0.29 / oz", recommended: true),
        product(id: "tj_everything_503", storeID: "trader_joes", name: "Everything But The Bagel Seasoning", brand: "Trader Joe's", category: "pantry", size: "2.3 oz", price: 2.49, unitPrice: "$1.08 / oz"),
        product(id: "tj_cookies_504", storeID: "trader_joes", name: "Almond Windmill Cookies", brand: "Trader Joe's", category: "pantry", size: "10 oz", price: 3.99, unitPrice: "$0.40 / oz"),
        product(id: "tj_wine_505", storeID: "trader_joes", name: "Charles Shaw Red Blend Wine", brand: "Charles Shaw", category: "beverages", size: "750 ml", price: 3.49, unitPrice: "$3.49 each"),
        product(id: "tj_salad_506", storeID: "trader_joes", name: "Harvest Chopped Salad Kit", brand: "Trader Joe's", category: "produce", size: "12.3 oz", price: 4.49, unitPrice: "$0.37 / oz"),
        product(id: "tj_ravioli_507", storeID: "trader_joes", name: "Butternut Squash Ravioli", brand: "Trader Joe's", category: "prepared", size: "9 oz", price: 3.99, unitPrice: "$0.44 / oz", recommended: true),
        product(id: "tj_peanut_508", storeID: "trader_joes", name: "Creamy Salted Peanut Butter", brand: "Trader Joe's", category: "pantry", size: "16 oz", price: 2.99, unitPrice: "$0.19 / oz", buyAgain: true),

        // Walgreens
        product(id: "wag_advil_601", storeID: "walgreens", name: "Ibuprofen Tablets", brand: "Advil", category: "retail", size: "50 ct", price: 9.99, unitPrice: "$0.20 each"),
        product(id: "wag_vitamins_602", storeID: "walgreens", name: "Adult Gummy Multivitamins", brand: "Nature Made", category: "retail", size: "150 ct", price: 14.99, unitPrice: "$0.10 each", recommended: true),
        product(id: "wag_tissues_603", storeID: "walgreens", name: "Soft Tissues Cube Box", brand: "Kleenex", category: "household", size: "3 boxes", price: 5.99, unitPrice: "$2.00 each"),
        product(id: "wag_toothbrush_604", storeID: "walgreens", name: "Soft Toothbrush Twin Pack", brand: "Oral-B", category: "retail", size: "2 ct", price: 6.49, unitPrice: "$3.25 each"),
        product(id: "wag_soap_605", storeID: "walgreens", name: "Moisturizing Body Wash", brand: "Dove", category: "retail", size: "22 fl oz", price: 8.99, unitPrice: "$0.41 / fl oz", buyAgain: true),
        product(id: "wag_chips_606", storeID: "walgreens", name: "Kettle Cooked Chips", brand: "Lay's", category: "pantry", size: "8 oz", price: 5.49, unitPrice: "$0.69 / oz"),

        // Jewel-Osco
        product(id: "jewel_chicken_701", storeID: "jewel_osco", name: "Whole Rotisserie Chicken", brand: "Jewel-Osco Deli", category: "meat_seafood", size: "1 ct", price: 7.99, unitPrice: "$7.99 each", recommended: true),
        product(id: "jewel_milk_702", storeID: "jewel_osco", name: "2% Reduced Fat Milk", brand: "Dean's", category: "dairy_eggs", size: "1 gal", price: 4.19, unitPrice: "$4.19 / gal", buyAgain: true),
        product(id: "jewel_apples_703", storeID: "jewel_osco", name: "Honeycrisp Apples", brand: "Fresh", category: "produce", size: "3 lb bag", price: 6.99, unitPrice: "$2.33 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "jewel_bread_704", storeID: "jewel_osco", name: "French Bread", brand: "Jewel-Osco Bakery", category: "bakery", size: "16 oz", price: 3.49, unitPrice: "$0.22 / oz"),
        product(id: "jewel_soup_705", storeID: "jewel_osco", name: "Chicken Noodle Soup", brand: "Progresso", category: "pantry", size: "18.5 oz", price: 3.29, unitPrice: "$0.18 / oz"),
        product(id: "jewel_ice_cream_706", storeID: "jewel_osco", name: "Vanilla Bean Ice Cream", brand: "Häagen-Dazs", category: "frozen", size: "14 fl oz", price: 5.99, unitPrice: "$0.43 / fl oz"),
        product(id: "jewel_strawberries_707", storeID: "jewel_osco", name: "Fresh Strawberries", brand: "Driscoll's", category: "produce", size: "1 lb", price: 4.99, unitPrice: "$4.99 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "jewel_juice_708", storeID: "jewel_osco", name: "Premium Orange Juice", brand: "Tropicana", category: "beverages", size: "52 fl oz", price: 4.49, unitPrice: "$0.09 / fl oz", buyAgain: true),

        // Sprouts
        product(id: "sprouts_berries_801", storeID: "sprouts", name: "Organic Mixed Berries", brand: "Sprouts", category: "produce", size: "12 oz", price: 5.99, unitPrice: "$0.50 / oz", tags: ["Organic"], isOrganic: true, recommended: true),
        product(id: "sprouts_almond_milk_802", storeID: "sprouts", name: "Unsweetened Almond Milk", brand: "Sprouts", category: "dairy_eggs", size: "64 fl oz", price: 3.49, unitPrice: "$0.05 / fl oz", tags: ["Gluten-Free", "Vegan", "Dairy-Free"]),
        product(id: "sprouts_chicken_803", storeID: "sprouts", name: "Free Range Chicken Breast", brand: "Sprouts", category: "meat_seafood", size: "1 lb", price: 7.99, unitPrice: "$7.99 / lb", tags: ["Free Range"]),
        product(id: "sprouts_quinoa_804", storeID: "sprouts", name: "Organic White Quinoa", brand: "Sprouts", category: "pantry", size: "16 oz", price: 4.49, unitPrice: "$0.28 / oz", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "sprouts_spinach_805", storeID: "sprouts", name: "Organic Baby Spinach", brand: "Sprouts", category: "produce", size: "5 oz", price: 2.99, unitPrice: "$0.60 / oz", tags: ["Organic"], isOrganic: true, buyAgain: true),
        product(id: "sprouts_kombucha_806", storeID: "sprouts", name: "Trilogy Kombucha", brand: "GT's Synergy", category: "beverages", size: "16 fl oz", price: 3.99, unitPrice: "$0.25 / fl oz", tags: ["Gluten-Free", "Vegan"]),

        // Sam's Club
        product(id: "sams_water_901", storeID: "sams_club", name: "Purified Water Pack", brand: "Member's Mark", category: "beverages", size: "40 x 16.9 fl oz", price: 3.98, unitPrice: "$0.10 each", buyAgain: true),
        product(id: "sams_chicken_902", storeID: "sams_club", name: "Rotisserie Chicken", brand: "Member's Mark", category: "meat_seafood", size: "1 ct", price: 5.98, unitPrice: "$5.98 each", recommended: true),
        product(id: "sams_paper_903", storeID: "sams_club", name: "Ultra Premium Bath Tissue", brand: "Member's Mark", category: "household", size: "45 ct", price: 24.98, unitPrice: "$0.56 / roll", buyAgain: true),
        product(id: "sams_trash_904", storeID: "sams_club", name: "Kitchen Trash Bags", brand: "Member's Mark", category: "household", size: "200 ct", price: 17.98, unitPrice: "$0.09 each"),
        product(id: "sams_coffee_905", storeID: "sams_club", name: "Colombian Whole Bean Coffee", brand: "Member's Mark", category: "beverages", size: "40 oz", price: 13.98, unitPrice: "$0.35 / oz"),
        product(id: "sams_eggs_906", storeID: "sams_club", name: "Cage Free Large Eggs", brand: "Member's Mark", category: "dairy_eggs", size: "24 ct", price: 5.98, unitPrice: "$0.25 each", tags: ["Gluten-Free"]),

        // ── Additional Costco Meat & Seafood ──
        product(id: "costco_ribeye_036", storeID: "costco", name: "USDA Choice Ribeye Steak", brand: "Kirkland Signature", category: "meat_seafood", size: "About 2.5 lb / package", price: 49.99, unitPrice: "$19.99 / lb", tags: ["Gluten-Free"], recommended: true),
        product(id: "costco_ground_beef_037", storeID: "costco", name: "Lean Ground Beef 90/10", brand: "Kirkland Signature", category: "meat_seafood", size: "4 lb", price: 23.99, unitPrice: "$6.00 / lb", buyAgain: true),
        product(id: "costco_pork_loin_038", storeID: "costco", name: "Boneless Pork Loin Roast", brand: "Kirkland Signature", category: "meat_seafood", size: "About 3 lb", price: 14.99, unitPrice: "$5.00 / lb"),
        product(id: "costco_shrimp_039", storeID: "costco", name: "Raw Tail-On Shrimp 21-25 ct", brand: "Kirkland Signature", category: "meat_seafood", size: "2 lb bag", price: 18.99, unitPrice: "$9.50 / lb", tags: ["Gluten-Free"], recommended: true),
        product(id: "costco_chicken_breast_040", storeID: "costco", name: "Boneless Skinless Chicken Breasts", brand: "Kirkland Signature", category: "meat_seafood", size: "6.5 lb", price: 24.99, unitPrice: "$3.85 / lb", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "costco_filet_mignon_041", storeID: "costco", name: "USDA Prime Filet Mignon", brand: "Kirkland Signature", category: "meat_seafood", size: "About 2 lb / package", price: 79.99, unitPrice: "$39.99 / lb"),
        product(id: "costco_bacon_042", storeID: "costco", name: "Thick Sliced Bacon", brand: "Kirkland Signature", category: "meat_seafood", size: "4 x 1 lb", price: 19.99, unitPrice: "$5.00 / lb", buyAgain: true),
        product(id: "costco_tilapia_043", storeID: "costco", name: "Tilapia Fillets", brand: "Kirkland Signature", category: "frozen", size: "4 lb bag", price: 17.99, unitPrice: "$4.50 / lb"),
        product(id: "costco_lamb_044", storeID: "costco", name: "New Zealand Lamb Rack", brand: "Kirkland Signature", category: "meat_seafood", size: "About 1.5 lb", price: 29.99, unitPrice: "$19.99 / lb"),
        product(id: "costco_turkey_045", storeID: "costco", name: "Oven Roasted Turkey Breast", brand: "Kirkland Signature", category: "meat_seafood", size: "About 2 lb", price: 11.99, unitPrice: "$6.00 / lb"),
        product(id: "costco_sausage_046", storeID: "costco", name: "Italian Sausage Links", brand: "Kirkland Signature", category: "meat_seafood", size: "6 ct", price: 12.49, unitPrice: "$2.08 each"),
        product(id: "costco_crab_047", storeID: "costco", name: "King Crab Legs", brand: "Kirkland Signature", category: "meat_seafood", size: "About 2 lb", price: 49.99, unitPrice: "$25.00 / lb"),

        // ── Additional Costco Produce ──
        product(id: "costco_oranges_048", storeID: "costco", name: "Navel Oranges", brand: "Sunkist", category: "produce", size: "8 lb bag", price: 9.99, unitPrice: "$1.25 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "costco_tomatoes_049", storeID: "costco", name: "Campari Tomatoes", brand: "Sunset", category: "produce", size: "2 lb", price: 5.99, unitPrice: "$3.00 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "costco_bell_peppers_050", storeID: "costco", name: "Organic Bell Peppers", brand: "Kirkland Signature", category: "produce", size: "6 ct", price: 7.99, unitPrice: "$1.33 each", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "costco_mushrooms_051", storeID: "costco", name: "Baby Bella Mushrooms", brand: "Giorgio", category: "produce", size: "24 oz", price: 4.99, unitPrice: "$0.21 / oz"),
        product(id: "costco_broccoli_052", storeID: "costco", name: "Broccoli Florets", brand: "Kirkland Signature", category: "produce", size: "2 lb bag", price: 5.49, unitPrice: "$2.75 / lb", tags: ["Gluten-Free", "Vegan"]),

        // ── Additional Costco Dairy ──
        product(id: "costco_butter_053", storeID: "costco", name: "Unsalted Butter", brand: "Kirkland Signature", category: "dairy_eggs", size: "4 x 1 lb", price: 12.99, unitPrice: "$3.25 / lb"),
        product(id: "costco_cream_cheese_054", storeID: "costco", name: "Cream Cheese", brand: "Philadelphia", category: "dairy_eggs", size: "2 x 16 oz", price: 8.99, unitPrice: "$0.28 / oz"),
        product(id: "costco_string_cheese_055", storeID: "costco", name: "String Cheese", brand: "Kirkland Signature", category: "dairy_eggs", size: "48 ct", price: 11.99, unitPrice: "$0.25 each"),
        product(id: "costco_half_and_half_056", storeID: "costco", name: "Half and Half", brand: "Kirkland Signature", category: "dairy_eggs", size: "2 x 32 fl oz", price: 5.99, unitPrice: "$0.09 / fl oz"),

        // ── Additional Costco Pantry ──
        product(id: "costco_olive_oil_057", storeID: "costco", name: "Extra Virgin Olive Oil", brand: "Kirkland Signature", category: "pantry", size: "2 L", price: 14.99, unitPrice: "$0.22 / fl oz"),
        product(id: "costco_rice_058", storeID: "costco", name: "Jasmine Rice", brand: "Kirkland Signature", category: "pantry", size: "25 lb", price: 18.99, unitPrice: "$0.76 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "costco_almonds_059", storeID: "costco", name: "Whole Almonds", brand: "Kirkland Signature", category: "pantry", size: "3 lb bag", price: 14.99, unitPrice: "$5.00 / lb"),
        product(id: "costco_chips_060", storeID: "costco", name: "Organic Tortilla Chips", brand: "Kirkland Signature", category: "pantry", size: "40 oz", price: 6.49, unitPrice: "$0.16 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "costco_peanut_butter_061", storeID: "costco", name: "Organic Peanut Butter", brand: "Kirkland Signature", category: "pantry", size: "2 x 28 oz", price: 10.99, unitPrice: "$0.20 / oz", tags: ["Organic"], isOrganic: true),

        // ── Additional Costco Frozen ──
        product(id: "costco_pizza_062", storeID: "costco", name: "Frozen Cheese Pizza", brand: "Kirkland Signature", category: "frozen", size: "4 ct", price: 11.49, unitPrice: "$2.87 each"),
        product(id: "costco_fruit_bars_063", storeID: "costco", name: "Fruit & Veggie Bars", brand: "Kirkland Signature", category: "frozen", size: "30 ct", price: 14.99, unitPrice: "$0.50 each"),
        product(id: "costco_ice_cream_064", storeID: "costco", name: "Vanilla Ice Cream", brand: "Kirkland Signature", category: "frozen", size: "2 x 48 fl oz", price: 10.99, unitPrice: "$0.11 / fl oz"),
        product(id: "costco_berries_frozen_065", storeID: "costco", name: "Organic Frozen Mixed Berries", brand: "Kirkland Signature", category: "frozen", size: "3 lb bag", price: 10.99, unitPrice: "$3.66 / lb", tags: ["Organic"], isOrganic: true),
        product(id: "costco_waffles_066", storeID: "costco", name: "Belgian Waffles", brand: "Kirkland Signature", category: "frozen", size: "24 ct", price: 9.99, unitPrice: "$0.42 each"),

        // ── Additional Costco Beverages ──
        product(id: "costco_juice_067", storeID: "costco", name: "Organic Apple Juice", brand: "Kirkland Signature", category: "beverages", size: "2 x 96 fl oz", price: 9.99, unitPrice: "$0.05 / fl oz", tags: ["Organic"], isOrganic: true),
        product(id: "costco_coconut_water_068", storeID: "costco", name: "Coconut Water", brand: "Vita Coco", category: "beverages", size: "18 x 11.1 fl oz", price: 19.99, unitPrice: "$1.11 each", tags: ["Gluten-Free", "Vegan", "Non-GMO"]),

        // ── Additional Giant Eagle Meat ──
        product(id: "giant_ground_beef_216", storeID: "giant_eagle", name: "85% Lean Ground Beef", brand: "Giant Eagle", category: "meat_seafood", size: "1.5 lb pack", price: 8.99, unitPrice: "$5.99 / lb"),
        product(id: "giant_bacon_217", storeID: "giant_eagle", name: "Center Cut Bacon", brand: "Oscar Mayer", category: "meat_seafood", size: "12 oz", price: 6.99, unitPrice: "$0.58 / oz", buyAgain: true),
        product(id: "giant_salmon_218", storeID: "giant_eagle", name: "Atlantic Salmon Fillets", brand: "Giant Eagle", category: "meat_seafood", size: "12 oz", price: 10.99, unitPrice: "$0.92 / oz"),
        product(id: "giant_pork_chops_219", storeID: "giant_eagle", name: "Center Cut Pork Chops", brand: "Giant Eagle", category: "meat_seafood", size: "1.2 lb pack", price: 7.49, unitPrice: "$6.24 / lb"),
        product(id: "giant_hot_dogs_220", storeID: "giant_eagle", name: "Beef Hot Dogs", brand: "Hebrew National", category: "meat_seafood", size: "12 oz", price: 5.49, unitPrice: "$0.46 / oz", tags: ["Gluten-Free", "Kosher"]),
        product(id: "giant_turkey_221", storeID: "giant_eagle", name: "Ground Turkey 93/7", brand: "Butterball", category: "meat_seafood", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb"),

        // ── Additional Giant Eagle Produce & Pantry ──
        product(id: "giant_bananas_222", storeID: "giant_eagle", name: "Bananas", brand: "Dole", category: "produce", size: "1 bunch", price: 1.49, unitPrice: "$0.29 each"),
        product(id: "giant_apples_223", storeID: "giant_eagle", name: "Gala Apples", brand: "Giant Eagle", category: "produce", size: "3 lb bag", price: 4.99, unitPrice: "$1.66 / lb"),
        product(id: "giant_tomatoes_224", storeID: "giant_eagle", name: "Roma Tomatoes", brand: "Giant Eagle", category: "produce", size: "1 lb", price: 2.49, unitPrice: "$2.49 / lb"),
        product(id: "giant_potatoes_225", storeID: "giant_eagle", name: "Russet Potatoes", brand: "Giant Eagle", category: "produce", size: "5 lb bag", price: 4.99, unitPrice: "$1.00 / lb"),
        product(id: "giant_cereal_226", storeID: "giant_eagle", name: "Frosted Flakes", brand: "Kellogg's", category: "pantry", size: "13.5 oz", price: 4.29, unitPrice: "$0.32 / oz"),
        product(id: "giant_chips_227", storeID: "giant_eagle", name: "Wavy Potato Chips", brand: "Lay's", category: "pantry", size: "10 oz", price: 4.99, unitPrice: "$0.50 / oz"),
        product(id: "giant_ice_cream_228", storeID: "giant_eagle", name: "Cookies & Cream Ice Cream", brand: "Turkey Hill", category: "frozen", size: "48 fl oz", price: 4.99, unitPrice: "$0.10 / fl oz"),
        product(id: "giant_frozen_pizza_229", storeID: "giant_eagle", name: "Rising Crust Pizza", brand: "DiGiorno", category: "frozen", size: "27.5 oz", price: 7.99, unitPrice: "$0.29 / oz"),
        product(id: "giant_water_230", storeID: "giant_eagle", name: "Spring Water", brand: "Giant Eagle", category: "beverages", size: "24 x 16.9 fl oz", price: 3.49, unitPrice: "$0.15 each"),

        // ── Additional Walmart Products ──
        product(id: "walmart_ground_turkey_311", storeID: "walmart", name: "All Natural Ground Turkey", brand: "Jennie-O", category: "meat_seafood", size: "1 lb", price: 5.47, unitPrice: "$5.47 / lb"),
        product(id: "walmart_pork_chops_312", storeID: "walmart", name: "Thick Cut Bone-In Pork Chops", brand: "Great Value", category: "meat_seafood", size: "2.5 lb", price: 8.97, unitPrice: "$3.59 / lb"),
        product(id: "walmart_bacon_313", storeID: "walmart", name: "Thick Sliced Bacon", brand: "Great Value", category: "meat_seafood", size: "24 oz", price: 7.98, unitPrice: "$0.33 / oz", buyAgain: true),
        product(id: "walmart_shrimp_314", storeID: "walmart", name: "Frozen Raw Shrimp", brand: "Great Value", category: "frozen", size: "1 lb bag", price: 7.98, unitPrice: "$7.98 / lb"),
        product(id: "walmart_ground_beef_315", storeID: "walmart", name: "80/20 Ground Beef", brand: "Great Value", category: "meat_seafood", size: "2 lb roll", price: 7.47, unitPrice: "$3.74 / lb"),
        product(id: "walmart_steak_316", storeID: "walmart", name: "USDA Choice Ribeye Steak", brand: "Marketside Butcher", category: "meat_seafood", size: "About 1.25 lb", price: 16.97, unitPrice: "$13.58 / lb"),
        product(id: "walmart_hot_dogs_317", storeID: "walmart", name: "Beef Franks", brand: "Oscar Mayer", category: "meat_seafood", size: "1 lb", price: 4.98, unitPrice: "$4.98 / lb"),
        product(id: "walmart_deli_ham_318", storeID: "walmart", name: "Honey Ham Lunch Meat", brand: "Great Value", category: "meat_seafood", size: "9 oz", price: 3.98, unitPrice: "$0.44 / oz"),
        product(id: "walmart_apples_319", storeID: "walmart", name: "Gala Apples", brand: "Fresh", category: "produce", size: "3 lb bag", price: 4.48, unitPrice: "$1.49 / lb"),
        product(id: "walmart_lettuce_320", storeID: "walmart", name: "Iceberg Lettuce Head", brand: "Fresh", category: "produce", size: "1 ct", price: 1.68, unitPrice: "$1.68 each", tags: ["Gluten-Free", "Vegan"]),
        product(id: "walmart_tomatoes_321", storeID: "walmart", name: "Roma Tomatoes", brand: "Fresh", category: "produce", size: "6 ct", price: 1.98, unitPrice: "$0.33 each"),
        product(id: "walmart_onions_322", storeID: "walmart", name: "Yellow Onions", brand: "Fresh", category: "produce", size: "3 lb bag", price: 2.98, unitPrice: "$0.99 / lb"),
        product(id: "walmart_potatoes_323", storeID: "walmart", name: "Russet Potatoes", brand: "Fresh", category: "produce", size: "5 lb bag", price: 3.98, unitPrice: "$0.80 / lb"),
        product(id: "walmart_yogurt_324", storeID: "walmart", name: "Strawberry Greek Yogurt", brand: "Chobani", category: "dairy_eggs", size: "4 ct", price: 5.48, unitPrice: "$1.37 each", tags: ["Gluten-Free"]),
        product(id: "walmart_cheese_325", storeID: "walmart", name: "Sharp Cheddar Cheese Block", brand: "Great Value", category: "dairy_eggs", size: "16 oz", price: 3.98, unitPrice: "$0.25 / oz", buyAgain: true),
        product(id: "walmart_butter_326", storeID: "walmart", name: "Sweet Cream Butter", brand: "Great Value", category: "dairy_eggs", size: "1 lb", price: 3.98, unitPrice: "$3.98 / lb"),
        product(id: "walmart_frozen_pizza_327", storeID: "walmart", name: "Pepperoni Pizza", brand: "DiGiorno", category: "frozen", size: "27.5 oz", price: 6.98, unitPrice: "$0.25 / oz"),
        product(id: "walmart_ice_cream_328", storeID: "walmart", name: "Chocolate Ice Cream", brand: "Great Value", category: "frozen", size: "48 fl oz", price: 3.98, unitPrice: "$0.08 / fl oz"),
        product(id: "walmart_waffles_329", storeID: "walmart", name: "Frozen Waffles", brand: "Eggo", category: "frozen", size: "10 ct", price: 3.98, unitPrice: "$0.40 each"),
        product(id: "walmart_pasta_330", storeID: "walmart", name: "Spaghetti Pasta", brand: "Great Value", category: "pantry", size: "16 oz", price: 1.18, unitPrice: "$0.07 / oz"),
        product(id: "walmart_sauce_331", storeID: "walmart", name: "Marinara Sauce", brand: "Prego", category: "pantry", size: "24 oz", price: 3.28, unitPrice: "$0.14 / oz"),
        product(id: "walmart_peanut_butter_332", storeID: "walmart", name: "Creamy Peanut Butter", brand: "Jif", category: "pantry", size: "28 oz", price: 4.98, unitPrice: "$0.18 / oz"),
        product(id: "walmart_canned_corn_333", storeID: "walmart", name: "Whole Kernel Sweet Corn", brand: "Green Giant", category: "pantry", size: "15.25 oz", price: 1.28, unitPrice: "$0.08 / oz"),
        product(id: "walmart_juice_334", storeID: "walmart", name: "Orange Juice", brand: "Tropicana", category: "beverages", size: "52 fl oz", price: 4.48, unitPrice: "$0.09 / fl oz"),
        product(id: "walmart_soda_335", storeID: "walmart", name: "Coca-Cola Cans", brand: "Coca-Cola", category: "beverages", size: "12 x 12 fl oz", price: 7.48, unitPrice: "$0.62 each"),
        product(id: "walmart_coffee_336", storeID: "walmart", name: "Medium Roast Ground Coffee", brand: "Folgers", category: "beverages", size: "30.5 oz", price: 9.98, unitPrice: "$0.33 / oz"),
        product(id: "walmart_paper_towels_337", storeID: "walmart", name: "Paper Towels", brand: "Bounty", category: "household", size: "6 double rolls", price: 11.97, unitPrice: "$2.00 / roll"),
        product(id: "walmart_trash_bags_338", storeID: "walmart", name: "Kitchen Trash Bags", brand: "Glad", category: "household", size: "80 ct", price: 12.97, unitPrice: "$0.16 each"),
        product(id: "walmart_dish_soap_339", storeID: "walmart", name: "Dish Soap", brand: "Dawn", category: "household", size: "28 fl oz", price: 3.98, unitPrice: "$0.14 / fl oz"),

        // ── Additional Whole Foods Products ──
        product(id: "wf_chicken_409", storeID: "whole_foods", name: "Organic Free Range Chicken Breast", brand: "365 by Whole Foods", category: "meat_seafood", size: "1 lb", price: 9.99, unitPrice: "$9.99 / lb", tags: ["Organic", "Free Range"], isOrganic: true, recommended: true),
        product(id: "wf_ground_beef_410", storeID: "whole_foods", name: "Grass-Fed Ground Beef 85/15", brand: "365 by Whole Foods", category: "meat_seafood", size: "1 lb", price: 8.99, unitPrice: "$8.99 / lb"),
        product(id: "wf_steak_411", storeID: "whole_foods", name: "Grass-Fed NY Strip Steak", brand: "365 by Whole Foods", category: "meat_seafood", size: "About 12 oz", price: 16.99, unitPrice: "$22.65 / lb"),
        product(id: "wf_shrimp_412", storeID: "whole_foods", name: "Wild Caught Shrimp 16-20 ct", brand: "365 by Whole Foods", category: "meat_seafood", size: "1 lb", price: 13.99, unitPrice: "$13.99 / lb"),
        product(id: "wf_turkey_413", storeID: "whole_foods", name: "Organic Ground Turkey", brand: "Diestel", category: "meat_seafood", size: "1 lb", price: 8.49, unitPrice: "$8.49 / lb", tags: ["Organic"], isOrganic: true),
        product(id: "wf_bacon_414", storeID: "whole_foods", name: "Uncured Applewood Smoked Bacon", brand: "Applegate", category: "meat_seafood", size: "8 oz", price: 7.99, unitPrice: "$1.00 / oz"),
        product(id: "wf_berries_415", storeID: "whole_foods", name: "Organic Blueberries", brand: "Driscoll's", category: "produce", size: "6 oz", price: 4.99, unitPrice: "$0.83 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_bananas_416", storeID: "whole_foods", name: "Organic Bananas", brand: "Natural Foods Market", category: "produce", size: "1 bunch", price: 2.49, unitPrice: "$0.29 each", tags: ["Organic"], isOrganic: true),
        product(id: "wf_spinach_417", storeID: "whole_foods", name: "Organic Baby Spinach", brand: "365 by Whole Foods", category: "produce", size: "5 oz", price: 2.99, unitPrice: "$0.60 / oz", tags: ["Organic"], isOrganic: true, buyAgain: true),
        product(id: "wf_eggs_418", storeID: "whole_foods", name: "Pasture Raised Eggs", brand: "Vital Farms", category: "dairy_eggs", size: "12 ct", price: 8.49, unitPrice: "$0.71 each", tags: ["Free Range", "Gluten-Free"]),
        product(id: "wf_milk_419", storeID: "whole_foods", name: "Organic Whole Milk", brand: "365 by Whole Foods", category: "dairy_eggs", size: "1 gal", price: 5.99, unitPrice: "$5.99 / gal", tags: ["Organic"], isOrganic: true),
        product(id: "wf_cheese_420", storeID: "whole_foods", name: "Organic Sharp Cheddar", brand: "Organic Valley", category: "dairy_eggs", size: "8 oz", price: 5.99, unitPrice: "$0.75 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_bread_421", storeID: "whole_foods", name: "Organic Multigrain Bread", brand: "Dave's Killer Bread", category: "bakery", size: "27 oz", price: 6.49, unitPrice: "$0.24 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_hummus_422", storeID: "whole_foods", name: "Classic Hummus", brand: "365 by Whole Foods", category: "pantry", size: "10 oz", price: 3.49, unitPrice: "$0.35 / oz", tags: ["Gluten-Free", "Vegan", "Kosher"]),
        product(id: "wf_almond_butter_423", storeID: "whole_foods", name: "Creamy Almond Butter", brand: "365 by Whole Foods", category: "pantry", size: "16 oz", price: 7.99, unitPrice: "$0.50 / oz"),
        product(id: "wf_coffee_424", storeID: "whole_foods", name: "Organic French Roast Coffee", brand: "Allegro", category: "beverages", size: "12 oz", price: 9.99, unitPrice: "$0.83 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_sparkling_425", storeID: "whole_foods", name: "Italian Sparkling Mineral Water", brand: "San Pellegrino", category: "beverages", size: "6 x 16.9 fl oz", price: 7.99, unitPrice: "$1.33 each", tags: ["Gluten-Free", "Vegan", "Sugar-Free"]),
        product(id: "wf_frozen_meals_426", storeID: "whole_foods", name: "Organic Frozen Burritos", brand: "Amy's", category: "frozen", size: "6 oz", price: 4.99, unitPrice: "$0.83 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_ice_cream_427", storeID: "whole_foods", name: "Vanilla Bean Ice Cream", brand: "365 by Whole Foods", category: "frozen", size: "48 fl oz", price: 5.99, unitPrice: "$0.12 / fl oz"),
        product(id: "wf_strawberries_428", storeID: "whole_foods", name: "Organic Strawberries", brand: "Driscoll's", category: "produce", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb", tags: ["Organic"], isOrganic: true),
        product(id: "wf_raspberries_429", storeID: "whole_foods", name: "Organic Raspberries", brand: "Driscoll's", category: "produce", size: "6 oz", price: 5.49, unitPrice: "$0.92 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "wf_lemons_430", storeID: "whole_foods", name: "Organic Lemons", brand: "Natural Foods Market", category: "produce", size: "1 bag (5 ct)", price: 3.99, unitPrice: "$0.80 each", tags: ["Organic"], isOrganic: true),
        product(id: "wf_sweet_potatoes_431", storeID: "whole_foods", name: "Organic Sweet Potatoes", brand: "Natural Foods Market", category: "produce", size: "1 lb", price: 2.49, unitPrice: "$2.49 / lb", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "wf_tomatoes_432", storeID: "whole_foods", name: "Organic Roma Tomatoes", brand: "Natural Foods Market", category: "produce", size: "1 lb", price: 3.99, unitPrice: "$3.99 / lb", tags: ["Organic", "Vegan"], isOrganic: true),

        // ── Additional Trader Joe's Products ──
        product(id: "tj_chicken_breast_509", storeID: "trader_joes", name: "Grilled Chicken Breast Strips", brand: "Trader Joe's", category: "meat_seafood", size: "12 oz", price: 4.99, unitPrice: "$0.42 / oz"),
        product(id: "tj_ground_beef_510", storeID: "trader_joes", name: "80/20 Ground Beef", brand: "Trader Joe's", category: "meat_seafood", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb"),
        product(id: "tj_salmon_511", storeID: "trader_joes", name: "Wild Caught Sockeye Salmon", brand: "Trader Joe's", category: "meat_seafood", size: "12 oz", price: 9.99, unitPrice: "$0.83 / oz"),
        product(id: "tj_bacon_512", storeID: "trader_joes", name: "Uncured Apple Smoked Bacon", brand: "Trader Joe's", category: "meat_seafood", size: "8 oz", price: 4.99, unitPrice: "$0.62 / oz"),
        product(id: "tj_shrimp_513", storeID: "trader_joes", name: "Frozen Raw Shrimp", brand: "Trader Joe's", category: "frozen", size: "1 lb", price: 8.99, unitPrice: "$8.99 / lb"),
        product(id: "tj_bananas_514", storeID: "trader_joes", name: "Bananas", brand: "Trader Joe's", category: "produce", size: "1 bunch", price: 0.23, unitPrice: "$0.23 each"),
        product(id: "tj_avocados_515", storeID: "trader_joes", name: "Hass Avocados", brand: "Trader Joe's", category: "produce", size: "4 ct bag", price: 3.99, unitPrice: "$1.00 each"),
        product(id: "tj_eggs_516", storeID: "trader_joes", name: "Cage Free Large Eggs", brand: "Trader Joe's", category: "dairy_eggs", size: "12 ct", price: 3.99, unitPrice: "$0.33 each", tags: ["Gluten-Free"], buyAgain: true),
        product(id: "tj_cheese_517", storeID: "trader_joes", name: "Unexpected Cheddar Cheese", brand: "Trader Joe's", category: "dairy_eggs", size: "8 oz", price: 3.99, unitPrice: "$0.50 / oz", recommended: true),
        product(id: "tj_milk_518", storeID: "trader_joes", name: "Organic Whole Milk", brand: "Trader Joe's", category: "dairy_eggs", size: "1/2 gal", price: 3.99, unitPrice: "$0.06 / fl oz", tags: ["Organic"], isOrganic: true),
        product(id: "tj_bread_519", storeID: "trader_joes", name: "Sourdough Bread", brand: "Trader Joe's", category: "bakery", size: "24 oz", price: 3.99, unitPrice: "$0.17 / oz"),
        product(id: "tj_tortilla_chips_520", storeID: "trader_joes", name: "Organic Corn Chip Dippers", brand: "Trader Joe's", category: "pantry", size: "10 oz", price: 2.99, unitPrice: "$0.30 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "tj_pasta_sauce_521", storeID: "trader_joes", name: "Tomato Basil Marinara", brand: "Trader Joe's", category: "pantry", size: "25 oz", price: 3.49, unitPrice: "$0.14 / oz"),
        product(id: "tj_rice_522", storeID: "trader_joes", name: "Jasmine Rice", brand: "Trader Joe's", category: "pantry", size: "2 lb", price: 3.99, unitPrice: "$2.00 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "tj_frozen_mac_523", storeID: "trader_joes", name: "Hatch Chile Mac & Cheese", brand: "Trader Joe's", category: "frozen", size: "12 oz", price: 3.99, unitPrice: "$0.33 / oz"),
        product(id: "tj_ice_cream_524", storeID: "trader_joes", name: "Hold The Cone Mini Ice Cream Cones", brand: "Trader Joe's", category: "frozen", size: "8 ct", price: 3.49, unitPrice: "$0.44 each", recommended: true),
        product(id: "tj_coffee_525", storeID: "trader_joes", name: "Cold Brew Coffee", brand: "Trader Joe's", category: "beverages", size: "32 fl oz", price: 4.99, unitPrice: "$0.16 / fl oz"),
        product(id: "tj_sparkling_526", storeID: "trader_joes", name: "Sparkling Lemonade", brand: "Trader Joe's", category: "beverages", size: "25.4 fl oz", price: 2.99, unitPrice: "$0.12 / fl oz"),

        // ── Additional ALDI Products ──
        product(id: "aldi_ground_beef_120", storeID: "aldi", name: "Ground Beef 80/20", brand: "Earth Grown", category: "meat_seafood", size: "1 lb", price: 4.49, unitPrice: "$4.49 / lb"),
        product(id: "aldi_chicken_breast_121", storeID: "aldi", name: "Boneless Skinless Chicken Breast", brand: "Kirkwood", category: "meat_seafood", size: "2 lb bag", price: 6.99, unitPrice: "$3.50 / lb", recommended: true),
        product(id: "aldi_salmon_122", storeID: "aldi", name: "Fresh Atlantic Salmon Fillets", brand: "Fresh", category: "meat_seafood", size: "12 oz", price: 7.49, unitPrice: "$0.62 / oz"),
        product(id: "aldi_bacon_123", storeID: "aldi", name: "Thick Sliced Bacon", brand: "Appleton Farms", category: "meat_seafood", size: "16 oz", price: 4.99, unitPrice: "$0.31 / oz", buyAgain: true),
        product(id: "aldi_hot_dogs_124", storeID: "aldi", name: "Beef Franks", brand: "Park Avenue Deli", category: "meat_seafood", size: "1 lb", price: 3.49, unitPrice: "$3.49 / lb"),
        product(id: "aldi_sausage_125", storeID: "aldi", name: "Italian Sausage Links", brand: "Appleton Farms", category: "meat_seafood", size: "19 oz", price: 3.99, unitPrice: "$0.21 / oz"),
        product(id: "aldi_milk_126", storeID: "aldi", name: "Whole Milk", brand: "Friendly Farms", category: "dairy_eggs", size: "1 gal", price: 3.19, unitPrice: "$3.19 / gal", buyAgain: true),
        product(id: "aldi_butter_127", storeID: "aldi", name: "Sweet Cream Butter", brand: "Countryside Creamery", category: "dairy_eggs", size: "1 lb", price: 3.49, unitPrice: "$3.49 / lb"),
        product(id: "aldi_water_128", storeID: "aldi", name: "Purified Drinking Water", brand: "PurAqua", category: "beverages", size: "24 x 16.9 fl oz", price: 2.99, unitPrice: "$0.12 each"),
        product(id: "aldi_coffee_129", storeID: "aldi", name: "Colombian Medium Roast Coffee", brand: "Barissimo", category: "beverages", size: "11 oz", price: 4.49, unitPrice: "$0.41 / oz"),
        product(id: "aldi_frozen_pizza_130", storeID: "aldi", name: "Frozen Pepperoni Pizza", brand: "Mama Cozzi's", category: "frozen", size: "16 oz", price: 3.49, unitPrice: "$0.22 / oz"),
        product(id: "aldi_ice_cream_131", storeID: "aldi", name: "Vanilla Ice Cream", brand: "Belmont", category: "frozen", size: "48 fl oz", price: 3.49, unitPrice: "$0.07 / fl oz"),
        product(id: "aldi_chips_132", storeID: "aldi", name: "Wavy Potato Chips", brand: "Clancy's", category: "pantry", size: "10 oz", price: 2.29, unitPrice: "$0.23 / oz"),
        product(id: "aldi_cereal_133", storeID: "aldi", name: "Honey Nut Oat Cereal", brand: "Millville", category: "pantry", size: "12.25 oz", price: 2.29, unitPrice: "$0.19 / oz"),
        product(id: "aldi_oranges_134", storeID: "aldi", name: "Navel Oranges", brand: "Fresh", category: "produce", size: "4 lb bag", price: 4.49, unitPrice: "$1.12 / lb"),
        product(id: "aldi_potatoes_135", storeID: "aldi", name: "Russet Potatoes", brand: "Fresh", category: "produce", size: "5 lb bag", price: 3.99, unitPrice: "$0.80 / lb"),
        product(id: "aldi_paper_towels_136", storeID: "aldi", name: "Paper Towels", brand: "Boulder", category: "household", size: "6 rolls", price: 5.99, unitPrice: "$1.00 / roll"),
        product(id: "aldi_detergent_137", storeID: "aldi", name: "Laundry Detergent", brand: "Tandil", category: "household", size: "100 fl oz", price: 5.99, unitPrice: "$0.06 / fl oz"),

        // ── Additional Jewel-Osco Products ──
        product(id: "jewel_ground_beef_709", storeID: "jewel_osco", name: "80% Lean Ground Beef", brand: "Jewel-Osco", category: "meat_seafood", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb"),
        product(id: "jewel_pork_710", storeID: "jewel_osco", name: "Boneless Pork Chops", brand: "Jewel-Osco", category: "meat_seafood", size: "1.25 lb pack", price: 6.99, unitPrice: "$5.59 / lb"),
        product(id: "jewel_bacon_711", storeID: "jewel_osco", name: "Applewood Smoked Bacon", brand: "Oscar Mayer", category: "meat_seafood", size: "16 oz", price: 7.49, unitPrice: "$0.47 / oz", buyAgain: true),
        product(id: "jewel_salmon_712", storeID: "jewel_osco", name: "Atlantic Salmon Fillets", brand: "Fresh", category: "meat_seafood", size: "12 oz", price: 9.99, unitPrice: "$0.83 / oz"),
        product(id: "jewel_turkey_713", storeID: "jewel_osco", name: "Lean Ground Turkey", brand: "Jennie-O", category: "meat_seafood", size: "1 lb", price: 5.49, unitPrice: "$5.49 / lb"),
        product(id: "jewel_sausage_714", storeID: "jewel_osco", name: "Italian Sausage Links", brand: "Johnsonville", category: "meat_seafood", size: "19 oz", price: 5.99, unitPrice: "$0.32 / oz"),
        product(id: "jewel_eggs_715", storeID: "jewel_osco", name: "Large White Eggs", brand: "Jewel-Osco", category: "dairy_eggs", size: "18 ct", price: 4.49, unitPrice: "$0.25 each"),
        product(id: "jewel_cheese_716", storeID: "jewel_osco", name: "Shredded Mozzarella", brand: "Kraft", category: "dairy_eggs", size: "8 oz", price: 3.49, unitPrice: "$0.44 / oz"),
        product(id: "jewel_yogurt_717", storeID: "jewel_osco", name: "Greek Yogurt", brand: "Chobani", category: "dairy_eggs", size: "5.3 oz", price: 1.49, unitPrice: "$0.28 / oz", tags: ["Gluten-Free"]),
        product(id: "jewel_bananas_718", storeID: "jewel_osco", name: "Bananas", brand: "Fresh", category: "produce", size: "1 bunch", price: 0.69, unitPrice: "$0.23 each"),
        product(id: "jewel_potatoes_719", storeID: "jewel_osco", name: "Russet Potatoes", brand: "Fresh", category: "produce", size: "5 lb bag", price: 4.99, unitPrice: "$1.00 / lb"),
        product(id: "jewel_pasta_720", storeID: "jewel_osco", name: "Spaghetti", brand: "Barilla", category: "pantry", size: "16 oz", price: 1.99, unitPrice: "$0.12 / oz"),
        product(id: "jewel_sauce_721", storeID: "jewel_osco", name: "Tomato Basil Marinara", brand: "Classico", category: "pantry", size: "24 oz", price: 3.49, unitPrice: "$0.15 / oz"),
        product(id: "jewel_cereal_722", storeID: "jewel_osco", name: "Honey Nut Cheerios", brand: "General Mills", category: "pantry", size: "15.4 oz", price: 4.99, unitPrice: "$0.32 / oz"),
        product(id: "jewel_water_723", storeID: "jewel_osco", name: "Purified Water", brand: "Jewel-Osco", category: "beverages", size: "24 x 16.9 fl oz", price: 3.29, unitPrice: "$0.14 each"),
        product(id: "jewel_frozen_veggies_724", storeID: "jewel_osco", name: "Frozen Mixed Vegetables", brand: "Birds Eye", category: "frozen", size: "10 oz", price: 1.99, unitPrice: "$0.20 / oz"),
        product(id: "jewel_pizza_725", storeID: "jewel_osco", name: "Frozen Cheese Pizza", brand: "Tombstone", category: "frozen", size: "21 oz", price: 5.99, unitPrice: "$0.29 / oz"),
        product(id: "jewel_paper_towels_726", storeID: "jewel_osco", name: "Paper Towels", brand: "Bounty", category: "household", size: "4 big rolls", price: 8.99, unitPrice: "$2.25 / roll"),
        product(id: "jewel_detergent_727", storeID: "jewel_osco", name: "Laundry Detergent Pods", brand: "Tide", category: "household", size: "42 ct", price: 13.99, unitPrice: "$0.33 each"),

        // ── Additional Sprouts Products ──
        product(id: "sprouts_ground_beef_807", storeID: "sprouts", name: "Grass-Fed Ground Beef 85/15", brand: "Sprouts", category: "meat_seafood", size: "1 lb", price: 7.99, unitPrice: "$7.99 / lb"),
        product(id: "sprouts_salmon_808", storeID: "sprouts", name: "Wild Caught Alaskan Salmon", brand: "Sprouts", category: "meat_seafood", size: "6 oz", price: 8.99, unitPrice: "$1.50 / oz", recommended: true),
        product(id: "sprouts_turkey_809", storeID: "sprouts", name: "Organic Ground Turkey", brand: "Sprouts", category: "meat_seafood", size: "1 lb", price: 7.49, unitPrice: "$7.49 / lb", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_steak_810", storeID: "sprouts", name: "Grass-Fed Ribeye Steak", brand: "Sprouts", category: "meat_seafood", size: "About 12 oz", price: 14.99, unitPrice: "$19.99 / lb"),
        product(id: "sprouts_bacon_811", storeID: "sprouts", name: "Uncured Turkey Bacon", brand: "Applegate", category: "meat_seafood", size: "8 oz", price: 5.99, unitPrice: "$0.75 / oz"),
        product(id: "sprouts_shrimp_812", storeID: "sprouts", name: "Wild Caught Gulf Shrimp", brand: "Sprouts", category: "meat_seafood", size: "1 lb", price: 11.99, unitPrice: "$11.99 / lb"),
        product(id: "sprouts_avocados_813", storeID: "sprouts", name: "Organic Hass Avocados", brand: "Sprouts", category: "produce", size: "4 ct", price: 4.99, unitPrice: "$1.25 each", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_bananas_814", storeID: "sprouts", name: "Organic Bananas", brand: "Sprouts", category: "produce", size: "1 bunch", price: 0.29, unitPrice: "$0.29 each", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_kale_815", storeID: "sprouts", name: "Organic Lacinato Kale", brand: "Sprouts", category: "produce", size: "1 bunch", price: 2.49, unitPrice: "$2.49 each", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_eggs_816", storeID: "sprouts", name: "Cage Free Large Eggs", brand: "Sprouts", category: "dairy_eggs", size: "12 ct", price: 4.49, unitPrice: "$0.37 each", tags: ["Gluten-Free"]),
        product(id: "sprouts_yogurt_817", storeID: "sprouts", name: "Organic Greek Yogurt", brand: "Stonyfield", category: "dairy_eggs", size: "32 oz", price: 5.49, unitPrice: "$0.17 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_bread_818", storeID: "sprouts", name: "Organic Sprouted Wheat Bread", brand: "Dave's Killer Bread", category: "bakery", size: "27 oz", price: 5.99, unitPrice: "$0.22 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_granola_819", storeID: "sprouts", name: "Organic Granola", brand: "Sprouts", category: "pantry", size: "12 oz", price: 3.99, unitPrice: "$0.33 / oz", tags: ["Organic"], isOrganic: true),
        product(id: "sprouts_almond_milk_820", storeID: "sprouts", name: "Organic Oat Milk", brand: "Sprouts", category: "dairy_eggs", size: "64 fl oz", price: 3.99, unitPrice: "$0.06 / fl oz", tags: ["Organic", "Vegan", "Dairy-Free"], isOrganic: true),
        product(id: "sprouts_frozen_fruit_821", storeID: "sprouts", name: "Organic Frozen Mango Chunks", brand: "Sprouts", category: "frozen", size: "10 oz", price: 3.49, unitPrice: "$0.35 / oz", tags: ["Organic"], isOrganic: true),

        // ── Additional Sam's Club Products ──
        product(id: "sams_ribeye_907", storeID: "sams_club", name: "USDA Choice Ribeye Steaks", brand: "Member's Mark", category: "meat_seafood", size: "About 3 lb", price: 49.98, unitPrice: "$16.66 / lb"),
        product(id: "sams_ground_beef_908", storeID: "sams_club", name: "Ground Beef 80/20", brand: "Member's Mark", category: "meat_seafood", size: "5 lb", price: 22.98, unitPrice: "$4.60 / lb", buyAgain: true),
        product(id: "sams_chicken_breast_909", storeID: "sams_club", name: "Boneless Skinless Chicken Breasts", brand: "Member's Mark", category: "meat_seafood", size: "6 lb", price: 19.98, unitPrice: "$3.33 / lb", recommended: true),
        product(id: "sams_shrimp_910", storeID: "sams_club", name: "Raw Tail-On Shrimp 16-20 ct", brand: "Member's Mark", category: "meat_seafood", size: "2 lb bag", price: 16.98, unitPrice: "$8.49 / lb"),
        product(id: "sams_bacon_911", storeID: "sams_club", name: "Thick Sliced Bacon", brand: "Member's Mark", category: "meat_seafood", size: "3 lb", price: 14.98, unitPrice: "$4.99 / lb"),
        product(id: "sams_pork_loin_912", storeID: "sams_club", name: "Boneless Pork Loin", brand: "Member's Mark", category: "meat_seafood", size: "About 4 lb", price: 12.98, unitPrice: "$3.25 / lb"),
        product(id: "sams_salmon_913", storeID: "sams_club", name: "Fresh Atlantic Salmon Fillets", brand: "Member's Mark", category: "meat_seafood", size: "About 2.5 lb", price: 29.98, unitPrice: "$11.99 / lb"),
        product(id: "sams_milk_914", storeID: "sams_club", name: "2% Reduced Fat Milk", brand: "Member's Mark", category: "dairy_eggs", size: "2 x 1 gal", price: 6.48, unitPrice: "$3.24 / gal"),
        product(id: "sams_cheese_915", storeID: "sams_club", name: "Shredded Cheddar Cheese", brand: "Member's Mark", category: "dairy_eggs", size: "5 lb", price: 14.98, unitPrice: "$3.00 / lb"),
        product(id: "sams_bread_916", storeID: "sams_club", name: "Artisan Bread Loaves", brand: "Member's Mark", category: "bakery", size: "2 ct", price: 5.98, unitPrice: "$2.99 each"),
        product(id: "sams_frozen_pizza_917", storeID: "sams_club", name: "Pepperoni Frozen Pizza", brand: "Member's Mark", category: "frozen", size: "4 ct", price: 13.98, unitPrice: "$3.50 each"),
        product(id: "sams_rice_918", storeID: "sams_club", name: "Jasmine Rice", brand: "Member's Mark", category: "pantry", size: "25 lb", price: 16.98, unitPrice: "$0.68 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "sams_olive_oil_919", storeID: "sams_club", name: "Extra Virgin Olive Oil", brand: "Member's Mark", category: "pantry", size: "2 L", price: 11.98, unitPrice: "$0.18 / fl oz"),
        product(id: "sams_detergent_920", storeID: "sams_club", name: "Laundry Detergent", brand: "Tide", category: "household", size: "150 fl oz", price: 22.98, unitPrice: "$0.15 / fl oz"),

        // MARK: – Walgreens (expanded)
        product(id: "walg_water_1001", storeID: "walgreens", name: "Purified Water", brand: "Smartwater", category: "beverages", size: "1 L", price: 2.49, unitPrice: "$0.07 / fl oz"),
        product(id: "walg_gatorade_1002", storeID: "walgreens", name: "Thirst Quencher", brand: "Gatorade", category: "beverages", size: "28 fl oz", price: 2.29, unitPrice: "$0.08 / fl oz"),
        product(id: "walg_coke_1003", storeID: "walgreens", name: "Cola", brand: "Coca-Cola", category: "beverages", size: "12 ct", price: 7.49, unitPrice: "$0.62 each"),
        product(id: "walg_redbull_1004", storeID: "walgreens", name: "Energy Drink", brand: "Red Bull", category: "beverages", size: "8.4 fl oz", price: 3.29, unitPrice: "$0.39 / fl oz"),
        product(id: "walg_milk_1005", storeID: "walgreens", name: "Whole Milk", brand: "Walgreens", category: "dairy_eggs", size: "1 gal", price: 4.49, unitPrice: "$0.04 / fl oz"),
        product(id: "walg_eggs_1006", storeID: "walgreens", name: "Large White Eggs", brand: "Walgreens", category: "dairy_eggs", size: "12 ct", price: 4.29, unitPrice: "$0.36 each"),
        product(id: "walg_cheese_1007", storeID: "walgreens", name: "Shredded Cheddar Cheese", brand: "Sargento", category: "dairy_eggs", size: "8 oz", price: 4.49, unitPrice: "$0.56 / oz"),
        product(id: "walg_icecream_1008", storeID: "walgreens", name: "Vanilla Ice Cream", brand: "Häagen-Dazs", category: "frozen", size: "14 fl oz", price: 5.99, unitPrice: "$0.43 / fl oz"),
        product(id: "walg_pizza_1009", storeID: "walgreens", name: "Pepperoni Pizza", brand: "DiGiorno", category: "frozen", size: "22.2 oz", price: 7.49, unitPrice: "$0.34 / oz"),
        product(id: "walg_chips_1010", storeID: "walgreens", name: "Potato Chips", brand: "Lay's", category: "pantry", size: "8 oz", price: 4.79, unitPrice: "$0.60 / oz"),
        product(id: "walg_oreos_1011", storeID: "walgreens", name: "Chocolate Sandwich Cookies", brand: "Oreo", category: "pantry", size: "14.3 oz", price: 5.49, unitPrice: "$0.38 / oz"),
        product(id: "walg_soup_1012", storeID: "walgreens", name: "Chicken Noodle Soup", brand: "Campbell's", category: "pantry", size: "10.75 oz", price: 1.79, unitPrice: "$0.17 / oz"),
        product(id: "walg_cereal_1013", storeID: "walgreens", name: "Frosted Flakes", brand: "Kellogg's", category: "pantry", size: "13.5 oz", price: 4.99, unitPrice: "$0.37 / oz"),
        product(id: "walg_paper_1014", storeID: "walgreens", name: "Paper Towels", brand: "Bounty", category: "household", size: "6 ct", price: 15.99, unitPrice: "$2.67 each"),
        product(id: "walg_tissue_1015", storeID: "walgreens", name: "Bath Tissue", brand: "Charmin", category: "household", size: "12 ct", price: 14.99, unitPrice: "$1.25 each"),
        product(id: "walg_detergent_1016", storeID: "walgreens", name: "Laundry Pods", brand: "Tide", category: "household", size: "42 ct", price: 14.99, unitPrice: "$0.36 each"),
        product(id: "walg_dish_1017", storeID: "walgreens", name: "Dish Soap", brand: "Dawn", category: "household", size: "19.4 fl oz", price: 4.29, unitPrice: "$0.22 / fl oz"),
        product(id: "walg_bandaid_1018", storeID: "walgreens", name: "Adhesive Bandages", brand: "Band-Aid", category: "retail", size: "100 ct", price: 8.99, unitPrice: "$0.09 each"),
        product(id: "walg_tylenol_1019", storeID: "walgreens", name: "Extra Strength Acetaminophen", brand: "Tylenol", category: "retail", size: "100 ct", price: 11.99, unitPrice: "$0.12 each"),
        product(id: "walg_banana_1020", storeID: "walgreens", name: "Bananas", brand: "Walgreens Fresh", category: "produce", size: "1 bunch", price: 1.29, unitPrice: "$0.26 each"),
        product(id: "walg_apple_1021", storeID: "walgreens", name: "Gala Apples", brand: "Walgreens Fresh", category: "produce", size: "3 ct", price: 3.49, unitPrice: "$1.16 each"),

        // MARK: – Target (expanded)
        product(id: "tgt_banana_1030", storeID: "target", name: "Organic Bananas", brand: "Good & Gather", category: "produce", size: "1 bunch", price: 1.29, unitPrice: "$0.26 each", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "tgt_avocado_1031", storeID: "target", name: "Hass Avocados", brand: "Good & Gather", category: "produce", size: "4 ct", price: 3.99, unitPrice: "$1.00 each"),
        product(id: "tgt_strawberry_1032", storeID: "target", name: "Strawberries", brand: "Good & Gather", category: "produce", size: "1 lb", price: 3.99, unitPrice: "$3.99 / lb"),
        product(id: "tgt_spinach_1033", storeID: "target", name: "Baby Spinach", brand: "Good & Gather", category: "produce", size: "5 oz", price: 2.69, unitPrice: "$0.54 / oz", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "tgt_tomato_1034", storeID: "target", name: "Roma Tomatoes", brand: "Good & Gather", category: "produce", size: "6 ct", price: 2.99, unitPrice: "$0.50 each"),
        product(id: "tgt_milk_1035", storeID: "target", name: "2% Reduced Fat Milk", brand: "Good & Gather", category: "dairy_eggs", size: "1 gal", price: 3.89, unitPrice: "$0.03 / fl oz"),
        product(id: "tgt_eggs_1036", storeID: "target", name: "Cage-Free Large Brown Eggs", brand: "Good & Gather", category: "dairy_eggs", size: "18 ct", price: 6.49, unitPrice: "$0.36 each", tags: ["Gluten-Free"]),
        product(id: "tgt_yogurt_1037", storeID: "target", name: "Greek Yogurt", brand: "Chobani", category: "dairy_eggs", size: "32 oz", price: 5.79, unitPrice: "$0.18 / oz", tags: ["Gluten-Free"]),
        product(id: "tgt_butter_1038", storeID: "target", name: "Salted Butter", brand: "Land O'Lakes", category: "dairy_eggs", size: "1 lb", price: 5.29, unitPrice: "$5.29 / lb"),
        product(id: "tgt_chicken_1039", storeID: "target", name: "Boneless Skinless Chicken Breast", brand: "Good & Gather", category: "meat_seafood", size: "2.5 lb", price: 10.99, unitPrice: "$4.40 / lb"),
        product(id: "tgt_ground_beef_1040", storeID: "target", name: "80/20 Ground Beef", brand: "Good & Gather", category: "meat_seafood", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb"),
        product(id: "tgt_salmon_1041", storeID: "target", name: "Atlantic Salmon Fillet", brand: "Good & Gather", category: "meat_seafood", size: "12 oz", price: 8.99, unitPrice: "$0.75 / oz"),
        product(id: "tgt_bacon_1042", storeID: "target", name: "Hardwood Smoked Bacon", brand: "Oscar Mayer", category: "meat_seafood", size: "16 oz", price: 6.49, unitPrice: "$0.41 / oz"),
        product(id: "tgt_bread_1043", storeID: "target", name: "White Sandwich Bread", brand: "Good & Gather", category: "bakery", size: "20 oz", price: 2.49, unitPrice: "$0.12 / oz"),
        product(id: "tgt_bagels_1044", storeID: "target", name: "Plain Bagels", brand: "Good & Gather", category: "bakery", size: "5 ct", price: 3.29, unitPrice: "$0.66 each"),
        product(id: "tgt_muffins_1045", storeID: "target", name: "Blueberry Muffins", brand: "Favorite Day", category: "bakery", size: "4 ct", price: 4.49, unitPrice: "$1.12 each"),
        product(id: "tgt_frozen_waffles_1046", storeID: "target", name: "Frozen Waffles", brand: "Eggo", category: "frozen", size: "10 ct", price: 3.49, unitPrice: "$0.35 each"),
        product(id: "tgt_ice_cream_1047", storeID: "target", name: "Chocolate Ice Cream", brand: "Favorite Day", category: "frozen", size: "48 fl oz", price: 4.49, unitPrice: "$0.09 / fl oz"),
        product(id: "tgt_frozen_meals_1048", storeID: "target", name: "Chicken Alfredo", brand: "Stouffer's", category: "frozen", size: "11.5 oz", price: 3.99, unitPrice: "$0.35 / oz"),
        product(id: "tgt_pasta_1049", storeID: "target", name: "Spaghetti", brand: "Barilla", category: "pantry", size: "16 oz", price: 1.69, unitPrice: "$0.11 / oz"),
        product(id: "tgt_sauce_1050", storeID: "target", name: "Marinara Sauce", brand: "Rao's", category: "pantry", size: "24 oz", price: 7.99, unitPrice: "$0.33 / oz"),
        product(id: "tgt_cereal_1051", storeID: "target", name: "Honey Nut Cheerios", brand: "General Mills", category: "pantry", size: "15.4 oz", price: 4.99, unitPrice: "$0.32 / oz"),
        product(id: "tgt_pb_1052", storeID: "target", name: "Creamy Peanut Butter", brand: "Jif", category: "pantry", size: "16 oz", price: 3.79, unitPrice: "$0.24 / oz"),
        product(id: "tgt_coffee_1053", storeID: "target", name: "Medium Roast K-Cups", brand: "Good & Gather", category: "beverages", size: "36 ct", price: 14.99, unitPrice: "$0.42 each"),
        product(id: "tgt_soda_1054", storeID: "target", name: "Cola", brand: "Coca-Cola", category: "beverages", size: "12 ct", price: 6.99, unitPrice: "$0.58 each"),
        product(id: "tgt_water_1055", storeID: "target", name: "Purified Water", brand: "Good & Gather", category: "beverages", size: "24 ct", price: 3.99, unitPrice: "$0.17 each"),
        product(id: "tgt_paper_1056", storeID: "target", name: "Paper Towels", brand: "Up & Up", category: "household", size: "8 ct", price: 11.99, unitPrice: "$1.50 each"),
        product(id: "tgt_trash_1057", storeID: "target", name: "Tall Kitchen Trash Bags", brand: "Up & Up", category: "household", size: "40 ct", price: 8.99, unitPrice: "$0.22 each"),

        // MARK: – CVS (expanded)
        product(id: "cvs_water_1060", storeID: "cvs", name: "Spring Water", brand: "Poland Spring", category: "beverages", size: "24 ct", price: 5.99, unitPrice: "$0.25 each"),
        product(id: "cvs_soda_1061", storeID: "cvs", name: "Dr Pepper", brand: "Dr Pepper", category: "beverages", size: "12 ct", price: 7.49, unitPrice: "$0.62 each"),
        product(id: "cvs_juice_1062", storeID: "cvs", name: "Orange Juice", brand: "Tropicana", category: "beverages", size: "52 fl oz", price: 4.99, unitPrice: "$0.10 / fl oz"),
        product(id: "cvs_coffee_1063", storeID: "cvs", name: "Ground Coffee", brand: "Folgers", category: "beverages", size: "30.5 oz", price: 10.99, unitPrice: "$0.36 / oz"),
        product(id: "cvs_chips_1064", storeID: "cvs", name: "Tortilla Chips", brand: "Tostitos", category: "pantry", size: "13 oz", price: 5.49, unitPrice: "$0.42 / oz"),
        product(id: "cvs_crackers_1065", storeID: "cvs", name: "Cheddar Crackers", brand: "Goldfish", category: "pantry", size: "6.6 oz", price: 3.49, unitPrice: "$0.53 / oz"),
        product(id: "cvs_nuts_1066", storeID: "cvs", name: "Mixed Nuts", brand: "Planters", category: "pantry", size: "10.3 oz", price: 7.99, unitPrice: "$0.78 / oz"),
        product(id: "cvs_candy_1067", storeID: "cvs", name: "Peanut M&Ms", brand: "M&M's", category: "pantry", size: "10.7 oz", price: 5.49, unitPrice: "$0.51 / oz"),
        product(id: "cvs_milk_1068", storeID: "cvs", name: "Whole Milk", brand: "CVS Gold Emblem", category: "dairy_eggs", size: "1 gal", price: 4.69, unitPrice: "$0.04 / fl oz"),
        product(id: "cvs_cheese_1069", storeID: "cvs", name: "String Cheese", brand: "Frigo", category: "dairy_eggs", size: "12 ct", price: 5.49, unitPrice: "$0.46 each"),
        product(id: "cvs_icecream_1070", storeID: "cvs", name: "Cookie Dough Ice Cream", brand: "Ben & Jerry's", category: "frozen", size: "1 pt", price: 5.99, unitPrice: "$0.37 / fl oz"),
        product(id: "cvs_burrito_1071", storeID: "cvs", name: "Bean & Cheese Burrito", brand: "El Monterey", category: "frozen", size: "5 ct", price: 4.99, unitPrice: "$1.00 each"),
        product(id: "cvs_paper_1072", storeID: "cvs", name: "Paper Towels", brand: "Bounty", category: "household", size: "4 ct", price: 11.49, unitPrice: "$2.87 each"),
        product(id: "cvs_soap_1073", storeID: "cvs", name: "Liquid Hand Soap", brand: "Softsoap", category: "household", size: "7.5 fl oz", price: 2.99, unitPrice: "$0.40 / fl oz"),
        product(id: "cvs_trash_1074", storeID: "cvs", name: "Tall Kitchen Bags", brand: "Glad", category: "household", size: "45 ct", price: 9.99, unitPrice: "$0.22 each"),
        product(id: "cvs_sunscreen_1075", storeID: "cvs", name: "Sport Sunscreen SPF 50", brand: "Coppertone", category: "retail", size: "5.5 oz", price: 10.99, unitPrice: "$2.00 / oz"),
        product(id: "cvs_vitamins_1076", storeID: "cvs", name: "Daily Multivitamin", brand: "Nature Made", category: "retail", size: "130 ct", price: 12.99, unitPrice: "$0.10 each"),
        product(id: "cvs_toothpaste_1077", storeID: "cvs", name: "Whitening Toothpaste", brand: "Crest", category: "retail", size: "3.8 oz", price: 5.49, unitPrice: "$1.45 / oz"),

        // MARK: – Petco (expanded pet)
        product(id: "petco_dog_food_1080", storeID: "petco", name: "Adult Dry Dog Food", brand: "Blue Buffalo", category: "pet", size: "30 lb", price: 54.99, unitPrice: "$1.83 / lb"),
        product(id: "petco_dog_treats_1081", storeID: "petco", name: "Dental Dog Treats", brand: "Greenies", category: "pet", size: "36 ct", price: 29.99, unitPrice: "$0.83 each"),
        product(id: "petco_cat_food_1082", storeID: "petco", name: "Indoor Cat Dry Food", brand: "Blue Buffalo", category: "pet", size: "15 lb", price: 39.99, unitPrice: "$2.67 / lb"),
        product(id: "petco_cat_treats_1083", storeID: "petco", name: "Crunchy Cat Treats", brand: "Temptations", category: "pet", size: "16 oz", price: 7.99, unitPrice: "$0.50 / oz"),
        product(id: "petco_wet_dog_1084", storeID: "petco", name: "Wet Dog Food Variety Pack", brand: "Purina ONE", category: "pet", size: "12 ct", price: 18.99, unitPrice: "$1.58 each"),
        product(id: "petco_wet_cat_1085", storeID: "petco", name: "Wet Cat Food Variety Pack", brand: "Fancy Feast", category: "pet", size: "24 ct", price: 19.99, unitPrice: "$0.83 each"),
        product(id: "petco_litter_1086", storeID: "petco", name: "Clumping Cat Litter", brand: "Arm & Hammer", category: "pet", size: "40 lb", price: 17.99, unitPrice: "$0.45 / lb"),
        product(id: "petco_puppy_1087", storeID: "petco", name: "Puppy Dry Food", brand: "Hill's Science Diet", category: "pet", size: "15.5 lb", price: 44.99, unitPrice: "$2.90 / lb"),
        product(id: "petco_toy_1088", storeID: "petco", name: "Squeaky Plush Dog Toy", brand: "KONG", category: "pet", size: "1 ct", price: 9.99, unitPrice: "$9.99 each"),
        product(id: "petco_leash_1089", storeID: "petco", name: "Nylon Dog Leash", brand: "Petco", category: "pet", size: "6 ft", price: 12.99, unitPrice: "$12.99 each"),
        product(id: "petco_bed_1090", storeID: "petco", name: "Orthopedic Dog Bed", brand: "EveryYay", category: "pet", size: "36 in", price: 49.99, unitPrice: "$49.99 each"),
        product(id: "petco_fish_1091", storeID: "petco", name: "Tropical Fish Flakes", brand: "TetraMin", category: "pet", size: "7.06 oz", price: 12.49, unitPrice: "$1.77 / oz"),
        product(id: "petco_bird_1092", storeID: "petco", name: "Parakeet Seed Mix", brand: "Kaytee", category: "pet", size: "5 lb", price: 10.99, unitPrice: "$2.20 / lb"),

        // MARK: – Dollar Tree (expanded)
        product(id: "dt_water_1100", storeID: "dollar_tree", name: "Purified Water", brand: "Crystal Clear", category: "beverages", size: "16.9 fl oz 6-pk", price: 1.25, unitPrice: "$0.21 each"),
        product(id: "dt_soda_1101", storeID: "dollar_tree", name: "Cola", brand: "Great Value", category: "beverages", size: "2 L", price: 1.25, unitPrice: "$0.02 / fl oz"),
        product(id: "dt_juice_1102", storeID: "dollar_tree", name: "Apple Juice", brand: "Tree Top", category: "beverages", size: "15.2 fl oz", price: 1.25, unitPrice: "$0.08 / fl oz"),
        product(id: "dt_chips_1103", storeID: "dollar_tree", name: "Potato Chips", brand: "Clancy's", category: "pantry", size: "5 oz", price: 1.25, unitPrice: "$0.25 / oz"),
        product(id: "dt_cookies_1104", storeID: "dollar_tree", name: "Chocolate Chip Cookies", brand: "Lil' Dutch Maid", category: "pantry", size: "10 oz", price: 1.25, unitPrice: "$0.13 / oz"),
        product(id: "dt_pasta_1105", storeID: "dollar_tree", name: "Elbow Macaroni", brand: "Dakota Growers", category: "pantry", size: "16 oz", price: 1.25, unitPrice: "$0.08 / oz"),
        product(id: "dt_sauce_1106", storeID: "dollar_tree", name: "Tomato Sauce", brand: "Hunt's", category: "pantry", size: "8 oz", price: 1.25, unitPrice: "$0.16 / oz"),
        product(id: "dt_beans_1107", storeID: "dollar_tree", name: "Pinto Beans", brand: "Bush's", category: "pantry", size: "15 oz", price: 1.25, unitPrice: "$0.08 / oz"),
        product(id: "dt_soap_1108", storeID: "dollar_tree", name: "Dish Soap", brand: "LA's Totally Awesome", category: "household", size: "20 fl oz", price: 1.25, unitPrice: "$0.06 / fl oz"),
        product(id: "dt_trash_1109", storeID: "dollar_tree", name: "Tall Kitchen Bags", brand: "True Living", category: "household", size: "10 ct", price: 1.25, unitPrice: "$0.13 each"),
        product(id: "dt_cleaner_1110", storeID: "dollar_tree", name: "All-Purpose Cleaner", brand: "LA's Totally Awesome", category: "household", size: "20 fl oz", price: 1.25, unitPrice: "$0.06 / fl oz"),
        product(id: "dt_sponge_1111", storeID: "dollar_tree", name: "Scrub Sponges", brand: "True Living", category: "household", size: "3 ct", price: 1.25, unitPrice: "$0.42 each"),

        // MARK: – Family Dollar (expanded)
        product(id: "fd_water_1120", storeID: "family_dollar", name: "Spring Water", brand: "Deer Park", category: "beverages", size: "24 ct", price: 4.50, unitPrice: "$0.19 each"),
        product(id: "fd_soda_1121", storeID: "family_dollar", name: "Mountain Dew", brand: "PepsiCo", category: "beverages", size: "12 ct", price: 5.50, unitPrice: "$0.46 each"),
        product(id: "fd_juice_1122", storeID: "family_dollar", name: "Grape Juice", brand: "Welch's", category: "beverages", size: "64 fl oz", price: 3.75, unitPrice: "$0.06 / fl oz"),
        product(id: "fd_milk_1123", storeID: "family_dollar", name: "2% Milk", brand: "Family Dollar", category: "dairy_eggs", size: "1 gal", price: 3.99, unitPrice: "$0.03 / fl oz"),
        product(id: "fd_eggs_1124", storeID: "family_dollar", name: "Large Eggs", brand: "Family Dollar", category: "dairy_eggs", size: "12 ct", price: 3.49, unitPrice: "$0.29 each"),
        product(id: "fd_bread_1125", storeID: "family_dollar", name: "White Bread", brand: "Sunbeam", category: "bakery", size: "20 oz", price: 2.25, unitPrice: "$0.11 / oz"),
        product(id: "fd_cereal_1126", storeID: "family_dollar", name: "Fruity Os Cereal", brand: "Malt-O-Meal", category: "pantry", size: "12.5 oz", price: 2.75, unitPrice: "$0.22 / oz"),
        product(id: "fd_ramen_1127", storeID: "family_dollar", name: "Instant Ramen Variety Pack", brand: "Maruchan", category: "pantry", size: "12 ct", price: 3.00, unitPrice: "$0.25 each"),
        product(id: "fd_rice_1128", storeID: "family_dollar", name: "Long Grain Rice", brand: "Riceland", category: "pantry", size: "5 lb", price: 3.50, unitPrice: "$0.70 / lb", tags: ["Gluten-Free", "Vegan"]),
        product(id: "fd_pbutter_1129", storeID: "family_dollar", name: "Creamy Peanut Butter", brand: "Peter Pan", category: "pantry", size: "16.3 oz", price: 2.75, unitPrice: "$0.17 / oz"),
        product(id: "fd_detergent_1130", storeID: "family_dollar", name: "Laundry Detergent", brand: "Gain", category: "household", size: "50 fl oz", price: 5.50, unitPrice: "$0.11 / fl oz"),
        product(id: "fd_bleach_1131", storeID: "family_dollar", name: "Disinfecting Bleach", brand: "Clorox", category: "household", size: "43 fl oz", price: 3.75, unitPrice: "$0.09 / fl oz"),
        product(id: "fd_paper_1132", storeID: "family_dollar", name: "Paper Towels", brand: "Sparkle", category: "household", size: "4 ct", price: 4.50, unitPrice: "$1.13 each"),
        product(id: "fd_batteries_1133", storeID: "family_dollar", name: "AA Batteries", brand: "Energizer", category: "retail", size: "8 ct", price: 6.50, unitPrice: "$0.81 each"),

        // MARK: – Market District (expanded)
        product(id: "md_rotisserie_1140", storeID: "market_district", name: "Rotisserie Chicken", brand: "Market District", category: "prepared", size: "32 oz", price: 9.99, unitPrice: "$0.31 / oz"),
        product(id: "md_sushi_1141", storeID: "market_district", name: "Sushi Combo Platter", brand: "Market District", category: "prepared", size: "12 pc", price: 12.99, unitPrice: "$1.08 each"),
        product(id: "md_mac_cheese_1142", storeID: "market_district", name: "Mac & Cheese", brand: "Market District", category: "prepared", size: "16 oz", price: 7.99, unitPrice: "$0.50 / oz"),
        product(id: "md_steak_1143", storeID: "market_district", name: "USDA Choice NY Strip Steak", brand: "Market District", category: "meat_seafood", size: "12 oz", price: 14.99, unitPrice: "$1.25 / oz"),
        product(id: "md_ground_turkey_1144", storeID: "market_district", name: "93/7 Ground Turkey", brand: "Market District", category: "meat_seafood", size: "1 lb", price: 5.99, unitPrice: "$5.99 / lb"),
        product(id: "md_shrimp_1145", storeID: "market_district", name: "Wild-Caught Jumbo Shrimp", brand: "Market District", category: "meat_seafood", size: "1 lb", price: 12.99, unitPrice: "$12.99 / lb"),
        product(id: "md_brie_1146", storeID: "market_district", name: "Double Cream Brie", brand: "President", category: "dairy_eggs", size: "8 oz", price: 6.99, unitPrice: "$0.87 / oz"),
        product(id: "md_goat_cheese_1147", storeID: "market_district", name: "Goat Cheese Log", brand: "Montchevre", category: "dairy_eggs", size: "4 oz", price: 4.99, unitPrice: "$1.25 / oz"),
        product(id: "md_kale_1148", storeID: "market_district", name: "Organic Tuscan Kale", brand: "Market District", category: "produce", size: "1 bunch", price: 2.99, unitPrice: "$2.99 each", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "md_mushroom_1149", storeID: "market_district", name: "Baby Bella Mushrooms", brand: "Market District", category: "produce", size: "8 oz", price: 3.49, unitPrice: "$0.44 / oz"),
        product(id: "md_sourdough_1150", storeID: "market_district", name: "Artisan Sourdough Boule", brand: "Market District", category: "bakery", size: "24 oz", price: 5.99, unitPrice: "$0.25 / oz"),
        product(id: "md_croissant_1151", storeID: "market_district", name: "Butter Croissants", brand: "Market District", category: "bakery", size: "4 ct", price: 4.99, unitPrice: "$1.25 each"),
        product(id: "md_gelato_1152", storeID: "market_district", name: "Pistachio Gelato", brand: "Talenti", category: "frozen", size: "1 pt", price: 5.49, unitPrice: "$0.34 / fl oz"),
        product(id: "md_olive_oil_1153", storeID: "market_district", name: "Extra Virgin Olive Oil", brand: "Colavita", category: "pantry", size: "17 fl oz", price: 8.99, unitPrice: "$0.53 / fl oz"),
        product(id: "md_kombucha_1154", storeID: "market_district", name: "Ginger Kombucha", brand: "GT's", category: "beverages", size: "16 fl oz", price: 3.99, unitPrice: "$0.25 / fl oz", tags: ["Gluten-Free", "Vegan"]),

        // MARK: – Panera (expanded)
        product(id: "panera_mac_1160", storeID: "panera", name: "Mac & Cheese", brand: "Panera", category: "prepared", size: "16 oz", price: 9.99, unitPrice: "$0.62 / oz"),
        product(id: "panera_broccoli_soup_1161", storeID: "panera", name: "Broccoli Cheddar Soup", brand: "Panera", category: "prepared", size: "16 oz", price: 8.99, unitPrice: "$0.56 / oz"),
        product(id: "panera_chicken_salad_1162", storeID: "panera", name: "Chicken Caesar Salad", brand: "Panera", category: "prepared", size: "12 oz", price: 10.49, unitPrice: "$0.87 / oz"),
        product(id: "panera_turkey_sand_1163", storeID: "panera", name: "Turkey Avocado BLT", brand: "Panera", category: "prepared", size: "1 ct", price: 11.99, unitPrice: "$11.99 each"),
        product(id: "panera_tomato_soup_1164", storeID: "panera", name: "Creamy Tomato Soup", brand: "Panera", category: "prepared", size: "16 oz", price: 7.99, unitPrice: "$0.50 / oz"),
        product(id: "panera_lemonade_1165", storeID: "panera", name: "Strawberry Lemonade", brand: "Panera", category: "beverages", size: "20 fl oz", price: 3.49, unitPrice: "$0.17 / fl oz"),
        product(id: "panera_coffee_1166", storeID: "panera", name: "Dark Roast Coffee", brand: "Panera", category: "beverages", size: "12 fl oz", price: 2.99, unitPrice: "$0.25 / fl oz"),
        product(id: "panera_smoothie_1167", storeID: "panera", name: "Green Passion Smoothie", brand: "Panera", category: "beverages", size: "16 fl oz", price: 6.49, unitPrice: "$0.41 / fl oz"),
        product(id: "panera_bagel_1168", storeID: "panera", name: "Everything Bagels", brand: "Panera", category: "bakery", size: "6 ct", price: 8.99, unitPrice: "$1.50 each"),
        product(id: "panera_cookie_1169", storeID: "panera", name: "Chocolate Chip Cookie", brand: "Panera", category: "bakery", size: "4 ct", price: 7.49, unitPrice: "$1.87 each"),

        // MARK: – Chipotle (expanded)
        product(id: "chip_burrito_1170", storeID: "chipotle", name: "Chicken Burrito Bowl", brand: "Chipotle", category: "prepared", size: "1 ct", price: 11.75, unitPrice: "$11.75 each"),
        product(id: "chip_tacos_1171", storeID: "chipotle", name: "Steak Tacos", brand: "Chipotle", category: "prepared", size: "3 ct", price: 13.50, unitPrice: "$4.50 each"),
        product(id: "chip_quesadilla_1172", storeID: "chipotle", name: "Cheese Quesadilla", brand: "Chipotle", category: "prepared", size: "1 ct", price: 9.25, unitPrice: "$9.25 each"),
        product(id: "chip_salad_1173", storeID: "chipotle", name: "Barbacoa Salad Bowl", brand: "Chipotle", category: "prepared", size: "1 ct", price: 12.50, unitPrice: "$12.50 each"),
        product(id: "chip_guac_1174", storeID: "chipotle", name: "Large Guacamole & Chips", brand: "Chipotle", category: "prepared", size: "8 oz", price: 6.50, unitPrice: "$0.81 / oz"),
        product(id: "chip_queso_1175", storeID: "chipotle", name: "Queso Blanco & Chips", brand: "Chipotle", category: "prepared", size: "8 oz", price: 5.95, unitPrice: "$0.74 / oz"),
        product(id: "chip_drink_1176", storeID: "chipotle", name: "Mexican Coca-Cola", brand: "Coca-Cola", category: "beverages", size: "12 fl oz", price: 2.95, unitPrice: "$0.25 / fl oz"),
        product(id: "chip_lemonade_1177", storeID: "chipotle", name: "Organic Lemonade", brand: "Chipotle", category: "beverages", size: "16 fl oz", price: 3.25, unitPrice: "$0.20 / fl oz"),

        // MARK: – Lowe's (expanded retail)
        product(id: "lowes_paint_1180", storeID: "lowes", name: "Interior Flat Paint", brand: "Valspar", category: "retail", size: "1 gal", price: 32.98, unitPrice: "$0.26 / fl oz"),
        product(id: "lowes_lightbulb_1181", storeID: "lowes", name: "LED Light Bulbs", brand: "GE", category: "retail", size: "4 ct", price: 8.98, unitPrice: "$2.25 each"),
        product(id: "lowes_tape_1182", storeID: "lowes", name: "Painter's Tape", brand: "FrogTape", category: "retail", size: "1.41 in x 60 yd", price: 7.98, unitPrice: "$7.98 each"),
        product(id: "lowes_mulch_1183", storeID: "lowes", name: "Premium Hardwood Mulch", brand: "Scotts", category: "retail", size: "2 cu ft", price: 4.48, unitPrice: "$2.24 / cu ft"),
        product(id: "lowes_soil_1184", storeID: "lowes", name: "Potting Mix", brand: "Miracle-Gro", category: "retail", size: "1 cu ft", price: 7.48, unitPrice: "$7.48 each"),
        product(id: "lowes_drill_1185", storeID: "lowes", name: "20V Cordless Drill", brand: "DEWALT", category: "retail", size: "1 ct", price: 99.00, unitPrice: "$99.00 each"),
        product(id: "lowes_nails_1186", storeID: "lowes", name: "Finishing Nails", brand: "Grip-Rite", category: "retail", size: "1 lb", price: 5.98, unitPrice: "$5.98 / lb"),
        product(id: "lowes_hose_1187", storeID: "lowes", name: "Garden Hose", brand: "Flexzilla", category: "retail", size: "50 ft", price: 34.98, unitPrice: "$0.70 / ft"),
        product(id: "lowes_gloves_1188", storeID: "lowes", name: "Work Gloves", brand: "Mechanix Wear", category: "retail", size: "1 pair", price: 14.98, unitPrice: "$14.98 each"),
        product(id: "lowes_duct_tape_1189", storeID: "lowes", name: "Duct Tape", brand: "Gorilla", category: "retail", size: "35 yd", price: 8.98, unitPrice: "$0.26 / yd"),

        // MARK: – Michaels (expanded retail)
        product(id: "mich_paint_1190", storeID: "michaels", name: "Acrylic Paint Set", brand: "Artist's Loft", category: "retail", size: "24 ct", price: 12.99, unitPrice: "$0.54 each"),
        product(id: "mich_canvas_1191", storeID: "michaels", name: "Stretched Canvas", brand: "Artist's Loft", category: "retail", size: "16x20 in", price: 9.99, unitPrice: "$9.99 each"),
        product(id: "mich_brushes_1192", storeID: "michaels", name: "Paint Brush Set", brand: "Artist's Loft", category: "retail", size: "10 ct", price: 7.99, unitPrice: "$0.80 each"),
        product(id: "mich_yarn_1193", storeID: "michaels", name: "Soft Classic Yarn", brand: "Loops & Threads", category: "retail", size: "7 oz", price: 4.99, unitPrice: "$0.71 / oz"),
        product(id: "mich_glue_1194", storeID: "michaels", name: "Hot Glue Sticks", brand: "Ashland", category: "retail", size: "30 ct", price: 6.99, unitPrice: "$0.23 each"),
        product(id: "mich_markers_1195", storeID: "michaels", name: "Dual Tip Markers", brand: "Copic", category: "retail", size: "12 ct", price: 69.99, unitPrice: "$5.83 each"),
        product(id: "mich_beads_1196", storeID: "michaels", name: "Glass Seed Beads", brand: "Bead Landing", category: "retail", size: "1 lb", price: 14.99, unitPrice: "$14.99 / lb"),
        product(id: "mich_paper_1197", storeID: "michaels", name: "Cardstock Paper Pack", brand: "Recollections", category: "retail", size: "100 ct", price: 11.99, unitPrice: "$0.12 each"),
        product(id: "mich_ribbon_1198", storeID: "michaels", name: "Satin Ribbon", brand: "Celebrate It", category: "retail", size: "6 yd", price: 3.99, unitPrice: "$0.67 / yd"),
        product(id: "mich_frame_1199", storeID: "michaels", name: "Gallery Wall Frame", brand: "Studio Décor", category: "retail", size: "8x10 in", price: 14.99, unitPrice: "$14.99 each"),

        // MARK: – Bakery gap fills (existing grocery stores)
        product(id: "costco_muffins_1200", storeID: "costco", name: "Blueberry Muffins", brand: "Kirkland Signature", category: "bakery", size: "6 ct", price: 8.99, unitPrice: "$1.50 each"),
        product(id: "costco_croissants_1201", storeID: "costco", name: "All-Butter Croissants", brand: "Kirkland Signature", category: "bakery", size: "12 ct", price: 6.99, unitPrice: "$0.58 each"),
        product(id: "costco_bagels_1202", storeID: "costco", name: "Everything Bagels", brand: "Kirkland Signature", category: "bakery", size: "12 ct", price: 7.49, unitPrice: "$0.62 each"),
        product(id: "walmart_donuts_1203", storeID: "walmart", name: "Glazed Donuts", brand: "Marketside", category: "bakery", size: "6 ct", price: 3.97, unitPrice: "$0.66 each"),
        product(id: "walmart_rolls_1204", storeID: "walmart", name: "Hawaiian Sweet Rolls", brand: "King's Hawaiian", category: "bakery", size: "12 ct", price: 4.48, unitPrice: "$0.37 each"),
        product(id: "aldi_bread_1205", storeID: "aldi", name: "Whole Wheat Bread", brand: "L'oven Fresh", category: "bakery", size: "20 oz", price: 1.45, unitPrice: "$0.07 / oz"),
        product(id: "aldi_ciabatta_1206", storeID: "aldi", name: "Ciabatta Rolls", brand: "L'oven Fresh", category: "bakery", size: "4 ct", price: 2.49, unitPrice: "$0.62 each"),
        product(id: "ge_cookies_1207", storeID: "giant_eagle", name: "Sugar Cookies", brand: "Giant Eagle", category: "bakery", size: "12 ct", price: 4.99, unitPrice: "$0.42 each"),
        product(id: "ge_rye_1208", storeID: "giant_eagle", name: "Marble Rye Bread", brand: "Giant Eagle", category: "bakery", size: "22 oz", price: 3.99, unitPrice: "$0.18 / oz"),
        product(id: "jewel_cake_1209", storeID: "jewel_osco", name: "Chocolate Layer Cake", brand: "Jewel-Osco", category: "bakery", size: "32 oz", price: 12.99, unitPrice: "$0.41 / oz"),
        product(id: "jewel_rolls_1210", storeID: "jewel_osco", name: "Ciabatta Dinner Rolls", brand: "Jewel-Osco", category: "bakery", size: "6 ct", price: 3.49, unitPrice: "$0.58 each"),
        product(id: "tj_sourdough_1211", storeID: "trader_joes", name: "Sourdough Bread", brand: "Trader Joe's", category: "bakery", size: "24 oz", price: 3.49, unitPrice: "$0.15 / oz"),
        product(id: "tj_crumpets_1212", storeID: "trader_joes", name: "English Crumpets", brand: "Trader Joe's", category: "bakery", size: "6 ct", price: 2.99, unitPrice: "$0.50 each"),
        product(id: "wf_baguette_1213", storeID: "whole_foods", name: "French Baguette", brand: "Natural Foods Market", category: "bakery", size: "16 oz", price: 3.49, unitPrice: "$0.22 / oz"),
        product(id: "wf_scones_1214", storeID: "whole_foods", name: "Blueberry Scones", brand: "Natural Foods Market", category: "bakery", size: "4 ct", price: 5.99, unitPrice: "$1.50 each"),
        product(id: "wf_birthday_cake_1219", storeID: "whole_foods", name: "Birthday Celebration Cake", brand: "Whole Foods Bakery", category: "bakery", size: "8 inch", price: 34.99, unitPrice: "$34.99 each"),
        product(id: "sprouts_tortillas_1215", storeID: "sprouts", name: "Flour Tortillas", brand: "Sprouts", category: "bakery", size: "10 ct", price: 2.99, unitPrice: "$0.30 each"),
        product(id: "sprouts_muffins_1216", storeID: "sprouts", name: "Morning Glory Muffins", brand: "Sprouts", category: "bakery", size: "4 ct", price: 5.49, unitPrice: "$1.37 each"),
        product(id: "sams_danish_1217", storeID: "sams_club", name: "Cheese Danish", brand: "Member's Mark", category: "bakery", size: "12 ct", price: 7.98, unitPrice: "$0.67 each"),
        product(id: "sams_cinnamon_1218", storeID: "sams_club", name: "Cinnamon Rolls", brand: "Member's Mark", category: "bakery", size: "12 ct", price: 6.98, unitPrice: "$0.58 each"),

        // ── Benchmark: added products for task coverage ──
        product(id: "wf_blueberries_421", storeID: "whole_foods", name: "Organic Blueberries", brand: "365 by Whole Foods", category: "produce", size: "6 oz", price: 4.99, unitPrice: "$0.83 / oz", tags: ["Organic", "Gluten-Free", "Vegan"], isOrganic: true),
        product(id: "tj_mandarins_510", storeID: "trader_joes", name: "Seedless Mandarin Oranges", brand: "Trader Joe's", category: "produce", size: "3 lb bag", price: 4.49, unitPrice: "$1.50 / lb", tags: ["Gluten-Free", "Vegan"])
    ]

    static var deliverySlots: [DeliverySlot] {
        buildSlots(mode: .delivery)
    }

    static var pickupSlots: [DeliverySlot] {
        buildSlots(mode: .pickup)
    }

    private static func buildSlots(mode: DeliveryMode) -> [DeliverySlot] {
        let cal = Calendar.current
        let now = Date()
        let hour = cal.component(.hour, from: now)
        let minute = cal.component(.minute, from: now)
        let tf = DateFormatter()
        tf.dateFormat = "h:mm a"

        var slots = [DeliverySlot]()
        let windowMin = mode == .delivery ? 35 : 45
        let fees: [Double] = [0, 1.99, 2.99, 0, 0, 1.99]

        // Today slots: next available windows starting ~1h from now
        let baseMinutes = hour * 60 + minute + 55
        for i in 0..<3 {
            let startMin = baseMinutes + i * 50
            guard startMin < 22 * 60 else { continue } // no slots past 10pm
            let endMin = startMin + windowMin
            let startDate = cal.date(bySettingHour: startMin / 60, minute: startMin % 60, second: 0, of: now)!
            let endDate = cal.date(bySettingHour: endMin / 60, minute: endMin % 60, second: 0, of: now)!
            let fee = fees[i]
            let isAvailable = startMin < 21 * 60
            slots.append(DeliverySlot(
                id: "today_\(startMin)",
                mode: mode,
                dayLabel: "Today",
                timeLabel: "\(tf.string(from: startDate)) - \(tf.string(from: endDate))",
                fee: fee,
                isAvailable: isAvailable
            ))
        }

        // Tomorrow slots
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        let tomorrowSlots: [(Int, Int, Double)] = [(9, 0, 0), (11, 0, 0), (14, 0, 1.99)]
        for (h, m, fee) in tomorrowSlots {
            let startDate = cal.date(bySettingHour: h, minute: m, second: 0, of: tomorrow)!
            let endDate = cal.date(byAdding: .minute, value: windowMin + 15, to: startDate)!
            slots.append(DeliverySlot(
                id: "tomorrow_\(h * 100 + m)",
                mode: mode,
                dayLabel: "Tomorrow",
                timeLabel: "\(tf.string(from: startDate)) - \(tf.string(from: endDate))",
                fee: fee,
                isAvailable: true
            ))
        }

        return slots
    }

    static let popularSearches: [String] = [
        "bananas",
        "eggs",
        "milk",
        "bread",
        "chicken breast",
        "avocado",
        "strawberries",
        "ground beef",
        "cheese",
        "yogurt",
        "coffee",
        "ice cream",
        "salmon",
        "paper towels",
        "bacon",
        "orange juice",
        "rice",
        "pasta",
        "butter",
        "cereal"
    ]

    static let promotions: [Promotion] = [
        Promotion(id: "promo_001", title: "$0 delivery fees on your next 3 orders", subtitle: "Svc fees apply. 3 orders in 14 days. Excl restaurants. Terms apply.", badgeText: "Limited time", callToAction: "Got it"),
        Promotion(id: "promo_002", title: "Add Costco membership", subtitle: "Unlock member-only warehouse savings and delivery access.", badgeText: "Costco", callToAction: "Join now"),
        Promotion(id: "promo_003", title: "Spend $10 to unlock delivery", subtitle: "Build a small cart fast with fruit, water, and pantry staples.", badgeText: "Savings", callToAction: "Shop now"),
        Promotion(id: "promo_004", title: "Get $10 off your first Whole Foods order", subtitle: "Min. $35 order. Use code WHOLEFIRST at checkout. Valid through 3/31.", badgeText: "New", callToAction: "Shop Whole Foods"),
        Promotion(id: "promo_005", title: "Buy 2, get 1 free on select frozen items", subtitle: "Costco frozen aisle favorites. Automatically applied at checkout.", badgeText: "BOGO", callToAction: "See items"),
        Promotion(id: "promo_006", title: "FreshCart+ members: 5% back on Trader Joe's", subtitle: "Earn credit on every TJ's order this month. No code needed.", badgeText: "Members", callToAction: "Learn more"),
        Promotion(id: "promo_007", title: "Spring cleaning essentials under $5", subtitle: "Household staples from Target, Dollar Tree, and more. While supplies last.", badgeText: "Spring", callToAction: "Browse deals")
    ]

    static let membershipStatus = MembershipStatus(
        tierName: "FreshCart+",
        savingsToDate: 247.83,
        nextBillingDate: date("2026-04-12T00:00:00Z"),
        benefits: ["$0 delivery on eligible orders over $35", "Lower service fees (reduced to 2%)", "Priority support with dedicated chat", "5% credit back on select stores", "Free priority delivery upgrades (2 per month)"]
    )

    static let userProfile = UserProfile(
        firstName: "Jordan",
        lastName: "Avery",
        emailAddress: "jordan.avery@email.com",
        phoneNumber: "(312) 847-2193",
        addresses: [
            Address(id: "home_001", label: "Home", streetLine1: "410 Brannan St", streetLine2: "Unit 12B, San Francisco, CA 94107", instructions: "Call box 12B — leave on the bench by the elevator if no answer"),
            Address(id: "work_002", label: "Work", streetLine1: "525 Market St", streetLine2: "Suite 900, San Francisco, CA 94105", instructions: "Check in with lobby security; they'll direct you to the freight elevator"),
            Address(id: "friend_003", label: "Mom's House", streetLine1: "2847 Diamond St", streetLine2: "San Francisco, CA 94131", instructions: "Leave on the covered porch bench to the left of the front door"),
            Address(id: "studio_004", label: "Gym", streetLine1: "1234 Folsom St", streetLine2: "Unit 4A, San Francisco, CA 94103", instructions: "Ring buzzer for 4A, or text me and I'll come down")
        ],
        paymentMethods: [
            PaymentMethod(id: "visa_6645", label: "Visa", detail: "•••• 6645", isDefault: true),
            PaymentMethod(id: "apple_pay_0001", label: "Apple Pay", detail: "Default wallet", isDefault: false),
            PaymentMethod(id: "visa_2095", label: "Mastercard", detail: "•••• 2095", isDefault: false)
        ],
        savedStoreIDs: ["costco", "aldi", "target", "petco", "panera", "cvs", "giant_eagle", "michaels", "walmart", "whole_foods", "trader_joes", "jewel_osco"],
        notificationsEnabled: true
    )

    static let catalogData = CatalogData(metadata: metadata, stores: stores, categories: categories, products: products)
    static let snapshotCatalogData = CatalogData(metadata: snapshotMetadata, stores: stores, categories: categories, products: products)

    static func initialState() -> FreshCartState {
        FreshCartState(
            selectedTab: .home,
            catalogSource: .seeded,
            selectedStoreID: "costco",
            deliveryMode: .delivery,
            selectedAddressID: "home_001",
            selectedPaymentMethodID: "visa_6645",
            selectedDeliverySlotID: "today_523",
            selectedPickupSlotID: "today_500",
            recentSearches: ["salmon", "paper towels", "storage bins", "dog food", "chicken bowl", "allergy relief", "craft paint", "avocado", "organic spinach", "chicken breast", "kombucha", "ice cream", "greek yogurt"],
            savedProductIDs: ["salmon_fresh_005", "grapes_001", "target_paper_towels_117", "chipotle_bowl_136", "cvs_allergy_218", "michaels_paint_230", "wf_avocado_402", "tj_mandarin_501", "walmart_chicken_303", "aldi_yogurt_113", "costco_shrimp_039", "sprouts_berries_801", "panera_soup_131", "jewel_chicken_701", "wf_kombucha_404", "tj_cauliflower_502"],
            cartItems: [
                CartItem(productID: "eggs_018", quantity: 2, substitutionPreference: SubstitutionPreference(type: .refundItem), note: "Check expiration date — want at least 2 weeks out", addedAt: date("2026-03-16T11:30:00Z")),
                CartItem(productID: "milk_020", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-16T11:31:00Z")),
                CartItem(productID: "rotisserie_033", quantity: 1, substitutionPreference: SubstitutionPreference(type: .doNotReplace), note: "Must have — skip if none available, no sub", addedAt: date("2026-03-16T11:32:00Z")),
                CartItem(productID: "spinach_025", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-16T11:33:00Z")),
                CartItem(productID: "blueberries_003", quantity: 2, substitutionPreference: SubstitutionPreference(type: .specificReplacement, replacementProductID: "raspberries_004"), note: "If no blueberries, get raspberries instead", addedAt: date("2026-03-16T11:34:00Z")),
                CartItem(productID: "croissants_023", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "Grab from the fresh bakery section if possible", addedAt: date("2026-03-16T11:35:00Z")),
                CartItem(productID: "costco_chicken_breast_040", quantity: 1, substitutionPreference: SubstitutionPreference(type: .specificReplacement, replacementProductID: "costco_pork_loin_038"), note: "Boneless only. If out, get pork loin.", addedAt: date("2026-03-16T11:36:00Z")),
                CartItem(productID: "costco_olive_oil_057", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-16T11:37:00Z")),
                CartItem(productID: "sparkling_water_027", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-16T11:38:00Z"))
            ],
            storeCarts: [
                "walmart": [
                    CartItem(productID: "walmart_bananas_304", quantity: 2, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "Green-ish ones, not too ripe", addedAt: date("2026-03-14T09:15:00Z")),
                    CartItem(productID: "walmart_chicken_303", quantity: 1, substitutionPreference: SubstitutionPreference(type: .specificReplacement, replacementProductID: "walmart_ground_turkey_311"), note: "If chicken is out, ground turkey works", addedAt: date("2026-03-14T09:16:00Z")),
                    CartItem(productID: "walmart_bread_302", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-14T09:17:00Z")),
                    CartItem(productID: "walmart_eggs_305", quantity: 1, substitutionPreference: SubstitutionPreference(type: .refundItem), note: "Great Value brand only", addedAt: date("2026-03-14T09:18:00Z")),
                    CartItem(productID: "walmart_cheese_325", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-14T09:19:00Z")),
                    CartItem(productID: "walmart_pasta_330", quantity: 2, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-14T09:20:00Z"))
                ],
                "trader_joes": [
                    CartItem(productID: "tj_mandarin_501", quantity: 2, substitutionPreference: SubstitutionPreference(type: .doNotReplace), note: "Must have — this is the whole reason for the order", addedAt: date("2026-03-15T16:40:00Z")),
                    CartItem(productID: "tj_cauliflower_502", quantity: 2, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T16:41:00Z")),
                    CartItem(productID: "tj_everything_503", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T16:42:00Z")),
                    CartItem(productID: "tj_cheese_517", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T16:43:00Z")),
                    CartItem(productID: "tj_peanut_508", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T16:44:00Z"))
                ],
                "whole_foods": [
                    CartItem(productID: "wf_salmon_401", quantity: 1, substitutionPreference: SubstitutionPreference(type: .specificReplacement, replacementProductID: "wf_chicken_409"), note: "Wild caught only — if unavailable, organic chicken breast", addedAt: date("2026-03-15T10:20:00Z")),
                    CartItem(productID: "wf_avocado_402", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "Ripe ones please, ready to eat today", addedAt: date("2026-03-15T10:21:00Z")),
                    CartItem(productID: "wf_kale_403", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T10:22:00Z")),
                    CartItem(productID: "wf_kombucha_404", quantity: 2, substitutionPreference: SubstitutionPreference(type: .doNotReplace), note: "Ginger lemon flavor only", addedAt: date("2026-03-15T10:23:00Z")),
                    CartItem(productID: "wf_eggs_418", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T10:24:00Z")),
                    CartItem(productID: "wf_almond_butter_423", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-15T10:25:00Z"))
                ],
                "sprouts": [
                    CartItem(productID: "sprouts_berries_801", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-13T14:10:00Z")),
                    CartItem(productID: "sprouts_chicken_803", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "Free range only", addedAt: date("2026-03-13T14:11:00Z")),
                    CartItem(productID: "sprouts_quinoa_804", quantity: 1, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-13T14:12:00Z")),
                    CartItem(productID: "sprouts_kombucha_806", quantity: 2, substitutionPreference: SubstitutionPreference(type: .bestMatch), note: "", addedAt: date("2026-03-13T14:13:00Z"))
                ]
            ],
            orders: seededOrders(),
            promotions: promotions,
            membershipStatus: membershipStatus,
            userProfile: userProfile,
            tipAmount: 5.00,
            contactlessHandoff: true,
            orderNotes: "Text when you arrive, I'll come down for cold items.",
            specialInstructions: "Call box 12B — leave on the bench by the elevator if no answer",
            priorityDelivery: false,
            promoCode: "",
            promoApplied: false,
            orderSequence: 2083,
            lastUpdated: date("2026-03-16T15:19:00Z"),
            seedVersion: 3
        )
    }

    private static var productMap: [String: Product] {
        Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
    }

    private static func seededOrders() -> [Order] {
        [
            // ── Active: currently being shopped at Costco ──
            order(
                id: "order_active_001",
                orderNumber: "COS-2077",
                storeID: "costco",
                itemTuples: [("grapes_001", 1, .bestMatch), ("water_019", 1, .bestMatch), ("madegood_009", 1, .bestMatch), ("costco_chicken_breast_040", 1, .specificReplacement), ("croissants_023", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .shopping,
                createdAt: date("2026-03-16T14:10:00Z"),
                updatedAt: date("2026-03-16T14:42:00Z"),
                notes: "Text if grapes look overripe. Prefer green and firm, not soft.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-16T14:10:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-16T14:18:00Z", "Jamie R. was assigned to shop your order."),
                    (.shopping, "2026-03-16T14:42:00Z", "Jamie R. started shopping your order.")
                ]
            ),
            // ── Active: out for delivery from Whole Foods ──
            order(
                id: "order_active_034",
                orderNumber: "WFM-2079",
                storeID: "whole_foods",
                itemTuples: [("wf_salmon_401", 1, .specificReplacement), ("wf_avocado_402", 1, .bestMatch), ("wf_spinach_417", 1, .bestMatch), ("wf_eggs_418", 1, .refundItem), ("wf_sourdough_407", 1, .bestMatch), ("wf_kombucha_404", 2, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .outForDelivery,
                createdAt: date("2026-03-16T11:05:00Z"),
                updatedAt: date("2026-03-16T13:18:00Z"),
                notes: "Wild caught salmon only. If unavailable, sub with organic chicken breast. Avocados should be ripe but not mushy.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-16T11:05:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-16T11:18:00Z", "Priya M. was assigned to shop your order."),
                    (.shopping, "2026-03-16T11:35:00Z", "Priya M. started shopping your order."),
                    (.outForDelivery, "2026-03-16T13:18:00Z", "Priya M. is on the way to you. Estimated arrival in 15 min.")
                ]
            ),
            // ── Active: shopper just assigned for Trader Joe's ──
            order(
                id: "order_active_035",
                orderNumber: "TJ-2080",
                storeID: "trader_joes",
                itemTuples: [("tj_mandarin_501", 3, .bestMatch), ("tj_cauliflower_502", 2, .bestMatch), ("tj_cheese_517", 1, .bestMatch), ("tj_ice_cream_524", 1, .doNotReplace), ("tj_eggs_516", 1, .refundItem), ("tj_bread_519", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "apple_pay_0001",
                status: .shopperAssigned,
                createdAt: date("2026-03-16T15:02:00Z"),
                updatedAt: date("2026-03-16T15:14:00Z"),
                notes: "Please double-bag the ice cream cones, they melt fast. Eggs: refund only, no substitutes.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-16T15:02:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-16T15:14:00Z", "Marcus T. was assigned to shop your order.")
                ]
            ),
            // ── Scheduled: Costco tomorrow morning ──
            order(
                id: "order_scheduled_002",
                orderNumber: "COS-2081",
                storeID: "costco",
                itemTuples: [("salmon_frozen_008", 1, .bestMatch), ("eggs_018", 2, .refundItem), ("costco_ribeye_036", 1, .specificReplacement), ("costco_olive_oil_057", 1, .bestMatch), ("costco_bacon_042", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "tomorrow_900",
                addressID: "home_001",
                paymentMethodID: "apple_pay_0001",
                status: .scheduled,
                createdAt: date("2026-03-15T19:20:00Z"),
                updatedAt: date("2026-03-15T19:20:00Z"),
                notes: "If ribeye is out, substitute with NY strip. Do NOT substitute eggs — refund only.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.scheduled, "2026-03-15T19:20:00Z", "Your order was scheduled for tomorrow morning.")
                ]
            ),
            order(
                id: "order_past_003",
                orderNumber: "COS-2069",
                storeID: "costco",
                itemTuples: [("salmon_fresh_005", 1, .specificReplacement), ("paper_towels_015", 1, .bestMatch), ("milk_020", 1, .bestMatch), ("costco_ground_beef_037", 1, .bestMatch), ("sparkling_water_027", 2, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-03-02T15:00:00Z"),
                updatedAt: date("2026-03-02T18:05:00Z"),
                notes: "Prefer wild-caught salmon. If Atlantic is out, sub with sockeye.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-02T15:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-02T15:24:00Z", "Jamie R. was assigned to shop your order."),
                    (.shopping, "2026-03-02T16:06:00Z", "Jamie R. started shopping your order."),
                    (.outForDelivery, "2026-03-02T17:32:00Z", "Jamie R. is on the way to you."),
                    (.delivered, "2026-03-02T18:05:00Z", "Your order was delivered by Jamie R.")
                ],
                rating: ShopperRating(stars: 5, comment: "Jamie picked perfect substitutions, salmon was incredibly fresh!", tipAdjustment: 2.00)
            ),
            order(
                id: "order_past_004",
                orderNumber: "ALD-2065",
                storeID: "aldi",
                itemTuples: [("bananas_102", 2, .bestMatch), ("eggs_105", 1, .bestMatch)],
                deliveryMode: .pickup,
                slotID: "today_500",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .pickedUp,
                createdAt: date("2026-02-28T15:10:00Z"),
                updatedAt: date("2026-02-28T17:05:00Z"),
                notes: "",
                instructions: "Pickup lane 2",
                eventTuples: [
                    (.placed, "2026-02-28T15:10:00Z", "Your order was placed."),
                    (.shopping, "2026-02-28T15:52:00Z", "Your order was being shopped."),
                    (.readyForPickup, "2026-02-28T16:42:00Z", "Your order was ready for pickup."),
                    (.pickedUp, "2026-02-28T17:05:00Z", "Your order was picked up.")
                ]
            ),
            order(
                id: "order_past_005",
                orderNumber: "TGT-2058",
                storeID: "target",
                itemTuples: [("cleaner_103", 1, .refundItem), ("storage_bins_106", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "work_002",
                paymentMethodID: "visa_6645",
                status: .canceled,
                createdAt: date("2026-02-26T17:10:00Z"),
                updatedAt: date("2026-02-26T17:32:00Z"),
                notes: "Please text before arriving at the office.",
                instructions: "Leave with front desk",
                eventTuples: [
                    (.placed, "2026-02-26T17:10:00Z", "Your order was placed."),
                    (.canceled, "2026-02-26T17:32:00Z", "Your order was canceled before shopping began.")
                ]
            ),
            order(
                id: "order_past_006",
                orderNumber: "PAN-2051",
                storeID: "panera",
                itemTuples: [("panera_soup_131", 1, .bestMatch), ("panera_sandwich_133", 1, .bestMatch), ("panera_tea_135", 1, .bestMatch), ("panera_cookie_138", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "work_002",
                paymentMethodID: "apple_pay_0001",
                status: .delivered,
                createdAt: date("2026-02-24T16:18:00Z"),
                updatedAt: date("2026-02-24T17:02:00Z"),
                notes: "Office lunch — please include extra napkins and utensils.",
                instructions: "Check in with lobby security; they'll direct you to the freight elevator",
                eventTuples: [
                    (.placed, "2026-02-24T16:18:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-24T16:26:00Z", "Carlos D. was assigned as your courier."),
                    (.shopping, "2026-02-24T16:40:00Z", "Your order is being prepared at Panera."),
                    (.outForDelivery, "2026-02-24T16:48:00Z", "Carlos D. picked up your order and is on the way."),
                    (.delivered, "2026-02-24T17:02:00Z", "Your order was delivered by Carlos D.")
                ],
                rating: ShopperRating(stars: 5, comment: "Super fast delivery, food was still warm!", tipAdjustment: 3.00)
            ),
            order(
                id: "order_past_007",
                orderNumber: "CVS-2048",
                storeID: "cvs",
                itemTuples: [("cvs_allergy_218", 1, .specificReplacement), ("cvs_tissues_216", 1, .bestMatch), ("cvs_handsoap_219", 1, .bestMatch), ("cvs_toothpaste_214", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "visa_2095",
                status: .delivered,
                createdAt: date("2026-02-21T18:10:00Z"),
                updatedAt: date("2026-02-21T19:04:00Z"),
                notes: "Need allergy meds tonight. If Zyrtec is out, sub with Claritin (generic OK too). Text me before substituting.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-21T18:10:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-21T18:19:00Z", "Sam K. was assigned to shop your order."),
                    (.shopping, "2026-02-21T18:31:00Z", "Sam K. started shopping your order."),
                    (.outForDelivery, "2026-02-21T18:50:00Z", "Sam K. is on the way to you."),
                    (.delivered, "2026-02-21T19:04:00Z", "Your order was delivered by Sam K.")
                ],
                rating: ShopperRating(stars: 4, comment: "Everything looked good, thanks!", tipAdjustment: nil)
            ),
            // ── Scheduled: Chipotle for tomorrow lunch ──
            order(
                id: "order_scheduled_008",
                orderNumber: "CHI-2082",
                storeID: "chipotle",
                itemTuples: [("chipotle_bowl_136", 2, .bestMatch), ("chipotle_chips_138", 1, .bestMatch), ("chipotle_queso_139", 1, .bestMatch), ("chipotle_sprite_143", 1, .bestMatch), ("chipotle_drink_140", 1, .bestMatch)],
                deliveryMode: .delivery,
                slotID: "tomorrow_900",
                addressID: "work_002",
                paymentMethodID: "apple_pay_0001",
                status: .scheduled,
                createdAt: date("2026-03-16T08:45:00Z"),
                updatedAt: date("2026-03-16T08:45:00Z"),
                notes: "Team lunch for 2 — extra napkins. One bowl with no sour cream, one with extra guac.",
                instructions: "Check in with lobby security; they'll direct you to the freight elevator",
                eventTuples: [
                    (.scheduled, "2026-03-16T08:45:00Z", "Your order was scheduled for tomorrow.")
                ]
            ),

            // ── Older past orders (Nov 2025 – Feb 2026) ──

            order(
                id: "order_past_009",
                orderNumber: "WFM-2040",
                storeID: "whole_foods",
                itemTuples: [
                    ("wf_salmon_401", 2, .specificReplacement),
                    ("wf_avocado_402", 1, .bestMatch),
                    ("wf_kale_403", 1, .bestMatch),
                    ("wf_kombucha_404", 2, .doNotReplace),
                    ("wf_granola_405", 1, .bestMatch),
                    ("wf_yogurt_406", 1, .bestMatch),
                    ("wf_sourdough_407", 1, .bestMatch),
                    ("wf_pasta_408", 2, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-02-15T10:30:00Z"),
                updatedAt: date("2026-02-15T12:48:00Z"),
                notes: "Please pick the freshest salmon available. If sockeye is out, try Atlantic. Ripe avocados only — no hard ones.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-15T10:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-15T10:45:00Z", "Priya M. was assigned to shop your order."),
                    (.shopping, "2026-02-15T11:10:00Z", "Priya M. started shopping your order."),
                    (.outForDelivery, "2026-02-15T12:15:00Z", "Priya M. is on the way to you."),
                    (.delivered, "2026-02-15T12:48:00Z", "Your order was delivered by Priya M.")
                ],
                rating: ShopperRating(stars: 5, comment: "Salmon was super fresh, great picks all around.", tipAdjustment: 3.00)
            ),
            order(
                id: "order_past_010",
                orderNumber: "TJ-2035",
                storeID: "trader_joes",
                itemTuples: [
                    ("tj_mandarin_501", 2, .bestMatch),
                    ("tj_cauliflower_502", 1, .bestMatch),
                    ("tj_everything_503", 1, .bestMatch),
                    ("tj_cookies_504", 1, .bestMatch),
                    ("tj_salad_506", 1, .bestMatch),
                    ("tj_ravioli_507", 2, .bestMatch),
                    ("tj_peanut_508", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-02-08T14:00:00Z"),
                updatedAt: date("2026-02-08T15:38:00Z"),
                notes: "",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-08T14:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-08T14:12:00Z", "Aisha L. was assigned to shop your order."),
                    (.shopping, "2026-02-08T14:30:00Z", "Aisha L. started shopping your order."),
                    (.outForDelivery, "2026-02-08T15:10:00Z", "Aisha L. is on the way to you."),
                    (.delivered, "2026-02-08T15:38:00Z", "Your order was delivered by Aisha L.")
                ],
                rating: ShopperRating(stars: 5, comment: "Perfect, everything in great shape.", tipAdjustment: nil)
            ),
            order(
                id: "order_past_011",
                orderNumber: "CVS-2030",
                storeID: "cvs",
                itemTuples: [
                    ("cvs_pain_relief_127", 1, .bestMatch),
                    ("cvs_toothpaste_214", 1, .bestMatch),
                    ("cvs_batteries_213", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_2095",
                status: .delivered,
                createdAt: date("2026-01-28T19:45:00Z"),
                updatedAt: date("2026-01-28T20:32:00Z"),
                notes: "Quick evening run for essentials.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-01-28T19:45:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-28T19:52:00Z", "Sam K. was assigned to shop your order."),
                    (.shopping, "2026-01-28T20:00:00Z", "Sam K. started shopping your order."),
                    (.outForDelivery, "2026-01-28T20:18:00Z", "Sam K. is on the way to you."),
                    (.delivered, "2026-01-28T20:32:00Z", "Your order was delivered by Sam K.")
                ]
            ),
            order(
                id: "order_past_012",
                orderNumber: "COS-2024",
                storeID: "costco",
                itemTuples: [
                    ("toilet_paper_014", 1, .bestMatch),
                    ("paper_towels_015", 1, .bestMatch),
                    ("laundry_017", 1, .bestMatch),
                    ("eggs_018", 2, .refundItem),
                    ("milk_020", 1, .bestMatch),
                    ("sparkling_water_027", 1, .bestMatch),
                    ("trash_bags_030", 1, .bestMatch),
                    ("rotisserie_033", 2, .bestMatch),
                    ("croissants_023", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-01-18T11:00:00Z"),
                updatedAt: date("2026-01-18T14:12:00Z"),
                notes: "Big restock. Ring the call box if heavy bags.",
                instructions: "Call box 12B",
                eventTuples: [
                    (.placed, "2026-01-18T11:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-18T11:22:00Z", "Derek W. was assigned to shop your order."),
                    (.shopping, "2026-01-18T12:05:00Z", "Derek W. started shopping your order."),
                    (.outForDelivery, "2026-01-18T13:30:00Z", "Derek W. is on the way to you."),
                    (.delivered, "2026-01-18T14:12:00Z", "Your order was delivered by Derek W.")
                ],
                rating: ShopperRating(stars: 4, comment: "Heavy order handled really well, thank you!", tipAdjustment: 2.00)
            ),
            order(
                id: "order_past_013",
                orderNumber: "ALD-2018",
                storeID: "aldi",
                itemTuples: [
                    ("bananas_102", 1, .bestMatch),
                    ("aldi_spinach_108", 1, .bestMatch),
                    ("aldi_bread_110", 1, .bestMatch),
                    ("aldi_pasta_111", 2, .bestMatch),
                    ("aldi_sauce_112", 1, .bestMatch),
                    ("aldi_yogurt_113", 1, .bestMatch),
                    ("aldi_cheese_118", 2, .bestMatch)
                ],
                deliveryMode: .pickup,
                slotID: "today_500",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .pickedUp,
                createdAt: date("2026-01-05T09:15:00Z"),
                updatedAt: date("2026-01-05T11:40:00Z"),
                notes: "",
                instructions: "Pickup lane 3",
                eventTuples: [
                    (.placed, "2026-01-05T09:15:00Z", "Your order was placed."),
                    (.shopping, "2026-01-05T09:50:00Z", "Your order was being shopped."),
                    (.readyForPickup, "2026-01-05T10:55:00Z", "Your order was ready for pickup."),
                    (.pickedUp, "2026-01-05T11:40:00Z", "Your order was picked up.")
                ]
            ),
            order(
                id: "order_past_014",
                orderNumber: "TGT-2012",
                storeID: "target",
                itemTuples: [
                    ("target_paper_towels_117", 1, .bestMatch),
                    ("target_laundry_118", 1, .bestMatch),
                    ("target_soap_119", 2, .bestMatch),
                    ("target_candle_121", 1, .bestMatch),
                    ("target_dish_soap_123", 1, .bestMatch),
                    ("target_sparkling_125", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-12-20T13:00:00Z"),
                updatedAt: date("2025-12-20T15:25:00Z"),
                notes: "Holiday restock — any substitutions are fine. Just no scented versions of the soap or cleaner.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-12-20T13:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-12-20T13:18:00Z", "Tanya B. was assigned to shop your order."),
                    (.shopping, "2025-12-20T13:45:00Z", "Tanya B. started shopping your order."),
                    (.outForDelivery, "2025-12-20T14:50:00Z", "Tanya B. is on the way to you."),
                    (.delivered, "2025-12-20T15:25:00Z", "Your order was delivered by Tanya B.")
                ],
                rating: ShopperRating(stars: 5, comment: "Great holiday shopping, everything was in stock!", tipAdjustment: 3.00)
            ),
            order(
                id: "order_past_015",
                orderNumber: "PAN-2006",
                storeID: "panera",
                itemTuples: [
                    ("panera_soup_131", 2, .bestMatch),
                    ("panera_mac_136", 1, .bestMatch),
                    ("panera_baguette_137", 1, .bestMatch),
                    ("panera_cookie_138", 2, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "work_002",
                paymentMethodID: "visa_2095",
                status: .delivered,
                createdAt: date("2025-12-04T11:30:00Z"),
                updatedAt: date("2025-12-04T12:18:00Z"),
                notes: "Team lunch order — feeding 4 people. Extra napkins and utensils appreciated.",
                instructions: "Check in with lobby security; they'll direct you to the freight elevator",
                eventTuples: [
                    (.placed, "2025-12-04T11:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-12-04T11:38:00Z", "Carlos D. was assigned as your courier."),
                    (.shopping, "2025-12-04T11:48:00Z", "Your order is being prepared at Panera."),
                    (.outForDelivery, "2025-12-04T12:02:00Z", "Carlos D. picked up your order and is on the way."),
                    (.delivered, "2025-12-04T12:18:00Z", "Your order was delivered by Carlos D.")
                ],
                rating: ShopperRating(stars: 5, comment: "Team was impressed! Everything arrived hot and well-packed.", tipAdjustment: 5.00)
            ),
            order(
                id: "order_past_016",
                orderNumber: "COS-2001",
                storeID: "costco",
                itemTuples: [
                    ("salmon_fresh_005", 1, .specificReplacement),
                    ("strawberries_002", 1, .bestMatch),
                    ("blueberries_003", 1, .bestMatch),
                    ("water_019", 1, .bestMatch),
                    ("yogurt_032", 1, .bestMatch),
                    ("coffee_031", 1, .bestMatch),
                    ("bagels_034", 1, .bestMatch),
                    ("tissues_035", 1, .bestMatch),
                    ("protein_shakes_028", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-11-15T10:00:00Z"),
                updatedAt: date("2025-11-15T13:05:00Z"),
                notes: "Prefer sockeye if Atlantic is unavailable.",
                instructions: "Call box 12B",
                eventTuples: [
                    (.placed, "2025-11-15T10:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-11-15T10:20:00Z", "Jamie R. was assigned to shop your order."),
                    (.shopping, "2025-11-15T10:55:00Z", "Jamie R. started shopping your order."),
                    (.outForDelivery, "2025-11-15T12:20:00Z", "Jamie R. is on the way to you."),
                    (.delivered, "2025-11-15T13:05:00Z", "Your order was delivered by Jamie R.")
                ],
                rating: ShopperRating(stars: 5, comment: "Great shopper, very careful with the produce.", tipAdjustment: nil)
            ),

            // ── Additional past orders (Nov 2025 – Mar 2026) ──

            order(
                id: "order_past_017",
                orderNumber: "WMT-2003",
                storeID: "walmart",
                itemTuples: [
                    ("walmart_milk_301", 1, .bestMatch),
                    ("walmart_bread_302", 1, .bestMatch),
                    ("walmart_bananas_304", 2, .bestMatch),
                    ("walmart_eggs_305", 1, .bestMatch),
                    ("walmart_rice_306", 1, .bestMatch),
                    ("walmart_cereal_308", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-11-22T11:15:00Z"),
                updatedAt: date("2025-11-22T13:40:00Z"),
                notes: "",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-11-22T11:15:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-11-22T11:30:00Z", "Tanya B. was assigned to shop your order."),
                    (.shopping, "2025-11-22T12:00:00Z", "Tanya B. started shopping your order."),
                    (.outForDelivery, "2025-11-22T13:05:00Z", "Tanya B. is on the way to you."),
                    (.delivered, "2025-11-22T13:40:00Z", "Your order was delivered by Tanya B.")
                ],
                rating: ShopperRating(stars: 4, comment: "Fast delivery, everything was correct.", tipAdjustment: nil)
            ),
            order(
                id: "order_past_018",
                orderNumber: "TJ-2004",
                storeID: "trader_joes",
                itemTuples: [
                    ("tj_mandarin_501", 2, .bestMatch),
                    ("tj_cauliflower_502", 1, .bestMatch),
                    ("tj_cookies_504", 1, .bestMatch),
                    ("tj_salad_506", 1, .bestMatch),
                    ("tj_peanut_508", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-11-30T14:30:00Z"),
                updatedAt: date("2025-11-30T16:10:00Z"),
                notes: "Usual TJ's haul. Double bag the mandarin chicken so it doesn't leak.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-11-30T14:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-11-30T14:42:00Z", "Marcus T. was assigned to shop your order."),
                    (.shopping, "2025-11-30T15:05:00Z", "Marcus T. started shopping your order."),
                    (.outForDelivery, "2025-11-30T15:42:00Z", "Marcus T. is on the way to you."),
                    (.delivered, "2025-11-30T16:10:00Z", "Your order was delivered by Marcus T.")
                ]
            ),
            order(
                id: "order_past_019",
                orderNumber: "COS-2007",
                storeID: "costco",
                itemTuples: [
                    ("grapes_001", 1, .bestMatch),
                    ("raspberries_004", 1, .bestMatch),
                    ("eggs_018", 2, .bestMatch),
                    ("milk_020", 1, .bestMatch),
                    ("sparkling_water_027", 1, .bestMatch),
                    ("croissants_023", 1, .bestMatch),
                    ("protein_shakes_028", 1, .bestMatch),
                    ("rotisserie_033", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-12-08T10:30:00Z"),
                updatedAt: date("2025-12-08T13:15:00Z"),
                notes: "Extra croissants if available (grab 2 packs). Also if they have the seasonal muffins, text me.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-12-08T10:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-12-08T10:48:00Z", "Derek W. was assigned to shop your order."),
                    (.shopping, "2025-12-08T11:20:00Z", "Derek W. started shopping your order."),
                    (.outForDelivery, "2025-12-08T12:35:00Z", "Derek W. is on the way to you."),
                    (.delivered, "2025-12-08T13:15:00Z", "Your order was delivered by Derek W.")
                ]
            ),
            order(
                id: "order_past_020",
                orderNumber: "WFM-2010",
                storeID: "whole_foods",
                itemTuples: [
                    ("wf_salmon_401", 1, .bestMatch),
                    ("wf_avocado_402", 1, .bestMatch),
                    ("wf_kale_403", 2, .bestMatch),
                    ("wf_kombucha_404", 2, .bestMatch),
                    ("wf_yogurt_406", 1, .bestMatch),
                    ("wf_sourdough_407", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-12-13T09:45:00Z"),
                updatedAt: date("2025-12-13T12:05:00Z"),
                notes: "Ripe avocados please — soft enough to eat today. Salmon: check sell-by date, want freshest cut.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-12-13T09:45:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-12-13T10:02:00Z", "Priya M. was assigned to shop your order."),
                    (.shopping, "2025-12-13T10:30:00Z", "Priya M. started shopping your order."),
                    (.outForDelivery, "2025-12-13T11:28:00Z", "Priya M. is on the way to you."),
                    (.delivered, "2025-12-13T12:05:00Z", "Your order was delivered by Priya M.")
                ]
            ),
            order(
                id: "order_past_021",
                orderNumber: "WMT-2014",
                storeID: "walmart",
                itemTuples: [
                    ("walmart_chicken_303", 1, .bestMatch),
                    ("walmart_bananas_304", 1, .bestMatch),
                    ("walmart_eggs_305", 1, .bestMatch),
                    ("walmart_water_307", 1, .bestMatch),
                    ("walmart_chips_310", 1, .bestMatch),
                    ("walmart_detergent_309", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2025-12-27T14:00:00Z"),
                updatedAt: date("2025-12-27T16:18:00Z"),
                notes: "Post-holiday restock. All substitutions OK.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2025-12-27T14:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2025-12-27T14:15:00Z", "Tanya B. was assigned to shop your order."),
                    (.shopping, "2025-12-27T14:40:00Z", "Tanya B. started shopping your order."),
                    (.outForDelivery, "2025-12-27T15:45:00Z", "Tanya B. is on the way to you."),
                    (.delivered, "2025-12-27T16:18:00Z", "Your order was delivered by Tanya B.")
                ],
                rating: ShopperRating(stars: 3, comment: "Bananas were too ripe and chicken was warm. Delivery took longer than expected.", tipAdjustment: -2.00)
            ),
            order(
                id: "order_past_022",
                orderNumber: "JWL-2016",
                storeID: "jewel_osco",
                itemTuples: [
                    ("jewel_chicken_701", 1, .bestMatch),
                    ("jewel_milk_702", 1, .bestMatch),
                    ("jewel_apples_703", 1, .bestMatch),
                    ("jewel_bread_704", 1, .bestMatch),
                    ("jewel_juice_708", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-01-02T12:00:00Z"),
                updatedAt: date("2026-01-02T14:10:00Z"),
                notes: "New Year's grocery run. The rotisserie chicken is a must — refund if unavailable.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-01-02T12:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-02T12:14:00Z", "Derek W. was assigned to shop your order."),
                    (.shopping, "2026-01-02T12:38:00Z", "Derek W. started shopping your order."),
                    (.outForDelivery, "2026-01-02T13:35:00Z", "Derek W. is on the way to you."),
                    (.delivered, "2026-01-02T14:10:00Z", "Your order was delivered by Derek W.")
                ]
            ),
            order(
                id: "order_past_023",
                orderNumber: "WFM-2020",
                storeID: "whole_foods",
                itemTuples: [
                    ("wf_salmon_401", 1, .specificReplacement),
                    ("wf_kale_403", 1, .bestMatch),
                    ("wf_granola_405", 1, .bestMatch),
                    ("wf_yogurt_406", 1, .bestMatch),
                    ("wf_pasta_408", 2, .bestMatch),
                    ("wf_sourdough_407", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-01-11T10:00:00Z"),
                updatedAt: date("2026-01-11T12:30:00Z"),
                notes: "Fresh salmon preferred — wild caught only, no farmed substitutions. Sourdough should feel firm, not stale.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-01-11T10:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-11T10:18:00Z", "Priya M. was assigned to shop your order."),
                    (.shopping, "2026-01-11T10:45:00Z", "Priya M. started shopping your order."),
                    (.outForDelivery, "2026-01-11T11:50:00Z", "Priya M. is on the way to you."),
                    (.delivered, "2026-01-11T12:30:00Z", "Your order was delivered by Priya M.")
                ]
            ),
            order(
                id: "order_past_024",
                orderNumber: "TJ-2022",
                storeID: "trader_joes",
                itemTuples: [
                    ("tj_mandarin_501", 1, .bestMatch),
                    ("tj_everything_503", 1, .bestMatch),
                    ("tj_ravioli_507", 2, .bestMatch),
                    ("tj_wine_505", 1, .doNotReplace),
                    ("tj_salad_506", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-01-14T17:30:00Z"),
                updatedAt: date("2026-01-14T19:15:00Z"),
                notes: "Wine: do NOT substitute, I want Charles Shaw specifically. Everything else is flexible.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-01-14T17:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-14T17:40:00Z", "Aisha L. was assigned to shop your order."),
                    (.shopping, "2026-01-14T18:00:00Z", "Aisha L. started shopping your order."),
                    (.outForDelivery, "2026-01-14T18:42:00Z", "Aisha L. is on the way to you."),
                    (.delivered, "2026-01-14T19:15:00Z", "Your order was delivered by Aisha L.")
                ]
            ),
            order(
                id: "order_past_025",
                orderNumber: "SPR-2026",
                storeID: "sprouts",
                itemTuples: [
                    ("sprouts_berries_801", 1, .bestMatch),
                    ("sprouts_almond_milk_802", 1, .bestMatch),
                    ("sprouts_chicken_803", 2, .bestMatch),
                    ("sprouts_quinoa_804", 1, .bestMatch),
                    ("sprouts_spinach_805", 1, .bestMatch),
                    ("sprouts_kombucha_806", 2, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-01-24T10:30:00Z"),
                updatedAt: date("2026-01-24T12:55:00Z"),
                notes: "Organic produce only please.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-01-24T10:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-01-24T10:45:00Z", "Rachel P. was assigned to shop your order."),
                    (.shopping, "2026-01-24T11:10:00Z", "Rachel P. started shopping your order."),
                    (.outForDelivery, "2026-01-24T12:15:00Z", "Rachel P. is on the way to you."),
                    (.delivered, "2026-01-24T12:55:00Z", "Your order was delivered by Rachel P.")
                ],
                rating: ShopperRating(stars: 5, comment: "All organic, exactly what I wanted. Will request this shopper again.", tipAdjustment: 4.00)
            ),
            order(
                id: "order_past_026",
                orderNumber: "COS-2032",
                storeID: "costco",
                itemTuples: [
                    ("toilet_paper_014", 1, .bestMatch),
                    ("laundry_017", 1, .bestMatch),
                    ("eggs_018", 2, .bestMatch),
                    ("milk_020", 1, .bestMatch),
                    ("water_019", 1, .bestMatch),
                    ("salmon_frozen_008", 1, .bestMatch),
                    ("nuggets_011", 1, .bestMatch),
                    ("trash_bags_030", 1, .bestMatch),
                    ("paper_plates_029", 1, .bestMatch),
                    ("yogurt_032", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_720",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-02-01T09:00:00Z"),
                updatedAt: date("2026-02-01T12:20:00Z"),
                notes: "Monthly big restock. Heavy bags — might need 2 trips. Ring call box 12B when you arrive.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-01T09:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-01T09:25:00Z", "Jamie R. was assigned to shop your order."),
                    (.shopping, "2026-02-01T10:00:00Z", "Jamie R. started shopping your order."),
                    (.outForDelivery, "2026-02-01T11:30:00Z", "Jamie R. is on the way to you."),
                    (.delivered, "2026-02-01T12:20:00Z", "Your order was delivered by Jamie R.")
                ],
                rating: ShopperRating(stars: 5, comment: "Jamie always handles the big Costco runs so well. Everything packed carefully.", tipAdjustment: 5.00)
            ),
            order(
                id: "order_past_027",
                orderNumber: "WAG-2034",
                storeID: "walgreens",
                itemTuples: [
                    ("wag_advil_601", 1, .bestMatch),
                    ("wag_vitamins_602", 1, .bestMatch),
                    ("wag_soap_605", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_2095",
                status: .delivered,
                createdAt: date("2026-02-05T18:30:00Z"),
                updatedAt: date("2026-02-05T19:22:00Z"),
                notes: "Quick pharmacy run for vitamins and soap. Any generic substitutes are fine.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-05T18:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-05T18:38:00Z", "Sam K. was assigned to shop your order."),
                    (.shopping, "2026-02-05T18:48:00Z", "Sam K. started shopping your order."),
                    (.outForDelivery, "2026-02-05T19:08:00Z", "Sam K. is on the way to you."),
                    (.delivered, "2026-02-05T19:22:00Z", "Your order was delivered by Sam K.")
                ]
            ),
            order(
                id: "order_past_028",
                orderNumber: "WMT-2037",
                storeID: "walmart",
                itemTuples: [
                    ("walmart_milk_301", 1, .bestMatch),
                    ("walmart_bread_302", 1, .bestMatch),
                    ("walmart_chicken_303", 1, .bestMatch),
                    ("walmart_eggs_305", 1, .refundItem),
                    ("walmart_water_307", 1, .bestMatch),
                    ("walmart_cereal_308", 1, .bestMatch),
                    ("walmart_chips_310", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-02-12T11:00:00Z"),
                updatedAt: date("2026-02-12T13:35:00Z"),
                notes: "Refund eggs if out of stock, do not substitute. Everything else is flexible — best match is fine.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-12T11:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-12T11:18:00Z", "Tanya B. was assigned to shop your order."),
                    (.shopping, "2026-02-12T11:45:00Z", "Tanya B. started shopping your order."),
                    (.outForDelivery, "2026-02-12T12:55:00Z", "Tanya B. is on the way to you."),
                    (.delivered, "2026-02-12T13:35:00Z", "Your order was delivered by Tanya B.")
                ]
            ),
            order(
                id: "order_past_029",
                orderNumber: "TJ-2042",
                storeID: "trader_joes",
                itemTuples: [
                    ("tj_mandarin_501", 1, .bestMatch),
                    ("tj_cauliflower_502", 2, .bestMatch),
                    ("tj_everything_503", 1, .bestMatch),
                    ("tj_ravioli_507", 1, .bestMatch),
                    ("tj_peanut_508", 1, .bestMatch),
                    ("tj_wine_505", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-02-18T16:00:00Z"),
                updatedAt: date("2026-02-18T17:48:00Z"),
                notes: "Weekly TJ's run. Get the big bag of cauliflower gnocchi if they have it.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-02-18T16:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-02-18T16:12:00Z", "Marcus T. was assigned to shop your order."),
                    (.shopping, "2026-02-18T16:35:00Z", "Marcus T. started shopping your order."),
                    (.outForDelivery, "2026-02-18T17:20:00Z", "Marcus T. is on the way to you."),
                    (.delivered, "2026-02-18T17:48:00Z", "Your order was delivered by Marcus T.")
                ]
            ),
            order(
                id: "order_past_030",
                orderNumber: "JWL-2050",
                storeID: "jewel_osco",
                itemTuples: [
                    ("jewel_chicken_701", 1, .bestMatch),
                    ("jewel_strawberries_707", 1, .bestMatch),
                    ("jewel_bread_704", 1, .bestMatch),
                    ("jewel_ice_cream_706", 1, .bestMatch)
                ],
                deliveryMode: .pickup,
                slotID: "today_500",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .pickedUp,
                createdAt: date("2026-02-22T15:00:00Z"),
                updatedAt: date("2026-02-22T17:15:00Z"),
                notes: "Quick dinner pickup.",
                instructions: "Pickup lane 1",
                eventTuples: [
                    (.placed, "2026-02-22T15:00:00Z", "Your order was placed."),
                    (.shopping, "2026-02-22T15:35:00Z", "Your order was being shopped."),
                    (.readyForPickup, "2026-02-22T16:30:00Z", "Your order was ready for pickup."),
                    (.pickedUp, "2026-02-22T17:15:00Z", "Your order was picked up.")
                ]
            ),
            order(
                id: "order_past_031",
                orderNumber: "WMT-2062",
                storeID: "walmart",
                itemTuples: [
                    ("walmart_milk_301", 1, .bestMatch),
                    ("walmart_bananas_304", 2, .bestMatch),
                    ("walmart_eggs_305", 1, .bestMatch),
                    ("walmart_rice_306", 1, .bestMatch),
                    ("walmart_water_307", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-03-04T11:30:00Z"),
                updatedAt: date("2026-03-04T13:50:00Z"),
                notes: "Basic weekly restock. Any brand substitutions are fine.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-04T11:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-04T11:42:00Z", "Tanya B. was assigned to shop your order."),
                    (.shopping, "2026-03-04T12:10:00Z", "Tanya B. started shopping your order."),
                    (.outForDelivery, "2026-03-04T13:15:00Z", "Tanya B. is on the way to you."),
                    (.delivered, "2026-03-04T13:50:00Z", "Your order was delivered by Tanya B.")
                ]
            ),
            order(
                id: "order_past_032",
                orderNumber: "WFM-2072",
                storeID: "whole_foods",
                itemTuples: [
                    ("wf_salmon_401", 1, .bestMatch),
                    ("wf_avocado_402", 1, .bestMatch),
                    ("wf_kale_403", 1, .bestMatch),
                    ("wf_kombucha_404", 2, .bestMatch),
                    ("wf_granola_405", 1, .bestMatch),
                    ("wf_yogurt_406", 1, .bestMatch),
                    ("wf_sourdough_407", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_610",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-03-07T10:00:00Z"),
                updatedAt: date("2026-03-07T12:25:00Z"),
                notes: "Weekend grocery haul. Salmon: freshest cut available. Kombucha: ginger lemon or mango, no other flavors.",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-07T10:00:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-07T10:15:00Z", "Priya M. was assigned to shop your order."),
                    (.shopping, "2026-03-07T10:40:00Z", "Priya M. started shopping your order."),
                    (.outForDelivery, "2026-03-07T11:48:00Z", "Priya M. is on the way to you."),
                    (.delivered, "2026-03-07T12:25:00Z", "Your order was delivered by Priya M.")
                ],
                rating: ShopperRating(stars: 5, comment: "Priya is my go-to for Whole Foods. Perfect salmon every time.", tipAdjustment: 4.00)
            ),
            order(
                id: "order_past_033",
                orderNumber: "TJ-2075",
                storeID: "trader_joes",
                itemTuples: [
                    ("tj_mandarin_501", 1, .bestMatch),
                    ("tj_cauliflower_502", 1, .bestMatch),
                    ("tj_cookies_504", 1, .bestMatch),
                    ("tj_ravioli_507", 2, .bestMatch),
                    ("tj_peanut_508", 1, .bestMatch)
                ],
                deliveryMode: .delivery,
                slotID: "today_523",
                addressID: "home_001",
                paymentMethodID: "visa_6645",
                status: .delivered,
                createdAt: date("2026-03-09T15:30:00Z"),
                updatedAt: date("2026-03-09T17:12:00Z"),
                notes: "Midweek TJ's run. Extra cauliflower gnocchi if they have it!",
                instructions: "Call box 12B — leave on the bench by the elevator if no answer",
                eventTuples: [
                    (.placed, "2026-03-09T15:30:00Z", "Your order was placed."),
                    (.shopperAssigned, "2026-03-09T15:42:00Z", "Aisha L. was assigned to shop your order."),
                    (.shopping, "2026-03-09T16:05:00Z", "Aisha L. started shopping your order."),
                    (.outForDelivery, "2026-03-09T16:42:00Z", "Aisha L. is on the way to you."),
                    (.delivered, "2026-03-09T17:12:00Z", "Your order was delivered by Aisha L.")
                ],
                rating: ShopperRating(stars: 5, comment: "Love TJ's runs, everything was perfect.", tipAdjustment: 2.00)
            )
        ]
    }

    private static func order(
        id: String,
        orderNumber: String,
        storeID: String,
        itemTuples: [(String, Int, SubstitutionPreferenceType)],
        deliveryMode: DeliveryMode,
        slotID: String,
        addressID: String,
        paymentMethodID: String,
        status: OrderStatus,
        createdAt: Date,
        updatedAt: Date,
        notes: String,
        instructions: String,
        eventTuples: [(OrderStatus, String, String)],
        rating: ShopperRating? = nil
    ) -> Order {
        let items = itemTuples.map { productID, quantity, preferenceType in
            orderItem(productID: productID, quantity: quantity, preferenceType: preferenceType)
        }
        let slot = (deliveryMode == .delivery ? deliverySlots : pickupSlots).first(where: { $0.id == slotID }) ?? (deliveryMode == .delivery ? deliverySlots[0] : pickupSlots[0])
        let subtotal = items.reduce(0) { $0 + ($1.price * Double($1.quantity)) }
        let pricingSummary = makePricingSummary(subtotal: subtotal, slotFee: slot.fee, mode: deliveryMode)
        let address = userProfile.addresses.first(where: { $0.id == addressID }) ?? userProfile.addresses[0]
        let payment = userProfile.paymentMethods.first(where: { $0.id == paymentMethodID }) ?? userProfile.paymentMethods[0]
        let statusEvents = eventTuples.map { eventStatus, timestamp, message in
            OrderStatusEvent(id: "\(id)_\(eventStatus.rawValue)", status: eventStatus, timestamp: date(timestamp), message: message)
        }

        return Order(
            id: id,
            orderNumber: orderNumber,
            storeID: storeID,
            items: items,
            deliveryMode: deliveryMode,
            deliverySlot: slot,
            address: address,
            paymentMethod: payment,
            orderStatus: status,
            statusEvents: statusEvents,
            pricingSummary: pricingSummary,
            orderNotes: notes,
            deliveryInstructions: instructions,
            createdAt: createdAt,
            updatedAt: updatedAt,
            shopperRating: rating
        )
    }

    private static func orderItem(productID: String, quantity: Int, preferenceType: SubstitutionPreferenceType) -> OrderItem {
        let product = productMap[productID] ?? products[0]
        let replacement = preferenceType == .specificReplacement ? "salmon_sockeye_006" : nil
        return OrderItem(
            id: "\(productID)_item",
            productID: product.id,
            productName: product.productName,
            brand: product.brand,
            packageSize: product.packageSize,
            unitPrice: product.unitPrice,
            quantity: quantity,
            price: product.price,
            substitutionPreference: SubstitutionPreference(type: preferenceType, replacementProductID: replacement)
        )
    }

    private static func makePricingSummary(subtotal: Double, slotFee: Double, mode: DeliveryMode) -> PricingSummary {
        let deliveryFee = mode == .delivery ? slotFee : 0
        let serviceFee = round(subtotal * 0.05 * 100) / 100
        let tax = round(subtotal * 0.0825 * 100) / 100
        let tip = mode == .delivery ? 5.00 : 0
        let total = subtotal + deliveryFee + serviceFee + tax + tip
        return PricingSummary(
            itemSubtotal: subtotal,
            deliveryFee: deliveryFee,
            priorityFee: 0,
            serviceFee: serviceFee,
            taxEstimate: tax,
            tip: tip,
            promoDiscount: 0,
            estimatedTotal: total
        )
    }

    private static func product(
        id: String,
        storeID: String,
        name: String,
        brand: String,
        category: String,
        size: String,
        price: Double,
        unitPrice: String,
        saleLabel: String? = nil,
        tags: [String] = [],
        isOrganic: Bool = false,
        inStock: Bool = true,
        recommended: Bool = false,
        buyAgain: Bool = false
    ) -> Product {
        Product(
            id: id,
            storeID: storeID,
            productName: name,
            brand: brand,
            categoryID: category,
            packageSize: size,
            price: price,
            unitPrice: unitPrice,
            inStock: inStock,
            saleLabel: saleLabel,
            dietaryTags: tags,
            isOrganic: isOrganic,
            description: makeDescription(name: name, brand: brand, size: size, tags: tags, isOrganic: isOrganic),
            isRecommended: recommended,
            isBuyAgain: buyAgain
        )
    }

    private static func makeDescription(name: String, brand: String, size: String, tags: [String], isOrganic: Bool) -> String {
        var parts = ["\(brand) \(name) in a \(size.lowercased()) pack."]
        if isOrganic {
            parts.append("Organic option.")
        }
        if tags.isEmpty == false {
            parts.append("Highlights: \(tags.joined(separator: ", ")).")
        }
        parts.append("Available for delivery and pickup.")
        return parts.joined(separator: " ")
    }

    private static func date(_ value: String) -> Date {
        formatter.date(from: value) ?? Date(timeIntervalSince1970: 0)
    }
}
