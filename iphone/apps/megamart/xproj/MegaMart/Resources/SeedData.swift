import Foundation

enum SeedData {
    static let simulationStartDate = date("2026-03-01T15:00:00Z")

    static let popularSearches = [
        "ps5",
        "airpods pro",
        "headphones",
        "air fryer",
        "running shoes",
        "stanley tumbler",
        "protein powder",
        "paper towels",
        "dog treats",
        "paperlite",
        "crocs",
        "kitchenaid mixer"
    ]

    static let deliveryOptions = [
        DeliveryOption(
            id: "standard_delivery",
            title: "Free Standard Delivery",
            detail: "Usually ships with free delivery on eligible orders.",
            estimatedArrival: "Arrives Tomorrow",
            additionalCost: 0
        ),
        DeliveryOption(
            id: "two_day_delivery",
            title: "Two-Day Delivery",
            detail: "Reliable expedited delivery for most addresses.",
            estimatedArrival: "Arrives in 2 days",
            additionalCost: 4.99
        ),
        DeliveryOption(
            id: "same_day_delivery",
            title: "Same-Day Delivery",
            detail: "Fast local delivery window for eligible addresses.",
            estimatedArrival: "Arrives Today by 9 PM",
            additionalCost: 9.99
        )
    ]

    static let defaultProfile = UserProfile(
        id: "default_profile",
        name: "Jordan Avery",
        email: "jordan.avery@email.com",
        membershipLabel: "Prime member",
        defaultDeliveryLocation: "Deliver to San Francisco 94107",
        profileNote: "Gaming, home upgrades, and everyday essentials."
    )

    static let defaultAddresses = [
        benchmarkHomeAddress(recipientName: defaultProfile.name),
        benchmarkOfficeAddress(recipientName: defaultProfile.name)
    ]

    static let defaultPaymentMethods = [
        PaymentMethod(
            id: "payment_visa_6645",
            label: "Visa ending in 6645",
            details: "Chase Debit • Exp. 09/28",
            isDefault: true
        ),
        PaymentMethod(
            id: "payment_visa_2095",
            label: "Visa ending in 2095",
            details: "Freedom Unlimited • Exp. 03/29",
            isDefault: false
        ),
        PaymentMethod(
            id: "payment_store_card",
            label: "Store Card ending in 5510",
            details: "Promotional financing available on select items",
            isDefault: false
        )
    ]

    static func benchmarkHomeAddress(recipientName: String) -> Address {
        Address(
            id: "address_home",
            label: "Home",
            recipientName: recipientName,
            line1: "410 Brannan Street",
            line2: "Unit 12B",
            city: "San Francisco",
            state: "CA",
            postalCode: "94107"
        )
    }

    static func benchmarkOfficeAddress(recipientName: String) -> Address {
        Address(
            id: "address_office",
            label: "Office",
            recipientName: recipientName,
            line1: "88 Spear Street",
            line2: "Floor 9",
            city: "San Francisco",
            state: "CA",
            postalCode: "94105"
        )
    }

    static func benchmarkCurrentLocationAddress(recipientName: String) -> Address {
        Address(
            id: "address_current_location",
            label: "Current Location",
            recipientName: recipientName,
            line1: "410 Brannan Street",
            line2: "Suite 320",
            city: "San Francisco",
            state: "CA",
            postalCode: "94107"
        )
    }

    static let departments = [
        Department(id: "electronics", name: "Electronics", systemImage: "headphones"),
        Department(id: "home_kitchen", name: "Home & Kitchen", systemImage: "house"),
        Department(id: "books", name: "Books", systemImage: "book.closed"),
        Department(id: "clothing", name: "Clothing", systemImage: "tshirt"),
        Department(id: "beauty", name: "Beauty", systemImage: "sparkles"),
        Department(id: "groceries", name: "Groceries", systemImage: "cart"),
        Department(id: "office", name: "Office", systemImage: "briefcase"),
        Department(id: "toys", name: "Toys", systemImage: "gift"),
        Department(id: "pet_supplies", name: "Pet Supplies", systemImage: "pawprint"),
        Department(id: "sports_outdoors", name: "Sports & Outdoors", systemImage: "figure.run")
    ]

    static let categories = [
        ProductCategory(id: "audio", departmentID: "electronics", name: "Audio", systemImage: "headphones"),
        ProductCategory(id: "computer_accessories", departmentID: "electronics", name: "Computer Accessories", systemImage: "keyboard"),
        ProductCategory(id: "gaming", departmentID: "electronics", name: "Gaming", systemImage: "gamecontroller"),
        ProductCategory(id: "kitchen_appliances", departmentID: "home_kitchen", name: "Kitchen Appliances", systemImage: "fork.knife"),
        ProductCategory(id: "home_cleaning", departmentID: "home_kitchen", name: "Home Cleaning", systemImage: "sparkles"),
        ProductCategory(id: "fiction_books", departmentID: "books", name: "Fiction & Literature", systemImage: "book"),
        ProductCategory(id: "learning_books", departmentID: "books", name: "Business & Learning", systemImage: "text.book.closed"),
        ProductCategory(id: "mens_fashion", departmentID: "clothing", name: "Men's Fashion", systemImage: "hanger"),
        ProductCategory(id: "womens_fashion", departmentID: "clothing", name: "Women's Fashion", systemImage: "bag"),
        ProductCategory(id: "skin_care", departmentID: "beauty", name: "Skin Care", systemImage: "drop"),
        ProductCategory(id: "hair_care", departmentID: "beauty", name: "Hair Care", systemImage: "wind"),
        ProductCategory(id: "pantry_staples", departmentID: "groceries", name: "Pantry Staples", systemImage: "shippingbox"),
        ProductCategory(id: "household_essentials", departmentID: "groceries", name: "Household Essentials", systemImage: "basket"),
        ProductCategory(id: "workspace", departmentID: "office", name: "Workspace", systemImage: "lamp.desk"),
        ProductCategory(id: "office_supplies", departmentID: "office", name: "Office Supplies", systemImage: "pencil"),
        ProductCategory(id: "stem_toys", departmentID: "toys", name: "STEM Toys", systemImage: "gearshape.2"),
        ProductCategory(id: "family_games", departmentID: "toys", name: "Family Games", systemImage: "dice"),
        ProductCategory(id: "dog_supplies", departmentID: "pet_supplies", name: "Dog Supplies", systemImage: "dog"),
        ProductCategory(id: "cat_supplies", departmentID: "pet_supplies", name: "Cat Supplies", systemImage: "cat"),
        ProductCategory(id: "fitness_gear", departmentID: "sports_outdoors", name: "Fitness Gear", systemImage: "figure.strengthtraining.traditional"),
        ProductCategory(id: "outdoor_gear", departmentID: "sports_outdoors", name: "Outdoor Gear", systemImage: "tent")
    ]

    static func seededCatalog() -> CatalogData {
        CatalogData(
            metadata: nil,
            departments: departments,
            categories: categories,
            products: seededProducts
        )
    }

    static func initialState(snapshotMetadata: CatalogSnapshotMetadata?) -> MegaMartSimState {
        let lookup = Dictionary(uniqueKeysWithValues: seededProducts.map { ($0.id, $0) })
        return MegaMartSimState(
            selectedTab: .home,
            catalogSource: .seeded,
            snapshotMetadata: snapshotMetadata,
            isAuthenticated: true,
            cartItems: seededCartItems(productLookup: lookup),
            savedItems: seededSavedItems(productLookup: lookup),
            orders: seededOrders(productLookup: lookup),
            recentSearches: [
                "ps5", "charging station", "usb c charger", "dog treats",
                "running shoes", "desk lamp", "protein powder", "paperlite paperwhite",
                "air purifier", "face moisturizer", "camping tent", "bluetooth speaker",
                "yoga mat", "coffee beans", "monitor stand"
            ],
            recentlyViewedProductIDs: [
                "airpods_pro_108",
                "ps5_digital_bundle_081",
                "stanley_tumbler_119",
                "noise_canceling_headphones_001",
                "stand_mixer_111",
                "trail_backpack_077",
                "crocs_classic_116",
                "kindle_paperwhite_109",
                "protein_powder_041",
                "running_shoes_025",
                "mechanical_keyboard_003",
                "vitamix_blender_139",
                "air_fryer_009",
                "desk_converter_052",
                "wireless_earbuds_088",
                "instant_pot_090",
                "camping_tent_107",
                "yoga_mat_073",
                "dumbbell_set_078",
                "face_moisturizer_033",
                "espresso_machine_012",
                "usb_c_charger_002",
                "electric_kettle_140",
                "cordless_vacuum_010",
                "apple_watch_se_136",
                "birkenstock_arizona_143",
                "everyday_hoodie_026",
                "water_bottle_074",
                "resistance_bands_075",
                "bose_soundlink_flex_137"
            ],
            userProfile: defaultProfile,
            addresses: defaultAddresses,
            paymentMethods: defaultPaymentMethods,
            selectedAddressID: defaultAddresses[0].id,
            selectedPaymentMethodID: defaultPaymentMethods[0].id,
            simulationDate: simulationStartDate,
            userReviews: seededUserReviews
        )
    }

    // MARK: - Seeded Products

    private static let seededProducts: [Product] = [

        // ── Electronics ─────────────────────────────────────────────

        product(
            id: "noise_canceling_headphones_001",
            name: "Sony WH-1000XM5 Wireless Noise Cancelling Headphones",
            brand: "Sony",
            departmentID: "electronics",
            categoryID: "audio",
            price: 229.99,
            originalPrice: 299.99,
            rating: 4.7,
            reviewCount: 18_432,
            deliveryEstimate: "FREE delivery Tomorrow, 7 AM - 11 AM",
            sellerName: "Sony Official",
            imageSystemName: "headphones",
            imageURL: "https://images.unsplash.com/photo-1618366712010-f4ae9c647dcb?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 1,
            searchKeywords: ["bluetooth headphones", "over ear", "travel", "sony"],
            specifications: specs("Battery", "40 hours", "Connectivity", "Bluetooth 5.3", "Weight", "254 g"),
            aboutItems: [
                "Industry-leading noise cancellation with Auto NC Optimizer for any environment.",
                "Crystal-clear hands-free calling with four beamforming microphones.",
                "Multipoint connection lets you switch between two Bluetooth devices seamlessly."
            ],
            variants: variants("noise_canceling_headphones_001", name: "Color", values: ["Black", "Silver", "Midnight Blue"], unavailable: ["Midnight Blue"]),
            promotions: [promotion(id: "coupon_headphones", title: "Coupon", detail: "Apply $20 coupon at checkout.", badgeText: "Coupon")]
        ),
        product(
            id: "usb_c_charger_002",
            name: "Anker 65W USB-C GaN Charger, Nano II",
            brand: "Anker",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 34.99,
            originalPrice: 44.99,
            rating: 4.6,
            reviewCount: 9_244,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "powerplug",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/4a/Silicon_vs_GaN_30W_USB-C_chargers.jpg",
            popularityRank: 6,
            searchKeywords: ["charger", "gan", "laptop charger", "anker"],
            specifications: specs("Output", "65W USB-C PD", "Ports", "2", "Cable", "Not included"),
            aboutItems: [
                "GaN II technology delivers 65W of power in a charger 58% smaller than original models.",
                "Charges a MacBook Pro to 50% in just 46 minutes via USB-C Power Delivery 3.0.",
                "ActiveShield 2.0 safety system monitors temperature over 3 million times per day."
            ],
            variants: variants("usb_c_charger_002", name: "Pack", values: ["1-Pack", "2-Pack"], priceAdjustments: ["2-Pack": 24.99]),
            promotions: [promotion(id: "coupon_charger_002", title: "Coupon", detail: "Apply $5 off coupon at checkout.", badgeText: "$5 off")]
        ),
        product(
            id: "mechanical_keyboard_003",
            name: "Keychron K8 Pro Wireless Mechanical Keyboard",
            brand: "Keychron",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 119.99,
            originalPrice: 149.99,
            rating: 4.5,
            reviewCount: 6_120,
            deliveryEstimate: "FREE delivery Wed, Mar 4",
            imageSystemName: "keyboard",
            imageURL: "https://images.unsplash.com/photo-1595225476474-87563907a212?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 7,
            searchKeywords: ["keyboard", "gaming keyboard", "tactile", "keychron"],
            specifications: specs("Switch Type", "Hot-swappable", "Layout", "TKL", "Backlight", "RGB"),
            aboutItems: [
                "Hot-swappable sockets let you change switches without soldering — customize your typing feel in seconds.",
                "Wireless via Bluetooth 5.1 for up to 3 devices, or wired via USB-C with full N-key rollover.",
                "South-facing RGB backlighting with QMK/VIA programmability for unlimited key remapping."
            ],
            variants: variants("mechanical_keyboard_003", name: "Switch", values: ["Brown", "Red", "Blue"]) +
                variants("mechanical_keyboard_003", name: "Color", values: ["Black", "White"]),
            promotions: [promotion(id: "save_keyboard_003", title: "Save 20%", detail: "Save 20% on this mechanical keyboard.", badgeText: "Save 20%")]
        ),
        product(
            id: "monitor_27inch_004",
            name: "Dell S2722QC 27-Inch 4K USB-C Monitor",
            brand: "Dell",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 269.99,
            rating: 4.4,
            reviewCount: 3_280,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "display",
            imageURL: "https://images.unsplash.com/photo-1547082299-de196ea013d6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 13,
            searchKeywords: ["monitor", "4k", "office setup", "dell"],
            specifications: specs("Resolution", "3840 x 2160", "Refresh Rate", "60Hz", "Ports", "HDMI, USB-C 65W"),
            aboutItems: [
                "Stunning 4K UHD resolution with 99% sRGB color coverage for sharp, vibrant visuals.",
                "Built-in USB-C port delivers 65W of power — charge your laptop with a single cable.",
                "Integrated dual 3W speakers and AMD FreeSync technology for smooth, tear-free viewing."
            ]
        ),
        product(
            id: "bluetooth_speaker_005",
            name: "JBL Flip 6 Portable Bluetooth Speaker",
            brand: "JBL",
            departmentID: "electronics",
            categoryID: "audio",
            price: 59.99,
            originalPrice: 79.99,
            rating: 4.3,
            reviewCount: 12_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "speaker.wave.3",
            imageURL: "https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 8,
            searchKeywords: ["speaker", "portable", "water resistant", "jbl"],
            specifications: specs("Battery", "12 hours", "Water Rating", "IP67", "Pairing", "PartyBoost"),
            aboutItems: [
                "Bold, powerful JBL Original Pro Sound with an optimized racetrack-shaped woofer and dual passive radiators.",
                "IP67 waterproof and dustproof — take it to the pool, beach, or trail without worry.",
                "PartyBoost lets you pair two JBL speakers together for stereo sound or link multiple for a bigger party."
            ],
            promotions: [promotion(id: "deal_speaker_005", title: "Limited time deal", detail: "Limited time deal — save 25% on JBL Flip 6.", badgeText: "Limited time deal")]
        ),
        product(
            id: "smart_home_hub_006",
            name: "MegaMart Echo (4th Gen) Smart Speaker with Alexa",
            brand: "MegaMart",
            departmentID: "electronics",
            categoryID: "audio",
            price: 89.99,
            rating: 4.2,
            reviewCount: 4_618,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "homepod",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/5c/Amazon_Echo.jpg",
            popularityRank: 21,
            searchKeywords: ["smart speaker", "echo", "alexa", "voice assistant"],
            specifications: specs("Connectivity", "Wi-Fi 6, Bluetooth 5.0", "Speaker Size", "3.0 in woofer", "Mic", "Far-field array"),
            aboutItems: [
                "Premium sound powered by Dolby processing with a 3-inch woofer for room-filling audio.",
                "Built-in Zigbee smart home hub — control compatible lights, locks, and plugs with your voice.",
                "Privacy controls include a mic-off button that electronically disconnects the microphones."
            ],
            variants: variants("smart_home_hub_006", name: "Color", values: ["Charcoal", "Glacier White"])
        ),
        product(
            id: "wireless_mouse_007",
            name: "Logitech MX Master 3S Wireless Mouse",
            brand: "Logitech",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 42.99,
            rating: 4.5,
            reviewCount: 7_801,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "computermouse",
            imageURL: "https://images.unsplash.com/photo-1527814050087-3793815479db?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 16,
            searchKeywords: ["mouse", "bluetooth mouse", "office", "logitech", "mx master"],
            specifications: specs("Battery", "70 days rechargeable", "DPI", "8,000", "Connection", "USB receiver + Bluetooth"),
            aboutItems: [
                "Quiet-click technology reduces noise by 90% — ideal for shared workspaces and late-night sessions.",
                "MagSpeed electromagnetic scroll wheel scrolls 1,000 lines per second with pixel-precise stopping.",
                "Ergonomic silhouette with silicone thumb rest and 8,000 DPI tracking on virtually any surface, including glass."
            ],
            variants: variants("wireless_mouse_007", name: "Color", values: ["Graphite", "Pale Gray", "Rose"])
        ),
        product(
            id: "action_camera_008",
            name: "GoPro HERO12 Black Action Camera Bundle",
            brand: "GoPro",
            departmentID: "electronics",
            categoryID: "audio",
            price: 189.99,
            originalPrice: 219.99,
            rating: 4.1,
            reviewCount: 2_331,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "camera",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/05/GoPro_Hero_9_Black_-_Front_2.jpg",
            popularityRank: 38,
            searchKeywords: ["camera", "gopro", "action camera", "4k"],
            specifications: specs("Resolution", "5.3K 60fps", "Waterproof", "33 ft", "Stabilization", "HyperSmooth 6.0"),
            aboutItems: [
                "Capture stunning 5.3K video at 60fps and 27MP photos with the GP2 processor for ultra-sharp detail.",
                "HyperSmooth 6.0 with AutoBoost delivers the smoothest stabilization ever — no gimbal needed.",
                "Waterproof to 33 feet without a housing, with HDR video and a front-facing screen for easy vlogging."
            ],
            variants: variants("action_camera_008", name: "Bundle", values: ["Standard", "Adventure Kit"], unavailable: ["Adventure Kit"])
        ),

        // ── PlayStation / Gaming ────────────────────────────────────

        product(
            id: "ps5_digital_bundle_081",
            name: "PlayStation 5 Digital Edition - Fortnite Cobalt Star Bundle",
            brand: "PlayStation",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 399.00,
            rating: 4.7,
            reviewCount: 424,
            deliveryEstimate: "FREE delivery Wed, Mar 11",
            imageSystemName: "tv",
            imageURL: "https://images.unsplash.com/photo-1606813907291-d86efa9b94db?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 1,
            releaseLabel: "ESRB Rating: Everyone",
            searchKeywords: ["ps5", "playstation 5", "digital edition", "fortnite bundle", "console"],
            specifications: specs("Storage", "1TB SSD", "Edition", "Digital", "Bundle", "Fortnite Cobalt Star"),
            aboutItems: [
                "PlayStation 5 Digital Edition console with Fortnite bonus content and V-Bucks.",
                "Ultra-high speed SSD delivers lightning-fast load times.",
                "DualSense wireless controller with haptic feedback and adaptive triggers."
            ],
            promotions: [promotion(id: "ps5_console_prime", title: "Prime", detail: "Fast free delivery available for eligible addresses.", badgeText: "Prime")]
        ),
        product(
            id: "ps5_slim_disc_bundle_082",
            name: "Sony PlayStation 5 Slim 1TB Disc Console - Marvel's Spider-Man 2 Bundle",
            brand: "Sony",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 499.99,
            originalPrice: 529.99,
            rating: 4.6,
            reviewCount: 318,
            deliveryEstimate: "FREE delivery Tue, Mar 10",
            imageSystemName: "cpu",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/08/Playstation_5.jpg",
            popularityRank: 4,
            searchKeywords: ["ps5", "playstation 5 slim", "disc console", "bundle", "spider-man"],
            specifications: specs("Storage", "1TB SSD", "Edition", "Slim Disc", "Bundle", "Spider-Man 2"),
            aboutItems: [
                "PS5 Slim disc edition with 1TB SSD and Marvel's Spider-Man 2 full game voucher.",
                "30% smaller chassis design with an Ultra HD Blu-ray disc drive.",
                "Includes DualSense wireless controller and vertical stand."
            ]
        ),
        product(
            id: "ps5_charging_station_083",
            name: "PS5 Stand and Cooling Station with Dual Controller Charger",
            brand: "Kiwihome",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 33.99,
            originalPrice: 39.99,
            rating: 4.4,
            reviewCount: 10_924,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "battery.100.bolt",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d1/KontrolerDualSense.jpg",
            popularityRank: 3,
            searchKeywords: ["ps5", "charging station", "cooling station", "dual controller charger", "stand"],
            specifications: specs("Compatibility", "PS5 / Slim / Pro", "Charging Slots", "2", "Cooling", "Dual fan"),
            aboutItems: [
                "All-in-one vertical stand with dual controller charging dock for PS5 consoles.",
                "Quiet cooling fans prevent overheating during extended gaming sessions.",
                "LED charging indicators and 3 USB hub ports for accessories."
            ],
            promotions: [promotion(id: "ps5_station_coupon", title: "Deal", detail: "Save $6 instantly versus list price.", badgeText: "Deal")]
        ),
        product(
            id: "ps5_controller_084",
            name: "DualSense Wireless Controller for PlayStation 5",
            brand: "Sony",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 69.99,
            rating: 4.8,
            reviewCount: 6_502,
            deliveryEstimate: "FREE delivery Sun, Mar 8",
            imageSystemName: "gamecontroller.fill",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e0/Playstation_Dualsense_controller.jpg",
            popularityRank: 5,
            searchKeywords: ["ps5", "controller", "dualsense", "wireless controller", "sony"],
            specifications: specs("Connection", "Bluetooth 5.1", "Battery", "Rechargeable Li-ion", "Haptics", "Adaptive triggers"),
            aboutItems: [
                "Haptic feedback replaces traditional rumble with highly immersive, responsive vibrations you can feel in your hands.",
                "Adaptive triggers offer varying levels of force and tension for a more realistic gameplay experience.",
                "Built-in microphone and 3.5mm headset jack — jump into chat without extra accessories."
            ]
        ),
        product(
            id: "ps5_headset_085",
            name: "Sony PULSE 3D Wireless Headset for PlayStation 5",
            brand: "Sony",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 89.99,
            originalPrice: 109.99,
            rating: 4.5,
            reviewCount: 2_842,
            deliveryEstimate: "FREE delivery Mon, Mar 9",
            imageSystemName: "headphones",
            imageURL: "https://images.unsplash.com/photo-1599669454699-248893623440?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 6,
            searchKeywords: ["ps5", "gaming headset", "pulse 3d", "playstation headset", "sony"],
            specifications: specs("Audio", "Tempest 3D AudioTech", "Microphone", "Dual hidden mics", "Connection", "Wireless + 3.5mm"),
            aboutItems: [
                "Fine-tuned for PS5 Tempest 3D AudioTech — hear every footstep and explosion from precise directions.",
                "Dual hidden microphones with AI-based noise rejection keep your voice clear during intense matches.",
                "Refined lightweight design with cushioned ear cups for comfortable all-day gaming sessions."
            ]
        ),
        product(
            id: "ps5_external_storage_086",
            name: "WD_BLACK 2TB SN850X NVMe SSD for PS5 Consoles",
            brand: "Western Digital",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 119.99,
            originalPrice: 149.99,
            rating: 4.3,
            reviewCount: 1_933,
            deliveryEstimate: "FREE delivery Tue, Mar 10",
            sellerName: "Authorized WD Reseller",
            imageSystemName: "externaldrive.fill",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/ed/1TB_2280_NVME_SSD.jpg",
            popularityRank: 7,
            searchKeywords: ["ps5", "ssd", "nvme", "wd black", "storage expansion"],
            specifications: specs("Capacity", "2TB", "Speed", "7,300 MB/s", "Interface", "PCIe Gen4 NVMe"),
            aboutItems: [
                "PCIe Gen4 NVMe speeds up to 7,300 MB/s — load games and levels in seconds on your PS5.",
                "2TB capacity stores 50+ PS5 games so you never have to delete titles to make room.",
                "Includes heatsink designed specifically for PS5 expansion bay — no extra purchases needed."
            ]
        ),
        product(
            id: "ps5_cooling_stand_087",
            name: "NexiGo PS5 Cooling Stand with Headset Hook and USB Hub",
            brand: "NexiGo",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 29.99,
            originalPrice: 34.99,
            rating: 4.2,
            reviewCount: 1_142,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "wind",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0c/PS5_Stand.jpg",
            popularityRank: 8,
            searchKeywords: ["ps5", "cooling stand", "console stand", "usb hub", "nexigo"],
            specifications: specs("Fans", "Dual low-noise", "Ports", "3 USB", "Extras", "Headset hook"),
            aboutItems: [
                "Dual high-speed fans keep your PS5 running cool during marathon gaming sessions.",
                "Built-in headset hook and 3 USB ports keep your setup organized and clutter-free.",
                "Compatible with all PS5 models including Slim and Pro — no tools required for installation."
            ]
        ),

        // ── Home & Kitchen ──────────────────────────────────────────

        product(
            id: "air_fryer_009",
            name: "Ninja AF101 4-Quart Air Fryer",
            brand: "Ninja",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 94.99,
            originalPrice: 129.99,
            rating: 4.6,
            reviewCount: 22_110,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "takeoutbag.and.cup.and.straw",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d3/Air_Fryer_2020.jpg",
            popularityRank: 2,
            searchKeywords: ["air fryer", "ninja", "kitchen", "crispy"],
            specifications: specs("Capacity", "4 qt", "Presets", "4 (Air Fry, Roast, Reheat, Dehydrate)", "Dishwasher Safe", "Basket & crisper plate"),
            aboutItems: [
                "Crisps, roasts, reheats, and dehydrates using up to 75% less fat than traditional frying methods.",
                "Wide temperature range from 105°F to 400°F with 4 programmable cooking presets.",
                "Compact 4-quart ceramic-coated nonstick basket is dishwasher safe for effortless cleanup."
            ],
            variants: variants("air_fryer_009", name: "Color", values: ["Black", "White"]),
            promotions: [promotion(id: "deal_fryer_009", title: "Deal", detail: "Save 27% — lowest price in 30 days.", badgeText: "Deal")]
        ),
        product(
            id: "cordless_vacuum_010",
            name: "Dyson V15 Detect Cordless Vacuum Cleaner",
            brand: "Dyson",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 199.99,
            originalPrice: 249.99,
            rating: 4.4,
            reviewCount: 5_840,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "sparkles",
            imageURL: "https://images.unsplash.com/photo-1558317374-067fb5f30001?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 17,
            searchKeywords: ["vacuum", "dyson", "cordless vacuum", "stick vacuum"],
            specifications: specs("Runtime", "60 min", "Bin Capacity", "0.76 L", "Filter", "Whole-machine HEPA"),
            aboutItems: [
                "Piezo sensor counts and sizes dust particles 15,000 times per second, showing a real-time readout on screen.",
                "Laser Slim Fluffy cleaner head reveals microscopic dust invisible on hard floors.",
                "Up to 60 minutes of fade-free suction with whole-machine HEPA filtration that captures 99.99% of particles."
            ],
            promotions: [promotion(id: "save_vacuum_010", title: "Save $50", detail: "Save $50 on this Dyson cordless vacuum.", badgeText: "Save $50")]
        ),
        product(
            id: "cookware_set_011",
            name: "T-fal Signature Nonstick 12-Piece Cookware Set",
            brand: "T-fal",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 149.99,
            originalPrice: 189.99,
            rating: 4.5,
            reviewCount: 8_905,
            deliveryEstimate: "FREE delivery Saturday",
            imageSystemName: "frying.pan",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e4/Stainless_Steel_Frying_Pan.jpg",
            popularityRank: 12,
            searchKeywords: ["cookware", "t-fal", "pots and pans", "nonstick"],
            specifications: specs("Pieces", "12", "Material", "Aluminum + nonstick", "Dishwasher Safe", "Yes"),
            aboutItems: [
                "Thermo-Spot heat indicator turns solid red when the pan is perfectly preheated for searing and sautéing.",
                "12-piece set includes fry pans, saucepans, and a Dutch oven — everything you need to cook any meal.",
                "Durable titanium-reinforced nonstick interior is toxin-free and dishwasher safe for easy cleanup."
            ],
            variants: variants("cookware_set_011", name: "Color", values: ["Graphite", "Red"]),
            promotions: [promotion(id: "deal_cookware_011", title: "Deal", detail: "Save 21% on this 12-piece cookware set.", badgeText: "Deal")]
        ),
        product(
            id: "espresso_machine_012",
            name: "Nespresso Vertuo Next Coffee and Espresso Machine by Breville",
            brand: "Nespresso",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 159.99,
            rating: 4.3,
            reviewCount: 6_710,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "cup.and.saucer",
            imageURL: "https://images.unsplash.com/photo-1610632380989-680fe40816c6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 19,
            searchKeywords: ["espresso", "nespresso", "coffee machine", "breville"],
            specifications: specs("Brew Sizes", "5, 8, 14, 18 oz", "System", "Centrifusion", "Warm-up", "25 seconds"),
            aboutItems: [
                "Centrifusion technology reads each capsule barcode and adjusts brewing parameters for a perfect cup every time.",
                "Brews five sizes from espresso (1.35 oz) to full carafe (18 oz) with rich crema at the touch of a button.",
                "Heats up in just 25 seconds and auto-powers off after 9 minutes to save energy."
            ]
        ),
        product(
            id: "air_purifier_013",
            name: "Levoit Core 300 HEPA Air Purifier for Home",
            brand: "Levoit",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 89.99,
            rating: 4.5,
            reviewCount: 14_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "aqi.medium",
            imageURL: "https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 20,
            searchKeywords: ["air purifier", "levoit", "hepa", "bedroom"],
            specifications: specs("Coverage", "219 sq ft", "Filter", "H13 True HEPA", "Noise Level", "24 dB (sleep mode)"),
            aboutItems: [
                "H13 True HEPA filter captures 99.97% of airborne particles 0.3 microns in size, including dust, pollen, and pet dander.",
                "Ultra-quiet sleep mode runs at just 24 dB — quieter than a whisper — with a display-off function.",
                "360-degree air intake with 3-stage filtration cleans rooms up to 219 sq ft in under 15 minutes."
            ],
            promotions: [promotion(id: "coupon_air_purifier_013", title: "Coupon", detail: "Apply $10 off coupon at checkout.", badgeText: "$10 off")]
        ),
        product(
            id: "storage_container_set_014",
            name: "Rubbermaid Brilliance 22-Piece Food Storage Container Set",
            brand: "Rubbermaid",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 39.99,
            rating: 4.6,
            reviewCount: 9_320,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tray.2",
            imageURL: "https://images.unsplash.com/photo-1595435742656-5272d0b3fa82?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 31,
            searchKeywords: ["food storage", "rubbermaid", "containers", "meal prep"],
            specifications: specs("Pieces", "22 (11 containers + 11 lids)", "Material", "Tritan plastic", "Features", "Leak-proof, stain-resistant"),
            aboutItems: [
                "100% leak-proof and airtight lids with built-in vents for splatter-free microwaving.",
                "Crystal-clear, stain- and odor-resistant Tritan plastic lets you see contents at a glance.",
                "Modular, stackable design saves cabinet space — lids snap together for organized storage."
            ]
        ),
        product(
            id: "robot_mop_015",
            name: "iRobot Roomba Combo j5+ Self-Emptying Robot Vacuum & Mop",
            brand: "iRobot",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 349.99,
            originalPrice: 399.99,
            rating: 4.2,
            reviewCount: 3_520,
            deliveryEstimate: "FREE delivery Monday",
            imageSystemName: "circle.hexagongrid",
            imageURL: "https://images.unsplash.com/photo-1603712725038-e9334ae8f39f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 32,
            searchKeywords: ["robot vacuum", "irobot", "roomba", "self-emptying", "mop"],
            specifications: specs("Navigation", "iRobot OS + PrecisionVision", "Battery", "120 min", "Auto-empty", "Clean Base included"),
            aboutItems: [
                "Vacuums and mops simultaneously with smart navigation that avoids carpets when mopping.",
                "Self-emptying Clean Base holds up to 60 days of debris so you can forget about vacuuming for weeks.",
                "PrecisionVision Navigation identifies and avoids cords, shoes, and pet waste in real time."
            ],
            promotions: [promotion(id: "coupon_mop_015", title: "Coupon", detail: "Apply $25 off coupon at checkout.", badgeText: "$25 off")]
        ),
        product(
            id: "sheet_set_016",
            name: "Brooklinen Luxe Core Sheet Set, 480 Thread Count Sateen",
            brand: "Brooklinen",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 149.99,
            rating: 4.7,
            reviewCount: 5_210,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "bed.double",
            imageURL: "https://images.unsplash.com/photo-1540518614846-7eded433c457?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 33,
            searchKeywords: ["sheets", "brooklinen", "sateen", "bedding", "queen"],
            specifications: specs("Thread Count", "480 TC", "Material", "100% long-staple cotton", "Weave", "Sateen"),
            aboutItems: [
                "480-thread-count long-staple cotton with a buttery sateen weave that gets softer with every wash.",
                "Deep-pocket fitted sheet stretches to fit mattresses up to 15 inches with a secure all-around elastic.",
                "OEKO-TEX certified — free from harmful chemicals with a 365-day warranty from Brooklinen."
            ]
        ),

        // ── Books ───────────────────────────────────────────────────

        product(
            id: "paperback_novel_017",
            name: "The Midnight Library by Matt Haig (Paperback)",
            brand: "Viking Press",
            departmentID: "books",
            categoryID: "fiction_books",
            price: 13.99,
            originalPrice: 16.99,
            rating: 4.5,
            reviewCount: 52_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "book",
            imageURL: "https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 3,
            searchKeywords: ["novel", "fiction", "matt haig", "midnight library"],
            specifications: specs("Format", "Paperback", "Pages", "304", "Publisher", "Viking"),
            aboutItems: [
                "A dazzling novel about all the choices that go into a life well lived.",
                "New York Times bestseller with over 6 million copies sold worldwide.",
                "Nora Seed finds herself in a library between life and death, where every book offers a chance to try another life."
            ],
            promotions: [promotion(id: "deal_novel_017", title: "Limited time deal", detail: "Limited time deal on this bestseller.", badgeText: "Limited time deal")]
        ),
        product(
            id: "productivity_hardcover_018",
            name: "Atomic Habits by James Clear (Hardcover)",
            brand: "Avery Publishing",
            departmentID: "books",
            categoryID: "learning_books",
            price: 18.99,
            originalPrice: 27.00,
            rating: 4.8,
            reviewCount: 124_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "text.book.closed",
            imageURL: "https://images.unsplash.com/photo-1589998059171-988d887df646?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 2,
            searchKeywords: ["habits", "james clear", "self-help", "productivity"],
            specifications: specs("Format", "Hardcover", "Pages", "320", "Publisher", "Avery"),
            aboutItems: [
                "No. 1 New York Times bestseller — over 15 million copies sold.",
                "A proven framework for building good habits and breaking bad ones.",
                "Practical strategies drawn from biology, psychology, and neuroscience."
            ],
            promotions: [promotion(id: "save_hardcover_018", title: "Save 30%", detail: "Save 30% on this bestselling hardcover.", badgeText: "Save 30%")]
        ),
        product(
            id: "cookbook_019",
            name: "Salt, Fat, Acid, Heat by Samin Nosrat",
            brand: "Simon & Schuster",
            departmentID: "books",
            categoryID: "learning_books",
            price: 22.99,
            originalPrice: 35.00,
            rating: 4.7,
            reviewCount: 8_430,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "book",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/57/Joy_of_Cooking_editions.jpg",
            popularityRank: 18,
            searchKeywords: ["cookbook", "samin nosrat", "cooking", "salt fat acid heat"],
            specifications: specs("Format", "Hardcover", "Pages", "480", "Publisher", "Simon & Schuster"),
            aboutItems: [
                "James Beard Award-winning guide to mastering the four elements of good cooking.",
                "Beautiful illustrations by Wendy MacNaughton throughout.",
                "Now a hit Netflix series watched in over 190 countries."
            ],
            promotions: [promotion(id: "save_cookbook_019", title: "Save 34%", detail: "Save 34% on this award-winning cookbook.", badgeText: "Save 34%")]
        ),
        product(
            id: "mystery_box_set_020",
            name: "Millennium Trilogy Box Set (Girl with the Dragon Tattoo Series)",
            brand: "Vintage Crime",
            departmentID: "books",
            categoryID: "fiction_books",
            price: 27.99,
            originalPrice: 35.97,
            rating: 4.6,
            reviewCount: 15_600,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "books.vertical",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/a6/Paperbacks_%2835400967690%29.jpg",
            popularityRank: 24,
            searchKeywords: ["mystery", "box set", "stieg larsson", "thriller"],
            specifications: specs("Format", "Paperback Box Set", "Books", "3", "Publisher", "Vintage Crime/Black Lizard"),
            aboutItems: [
                "All three electrifying novels in Stieg Larsson's Millennium series in one collectible box set.",
                "Over 100 million copies sold worldwide — one of the bestselling thriller series of all time.",
                "Includes The Girl with the Dragon Tattoo, The Girl Who Played with Fire, and The Girl Who Kicked the Hornet's Nest."
            ],
            promotions: [promotion(id: "save_boxset_020", title: "Save 22%", detail: "Save 22% on this bestselling trilogy box set.", badgeText: "Save 22%")]
        ),
        product(
            id: "childrens_space_book_021",
            name: "There's No Place Like Space! (Cat in the Hat's Learning Library)",
            brand: "Random House",
            departmentID: "books",
            categoryID: "fiction_books",
            price: 9.99,
            rating: 4.8,
            reviewCount: 4_560,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "sparkles",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/3b/A_Proper_Space_Book_for_Babies_%2850879866102%29.jpg",
            popularityRank: 34,
            searchKeywords: ["children", "space", "picture book", "dr seuss"],
            specifications: specs("Format", "Hardcover", "Pages", "48", "Ages", "4-8 years"),
            aboutItems: [
                "The Cat in the Hat takes young readers on a rhyming tour of our solar system and beyond.",
                "Teaches real astronomy facts about planets, stars, and space exploration in fun Dr. Seuss style.",
                "Perfect for ages 4-8 — builds early science vocabulary while sparking a love of reading."
            ]
        ),
        product(
            id: "fantasy_map_guide_022",
            name: "The Atlas of Middle-earth by Karen Wynn Fonstad (Revised Edition)",
            brand: "Houghton Mifflin",
            departmentID: "books",
            categoryID: "fiction_books",
            price: 21.99,
            originalPrice: 30.00,
            rating: 4.7,
            reviewCount: 2_310,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "map",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/65/1924_fantasy_pictorial_map_-_Pirate_Island.jpg",
            popularityRank: 42,
            searchKeywords: ["atlas", "tolkien", "lord of the rings", "maps"],
            specifications: specs("Format", "Paperback", "Pages", "224", "Maps", "Over 100 full-color maps"),
            aboutItems: [
                "Over 100 full-color maps meticulously charting every region of Tolkien's Middle-earth.",
                "Covers The Hobbit, The Lord of the Rings, and The Silmarillion with detailed battle and journey maps.",
                "Essential companion for any Tolkien fan — revised edition with updated cartography and annotations."
            ],
            promotions: [promotion(id: "save_atlas_022", title: "Save 27%", detail: "Save 27% on this revised edition.", badgeText: "Save 27%")]
        ),
        product(
            id: "leadership_playbook_023",
            name: "Leaders Eat Last by Simon Sinek (Paperback)",
            brand: "Portfolio",
            departmentID: "books",
            categoryID: "learning_books",
            price: 14.99,
            originalPrice: 18.00,
            rating: 4.6,
            reviewCount: 18_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "person.3",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/91/Simon_Sinek_speaks_at_Camp_H.M._Smith_in_Hawaii.jpg",
            popularityRank: 28,
            searchKeywords: ["leadership", "simon sinek", "business", "management"],
            specifications: specs("Format", "Paperback", "Pages", "368", "Publisher", "Portfolio / Penguin"),
            aboutItems: [
                "Simon Sinek reveals why some teams pull together and others don't — rooted in biology and real leadership stories.",
                "New York Times and Wall Street Journal bestseller with over 1 million copies sold.",
                "Explores how great leaders build trust, cooperation, and a circle of safety that drives lasting success."
            ],
            promotions: [promotion(id: "save_leadership_023", title: "Save 17%", detail: "Save 17% on this bestselling paperback.", badgeText: "Save 17%")]
        ),
        product(
            id: "wellness_journal_024",
            name: "The Five Minute Journal by Intelligent Change",
            brand: "Intelligent Change",
            departmentID: "books",
            categoryID: "learning_books",
            price: 24.99,
            rating: 4.7,
            reviewCount: 21_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "square.and.pencil",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/97/Bullet-Journal-by-Matt-Ragland.jpg",
            popularityRank: 9,
            searchKeywords: ["journal", "gratitude", "five minute journal", "wellness"],
            specifications: specs("Format", "Hardcover", "Pages", "264", "Duration", "6 months of daily entries"),
            aboutItems: [
                "Structured morning and evening prompts take just 5 minutes a day to build a gratitude habit.",
                "Used by over 2 million people worldwide — backed by positive psychology research.",
                "Beautifully designed hardcover with inspirational quotes, weekly challenges, and a lay-flat binding."
            ]
        ),

        // ── Clothing ────────────────────────────────────────────────

        product(
            id: "running_shoes_025",
            name: "Nike Air Zoom Pegasus 40 Running Shoes",
            brand: "Nike",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 99.99,
            originalPrice: 130.00,
            rating: 4.5,
            reviewCount: 14_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/c0/Nike_Zoom_Pegasus_38_running_shoe.jpg",
            popularityRank: 5,
            searchKeywords: ["running shoes", "nike", "pegasus", "sneakers"],
            specifications: specs("Closure", "Lace-up", "Sole", "React foam + Zoom Air", "Drop", "10mm"),
            aboutItems: [
                "React foam midsole paired with a Zoom Air unit delivers a snappy, responsive ride mile after mile.",
                "Breathable engineered mesh upper with Flywire cables locks down your midfoot for a secure fit.",
                "Durable rubber outsole with waffle-pattern traction grips both road and light trail surfaces."
            ],
            variants: variants("running_shoes_025", name: "Size", values: ["9", "10", "11", "12"]) +
                variants("running_shoes_025", name: "Color", values: ["Black/White", "Blue/Silver", "Red/Black"]),
            promotions: [promotion(id: "save_pegasus_025", title: "Save 23%", detail: "Save 23% on Nike Pegasus 40 running shoes.", badgeText: "Save 23%")]
        ),
        product(
            id: "everyday_hoodie_026",
            name: "Champion Powerblend Fleece Pullover Hoodie",
            brand: "Champion",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 35.00,
            rating: 4.6,
            reviewCount: 42_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tshirt",
            imageURL: "https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 10,
            searchKeywords: ["hoodie", "champion", "fleece", "pullover"],
            specifications: specs("Material", "50% Cotton / 50% Polyester", "Fit", "Relaxed", "Care", "Machine washable"),
            aboutItems: [
                "Powerblend fleece resists pilling and shrinkage so it looks new wash after wash.",
                "Reduced bulk in the body with a relaxed fit — perfect for layering or wearing on its own.",
                "Ribbed cuffs and hem lock in warmth, while the kangaroo pocket keeps hands and essentials close."
            ],
            variants: variants("everyday_hoodie_026", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("everyday_hoodie_026", name: "Color", values: ["Oxford Gray", "Navy", "Black"])
        ),
        product(
            id: "performance_leggings_027",
            name: "Lululemon Align High-Rise Pant 25\"",
            brand: "Lululemon",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 98.00,
            rating: 4.8,
            reviewCount: 7_800,
            deliveryEstimate: "FREE delivery Wed, Mar 4",
            imageSystemName: "figure.walk",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/10/Woman-in-black-tank-top-and-black-leggings-doing-yoga-3823063.jpg",
            popularityRank: 15,
            searchKeywords: ["leggings", "lululemon", "align", "yoga pants"],
            specifications: specs("Material", "Nulu fabric", "Rise", "High", "Inseam", "25\""),
            aboutItems: [
                "Buttery-soft Nulu™ fabric feels weightless with four-way stretch for unrestricted movement.",
                "High-rise waistband lies flat and stays put through every yoga pose, barre class, or errand run.",
                "Minimal seams and a hidden waistband pocket for a sleek, no-distraction look and feel."
            ],
            variants: variants("performance_leggings_027", name: "Size", values: ["2", "4", "6", "8", "10"]) +
                variants("performance_leggings_027", name: "Color", values: ["Black", "True Navy", "Dark Olive"])
        ),
        product(
            id: "trail_jacket_028",
            name: "The North Face Venture 2 Waterproof Jacket",
            brand: "The North Face",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 89.99,
            originalPrice: 109.00,
            rating: 4.4,
            reviewCount: 11_200,
            deliveryEstimate: "FREE delivery Thursday",
            imageSystemName: "cloud.rain",
            imageURL: "https://images.unsplash.com/photo-1551028719-00167b16eac5?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 22,
            searchKeywords: ["jacket", "north face", "rain jacket", "waterproof"],
            specifications: specs("Material", "DryVent 2.5L", "Weight", "11.6 oz", "Features", "Packable, pit-zip vents"),
            aboutItems: [
                "DryVent 2.5-layer waterproof shell keeps you dry in heavy rain while remaining breathable.",
                "Pit-zip vents dump excess heat on steep climbs — ideal for unpredictable mountain weather.",
                "Packs into its own pocket for easy stow-and-go, weighing just 11.6 oz."
            ],
            variants: variants("trail_jacket_028", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("trail_jacket_028", name: "Color", values: ["TNF Black", "Shady Blue", "Meld Grey"]),
            promotions: [promotion(id: "deal_jacket_028", title: "Limited time deal", detail: "Limited time deal — save 17% on The North Face.", badgeText: "Limited time deal")]
        ),
        product(
            id: "crew_socks_029",
            name: "Nike Everyday Cushioned Crew Socks (6-Pack)",
            brand: "Nike",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 22.00,
            rating: 4.7,
            reviewCount: 33_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1586350977771-b3b0abd50c82?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 14,
            searchKeywords: ["socks", "nike", "crew socks", "athletic"],
            specifications: specs("Pack", "6 pairs", "Material", "Dri-FIT cotton blend", "Cushion", "Heel & toe"),
            aboutItems: [
                "Dri-FIT moisture-wicking technology pulls sweat away from the skin to keep feet dry during workouts.",
                "Reinforced heel and toe cushioning absorbs impact and reduces wear in high-friction zones.",
                "Six-pair value pack with a ribbed crew cuff that stays up all day without slipping."
            ],
            variants: variants("crew_socks_029", name: "Size", values: ["S", "M", "L"])
        ),
        product(
            id: "classic_jeans_030",
            name: "Levi's 501 Original Fit Jeans",
            brand: "Levi's",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 49.99,
            originalPrice: 69.50,
            rating: 4.4,
            reviewCount: 28_600,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "tshirt",
            imageURL: "https://images.unsplash.com/photo-1604176354204-9268737828e4?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 23,
            searchKeywords: ["jeans", "levis", "501", "denim"],
            specifications: specs("Fit", "Original / Straight", "Rise", "Regular", "Closure", "Button fly"),
            aboutItems: [
                "The original straight-leg jean since 1873 — an iconic silhouette that never goes out of style.",
                "Heavyweight non-stretch denim with a signature button fly breaks in and molds to your body over time.",
                "Sits at the waist with a straight fit through the hip and thigh for a classic, versatile look."
            ],
            variants: variants("classic_jeans_030", name: "Size", values: ["30x30", "32x30", "32x32", "34x32"]) +
                variants("classic_jeans_030", name: "Color", values: ["Medium Stonewash", "Rinse", "Black"]),
            promotions: [promotion(id: "deal_jeans_030", title: "Deal", detail: "Save 28% on Levi's 501 Original Fit.", badgeText: "Deal")]
        ),
        product(
            id: "polo_shirt_031",
            name: "Ralph Lauren Classic Fit Mesh Polo Shirt",
            brand: "Polo Ralph Lauren",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 79.99,
            originalPrice: 98.50,
            rating: 4.5,
            reviewCount: 6_350,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "tshirt",
            imageURL: "https://images.unsplash.com/photo-1586363104862-3a5e2ab60d99?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 27,
            searchKeywords: ["polo", "ralph lauren", "classic fit", "mesh polo"],
            specifications: specs("Material", "Cotton mesh", "Fit", "Classic", "Collar", "Two-button placket"),
            aboutItems: [
                "Signature breathable cotton mesh polo with the iconic embroidered pony at the chest.",
                "Classic fit sits comfortably at the body without being too tight or too loose.",
                "Ribbed polo collar and armbands hold their shape — dress it up with chinos or down with jeans."
            ],
            variants: variants("polo_shirt_031", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("polo_shirt_031", name: "Color", values: ["Newport Navy", "White", "Red"]),
            promotions: [promotion(id: "save_polo_031", title: "Save 19%", detail: "Save 19% on Ralph Lauren polo shirts.", badgeText: "Save 19%")]
        ),
        product(
            id: "lounge_set_032",
            name: "Barefoot Dreams CozyChic Lite Lounge Set",
            brand: "Barefoot Dreams",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 120.00,
            rating: 4.7,
            reviewCount: 3_450,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "bed.double",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/b8/Loungewear_MET_CI37.46.75_F.jpg",
            popularityRank: 36,
            searchKeywords: ["loungewear", "barefoot dreams", "cozy", "pajamas"],
            specifications: specs("Material", "CozyChic Lite knit", "Pieces", "Top + Pants", "Care", "Machine washable"),
            aboutItems: [
                "Luxuriously soft CozyChic Lite knit feels like a cloud — a celebrity and Oprah's Favorite Things pick.",
                "Matching top and pants set transitions seamlessly from lounging at home to running errands.",
                "Machine washable and dryer safe without losing its signature softness or shape."
            ],
            variants: variants("lounge_set_032", name: "Size", values: ["XS/S", "M/L"]) +
                variants("lounge_set_032", name: "Color", values: ["Oyster", "Carbon", "Dusty Rose"])
        ),

        // ── Beauty & Personal Care ──────────────────────────────────

        product(
            id: "face_moisturizer_033",
            name: "CeraVe Daily Moisturizing Lotion for Face & Body",
            brand: "CeraVe",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 14.99,
            rating: 4.7,
            reviewCount: 98_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "drop",
            imageURL: "https://images.unsplash.com/photo-1612817288484-6f916006741a?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 4,
            searchKeywords: ["moisturizer", "cerave", "face lotion", "sensitive skin"],
            specifications: specs("Size", "12 oz", "Skin Type", "Normal to Dry", "Key Ingredients", "3 Essential Ceramides + Hyaluronic Acid"),
            aboutItems: [
                "Developed with dermatologists — 3 essential ceramides restore and maintain the skin's protective barrier.",
                "Lightweight, oil-free formula with hyaluronic acid provides 24-hour hydration without clogging pores.",
                "Fragrance-free, non-comedogenic, and accepted by the National Eczema Association."
            ],
            variants: variants("face_moisturizer_033", name: "Size", values: ["1.7 oz", "8 oz", "12 oz"], priceAdjustments: ["1.7 oz": -8.00, "8 oz": -4.00]),
            promotions: [promotion(id: "subscribe_moisturizer_033", title: "Subscribe & Save", detail: "Subscribe & Save 15% on recurring deliveries.", badgeText: "Subscribe & Save 15%")]
        ),
        product(
            id: "vitamin_c_serum_034",
            name: "TruSkin Vitamin C Serum for Face",
            brand: "TruSkin",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 19.99,
            rating: 4.3,
            reviewCount: 67_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "eyedropper",
            imageURL: "https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 11,
            searchKeywords: ["vitamin c", "serum", "truskin", "brightening", "anti-aging"],
            specifications: specs("Size", "1 fl oz", "Key Ingredients", "Vitamin C, Hyaluronic Acid, Vitamin E", "Skin Type", "All skin types"),
            aboutItems: [
                "Potent Vitamin C and botanical hyaluronic acid brighten dull skin and reduce the appearance of fine lines.",
                "Antioxidant-rich formula with Vitamin E and jojoba oil protects against environmental damage.",
                "Plant-based, cruelty-free, and suitable for all skin types — over 67,000 five-star reviews."
            ],
            promotions: [promotion(id: "coupon_serum_034", title: "Coupon", detail: "Apply $3 off coupon at checkout.", badgeText: "$3 off")]
        ),
        product(
            id: "shampoo_duo_035",
            name: "Olaplex No.4 & No.5 Bond Maintenance Shampoo & Conditioner Set",
            brand: "Olaplex",
            departmentID: "beauty",
            categoryID: "hair_care",
            price: 56.00,
            rating: 4.6,
            reviewCount: 12_700,
            deliveryEstimate: "FREE delivery Thursday",
            imageSystemName: "drop.triangle",
            imageURL: "https://images.unsplash.com/photo-1556228720-195a672e8a03?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 25,
            searchKeywords: ["shampoo", "olaplex", "conditioner", "bond repair", "hair care"],
            specifications: specs("Size", "8.5 oz each", "Hair Type", "All types, especially damaged", "Key Ingredient", "Bis-Aminopropyl Diglycol Dimaleate"),
            aboutItems: [
                "Patented bond-building technology repairs broken disulfide bonds caused by heat, color, and chemical damage.",
                "Shampoo and conditioner duo restores strength, moisture, and shine to compromised hair.",
                "Color-safe, sulfate-free, and vegan — extends the life of salon color treatments."
            ]
        ),
        product(
            id: "sunscreen_lotion_036",
            name: "Neutrogena Ultra Sheer Dry-Touch SPF 55 Sunscreen",
            brand: "Neutrogena",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 10.99,
            rating: 4.5,
            reviewCount: 43_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "sun.max",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d0/Sunbum_sunscreen_spf_30.jpg",
            popularityRank: 9,
            searchKeywords: ["sunscreen", "neutrogena", "spf", "sun protection"],
            specifications: specs("SPF", "55", "Size", "3 fl oz", "Type", "Dry-Touch, non-greasy"),
            aboutItems: [
                "Broad-spectrum SPF 55 with Helioplex technology provides superior UVA/UVB protection that lasts.",
                "Dry-Touch formula absorbs quickly for a clean, non-greasy, matte finish under makeup or on its own.",
                "Lightweight, water-resistant for 80 minutes — the #1 dermatologist-recommended suncare brand."
            ],
            promotions: [promotion(id: "buy2_sunscreen_036", title: "Buy 2, save 10%", detail: "Buy 2 or more, save 10% on each.", badgeText: "Buy 2, save 10%")]
        ),
        product(
            id: "lip_balm_pack_037",
            name: "Burt's Bees 100% Natural Moisturizing Lip Balm (4-Pack)",
            brand: "Burt's Bees",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 9.48,
            rating: 4.7,
            reviewCount: 85_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "mouth",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/46/Various_colorful_lip_balm_sticks_%2840821280864%29.jpg",
            popularityRank: 10,
            searchKeywords: ["lip balm", "burts bees", "chapstick", "natural"],
            specifications: specs("Pack", "4 tubes", "Flavors", "Beeswax, Strawberry, Coconut & Pear, Vanilla Bean", "Ingredients", "100% natural, beeswax & vitamin E"),
            aboutItems: [
                "100% natural ingredients with beeswax and Vitamin E condition and moisturize dry, chapped lips.",
                "Four delicious flavors in one pack — Beeswax, Strawberry, Coconut & Pear, and Vanilla Bean.",
                "Compact tube slides into any pocket or purse — the bestselling natural lip balm in America."
            ],
            promotions: [promotion(id: "buy2_lip_balm_037", title: "Buy 2, save 10%", detail: "Buy 2 or more, save 10% on each.", badgeText: "Buy 2, save 10%")]
        ),
        product(
            id: "cleansing_balm_038",
            name: "Banila Co Clean It Zero Cleansing Balm Original",
            brand: "Banila Co",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 19.00,
            rating: 4.5,
            reviewCount: 22_800,
            deliveryEstimate: "FREE delivery Thursday",
            imageSystemName: "drop",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/03/Korean_cosmetic_products.jpg",
            popularityRank: 30,
            searchKeywords: ["cleansing balm", "banila co", "makeup remover", "double cleanse"],
            specifications: specs("Size", "3.38 oz", "Type", "Sherbet-to-oil balm", "Skin Type", "All types"),
            aboutItems: [
                "Transforms from a sherbet-like balm into a silky oil that melts away even waterproof makeup effortlessly.",
                "Zero-residue formula rinses clean with water — no double cleanse needed for everyday wear.",
                "Hypoallergenic and free of parabens, sulfates, and artificial fragrance — gentle enough for sensitive skin."
            ]
        ),
        product(
            id: "beard_trimmer_039",
            name: "Philips Norelco OneBlade Hybrid Electric Trimmer and Shaver",
            brand: "Philips",
            departmentID: "beauty",
            categoryID: "hair_care",
            price: 29.99,
            originalPrice: 34.99,
            rating: 4.4,
            reviewCount: 51_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "scissors",
            imageURL: "https://images.unsplash.com/photo-1621607512214-68297480165e?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 26,
            searchKeywords: ["trimmer", "philips", "oneblade", "beard trimmer", "shaver"],
            specifications: specs("Battery", "60 min cordless", "Guards", "3 stubble combs (1, 3, 5mm)", "Replacement Blade", "Every 4 months"),
            aboutItems: [
                "Unique OneBlade technology trims, edges, and shaves any length of hair without irritation.",
                "Three precision stubble combs (1mm, 3mm, 5mm) let you dial in your exact preferred look.",
                "Rechargeable battery lasts 60 minutes per charge — use wet or dry in or out of the shower."
            ],
            promotions: [promotion(id: "coupon_trimmer_039", title: "Coupon", detail: "Apply $5 off coupon at checkout.", badgeText: "$5 off")]
        ),
        product(
            id: "hair_dryer_brush_040",
            name: "Revlon One-Step Volumizer PLUS 2.0 Hair Dryer and Styler",
            brand: "Revlon",
            departmentID: "beauty",
            categoryID: "hair_care",
            price: 34.99,
            originalPrice: 44.99,
            rating: 4.5,
            reviewCount: 38_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "wind",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/1f/HITACHI_HAIR_DRYER_HD-1650.jpg",
            popularityRank: 16,
            searchKeywords: ["hair dryer", "revlon", "blow dry brush", "volumizer"],
            specifications: specs("Heat Settings", "3", "Ionic Technology", "Yes", "Barrel", "Oval design for volume & smoothing"),
            aboutItems: [
                "Combines a hair dryer and volumizing brush in one step — cuts blowout time in half.",
                "Oval brush design creates volume at the roots and smooth, sleek ends simultaneously.",
                "Ionic technology reduces frizz and static for a salon-quality finish at home."
            ],
            promotions: [promotion(id: "coupon_dryer_040", title: "Coupon", detail: "Apply $5 off coupon at checkout.", badgeText: "$5 off")]
        ),

        // ── Groceries & Household ───────────────────────────────────

        product(
            id: "protein_powder_041",
            name: "Optimum Nutrition Gold Standard 100% Whey Protein Powder",
            brand: "Optimum Nutrition",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 30.99,
            originalPrice: 37.99,
            rating: 4.7,
            reviewCount: 105_000,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "mug",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/78/Optimus_nutrition_gold_standard_whey_protein_%282%29.jpg",
            popularityRank: 3,
            searchKeywords: ["protein", "whey", "optimum nutrition", "gold standard"],
            specifications: specs("Servings", "24 per container", "Protein per Serving", "24g", "Sweetener", "Sucralose"),
            aboutItems: [
                "24g of premium whey protein per serving with 5.5g of naturally occurring BCAAs for muscle recovery.",
                "Mixes instantly with a spoon — no blender needed for a smooth, great-tasting shake every time.",
                "The world's best-selling whey protein powder, trusted by athletes for over 30 years."
            ],
            variants: variants("protein_powder_041", name: "Flavor", values: ["Double Rich Chocolate", "Vanilla Ice Cream", "Strawberry Banana"]),
            promotions: [promotion(id: "subscribe_protein_041", title: "Subscribe & Save", detail: "Subscribe & Save 15% on recurring deliveries.", badgeText: "Subscribe & Save 15%")]
        ),
        product(
            id: "organic_coffee_042",
            name: "Lavazza Super Crema Whole Bean Coffee Blend, Medium Espresso Roast",
            brand: "Lavazza",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 17.99,
            rating: 4.5,
            reviewCount: 48_700,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "cup.and.saucer",
            imageURL: "https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 14,
            searchKeywords: ["coffee", "lavazza", "whole bean", "espresso", "medium roast"],
            specifications: specs("Weight", "2.2 lb", "Roast", "Medium", "Flavor Notes", "Hazelnut, brown sugar, dried fruit"),
            aboutItems: [
                "Medium espresso roast with a velvety crema and tasting notes of hazelnut, brown sugar, and dried fruit.",
                "Expertly blended from premium Arabica and Robusta beans sourced from multiple origins.",
                "Whole bean format preserves peak freshness — grind just before brewing for the best flavor."
            ]
        ),
        product(
            id: "sparkling_water_043",
            name: "S.Pellegrino Sparkling Natural Mineral Water (24-Pack)",
            brand: "S.Pellegrino",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 19.99,
            rating: 4.6,
            reviewCount: 16_400,
            deliveryEstimate: "FREE delivery Saturday",
            imageSystemName: "waterbottle",
            imageURL: "https://images.unsplash.com/photo-1625772299848-391b6a87d7b3?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 29,
            searchKeywords: ["sparkling water", "pellegrino", "mineral water", "seltzer"],
            specifications: specs("Pack", "24 x 16.9 fl oz", "Source", "Italian Alps", "Calories", "0"),
            aboutItems: [
                "Naturally sourced from the Italian Alps — fine, persistent bubbles with a clean, crisp mineral taste.",
                "Zero calories, zero sweeteners — the perfect sparkling water for meals, cocktails, or on its own.",
                "24-pack of 16.9 oz bottles keeps your home or office stocked for weeks."
            ]
        ),
        product(
            id: "granola_pack_044",
            name: "KIND Healthy Grains Granola Bars Variety Pack (40 Count)",
            brand: "KIND",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 15.99,
            rating: 4.5,
            reviewCount: 29_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "leaf",
            imageURL: "https://images.unsplash.com/photo-1558030006-450675393462?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 35,
            searchKeywords: ["granola bars", "kind", "snack bars", "healthy snacks"],
            specifications: specs("Count", "40 bars", "Flavors", "Dark Chocolate, Oats & Honey, Peanut Butter, Maple Pumpkin", "Gluten Free", "Yes"),
            aboutItems: [
                "40-count variety pack with four fan-favorite flavors — perfect for lunch boxes, desks, and gym bags.",
                "Made with 5 super grains and gluten-free whole grain oats — only 4-5g of sugar per bar.",
                "Individually wrapped for grab-and-go convenience with a satisfying crunch in every bite."
            ]
        ),
        product(
            id: "olive_oil_045",
            name: "California Olive Ranch 100% California Extra Virgin Olive Oil",
            brand: "California Olive Ranch",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 12.99,
            rating: 4.6,
            reviewCount: 11_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "leaf",
            imageURL: "https://images.unsplash.com/photo-1608797178974-15b35a64ede9?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 40,
            searchKeywords: ["olive oil", "extra virgin", "california olive ranch", "cooking oil"],
            specifications: specs("Size", "25.4 fl oz", "Origin", "California", "Cold Pressed", "Yes"),
            aboutItems: [
                "100% California-grown olives cold-pressed within hours of harvest for peak freshness and flavor.",
                "Bright, versatile flavor profile perfect for salads, pasta, grilling, and everyday cooking.",
                "Certified extra virgin with full traceability from grove to bottle — no blending with imported oils."
            ]
        ),
        product(
            id: "paper_towels_046",
            name: "Bounty Quick-Size Paper Towels, 12 Family Rolls",
            brand: "Bounty",
            departmentID: "groceries",
            categoryID: "household_essentials",
            price: 28.99,
            rating: 4.8,
            reviewCount: 72_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "toilet.fill",
            imageURL: "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 1,
            searchKeywords: ["paper towels", "bounty", "household", "cleaning"],
            specifications: specs("Rolls", "12 Family (= 30 Regular)", "Sheet Size", "Quick-Size select-a-size", "2-Ply", "Yes"),
            aboutItems: [
                "2X more absorbent so you can use less — the quicker picker-upper handles tough messes in one sheet.",
                "Select-a-size sheets let you tear off just what you need to reduce waste.",
                "12 Family Rolls equal 30 Regular Rolls — stock up less often with bulk-size value."
            ],
            promotions: [promotion(id: "subscribe_towels_046", title: "Subscribe & Save", detail: "Subscribe & Save 15% on recurring deliveries.", badgeText: "Subscribe & Save 15%")]
        ),
        product(
            id: "detergent_pods_047",
            name: "Tide PODS Laundry Detergent Soap Pacs (42 Count), Spring Meadow",
            brand: "Tide",
            departmentID: "groceries",
            categoryID: "household_essentials",
            price: 14.99,
            rating: 4.7,
            reviewCount: 56_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "washer",
            imageURL: "https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 18,
            searchKeywords: ["detergent", "tide pods", "laundry", "soap"],
            specifications: specs("Count", "42 pacs", "Scent", "Spring Meadow", "Works in", "All machines, all water temps"),
            aboutItems: [
                "3-in-1 formula with detergent, stain remover, and color protector in a single pre-measured pac.",
                "Dissolves in all water temperatures and works in both standard and HE machines — no mess, no measuring.",
                "Spring Meadow scent leaves clothes smelling fresh and clean with long-lasting fragrance."
            ],
            promotions: [promotion(id: "coupon_detergent_047", title: "Coupon", detail: "Apply $2 off coupon at checkout.", badgeText: "$2 off")]
        ),
        product(
            id: "snack_box_048",
            name: "Frito-Lay Fun Times Mix Variety Pack (40 Count)",
            brand: "Frito-Lay",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 18.99,
            rating: 4.6,
            reviewCount: 24_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "bag",
            imageURL: "https://images.unsplash.com/photo-1621939514649-280e2ee25f60?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 37,
            searchKeywords: ["snacks", "frito lay", "variety pack", "chips", "lunch box"],
            specifications: specs("Count", "40 bags", "Flavors", "Lays, Doritos, Cheetos, Fritos", "Individual", "Single-serve bags"),
            aboutItems: [
                "40 single-serve bags of America's favorite snacks — Lay's, Doritos, Cheetos, and Fritos.",
                "Perfect for lunch boxes, pantry stocking, game day parties, and on-the-go snacking.",
                "Individually portioned bags keep snacks fresh and make calorie counting easy."
            ]
        ),

        // ── Office & Workspace ──────────────────────────────────────

        product(
            id: "led_desk_lamp_049",
            name: "BenQ ScreenBar Monitor Light",
            brand: "BenQ",
            departmentID: "office",
            categoryID: "workspace",
            price: 109.00,
            rating: 4.7,
            reviewCount: 8_340,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "lamp.desk",
            imageURL: "https://images.unsplash.com/photo-1525547719571-a2d4ac8945e2?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 11,
            searchKeywords: ["desk lamp", "benq", "monitor light", "screen bar"],
            specifications: specs("Color Temp", "2700K-6500K", "Brightness", "Auto-dimming sensor", "Mounting", "Clamps to monitor top"),
            aboutItems: [
                "Clips directly to your monitor — illuminates your desk without screen glare or wasted space.",
                "Built-in ambient light sensor auto-adjusts brightness for optimal eye comfort throughout the day.",
                "Adjustable color temperature from warm 2700K to cool 6500K suits any task from reading to video calls."
            ]
        ),
        product(
            id: "led_desk_lamp_135",
            name: "TaoTronics LED Desk Lamp with 3 Color Modes",
            brand: "TaoTronics",
            departmentID: "office",
            categoryID: "workspace",
            price: 35.99,
            rating: 4.5,
            reviewCount: 12_870,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "lamp.desk",
            imageURL: "https://images.unsplash.com/photo-1565374395542-0ce18882c857?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 16,
            searchKeywords: ["desk lamp", "led lamp", "office lamp", "reading lamp", "taotronics", "table lamp"],
            specifications: specs("Color Temp", "2700K-6500K", "Brightness", "5 levels, 410 lumens max", "Power", "USB-C, 12W"),
            aboutItems: [
                "Three color modes and five brightness levels let you customize lighting for any task — reading, working, or relaxing.",
                "Flexible gooseneck and adjustable arm position light exactly where you need it on your desk.",
                "Built-in USB charging port keeps your phone powered up while you work."
            ]
        ),
        product(
            id: "chair_cushion_050",
            name: "Purple Royal Seat Cushion for Desk Chair",
            brand: "Purple",
            departmentID: "office",
            categoryID: "workspace",
            price: 49.99,
            rating: 4.3,
            reviewCount: 14_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "chair.lounge",
            imageURL: "https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 39,
            searchKeywords: ["seat cushion", "purple", "ergonomic", "office chair"],
            specifications: specs("Material", "GelFlex Grid", "Dimensions", "17.5\" x 15.75\"", "Cover", "Removable, machine-washable"),
            aboutItems: [
                "GelFlex Grid technology collapses under pressure points and cradles your body for all-day seated comfort.",
                "Open-grid design promotes airflow to keep you cool — no more sweaty, uncomfortable sitting.",
                "Machine-washable cover and non-slip bottom keep the cushion clean and in place on any chair."
            ]
        ),
        product(
            id: "gel_pen_pack_051",
            name: "Pilot G2 Premium Gel Roller Pens, Fine Point (12-Pack)",
            brand: "Pilot",
            departmentID: "office",
            categoryID: "office_supplies",
            price: 12.99,
            rating: 4.8,
            reviewCount: 62_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "pencil",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/94/Pilot_pens.jpg",
            popularityRank: 15,
            searchKeywords: ["pens", "pilot g2", "gel pens", "office supplies"],
            specifications: specs("Tip", "0.7mm Fine", "Ink", "Gel, smear-proof", "Pack", "12 black pens"),
            aboutItems: [
                "America's #1 selling gel pen — smooth, skip-free writing with vivid gel ink that dries fast.",
                "Fine 0.7mm tip produces precise, clean lines ideal for note-taking, journaling, and detailed work.",
                "Comfortable rubber grip and refillable design reduce hand fatigue and waste."
            ],
            promotions: [promotion(id: "save_pens_051", title: "Save 15%", detail: "Save 15% when you buy 2 or more office supply items.", badgeText: "Save 15%")]
        ),
        product(
            id: "desk_converter_052",
            name: "FlexiSpot Standing Desk Converter, 35\" Wide",
            brand: "FlexiSpot",
            departmentID: "office",
            categoryID: "workspace",
            price: 249.99,
            originalPrice: 299.99,
            rating: 4.4,
            reviewCount: 4_780,
            deliveryEstimate: "FREE delivery Monday",
            imageSystemName: "desktopcomputer",
            imageURL: "https://images.unsplash.com/photo-1593062096033-9a26b09da705?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 41,
            searchKeywords: ["standing desk", "flexispot", "desk converter", "sit stand"],
            specifications: specs("Width", "35\"", "Height Range", "6.1\" - 19.7\"", "Weight Capacity", "33 lbs"),
            aboutItems: [
                "Converts any standard desk into a sit-stand workstation in seconds with a smooth gas-spring lift.",
                "35-inch wide surface fits dual monitors with a separate keyboard tray for ergonomic positioning.",
                "Height adjusts from 6.1 to 19.7 inches with 12 locking positions — supports up to 33 lbs."
            ],
            promotions: [promotion(id: "save_desk_052", title: "Save $50", detail: "Save $50 on this FlexiSpot standing desk converter.", badgeText: "Save $50")]
        ),
        product(
            id: "planner_notebook_053",
            name: "Moleskine Classic 12-Month Weekly Planner 2026",
            brand: "Moleskine",
            departmentID: "office",
            categoryID: "office_supplies",
            price: 24.95,
            rating: 4.6,
            reviewCount: 7_230,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "calendar",
            imageURL: "https://images.unsplash.com/photo-1544816565-aa8c1166648f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 43,
            searchKeywords: ["planner", "moleskine", "2026", "weekly planner", "notebook"],
            specifications: specs("Size", "Large (5\" x 8.25\")", "Pages", "144", "Cover", "Hard cover, elastic closure"),
            aboutItems: [
                "12-month weekly layout with plenty of space for appointments, goals, and to-do lists.",
                "Ivory-colored, acid-free 70g/m² paper prevents bleed-through from most pens and markers.",
                "Iconic Moleskine hardcover with rounded corners, elastic closure, and an expandable inner pocket."
            ],
            promotions: [promotion(id: "deal_planner_053", title: "Limited time deal", detail: "Limited time deal on 2026 planners.", badgeText: "Limited time deal")]
        ),
        product(
            id: "label_maker_054",
            name: "DYMO LetraTag 200B Portable Bluetooth Label Maker",
            brand: "DYMO",
            departmentID: "office",
            categoryID: "office_supplies",
            price: 39.99,
            rating: 4.3,
            reviewCount: 3_560,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "tag",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/28/DYMO_LetraTag_%28label_maker%29_-_Pulsn_machineroom_14_-_2014-10-31_10.48.18_%28by_GeschnittenBrot%29.jpg",
            popularityRank: 52,
            searchKeywords: ["label maker", "dymo", "letratag", "bluetooth", "organization"],
            specifications: specs("Connection", "Bluetooth + USB-C", "Labels", "Multiple tape colors/sizes", "App", "DYMO Connect"),
            aboutItems: [
                "Connects via Bluetooth to the DYMO Connect app — design and print labels right from your phone.",
                "Compact, portable design with USB-C charging makes labeling easy at home, school, or the office.",
                "Prints on multiple tape colors and sizes for organizing bins, files, cables, and pantry items."
            ]
        ),
        product(
            id: "monitor_riser_055",
            name: "FITUEYES Monitor Stand Riser with Storage Drawer",
            brand: "FITUEYES",
            departmentID: "office",
            categoryID: "workspace",
            price: 25.99,
            rating: 4.5,
            reviewCount: 18_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "rectangle.on.rectangle",
            imageURL: "https://images.unsplash.com/photo-1542435503-956c469947f6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 44,
            searchKeywords: ["monitor riser", "desk organizer", "fitueyes", "monitor stand"],
            specifications: specs("Material", "Wood composite", "Dimensions", "16.7\" x 7.9\" x 4.7\"", "Storage", "Pull-out drawer"),
            aboutItems: [
                "Elevates your monitor to a comfortable ergonomic height to reduce neck and back strain.",
                "Pull-out drawer stores pens, sticky notes, and small accessories to keep your desk clutter-free.",
                "Sturdy wood composite construction supports monitors up to 30 lbs with a clean, modern look."
            ]
        ),
        product(
            id: "usb_docking_station_056",
            name: "CalDigit TS4 Thunderbolt 4 Dock with 18 Ports",
            brand: "CalDigit",
            departmentID: "office",
            categoryID: "workspace",
            price: 299.99,
            rating: 4.7,
            reviewCount: 2_860,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "rectangle.connected.to.line.below",
            imageURL: "https://images.unsplash.com/photo-1611078489935-0cb964de46d6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 45,
            searchKeywords: ["thunderbolt dock", "caldigit", "usb-c", "docking station"],
            specifications: specs("Ports", "18 total", "Charging", "98W to host laptop", "Thunderbolt 4", "Up to 40 Gbps"),
            aboutItems: [
                "18 ports in one dock — connect displays, drives, audio, Ethernet, and USB devices with a single cable.",
                "98W power delivery charges your MacBook or PC laptop while transferring data at up to 40 Gbps.",
                "Built with an aluminum enclosure and no fans for silent, reliable operation on any desk setup."
            ]
        ),

        // ── Toys & Games ────────────────────────────────────────────

        product(
            id: "building_blocks_057",
            name: "LEGO Classic Large Creative Brick Box (484 Pieces)",
            brand: "LEGO",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 39.99,
            rating: 4.8,
            reviewCount: 16_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "square.stack.3d.up",
            imageURL: "https://images.unsplash.com/photo-1587654780291-39c9404d746b?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 6,
            searchKeywords: ["lego", "building blocks", "creative", "kids toys"],
            specifications: specs("Pieces", "484", "Ages", "4+", "Colors", "33 different colors"),
            aboutItems: [
                "484 colorful bricks in 33 colors inspire open-ended building with no instructions needed.",
                "Includes windows, doors, wheels, and eyes — everything kids need to build houses, vehicles, and creatures.",
                "Compatible with all LEGO sets and stored in a sturdy, reusable yellow storage box."
            ]
        ),
        product(
            id: "rc_car_058",
            name: "Traxxas Slash 1/16 Scale 4X4 Short Course Racing Truck",
            brand: "Traxxas",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 199.99,
            rating: 4.5,
            reviewCount: 3_120,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "car",
            imageURL: "https://images.unsplash.com/photo-1581235720704-06d3acfcb36f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 53,
            searchKeywords: ["rc car", "traxxas", "remote control", "slash"],
            specifications: specs("Scale", "1/16", "Drive", "4X4", "Speed", "30+ mph"),
            aboutItems: [
                "True 4X4 short course truck rips through dirt, grass, and pavement at speeds over 30 mph.",
                "Waterproof electronics let you drive through puddles, mud, and wet grass without damage.",
                "Ready-to-run out of the box with a 2.4GHz TQ radio system, NiMH battery, and wall charger included."
            ],
            variants: variants("rc_car_058", name: "Color", values: ["Red/White", "Blue/Black"])
        ),
        product(
            id: "board_game_059",
            name: "Catan Board Game (Base Edition)",
            brand: "Catan Studio",
            departmentID: "toys",
            categoryID: "family_games",
            price: 34.99,
            rating: 4.7,
            reviewCount: 42_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "dice",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/4f/Board_game_pieces.jpg",
            popularityRank: 8,
            searchKeywords: ["board game", "catan", "settlers", "strategy game", "family"],
            specifications: specs("Players", "3-4", "Age", "10+", "Play Time", "60-120 min"),
            aboutItems: [
                "Trade, build, and settle the island of Catan in this award-winning strategy board game for 3-4 players.",
                "Over 40 million copies sold worldwide — the gateway game that launched modern board gaming.",
                "Every game is different thanks to the modular hexagonal board that creates a new island each time."
            ]
        ),
        product(
            id: "art_supplies_060",
            name: "Crayola Inspiration Art Case (140 Pieces)",
            brand: "Crayola",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 24.99,
            rating: 4.6,
            reviewCount: 19_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "paintpalette",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/fe/Crayola_Crayons_%2812709198284%29.jpg",
            popularityRank: 13,
            searchKeywords: ["art supplies", "crayola", "crayons", "markers", "kids art"],
            specifications: specs("Pieces", "140", "Includes", "Crayons, markers, colored pencils, paper", "Ages", "3+"),
            aboutItems: [
                "140-piece portable art studio includes crayons, washable markers, colored pencils, and paper sheets.",
                "Durable hard-shell carrying case keeps everything organized and travels easily to school, trips, or playdates.",
                "Non-toxic, safety-tested art supplies from Crayola — trusted by parents and teachers for over 100 years."
            ]
        ),
        product(
            id: "puzzle_061",
            name: "Ravensburger 1000-Piece World Map Antique Puzzle",
            brand: "Ravensburger",
            departmentID: "toys",
            categoryID: "family_games",
            price: 17.99,
            rating: 4.7,
            reviewCount: 8_940,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "puzzlepiece",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/11/Jigsaw_puzzle_in_progress.jpg",
            popularityRank: 46,
            searchKeywords: ["puzzle", "ravensburger", "1000 piece", "jigsaw"],
            specifications: specs("Pieces", "1,000", "Finished Size", "27\" x 20\"", "Quality", "Premium softclick technology"),
            aboutItems: [
                "1,000 precision-cut pieces with Ravensburger's Softclick technology — every piece fits perfectly.",
                "Beautiful antique-style world map design makes a stunning display piece when framed after completion.",
                "Premium linen-finish paper reduces glare and provides a tactile, high-quality puzzling experience."
            ]
        ),
        product(
            id: "robot_kit_062",
            name: "LEGO MINDSTORMS Robot Inventor Building Set (949 Pieces)",
            brand: "LEGO",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 299.99,
            originalPrice: 359.99,
            rating: 4.6,
            reviewCount: 1_850,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "gearshape.2",
            imageURL: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 47,
            searchKeywords: ["robot", "lego mindstorms", "coding", "stem", "programmable"],
            specifications: specs("Pieces", "949", "Hub", "Bluetooth with 6-axis gyro", "Ages", "10+"),
            aboutItems: [
                "Build and code 5 unique robots with 949 pieces, motors, sensors, and a programmable intelligent hub.",
                "Scratch-based coding via the LEGO MINDSTORMS app teaches real programming concepts through play.",
                "Compatible with Python for advanced builders — grow from beginner to expert with one set."
            ],
            promotions: [promotion(id: "save_lego_062", title: "Save 17%", detail: "Save 17% on LEGO MINDSTORMS Robot Inventor.", badgeText: "Save 17%")]
        ),
        product(
            id: "plush_bear_063",
            name: "Jellycat Bartholomew Bear Plush, Medium (12\")",
            brand: "Jellycat",
            departmentID: "toys",
            categoryID: "family_games",
            price: 27.50,
            rating: 4.9,
            reviewCount: 5_620,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "teddybear",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/60/2023_Pluszowy_mi%C5%9B.jpg",
            popularityRank: 48,
            searchKeywords: ["plush", "jellycat", "teddy bear", "stuffed animal"],
            specifications: specs("Size", "12\" tall", "Material", "Polyester plush", "Ages", "Birth+"),
            aboutItems: [
                "Irresistibly soft and squishy polyester plush with Jellycat's signature floppy, huggable design.",
                "12-inch medium size is perfect for cuddling, display, and gifting for babies and children of all ages.",
                "Award-winning British design — surface washable and safe from birth, meeting all global toy safety standards."
            ]
        ),
        product(
            id: "outdoor_blaster_064",
            name: "Nerf Elite 2.0 Commander RD-6 Blaster",
            brand: "Nerf",
            departmentID: "toys",
            categoryID: "family_games",
            price: 11.99,
            rating: 4.4,
            reviewCount: 13_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "target",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/f4/NERF_N-Strike_Elite_MEGA_Mastodon.jpg",
            popularityRank: 49,
            searchKeywords: ["nerf", "blaster", "nerf gun", "outdoor toys"],
            specifications: specs("Darts", "12 included", "Rotating Drum", "6-dart", "Ages", "8+"),
            aboutItems: [
                "6-dart rotating drum fires one dart at a time for fast-action, slam-fire battling.",
                "Comes with 12 Official Nerf Elite foam darts — designed for distance and accuracy.",
                "Tactical rails let you customize with Nerf accessories — lightweight and easy to grip for ages 8+."
            ]
        ),

        // ── Pet Supplies ────────────────────────────────────────────

        product(
            id: "dog_treats_065",
            name: "Blue Buffalo Blue Bits Tender Beef Training Treats",
            brand: "Blue Buffalo",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 9.99,
            rating: 4.6,
            reviewCount: 32_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "dog",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/b7/Dog_with_treat.jpg",
            popularityRank: 7,
            searchKeywords: ["dog treats", "blue buffalo", "training treats", "beef"],
            specifications: specs("Weight", "16 oz", "Protein Source", "Real beef", "DHA", "Yes, for cognitive support"),
            aboutItems: [
                "Soft, moist training treats made with real beef as the first ingredient — dogs love the taste.",
                "Bite-sized morsels are perfect for training sessions, rewards, or an everyday snack.",
                "Enhanced with DHA and ARA to support cognitive development — no chicken by-product meals, corn, wheat, or soy."
            ],
            variants: variants("dog_treats_065", name: "Flavor", values: ["Beef", "Chicken", "Salmon"]),
            promotions: [promotion(id: "subscribe_treats_065", title: "Subscribe & Save", detail: "Subscribe & Save 15% on recurring deliveries.", badgeText: "Subscribe & Save 15%")]
        ),
        product(
            id: "cat_litter_066",
            name: "Dr. Elsey's Ultra Premium Clumping Cat Litter (40 lb)",
            brand: "Dr. Elsey's",
            departmentID: "pet_supplies",
            categoryID: "cat_supplies",
            price: 21.99,
            rating: 4.7,
            reviewCount: 74_200,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "cat",
            imageURL: "https://images.unsplash.com/photo-1586674638328-a4406842408f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 19,
            searchKeywords: ["cat litter", "dr elseys", "clumping", "unscented"],
            specifications: specs("Weight", "40 lb", "Type", "Clumping clay", "Dust", "99.9% dust-free"),
            aboutItems: [
                "Hard-clumping formula creates tight, easy-to-scoop clumps that lock in odor on contact.",
                "99.9% dust-free and hypoallergenic — safe for cats and families with allergies or sensitivities.",
                "Veterinarian recommended and unscented — ideal for multi-cat households and automatic litter boxes."
            ],
            promotions: [promotion(id: "coupon_litter_066", title: "Coupon", detail: "Apply $3 off coupon at checkout.", badgeText: "$3 off")]
        ),
        product(
            id: "pet_bed_067",
            name: "Furhaven Orthopedic Dog Bed, L-Shaped Chaise Lounger",
            brand: "Furhaven",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 39.99,
            originalPrice: 49.99,
            rating: 4.4,
            reviewCount: 89_100,
            deliveryEstimate: "FREE delivery Saturday",
            imageSystemName: "bed.double",
            imageURL: "https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 20,
            searchKeywords: ["dog bed", "furhaven", "orthopedic", "large dog bed"],
            specifications: specs("Foam", "Orthopedic egg-crate", "Size", "Large (36\" x 27\")", "Cover", "Removable, machine-washable"),
            aboutItems: [
                "Orthopedic egg-crate foam relieves pressure on joints and muscles — ideal for senior dogs or post-surgery recovery.",
                "L-shaped chaise design with a bolster pillow supports head and neck while napping.",
                "Removable, machine-washable faux-fur cover zips off easily for hassle-free cleaning."
            ],
            variants: variants("pet_bed_067", name: "Size", values: ["Medium", "Large", "Jumbo"], priceAdjustments: ["Medium": -10.00, "Jumbo": 20.00]) +
                variants("pet_bed_067", name: "Color", values: ["Gray", "Espresso", "Marine Blue"]),
            promotions: [promotion(id: "save_bed_067", title: "Save 20%", detail: "Save 20% on Furhaven orthopedic dog bed.", badgeText: "Save 20%")]
        ),
        product(
            id: "leash_harness_068",
            name: "Rabbitgoo No-Pull Dog Harness with Front & Back Leash Clips",
            brand: "Rabbitgoo",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 15.99,
            rating: 4.5,
            reviewCount: 114_000,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "circle.dotted",
            imageURL: "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 22,
            searchKeywords: ["dog harness", "rabbitgoo", "no pull", "leash"],
            specifications: specs("Clips", "Front + back", "Material", "Oxford nylon", "Reflective", "Yes"),
            aboutItems: [
                "Front and back leash clips give you two walking modes — no-pull training and everyday strolling.",
                "Adjustable chest and neck straps with 4 adjustment points ensure a snug, custom fit for any breed.",
                "Reflective nylon straps and lightweight breathable mesh keep your dog visible and comfortable day or night."
            ],
            variants: variants("leash_harness_068", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("leash_harness_068", name: "Color", values: ["Black", "Red", "Blue"])
        ),
        product(
            id: "scratching_post_069",
            name: "SmartCat Ultimate Scratching Post, 32\" Tall Sisal",
            brand: "SmartCat",
            departmentID: "pet_supplies",
            categoryID: "cat_supplies",
            price: 44.99,
            rating: 4.6,
            reviewCount: 21_300,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "cat",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/ca/Homemade_scratching_post.jpg",
            popularityRank: 50,
            searchKeywords: ["scratching post", "smartcat", "cat furniture", "sisal"],
            specifications: specs("Height", "32\"", "Material", "Woven sisal fiber", "Base", "16\" x 16\" wood"),
            aboutItems: [
                "32 inches tall so cats can fully stretch while scratching — satisfies their natural instinct and saves furniture.",
                "Durable woven sisal fiber lasts for years of heavy use without fraying or unraveling.",
                "Heavy 16\" x 16\" wooden base stays rock-solid and won't tip over, even with large cats."
            ]
        ),
        product(
            id: "automatic_feeder_070",
            name: "PetSafe Smart Feed 2nd Gen Automatic Dog and Cat Feeder",
            brand: "PetSafe",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 149.95,
            rating: 4.3,
            reviewCount: 5_810,
            deliveryEstimate: "FREE delivery Thursday",
            imageSystemName: "cup.and.saucer",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/a4/Futterautomat_mit_RFID_-_pet_feeder%2C_cat_feeder%2C_RFID_controlled.JPG",
            popularityRank: 54,
            searchKeywords: ["pet feeder", "petsafe", "automatic feeder", "smart feeder"],
            specifications: specs("Capacity", "24 cups", "Meals", "Up to 12 per day", "Control", "Wi-Fi app + Alexa compatible"),
            aboutItems: [
                "Schedule up to 12 meals per day from anywhere using the My PetSafe app on your phone.",
                "24-cup hopper holds enough dry food for days — Slow Feed mode dispenses gradually to reduce bloating.",
                "Works with Smart Assistant for voice-controlled feeding and sends meal notifications to your phone."
            ]
        ),
        product(
            id: "grooming_brush_071",
            name: "FURminator Undercoat Deshedding Tool for Medium-to-Large Dogs",
            brand: "FURminator",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 32.99,
            rating: 4.5,
            reviewCount: 47_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "comb",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/a8/Dog_brush.JPG",
            popularityRank: 55,
            searchKeywords: ["deshedding", "furminator", "grooming", "dog brush"],
            specifications: specs("Edge", "Stainless steel", "Coat Length", "Long hair", "FURejector", "One-click fur release"),
            aboutItems: [
                "Stainless steel deShedding edge reaches through the topcoat to safely remove loose undercoat hair.",
                "Reduces shedding up to 90% with regular use — keeps your home, car, and clothes fur-free.",
                "FURejector button releases collected fur with one click — no pulling or tugging on your dog's coat."
            ]
        ),
        product(
            id: "dental_chews_072",
            name: "Greenies Original Dental Dog Treats, Regular Size (36 Count)",
            brand: "Greenies",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 28.99,
            rating: 4.6,
            reviewCount: 53_600,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "dog",
            imageURL: "https://images.unsplash.com/photo-1568640347023-a616a30bc3bd?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 21,
            searchKeywords: ["dental chews", "greenies", "dog dental", "teeth cleaning"],
            specifications: specs("Count", "36", "Size", "Regular (25-50 lbs)", "VOHC Accepted", "Yes"),
            aboutItems: [
                "VOHC-accepted dental chews clinically proven to clean teeth, freshen breath, and reduce tartar buildup.",
                "Unique chewy texture reaches down to the gumline for a thorough clean dogs actually enjoy.",
                "Made with natural, easy-to-digest ingredients plus vitamins, minerals, and nutrients in every treat."
            ],
            variants: variants("dental_chews_072", name: "Dog Size", values: ["Petite", "Regular", "Large"], priceAdjustments: ["Petite": -5.00, "Large": 5.00]),
            promotions: [promotion(id: "save_chews_072", title: "Save 20%", detail: "Save 20% on your first Subscribe & Save order.", badgeText: "Save 20%")]
        ),

        // ── Sports & Outdoors ───────────────────────────────────────

        product(
            id: "yoga_mat_073",
            name: "Manduka PRO Yoga Mat, 6mm Thick (71\")",
            brand: "Manduka",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 92.00,
            originalPrice: 120.00,
            rating: 4.7,
            reviewCount: 11_200,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "figure.yoga",
            imageURL: "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 56,
            searchKeywords: ["yoga mat", "manduka", "pro", "thick", "non-slip"],
            specifications: specs("Thickness", "6mm", "Length", "71\"", "Material", "Closed-cell PVC, lifetime guarantee"),
            aboutItems: [
                "Dense 6mm cushioning protects knees and joints without sacrificing stability in standing poses.",
                "Closed-cell surface prevents sweat and bacteria from absorbing into the mat — just wipe clean.",
                "Lifetime guarantee from Manduka — built for daily practice and designed to never end up in a landfill."
            ],
            variants: variants("yoga_mat_073", name: "Color", values: ["Black", "Teal", "Indulge"]),
            promotions: [promotion(id: "save_yoga_073", title: "Save 23%", detail: "Save 23% on Manduka PRO Yoga Mat.", badgeText: "Save 23%")]
        ),
        product(
            id: "water_bottle_074",
            name: "Hydro Flask Wide Mouth Insulated Water Bottle (32 oz)",
            brand: "Hydro Flask",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 44.95,
            rating: 4.8,
            reviewCount: 29_600,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "waterbottle",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/29/HydroFlask_Insulated_Bottle_%2829133242351%29.jpg",
            popularityRank: 12,
            searchKeywords: ["water bottle", "hydro flask", "insulated", "stainless steel"],
            specifications: specs("Capacity", "32 oz", "Insulation", "TempShield double-wall vacuum", "Cold", "24 hours / Hot 12 hours"),
            aboutItems: [
                "TempShield double-wall vacuum insulation keeps drinks ice-cold for 24 hours or hot for 12 hours.",
                "18/8 pro-grade stainless steel is durable, pure-tasting, and BPA-free — no flavor transfer.",
                "Powder-coated finish provides a slip-free grip while the wide mouth fits ice cubes and is easy to clean."
            ],
            variants: variants("water_bottle_074", name: "Color", values: ["Pacific", "Black", "White", "Dew"]),
            promotions: [promotion(id: "deal_bottle_074", title: "Limited time deal", detail: "Limited time deal on Hydro Flask bottles.", badgeText: "Limited time deal")]
        ),
        product(
            id: "resistance_bands_075",
            name: "Fit Simplify Resistance Loop Exercise Bands (Set of 5)",
            brand: "Fit Simplify",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 10.95,
            rating: 4.5,
            reviewCount: 142_000,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "figure.strengthtraining.traditional",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/cf/Strength_band.png",
            popularityRank: 57,
            searchKeywords: ["resistance bands", "exercise bands", "fit simplify", "workout"],
            specifications: specs("Bands", "5 resistance levels", "Material", "Natural latex", "Includes", "Carry bag + instruction guide"),
            aboutItems: [
                "Set of 5 color-coded bands from extra-light to extra-heavy — versatile for rehab, yoga, and strength training.",
                "Premium natural latex is durable, snap-resistant, and gentle on the skin during extended workouts.",
                "Includes a portable carry bag and illustrated exercise guide — over 142,000 five-star reviews on MegaMart."
            ]
        ),
        product(
            id: "camping_lantern_076",
            name: "Black Diamond Moji Rechargeable Camping Lantern",
            brand: "Black Diamond",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 29.99,
            originalPrice: 39.99,
            rating: 4.4,
            reviewCount: 4_440,
            deliveryEstimate: "FREE delivery Saturday",
            sellerName: "Black Diamond Equipment",
            imageSystemName: "flashlight.on.fill",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/28/Streamlight_LED_Camping_Lantern_-_The_Siege_%2841339394074%29.jpg",
            popularityRank: 74,
            searchKeywords: ["camping lantern", "black diamond", "rechargeable", "outdoor"],
            specifications: specs("Brightness", "200 lumens", "Runtime", "70 hours (low)", "Charging", "USB-C"),
            aboutItems: [
                "200-lumen LED lantern with a frosted globe casts warm, even light across the entire campsite.",
                "Rechargeable via USB-C with up to 70 hours of runtime on low — no disposable batteries needed.",
                "Compact, crushproof design clips to tent loops or hangs from a carabiner for hands-free lighting."
            ],
            promotions: [promotion(id: "deal_lantern_076", title: "Deal", detail: "Save 25% on Black Diamond camping lantern.", badgeText: "Deal")]
        ),
        product(
            id: "trail_backpack_077",
            name: "Osprey Talon 22 Hiking Backpack",
            brand: "Osprey",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 69.99,
            rating: 4.6,
            reviewCount: 5_903,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "backpack.fill",
            imageURL: "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 51,
            searchKeywords: ["backpack", "osprey", "talon", "hiking", "daypack"],
            specifications: specs("Capacity", "22 L", "Reservoir", "Hydration compatible (3L)", "Weight", "1 lb 9 oz"),
            aboutItems: [
                "22-liter capacity with a dedicated hydration sleeve fits a 3L reservoir for all-day trail access to water.",
                "AirScape back panel and adjustable hip belt distribute weight evenly for a comfortable, ventilated carry.",
                "Scratch-free zippered sunglass pocket, trekking pole attachments, and stretch mesh side pockets for quick access."
            ],
            variants: variants("trail_backpack_077", name: "Color", values: ["Graphite", "Moss", "Copper"])
        ),
        product(
            id: "dumbbell_set_078",
            name: "Bowflex SelectTech 552 Adjustable Dumbbells (Pair)",
            brand: "Bowflex",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 199.99,
            originalPrice: 249.99,
            rating: 4.6,
            reviewCount: 6_120,
            deliveryEstimate: "FREE delivery Monday",
            imageSystemName: "dumbbell.fill",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Kurzhanteln_2_x_15_kg_1v2.jpg",
            popularityRank: 75,
            searchKeywords: ["dumbbells", "bowflex", "adjustable", "selecttech", "weights"],
            specifications: specs("Weight Range", "5-52.5 lb each", "Pairs", "2 dumbbells", "Adjustment", "Turn-dial mechanism"),
            aboutItems: [
                "Each dumbbell adjusts from 5 to 52.5 lbs in 2.5-lb increments — replaces 15 sets of weights.",
                "Turn-dial mechanism switches weight in seconds so you can keep rest times short between sets.",
                "Compact design saves space — an entire weight rack fits on a single stand in your home gym."
            ],
            promotions: [promotion(id: "save_dumbbells_078", title: "Save 20%", detail: "Save 20% versus the original list price.", badgeText: "Save 20%")]
        ),
        product(
            id: "pickleball_set_079",
            name: "JOOLA Ben Johns Hyperion CFS 16mm Pickleball Paddle",
            brand: "JOOLA",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 59.99,
            rating: 4.7,
            reviewCount: 3_780,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "sportscourt.fill",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/71/A_pickleball_paddle_with_two_pickleballs.jpg",
            popularityRank: 76,
            searchKeywords: ["pickleball", "joola", "paddle", "ben johns", "outdoor sports"],
            specifications: specs("Core", "Reactive Polymer Honeycomb", "Surface", "Carbon Friction", "Weight", "7.7-8.1 oz"),
            aboutItems: [
                "Ben Johns signature paddle with a Carbon Friction surface for maximum spin control and placement.",
                "Reactive Polymer Honeycomb core delivers a soft feel with explosive pop — the paddle of the #1 player in the world.",
                "16mm edge-to-edge sweet spot provides forgiveness and consistency on every shot."
            ]
        ),
        product(
            id: "foam_roller_080",
            name: "TriggerPoint GRID Foam Roller for Exercise (13\")",
            brand: "TriggerPoint",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 27.99,
            rating: 4.6,
            reviewCount: 8_004,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "rectangle.compress.vertical",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/41/Hartschaumrolle.jpg",
            popularityRank: 77,
            searchKeywords: ["foam roller", "triggerpoint", "grid", "recovery", "mobility"],
            specifications: specs("Length", "13\"", "Density", "Multi-density EVA foam", "Surface", "GRID pattern for targeted massage"),
            aboutItems: [
                "Patented GRID 3D surface channels blood and oxygen through muscle tissue for faster recovery.",
                "Multi-density EVA foam exterior over a rigid, hollow core provides firm, consistent pressure.",
                "Compact 13-inch size fits in any gym bag — rated to support users up to 500 lbs."
            ]
        ),

        // ── New Products ──────────────────────────────────────────────

        // Electronics
        product(
            id: "wireless_earbuds_088",
            name: "Samsung Galaxy Buds2 Pro True Wireless Earbuds",
            brand: "Samsung",
            departmentID: "electronics",
            categoryID: "audio",
            price: 149.99,
            originalPrice: 199.99,
            rating: 4.5,
            reviewCount: 15_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "airpodspro",
            imageURL: "https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 58,
            searchKeywords: ["earbuds", "samsung", "galaxy buds", "wireless", "bluetooth", "anc"],
            specifications: specs("Connection", "Bluetooth 5.3", "ANC", "Intelligent Active Noise Cancellation", "Battery", "5h (18h with case)"),
            aboutItems: [
                "Intelligent ANC adapts to your surroundings in real time — blocks noise on commutes and lets sound in when needed.",
                "24-bit Hi-Fi audio with 360 Audio delivers immersive, studio-quality sound in a compact earbud.",
                "IPX7 water resistance and up to 18 hours total battery with the wireless charging case."
            ],
            variants: variants("wireless_earbuds_088", name: "Color", values: ["Graphite", "White", "Bora Purple"]),
            promotions: [promotion(id: "save_buds_088", title: "Save $50", detail: "Save $50 on Samsung Galaxy Buds2 Pro.", badgeText: "Save $50")]
        ),
        product(
            id: "usbc_hub_089",
            name: "Satechi USB-C Multiport Pro Adapter, 4K HDMI",
            brand: "Satechi",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 79.99,
            rating: 4.4,
            reviewCount: 5_430,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "cable.connector",
            imageURL: "https://images.unsplash.com/photo-1625948515291-69613efd103f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 59,
            searchKeywords: ["usb hub", "satechi", "usb-c", "hdmi", "adapter", "dongle"],
            specifications: specs("Ports", "USB-C PD, HDMI 4K, USB-A, SD/Micro SD", "Charging", "60W Pass-through", "Material", "Aluminum"),
            aboutItems: [
                "Expands your laptop with 4K HDMI, USB-A, SD/Micro SD, and 60W USB-C pass-through charging in one hub.",
                "Sleek aluminum body matches MacBook and ultrabook designs with no driver installation required.",
                "Compact enough to slip into any laptop bag — perfect for presentations, photo transfers, and travel."
            ]
        ),

        // Home & Kitchen
        product(
            id: "instant_pot_090",
            name: "Instant Pot Duo 7-in-1 Electric Pressure Cooker (6 Qt)",
            brand: "Instant Pot",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 89.99,
            originalPrice: 99.99,
            rating: 4.7,
            reviewCount: 185_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "cooktop",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/31/Instant_Pot_DUO60_pressure_cooker.jpg",
            popularityRank: 60,
            searchKeywords: ["instant pot", "pressure cooker", "slow cooker", "rice cooker", "kitchen"],
            specifications: specs("Capacity", "6 Qt", "Functions", "Pressure Cook, Slow Cook, Rice, Steam, Sauté, Yogurt, Keep Warm", "Material", "Stainless steel inner pot"),
            aboutItems: [
                "7-in-1 functionality replaces multiple kitchen appliances in one space-saving design.",
                "#1 bestselling multi-cooker with over 185,000 five-star reviews.",
                "Safety features include overheat protection and lid-lock detection."
            ],
            promotions: [promotion(id: "coupon_instant_pot_090", title: "Coupon", detail: "Apply $10 off coupon at checkout.", badgeText: "$10 off")]
        ),
        product(
            id: "smart_thermostat_091",
            name: "Google Nest Learning Thermostat (4th Gen)",
            brand: "Google",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 249.99,
            rating: 4.3,
            reviewCount: 8_620,
            deliveryEstimate: "FREE delivery Tue, Mar 24 - Thu, Mar 26",
            imageSystemName: "thermometer",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/cd/Nest_Thermostat_3rd_Generation_%28Creative_Commons%29_%2845096474951%29.jpg",
            popularityRank: 61,
            searchKeywords: ["thermostat", "nest", "google", "smart home", "energy saving"],
            specifications: specs("Compatibility", "Works with 85% of HVAC systems", "Display", "LCD borderless display", "Connectivity", "Wi-Fi, Bluetooth, Matter"),
            aboutItems: [
                "Learns your schedule and programs itself to save energy automatically.",
                "Borderless display blends into any home décor and shows weather at a glance.",
                "Works with Google Home, Smart Assistant, and Apple HomeKit via Matter."
            ]
        ),

        // Books
        product(
            id: "scifi_novel_092",
            name: "Project Hail Mary by Andy Weir (Paperback)",
            brand: "Ballantine Books",
            departmentID: "books",
            categoryID: "fiction_books",
            price: 12.99,
            originalPrice: 17.00,
            rating: 4.8,
            reviewCount: 86_700,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "book",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ab/Project_Hail_Mary_pins.jpg",
            popularityRank: 62,
            searchKeywords: ["sci-fi", "andy weir", "project hail mary", "space", "novel"],
            specifications: specs("Format", "Paperback", "Pages", "496", "Publisher", "Ballantine Books"),
            aboutItems: [
                "From the author of The Martian — a lone astronaut must save Earth from an extinction-level threat.",
                "#1 New York Times bestseller and Goodreads Choice Award winner.",
                "Now a major motion picture starring Ryan Gosling."
            ]
        ),
        product(
            id: "finance_book_093",
            name: "The Psychology of Money by Morgan Housel (Paperback)",
            brand: "Harriman House",
            departmentID: "books",
            categoryID: "learning_books",
            price: 14.99,
            originalPrice: 19.99,
            rating: 4.7,
            reviewCount: 72_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "text.book.closed",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/0a/Paperback_book_with_green_cover.jpg",
            popularityRank: 63,
            searchKeywords: ["finance", "psychology", "money", "investing", "morgan housel"],
            specifications: specs("Format", "Paperback", "Pages", "256", "Publisher", "Harriman House"),
            aboutItems: [
                "19 short stories exploring the strange ways people think about money.",
                "Over 4 million copies sold — a modern classic in personal finance.",
                "Wall Street Journal and New York Times bestseller."
            ]
        ),

        // Clothing
        product(
            id: "womens_sneakers_094",
            name: "New Balance 574 Core Women's Sneakers",
            brand: "New Balance",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 79.99,
            rating: 4.6,
            reviewCount: 22_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1491553895911-0055eca6402d?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 64,
            searchKeywords: ["sneakers", "new balance", "574", "women", "casual shoes"],
            specifications: specs("Closure", "Lace-up", "Sole", "ENCAP midsole", "Material", "Suede / Mesh upper"),
            aboutItems: [
                "Iconic 574 silhouette with a premium suede and mesh upper for a retro-modern streetwear look.",
                "ENCAP midsole technology combines lightweight foam with a durable polyurethane rim for all-day cushioning.",
                "Classic lace-up closure with a padded collar and tongue for a comfortable, secure fit."
            ],
            variants: variants("womens_sneakers_094", name: "Size", values: ["6", "7", "8", "9"]) +
                variants("womens_sneakers_094", name: "Color", values: ["Grey/White", "Navy/Red", "Black/White"])
        ),
        product(
            id: "puffer_vest_095",
            name: "Patagonia Down Sweater Vest",
            brand: "Patagonia",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 179.00,
            rating: 4.7,
            reviewCount: 3_480,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "tshirt",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/b8/Adidas_Helionic_Down_vest.jpg",
            popularityRank: 65,
            searchKeywords: ["vest", "patagonia", "down vest", "puffer", "outdoor"],
            specifications: specs("Fill", "800-fill-power traceable goose down", "Shell", "Recycled ripstop nylon", "Weight", "8.5 oz"),
            aboutItems: [
                "800-fill-power traceable goose down delivers exceptional warmth at just 8.5 oz — packs into its own internal pocket.",
                "Recycled ripstop nylon shell is windproof and treated with a DWR finish for light rain protection.",
                "Fair Trade Certified sewn — Patagonia donates 1% of sales to environmental nonprofits."
            ],
            variants: variants("puffer_vest_095", name: "Size", values: ["XS", "S", "M", "L"]) +
                variants("puffer_vest_095", name: "Color", values: ["Black", "Nouveau Green", "Borealis Green"])
        ),

        // Beauty & Personal Care
        product(
            id: "electric_toothbrush_096",
            name: "Oral-B iO Series 9 Rechargeable Electric Toothbrush",
            brand: "Oral-B",
            departmentID: "beauty",
            categoryID: "hair_care",
            price: 199.99,
            originalPrice: 249.99,
            rating: 4.6,
            reviewCount: 11_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "mouth",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/f/fd/Oral-B_Pro_760_Black_Edition_20220921_HOF04732.png",
            popularityRank: 66,
            searchKeywords: ["toothbrush", "oral-b", "electric", "io series 9", "rechargeable"],
            specifications: specs("Technology", "iO Micro-Vibration", "Modes", "7 Smart Cleaning Modes", "Battery", "14 days per charge"),
            aboutItems: [
                "Dentist-inspired round brush head delivers a professional clean feel every day.",
                "Interactive color display with a personalized 3D teeth tracking AI coach.",
                "Magnetic charger provides a full charge in approximately 3 hours."
            ],
            promotions: [promotion(id: "save_toothbrush_096", title: "Save $50", detail: "Save $50 on Oral-B iO Series 9.", badgeText: "Save $50")]
        ),
        product(
            id: "face_mask_097",
            name: "Innisfree Super Volcanic Pore Clay Mask (3.38 oz)",
            brand: "Innisfree",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 13.99,
            rating: 4.4,
            reviewCount: 18_600,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "drop",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e3/Facial_mask.jpg",
            popularityRank: 67,
            searchKeywords: ["face mask", "clay mask", "innisfree", "pore care", "skincare"],
            specifications: specs("Size", "3.38 fl oz (100 ml)", "Skin Type", "Oily / Combination", "Key Ingredient", "Jeju Volcanic Cluster"),
            aboutItems: [
                "Made with Jeju volcanic clusters to deeply absorb excess sebum and minimize pores.",
                "Cooling clay formula provides a spa-like experience at home.",
                "Dermatologically tested, free of parabens, mineral oil, and synthetic dyes."
            ]
        ),

        // Groceries & Household
        product(
            id: "energy_drinks_098",
            name: "Celsius Sparkling Energy Drink Variety Pack (12 Count)",
            brand: "Celsius",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 18.99,
            rating: 4.5,
            reviewCount: 38_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "bolt",
            imageURL: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 68,
            searchKeywords: ["energy drink", "celsius", "fitness drink", "sparkling", "no sugar"],
            specifications: specs("Count", "12 cans", "Calories", "10 per can", "Caffeine", "200mg natural caffeine"),
            aboutItems: [
                "Clinically proven to boost metabolism with MetaPlus blend of green tea and ginger.",
                "Zero sugar, no artificial preservatives or flavors, and only 10 calories per can.",
                "Variety pack includes Sparkling Orange, Wild Berry, Kiwi Guava, and Watermelon."
            ]
        ),
        product(
            id: "trash_bags_099",
            name: "Glad ForceFlex Plus Tall Kitchen Trash Bags, 13 Gal (80 Count)",
            brand: "Glad",
            departmentID: "groceries",
            categoryID: "household_essentials",
            price: 16.99,
            rating: 4.7,
            reviewCount: 64_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "trash",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/2d/Black_garbage_bag.jpg",
            popularityRank: 69,
            searchKeywords: ["trash bags", "glad", "forceflex", "garbage bags", "kitchen"],
            specifications: specs("Count", "80 bags", "Capacity", "13 gallon", "Features", "Stretchable strength, leak protection"),
            aboutItems: [
                "Stretchable ForceFlex technology expands around sharp edges and heavy loads without ripping.",
                "LeakGuard protection with a reinforced bottom prevents messy leaks and drips.",
                "80-count box of 13-gallon bags with Gain Original scent that neutralizes kitchen trash odors."
            ],
            promotions: [promotion(id: "subscribe_trash_099", title: "Subscribe & Save", detail: "Subscribe & Save 15% on recurring deliveries.", badgeText: "Subscribe & Save 15%")]
        ),

        // Office & Workspace
        product(
            id: "webcam_100",
            name: "Logitech C920x HD Pro Webcam, Full HD 1080p",
            brand: "Logitech",
            departmentID: "office",
            categoryID: "workspace",
            price: 59.99,
            rating: 4.5,
            reviewCount: 28_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "web.camera",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/79/Webcam_%28Logitech_c922%29.jpg",
            popularityRank: 70,
            searchKeywords: ["webcam", "logitech", "c920", "1080p", "video call", "zoom"],
            specifications: specs("Resolution", "Full HD 1080p / 30fps", "Microphone", "Dual stereo", "Field of View", "78° diagonal"),
            aboutItems: [
                "Full HD 1080p video calling and recording with automatic light correction.",
                "Dual built-in mics with noise reduction for clear audio on every call.",
                "Universal clip fits laptops, LCD, and monitors — no software installation required."
            ]
        ),
        product(
            id: "sticky_notes_101",
            name: "Post-it Super Sticky Notes, 3x3 in, Assorted Colors (24 Pads)",
            brand: "Post-it",
            departmentID: "office",
            categoryID: "office_supplies",
            price: 22.99,
            rating: 4.8,
            reviewCount: 44_700,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "note.text",
            imageURL: "https://images.unsplash.com/photo-1586953208448-b95a79798f07?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 71,
            searchKeywords: ["sticky notes", "post-it", "office supplies", "notes", "stationery"],
            specifications: specs("Size", "3\" x 3\"", "Sheets", "70 per pad (1,680 total)", "Colors", "Assorted brights"),
            aboutItems: [
                "Super Sticky adhesive holds stronger and longer on more surfaces than standard sticky notes.",
                "1,680 sheets across 24 pads in bright assorted colors for color-coding tasks, ideas, and reminders.",
                "Made with sustainably sourced paper and packaged in recyclable material — 3M's #1 selling note brand."
            ],
            promotions: [promotion(id: "buy2_sticky_101", title: "Buy 2, save 10%", detail: "Buy 2 or more, save 10% on each.", badgeText: "Buy 2, save 10%")]
        ),

        // Toys & Games
        product(
            id: "card_game_102",
            name: "Exploding Kittens Card Game — Original Edition",
            brand: "Exploding Kittens",
            departmentID: "toys",
            categoryID: "family_games",
            price: 19.99,
            rating: 4.7,
            reviewCount: 68_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "suit.heart",
            imageURL: "https://images.unsplash.com/photo-1529699211952-734e80c4d42b?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 72,
            searchKeywords: ["card game", "exploding kittens", "party game", "family game"],
            specifications: specs("Players", "2-5", "Ages", "7+", "Play Time", "15 minutes"),
            aboutItems: [
                "A highly strategic kitty-powered version of Russian Roulette — by the creators of The Oatmeal.",
                "The most backed game in Kickstarter history with over 9 million copies sold.",
                "Easy to learn and quick to play — perfect for parties, game nights, and families."
            ]
        ),
        product(
            id: "science_kit_103",
            name: "National Geographic Mega Fossil Dig Kit — 15 Real Fossils",
            brand: "National Geographic",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 29.99,
            rating: 4.6,
            reviewCount: 12_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "fossil.shell",
            imageURL: "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 73,
            searchKeywords: ["science kit", "fossils", "national geographic", "stem", "kids"],
            specifications: specs("Fossils", "15 real specimens", "Ages", "8+", "Includes", "Dig tools + learning guide"),
            aboutItems: [
                "Dig up 15 real fossils including dinosaur bones, shark teeth, and ammonites.",
                "Full-color learning guide written by National Geographic scientists.",
                "STEM-approved educational toy that sparks curiosity in geology and paleontology."
            ]
        ),

        // Pet Supplies
        product(
            id: "cat_toy_104",
            name: "Potaroma Flopping Fish Cat Toy with Catnip, USB Rechargeable",
            brand: "Potaroma",
            departmentID: "pet_supplies",
            categoryID: "cat_supplies",
            price: 12.99,
            rating: 4.3,
            reviewCount: 42_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "cat",
            imageURL: "https://images.unsplash.com/photo-1742459385246-69934816e85f?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 74,
            searchKeywords: ["cat toy", "flopping fish", "interactive", "catnip", "potaroma"],
            specifications: specs("Power", "USB rechargeable", "Activation", "Touch-activated motion sensor", "Includes", "Catnip packet + USB cable"),
            aboutItems: [
                "Realistic flopping fish motion activated by your cat's touch — keeps indoor cats entertained.",
                "Built-in catnip pouch and refillable zipper for refreshing the scent.",
                "Rechargeable via USB — no batteries required. Auto-off after 10 minutes to save power."
            ]
        ),
        product(
            id: "dog_food_105",
            name: "Blue Buffalo Life Protection Formula Adult Dry Dog Food, Chicken (30 lb)",
            brand: "Blue Buffalo",
            departmentID: "pet_supplies",
            categoryID: "dog_supplies",
            price: 49.99,
            rating: 4.6,
            reviewCount: 54_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "dog",
            imageURL: "https://images.unsplash.com/photo-1589924691995-400dc9ecc119?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 75,
            searchKeywords: ["dog food", "blue buffalo", "dry food", "chicken", "adult dog"],
            specifications: specs("Weight", "30 lb", "Protein", "Deboned chicken + chicken meal", "LifeSource Bits", "Antioxidants, vitamins & minerals"),
            aboutItems: [
                "Made with real deboned chicken as the first ingredient for lean muscle support.",
                "Enhanced with LifeSource Bits — a precise blend of antioxidants, vitamins, and minerals.",
                "No chicken (or poultry) by-product meals, corn, wheat, soy, artificial flavors, or preservatives."
            ],
            promotions: [promotion(id: "coupon_dogfood_105", title: "Coupon", detail: "Apply $15 off coupon at checkout.", badgeText: "$15 off")]
        ),

        // Sports & Outdoors
        product(
            id: "jump_rope_106",
            name: "Crossrope Get Lean Jump Rope Set — Weighted Ropes",
            brand: "Crossrope",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 69.99,
            rating: 4.5,
            reviewCount: 6_400,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "figure.jumprope",
            imageURL: "https://images.unsplash.com/photo-1514996937319-344454492b37?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 78,
            searchKeywords: ["jump rope", "crossrope", "weighted", "fitness", "cardio"],
            specifications: specs("Ropes", "1/4 lb (speed) + 1 lb (power)", "Handle", "Slim ergonomic, fast clip", "App", "Crossrope app with workouts"),
            aboutItems: [
                "Patented fast-clip connection lets you swap between weight ropes in seconds.",
                "Weighted ropes provide a full-body workout — burn up to 1,000 calories per hour.",
                "Includes free access to the Crossrope app with 3,000+ guided workouts."
            ]
        ),
        product(
            id: "camping_tent_107",
            name: "Coleman Sundome 4-Person Camping Tent",
            brand: "Coleman",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 89.99,
            originalPrice: 119.99,
            rating: 4.4,
            reviewCount: 34_200,
            deliveryEstimate: "FREE delivery Monday",
            imageSystemName: "tent",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/18/Camping_tent_on_tarp.jpg",
            popularityRank: 79,
            searchKeywords: ["tent", "camping", "coleman", "4 person", "outdoor"],
            specifications: specs("Capacity", "4 person (9 x 7 ft)", "Height", "4 ft 11 in center", "Weather", "WeatherTec system with welded floors"),
            aboutItems: [
                "Easy 10-minute setup with snag-free Insta-Clip pole attachment and continuous pole sleeves.",
                "WeatherTec system with patented welded floors and inverted seams keeps you dry.",
                "Large windows and ground vent for enhanced airflow on warm nights."
            ],
            promotions: [promotion(id: "deal_tent_107", title: "Deal", detail: "Save 25% on Coleman Sundome camping tent.", badgeText: "Deal")]
        ),

        // ── Additional Bestsellers ────────────────────────────────────

        // Electronics
        product(
            id: "airpods_pro_108",
            name: "Apple AirPods Pro (2nd Generation) with MagSafe Charging Case (USB‑C)",
            brand: "Apple",
            departmentID: "electronics",
            categoryID: "audio",
            price: 189.99,
            originalPrice: 249.00,
            rating: 4.7,
            reviewCount: 112_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "airpodspro",
            imageURL: "https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 80,
            searchKeywords: ["airpods", "apple", "earbuds", "noise cancelling", "wireless"],
            specifications: specs("Chip", "Apple H2", "ANC", "2x more Active Noise Cancellation", "Battery", "6h (30h with case)"),
            aboutItems: [
                "Apple H2 chip delivers 2x more active noise cancellation than the previous generation.",
                "Adaptive Transparency dynamically reduces harsh environmental noise like construction or sirens.",
                "Personalized Spatial Audio with dynamic head tracking for immersive, theater-like sound."
            ],
            variants: variants("airpods_pro_108", name: "Case", values: ["MagSafe (USB-C)", "MagSafe (Lightning)"]),
            promotions: [promotion(id: "save_airpods_108", title: "Save $59", detail: "Save $59 on AirPods Pro (2nd Gen).", badgeText: "Save $59")]
        ),
        product(
            id: "kindle_paperwhite_109",
            name: "PaperLite Reader (11th Generation) — 6.8\" Display, 16 GB",
            brand: "MegaMart",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 139.99,
            rating: 4.7,
            reviewCount: 67_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "book.closed",
            imageURL: "https://images.unsplash.com/photo-1543002588-bfa74002ed7e?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 81,
            searchKeywords: ["paperlite", "e-reader", "paperwhite", "ebook", "reading"],
            specifications: specs("Display", "6.8\" glare-free 300 ppi", "Storage", "16 GB", "Battery", "Up to 10 weeks"),
            aboutItems: [
                "6.8-inch glare-free display with adjustable warm light for comfortable reading day or night.",
                "IPX8 rated waterproof — read in the bath, by the pool, or at the beach worry-free.",
                "Up to 10 weeks of battery life on a single charge with USB-C fast charging."
            ]
        ),
        product(
            id: "power_bank_110",
            name: "Anker PowerCore 26800mAh Portable Charger with Dual Input",
            brand: "Anker",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 65.99,
            rating: 4.6,
            reviewCount: 38_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "battery.100",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/75/Portable_power_bank.jpg",
            popularityRank: 82,
            searchKeywords: ["power bank", "anker", "portable charger", "battery", "travel"],
            specifications: specs("Capacity", "26,800 mAh", "Output", "3A Dual USB", "Recharge", "6.5 hours (dual input)"),
            aboutItems: [
                "Massive 26,800 mAh capacity charges an iPhone over 6 times or a Galaxy S23 nearly 5 times.",
                "Dual USB ports with PowerIQ technology detect and deliver the fastest charge for any connected device.",
                "MultiProtect safety system with 10-point protection for worry-free charging at home or on the go."
            ]
        ),

        // Home & Kitchen
        product(
            id: "stand_mixer_111",
            name: "KitchenAid Classic Plus 4.5-Quart Tilt-Head Stand Mixer",
            brand: "KitchenAid",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 279.99,
            originalPrice: 329.99,
            rating: 4.8,
            reviewCount: 74_200,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "takeoutbag.and.cup.and.straw",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/4a/KitchenAid_Stand_Mixer.jpg",
            popularityRank: 83,
            searchKeywords: ["stand mixer", "kitchenaid", "baking", "mixer", "kitchen"],
            specifications: specs("Capacity", "4.5 Qt stainless steel bowl", "Motor", "275W, 10 speeds", "Attachments", "Flat beater, dough hook, wire whip"),
            aboutItems: [
                "10-speed tilt-head stand mixer handles everything from slow stir to fast whip with ease.",
                "Includes flat beater, dough hook, and 6-wire whip — plus a power hub for 10+ optional attachments.",
                "Iconic KitchenAid design available in 20+ colors to match any kitchen."
            ],
            variants: variants("stand_mixer_111", name: "Color", values: ["Empire Red", "Silver", "Onyx Black", "White"]),
            promotions: [promotion(id: "coupon_mixer_111", title: "Coupon", detail: "Apply $20 off coupon at checkout.", badgeText: "$20 off")]
        ),
        product(
            id: "candle_set_112",
            name: "Yankee Candle Large Jar, Midsummer's Night (22 oz)",
            brand: "Yankee Candle",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 30.99,
            originalPrice: 34.99,
            rating: 4.7,
            reviewCount: 23_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "flame",
            imageURL: "https://images.unsplash.com/photo-1602874801007-bd458bb1b8b6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 84,
            searchKeywords: ["candle", "yankee candle", "scented", "home fragrance"],
            specifications: specs("Size", "22 oz", "Burn Time", "110-150 hours", "Wax", "Premium-grade paraffin"),
            aboutItems: [
                "Premium paraffin wax with natural fiber wick delivers a clean, consistent burn for 110-150 hours.",
                "Midsummer's Night scent blends musk, patchouli, sage, and mahogany cologne for a warm, masculine fragrance.",
                "Iconic glass jar with lid preserves fragrance between burns — a timeless home décor piece."
            ],
            promotions: [promotion(id: "deal_candle_112", title: "Deal", detail: "Save 11% on Yankee Candle Large Jar.", badgeText: "Deal")]
        ),
        product(
            id: "ring_doorbell_113",
            name: "Ring Video Doorbell 4 — Enhanced Wi-Fi, 1080p HD Video",
            brand: "Ring",
            departmentID: "home_kitchen",
            categoryID: "home_cleaning",
            price: 199.99,
            rating: 4.4,
            reviewCount: 42_600,
            deliveryEstimate: "FREE delivery Wed, Mar 18 - Fri, Mar 20",
            imageSystemName: "video.doorbell",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d1/Ring_Doorbell_%2849198898206%29.jpg",
            popularityRank: 85,
            searchKeywords: ["doorbell", "ring", "video doorbell", "smart home", "security"],
            specifications: specs("Video", "1080p HD with Color Pre-Roll", "Power", "Battery or hardwired", "Night Vision", "Color Night Vision"),
            aboutItems: [
                "1080p HD video with Color Pre-Roll gives you a 4-second preview of what triggered your motion alert.",
                "Two-way talk with noise cancellation lets you hear and speak to visitors from anywhere via the Ring app.",
                "Quick-release rechargeable battery or connect to existing doorbell wiring for continuous power."
            ]
        ),

        // Clothing
        product(
            id: "adidas_ultraboost_114",
            name: "adidas Ultraboost Light Running Shoes",
            brand: "adidas",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 140.00,
            originalPrice: 190.00,
            rating: 4.5,
            reviewCount: 8_920,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1608231387042-66d1773070a5?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 86,
            searchKeywords: ["running shoes", "adidas", "ultraboost", "sneakers", "men"],
            specifications: specs("Sole", "BOOST + LIGHTSTRIKE midsole", "Upper", "Primeknit+", "Outsole", "Continental rubber"),
            aboutItems: [
                "30% lighter than previous Ultraboost with the same iconic energy return from full-length BOOST.",
                "Primeknit+ upper adapts to foot movement for a breathable, sock-like fit on every run.",
                "Continental rubber outsole provides superior grip in wet and dry conditions."
            ],
            variants: variants("adidas_ultraboost_114", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("adidas_ultraboost_114", name: "Color", values: ["Core Black", "Cloud White", "Solar Red"]),
            promotions: [promotion(id: "save_ultraboost_114", title: "Save 26%", detail: "Save 26% on adidas Ultraboost Light.", badgeText: "Save 26%")]
        ),
        product(
            id: "summer_dress_115",
            name: "MegaMart Essentials Women's Relaxed-Fit Short-Sleeve Midi Dress",
            brand: "MegaMart Essentials",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 28.90,
            rating: 4.3,
            reviewCount: 15_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tshirt",
            imageURL: "https://images.unsplash.com/photo-1434389677669-e08b4cac3105?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 87,
            searchKeywords: ["dress", "midi dress", "women", "summer", "casual"],
            specifications: specs("Material", "95% Viscose, 5% Elastane", "Fit", "Relaxed", "Length", "Midi"),
            aboutItems: [
                "Relaxed-fit midi dress in soft viscose blend drapes beautifully and moves with you all day.",
                "Short sleeves and a crew neckline keep it effortless — dress it up with heels or down with sneakers.",
                "Machine washable and wrinkle-resistant fabric is perfect for travel and everyday wear."
            ],
            variants: variants("summer_dress_115", name: "Size", values: ["XS", "S", "M", "L", "XL"]) +
                variants("summer_dress_115", name: "Color", values: ["Black", "Navy", "Olive Floral"])
        ),
        product(
            id: "crocs_classic_116",
            name: "Crocs Unisex-Adult Classic Clog",
            brand: "Crocs",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 34.99,
            originalPrice: 49.99,
            rating: 4.8,
            reviewCount: 218_000,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/5/55/Crocs-synthetic-clogs.jpg",
            popularityRank: 88,
            searchKeywords: ["crocs", "clogs", "slides", "comfortable shoes", "casual"],
            specifications: specs("Material", "Croslite foam", "Fit", "Roomy", "Features", "Ventilation ports, pivoting heel strap"),
            aboutItems: [
                "Lightweight, flexible Croslite foam construction molds to your feet for personalized comfort.",
                "Ventilation ports add breathability and help shed water and debris — great for beach or garden.",
                "Customizable with Jibbitz charms — over 218,000 five-star reviews make it MegaMart's top-rated clog."
            ],
            variants: variants("crocs_classic_116", name: "Size", values: ["7", "8", "9", "10", "11"]) +
                variants("crocs_classic_116", name: "Color", values: ["Black", "White", "Army Green", "Electric Pink"]),
            promotions: [promotion(id: "deal_crocs_116", title: "Deal", detail: "Save 30% on Crocs Classic Clogs.", badgeText: "Deal")]
        ),
        product(
            id: "asics_gel_nimbus_123",
            name: "ASICS Gel-Nimbus 26 Running Shoes",
            brand: "ASICS",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 129.95,
            originalPrice: 160.00,
            rating: 4.6,
            reviewCount: 11_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1520256862855-398228c41684?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 95,
            searchKeywords: ["running shoes", "asics", "gel nimbus", "neutral", "cushioned"],
            specifications: specs("Midsole", "FF BLAST PLUS ECO", "Upper", "Engineered knit", "Drop", "8mm"),
            aboutItems: [
                "FF BLAST PLUS ECO cushioning delivers a pillowy, responsive ride for long-distance training.",
                "PureGEL technology in the heel absorbs impact at landing for smoother transitions.",
                "Engineered knit upper with internal reinforcements adapts to the foot for a glove-like fit."
            ],
            variants: variants("asics_gel_nimbus_123", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("asics_gel_nimbus_123", name: "Color", values: ["French Blue", "Black/Pure Silver", "Foggy Teal"])
        ),
        product(
            id: "hoka_clifton_124",
            name: "HOKA Clifton 9 Road Running Shoes",
            brand: "HOKA",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 119.99,
            originalPrice: 145.00,
            rating: 4.7,
            reviewCount: 9_850,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/b/bb/Hoka_Running_Shoe.jpg",
            popularityRank: 96,
            searchKeywords: ["running shoes", "hoka", "clifton", "cushioned", "lightweight"],
            specifications: specs("Midsole", "Compression-molded EVA", "Weight", "248g (Men's 9)", "Drop", "5mm"),
            aboutItems: [
                "Lighter and bouncier than ever with a reimagined compression-molded EVA midsole.",
                "Early-stage Meta-Rocker geometry creates a smooth heel-to-toe transition stride after stride.",
                "Breathable engineered mesh upper with pull-tab heel for easy on-and-off."
            ],
            variants: variants("hoka_clifton_124", name: "Size", values: ["8", "9", "10", "11", "12", "13"]) +
                variants("hoka_clifton_124", name: "Color", values: ["Black/White", "Airy Blue", "Cerise/Real Teal"])
        ),
        product(
            id: "brooks_ghost_125",
            name: "Brooks Ghost 16 Neutral Running Shoes",
            brand: "Brooks",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 109.95,
            originalPrice: 140.00,
            rating: 4.7,
            reviewCount: 15_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1549298916-b41d501d3772?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 97,
            searchKeywords: ["running shoes", "brooks", "ghost", "neutral", "road running"],
            specifications: specs("Midsole", "DNA LOFT v2 nitrogen-infused", "Support", "Neutral", "Drop", "12mm"),
            aboutItems: [
                "DNA LOFT v2 nitrogen-infused midsole cushioning is 10% lighter with softer landings and smoother transitions.",
                "3D Fit Print upper provides a secure, adaptive fit with strategic stretch and structure.",
                "Segmented crash pad adapts to every footstrike for a smooth, balanced feel from heel to toe."
            ],
            variants: variants("brooks_ghost_125", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("brooks_ghost_125", name: "Color", values: ["Black/Ebony", "Blue/Lime", "Oyster/Alloy"])
        ),
        product(
            id: "nb_fresh_foam_126",
            name: "New Balance Fresh Foam X 1080v13 Running Shoes",
            brand: "New Balance",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 114.99,
            originalPrice: 159.99,
            rating: 4.5,
            reviewCount: 7_640,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e0/New_Balance_Fresh_Foam_shoe_on_display.jpg",
            popularityRank: 98,
            searchKeywords: ["running shoes", "new balance", "fresh foam", "1080", "cushioned"],
            specifications: specs("Midsole", "Fresh Foam X", "Upper", "Hypoknit", "Drop", "6mm"),
            aboutItems: [
                "Fresh Foam X midsole uses data-driven design for precisely tuned cushioning underfoot.",
                "Hypoknit upper integrates targeted zones of stretch and support for a contoured, breathable fit.",
                "Ultra Heel design hugs the back of the foot for a snug, slip-free fit without break-in time."
            ],
            variants: variants("nb_fresh_foam_126", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("nb_fresh_foam_126", name: "Color", values: ["Black/Thunder", "Heritage Blue", "White/Navy"])
        ),
        product(
            id: "saucony_ride_127",
            name: "Saucony Ride 17 Running Shoes",
            brand: "Saucony",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 109.99,
            originalPrice: 140.00,
            rating: 4.6,
            reviewCount: 6_320,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/e4/Saucony_shoes.jpg",
            popularityRank: 99,
            searchKeywords: ["running shoes", "saucony", "ride", "neutral", "daily trainer"],
            specifications: specs("Midsole", "PWRRUN+ foam", "Upper", "Engineered mesh", "Drop", "8mm"),
            aboutItems: [
                "PWRRUN+ midsole foam is 28% lighter than standard EVA with enhanced energy return for daily training.",
                "Redesigned engineered mesh upper delivers a breathable, adaptable fit without hotspots.",
                "Durable TRACTION-XT rubber outsole covers high-wear zones for confident grip on roads and sidewalks."
            ],
            variants: variants("saucony_ride_127", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("saucony_ride_127", name: "Color", values: ["Shadow/Vizired", "Fog/Storm", "Black/White"])
        ),
        product(
            id: "on_cloudmonster_128",
            name: "On Cloudmonster Road Running Shoes",
            brand: "On",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 149.99,
            originalPrice: 169.99,
            rating: 4.5,
            reviewCount: 5_180,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/9/98/On_Cloud_Running_Shoes.jpg",
            popularityRank: 100,
            searchKeywords: ["running shoes", "on", "cloudmonster", "max cushion", "swiss"],
            specifications: specs("Midsole", "Helion superfoam + CloudTec", "Weight", "285g (Men's 9)", "Drop", "6mm"),
            aboutItems: [
                "Oversized CloudTec cushioning pods compress on landing and spring back for explosive toe-offs.",
                "Helion superfoam delivers maximum energy return without adding weight — a plush yet responsive ride.",
                "Speedboard between midsole layers converts landing energy into forward propulsion with every stride."
            ],
            variants: variants("on_cloudmonster_128", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("on_cloudmonster_128", name: "Color", values: ["Fawn/Turmeric", "Acai/Aloe", "All Black"])
        ),
        product(
            id: "nike_vomero_129",
            name: "Nike Vomero 18 Cushioned Running Shoes",
            brand: "Nike",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 139.99,
            originalPrice: 160.00,
            rating: 4.6,
            reviewCount: 4_720,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1595950653106-6c9ebd614d3a?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 101,
            isNewestArrival: true,
            releaseLabel: "New arrival",
            searchKeywords: ["running shoes", "nike", "vomero", "cushioned", "max cushion"],
            specifications: specs("Midsole", "ZoomX foam", "Upper", "Flyknit", "Drop", "10mm"),
            aboutItems: [
                "Full-length ZoomX foam midsole provides Nike's lightest and most responsive cushioning for long runs.",
                "Flyknit upper wraps the foot in breathable, supportive comfort with a secure midfoot lockdown.",
                "Wider forefoot platform increases stability while the redesigned outsole improves wet-traction grip."
            ],
            variants: variants("nike_vomero_129", name: "Size", values: ["8", "9", "10", "11", "12", "13"]) +
                variants("nike_vomero_129", name: "Color", values: ["Black/White", "Dusty Cactus", "Wolf Grey"])
        ),
        product(
            id: "nike_invincible_130",
            name: "Nike InfinityRN 4 Women's Road Running Shoes",
            brand: "Nike",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 109.99,
            originalPrice: 160.00,
            rating: 4.4,
            reviewCount: 8_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1562183241-b937e95585b6?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 102,
            searchKeywords: ["running shoes", "nike", "infinity", "women", "stability", "support"],
            specifications: specs("Midsole", "React foam + Zoom Air", "Support", "Supportive neutral", "Drop", "9mm"),
            aboutItems: [
                "ReactX foam midsole provides 13% more energy return than React foam for a springy, cushioned ride.",
                "Wider, flared midsole design gives a stable platform that supports the foot through each stride.",
                "Breathable Flyknit upper with padded collar and tongue for a snug, comfortable fit on every run."
            ],
            variants: variants("nike_invincible_130", name: "Size", values: ["6", "7", "8", "9", "10"]) +
                variants("nike_invincible_130", name: "Color", values: ["Black/Anthracite", "Barely Rose", "Photon Dust"])
        ),
        product(
            id: "brooks_adrenaline_131",
            name: "Brooks Adrenaline GTS 24 Women's Supportive Running Shoes",
            brand: "Brooks",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 119.95,
            originalPrice: 140.00,
            rating: 4.7,
            reviewCount: 12_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1595341888016-a392ef81b7de?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 103,
            searchKeywords: ["running shoes", "brooks", "adrenaline", "gts", "women", "stability", "support"],
            specifications: specs("Midsole", "DNA LOFT v2 nitrogen-infused", "Support", "GuideRails holistic support", "Drop", "12mm"),
            aboutItems: [
                "GuideRails holistic support system keeps excess movement in check without restricting natural motion.",
                "DNA LOFT v2 nitrogen-infused cushioning is soft underfoot while remaining lightweight and responsive.",
                "Trusted by podiatrists and physical therapists — the #1 recommended running shoe for overpronation."
            ],
            variants: variants("brooks_adrenaline_131", name: "Size", values: ["6", "7", "8", "9", "10"]) +
                variants("brooks_adrenaline_131", name: "Color", values: ["Black/Purple", "Blue/Lime", "Peacoat/Tanager"])
        ),
        product(
            id: "hoka_bondi_132",
            name: "HOKA Bondi 8 Max-Cushion Running Shoes",
            brand: "HOKA",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 149.99,
            originalPrice: 165.00,
            rating: 4.6,
            reviewCount: 13_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1556906781-9a412961c28c?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 104,
            searchKeywords: ["running shoes", "hoka", "bondi", "max cushion", "plush"],
            specifications: specs("Midsole", "Compression-molded EVA", "Weight", "307g (Men's 9)", "Drop", "4mm"),
            aboutItems: [
                "HOKA's most cushioned road shoe with a pillowy, ultra-soft midsole for all-day comfort.",
                "Full EVA midsole with extended heel geometry smooths out every stride from landing to toe-off.",
                "Ortholite memory foam insole adds another layer of comfort — a favorite among healthcare workers and travelers."
            ],
            variants: variants("hoka_bondi_132", name: "Size", values: ["8", "9", "10", "11", "12", "13"]) +
                variants("hoka_bondi_132", name: "Color", values: ["Black/Black", "Coastal Sky/All Aboard", "Goblin Blue/Mountain Spring"])
        ),
        product(
            id: "asics_kayano_133",
            name: "ASICS Gel-Kayano 31 Stability Running Shoes",
            brand: "ASICS",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 139.95,
            originalPrice: 160.00,
            rating: 4.5,
            reviewCount: 6_850,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "shoe",
            imageURL: "https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 105,
            searchKeywords: ["running shoes", "asics", "kayano", "stability", "support", "overpronation"],
            specifications: specs("Midsole", "FF BLAST PLUS + PureGEL", "Support", "4D Guidance System", "Drop", "10mm"),
            aboutItems: [
                "4D Guidance System provides adaptive stability by supporting the foot through every phase of the gait cycle.",
                "FF BLAST PLUS ECO midsole and PureGEL technology deliver a smooth, cushioned ride for long distances.",
                "30th anniversary edition with a redesigned upper that's lighter, more breathable, and more sustainable."
            ],
            variants: variants("asics_kayano_133", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("asics_kayano_133", name: "Color", values: ["Black/Pure Silver", "French Blue/Electric Lime", "Piedmont Grey"])
        ),
        product(
            id: "mizuno_wave_rider_134",
            name: "Mizuno Wave Rider 28 Running Shoes",
            brand: "Mizuno",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 109.99,
            originalPrice: 140.00,
            rating: 4.5,
            reviewCount: 4_200,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/ab/Saucony_Type_A8.jpg",
            popularityRank: 106,
            searchKeywords: ["running shoes", "mizuno", "wave rider", "neutral", "daily trainer"],
            specifications: specs("Midsole", "MIZUNO ENERZY + Wave plate", "Upper", "Engineered mesh", "Drop", "12mm"),
            aboutItems: [
                "MIZUNO ENERZY foam cushioning combined with the signature Wave plate delivers a smooth, responsive ride.",
                "Wave plate technology provides both cushioning and stability without adding bulk or weight.",
                "Smooth upper with engineered mesh zones balances breathability and structure for a comfortable fit."
            ],
            variants: variants("mizuno_wave_rider_134", name: "Size", values: ["8", "9", "10", "11", "12"]) +
                variants("mizuno_wave_rider_134", name: "Color", values: ["Undyed White/Lime", "Navy/Orange", "Black/Silver"])
        ),

        // Groceries & Household
        product(
            id: "himalayan_salt_117",
            name: "Sherpa Pink Himalayan Salt, Fine Grain (5 lb Bag)",
            brand: "Sherpa Pink",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 10.99,
            rating: 4.7,
            reviewCount: 26_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "leaf",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/46/Himalayan_salt_%28coarse%29.jpg",
            popularityRank: 89,
            searchKeywords: ["himalayan salt", "pink salt", "cooking", "seasoning"],
            specifications: specs("Weight", "5 lb", "Grain", "Fine (table salt replacement)", "Origin", "Khewra Salt Mine, Pakistan"),
            aboutItems: [
                "100% pure Himalayan pink salt mined from ancient seabeds in the Khewra Salt Mine.",
                "Fine grain dissolves easily — use as a direct replacement for regular table salt in any recipe.",
                "Contains 84 naturally occurring trace minerals that give it its distinctive pink color and subtle flavor."
            ]
        ),
        product(
            id: "water_filter_118",
            name: "Brita Standard Metro Water Filter Pitcher (6-Cup)",
            brand: "Brita",
            departmentID: "groceries",
            categoryID: "household_essentials",
            price: 22.99,
            rating: 4.6,
            reviewCount: 31_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "drop.degreesign",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/dd/Brita_water_filter_in_use.JPG",
            popularityRank: 90,
            searchKeywords: ["water filter", "brita", "pitcher", "filtered water", "household"],
            specifications: specs("Capacity", "6 cups", "Filter", "Standard (lasts 2 months / 40 gal)", "BPA Free", "Yes"),
            aboutItems: [
                "Reduces chlorine taste and odor, copper, mercury, and cadmium for cleaner, great-tasting water.",
                "Slim design fits easily in most refrigerator doors — perfect for small kitchens and dorm rooms.",
                "One Brita Standard filter replaces 300 single-use plastic water bottles — better for you and the planet."
            ]
        ),

        // Sports & Outdoors
        product(
            id: "stanley_tumbler_119",
            name: "Stanley Quencher H2.0 FlowState Tumbler (40 oz)",
            brand: "Stanley",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 45.00,
            rating: 4.7,
            reviewCount: 58_200,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "cup.and.saucer",
            imageURL: "https://images.unsplash.com/photo-1502462041640-b3d7e50d0662?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 91,
            searchKeywords: ["tumbler", "stanley", "quencher", "water bottle", "insulated"],
            specifications: specs("Capacity", "40 oz", "Insulation", "Double-wall vacuum", "Material", "90% recycled stainless steel"),
            aboutItems: [
                "Keeps drinks cold for 11 hours, iced for 2 days, or hot for 7 hours with double-wall vacuum insulation.",
                "FlowState lid with 3 positions: straw, no-straw, and sealed — fits most car cup holders.",
                "Made from 90% recycled stainless steel — the viral tumbler that took social media by storm."
            ],
            variants: variants("stanley_tumbler_119", name: "Color", values: ["Cream", "Rose Quartz", "Alpine Green", "Black"])
        ),

        // Toys & Games
        product(
            id: "magnetic_tiles_120",
            name: "PicassoTiles 100-Piece Magnetic Building Tiles Set",
            brand: "PicassoTiles",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 39.99,
            rating: 4.7,
            reviewCount: 34_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "square.grid.3x3",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/6/6c/Magformers_rainbow.jpg",
            popularityRank: 92,
            searchKeywords: ["magnetic tiles", "picassotiles", "stem toy", "building", "kids"],
            specifications: specs("Pieces", "100", "Material", "Non-toxic ABS plastic", "Ages", "3+"),
            aboutItems: [
                "100 colorful magnetic tiles snap together to build castles, houses, animals, and 3D structures.",
                "Develops STEM skills, spatial reasoning, and creativity through open-ended, screen-free play.",
                "BPA-free, non-toxic ABS plastic with rounded edges — ASTM and CPSIA certified for child safety."
            ]
        ),

        // Pet Supplies
        product(
            id: "cat_tree_121",
            name: "FEANDREA 56-Inch Multi-Level Cat Tree with Sisal Scratching Posts",
            brand: "FEANDREA",
            departmentID: "pet_supplies",
            categoryID: "cat_supplies",
            price: 59.99,
            originalPrice: 79.99,
            rating: 4.5,
            reviewCount: 28_700,
            deliveryEstimate: "FREE delivery Monday",
            imageSystemName: "cat",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat_tree_with_2_cats.jpg",
            popularityRank: 93,
            searchKeywords: ["cat tree", "feandrea", "cat tower", "scratching post", "cat furniture"],
            specifications: specs("Height", "56\"", "Levels", "5 platforms + 2 condos", "Posts", "Sisal-wrapped scratching posts"),
            aboutItems: [
                "5 platforms, 2 cozy condos, and a hammock give cats multiple spots to perch, play, and nap.",
                "Sisal-wrapped scratching posts satisfy clawing instincts and protect your furniture.",
                "Sturdy particleboard base with anti-toppling wall anchor — holds cats up to 33 lbs."
            ],
            promotions: [promotion(id: "deal_cattree_121", title: "Deal", detail: "Save 25% on FEANDREA cat tree.", badgeText: "Deal")]
        ),

        // Office
        product(
            id: "noise_machine_122",
            name: "Dreamegg White Noise Machine — 21 Soothing Sounds",
            brand: "Dreamegg",
            departmentID: "office",
            categoryID: "workspace",
            price: 25.99,
            rating: 4.6,
            reviewCount: 42_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "speaker.wave.2",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/2d/LectroFan_white_noise_machine.jpg",
            popularityRank: 94,
            searchKeywords: ["white noise", "sound machine", "sleep", "office", "focus"],
            specifications: specs("Sounds", "21 (7 white noise, 7 fan, 7 nature)", "Timer", "Auto-off timer", "Power", "USB-C or battery"),
            aboutItems: [
                "21 non-looping sounds including white noise, fan, ocean, rain, and brook for sleep, focus, or relaxation.",
                "Compact, portable design with USB-C power or battery operation — perfect for office, nursery, or travel.",
                "Memory function remembers your last sound and volume setting — just press power and go."
            ]
        ),

        // ── Additional Realistic Products ───────────────────────────

        // Electronics
        product(
            id: "apple_watch_se_136",
            name: "Apple Watch SE (2nd Gen) GPS 44mm with Sport Band",
            brand: "Apple",
            departmentID: "electronics",
            categoryID: "computer_accessories",
            price: 229.00,
            originalPrice: 279.00,
            rating: 4.6,
            reviewCount: 42_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "applewatch",
            imageURL: "https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 107,
            searchKeywords: ["apple watch", "smartwatch", "fitness tracker", "gps watch"],
            specifications: specs("Display", "44mm Retina LTPO OLED", "Chip", "S8 SiP", "Water Resistance", "50m (WR50)"),
            aboutItems: [
                "S8 SiP delivers the same performance as Apple Watch Series 8 at a more accessible price point.",
                "Advanced health features including heart rate monitoring, crash detection, and fall detection.",
                "Swimproof to 50 meters with built-in GPS for accurate outdoor workout tracking."
            ],
            variants: variants("apple_watch_se_136", name: "Color", values: ["Midnight", "Starlight", "Silver"]),
            promotions: [promotion(id: "save_watch_136", title: "Save $50", detail: "Save $50 on Apple Watch SE (2nd Gen).", badgeText: "Save $50")]
        ),
        product(
            id: "bose_soundlink_flex_137",
            name: "Bose SoundLink Flex Portable Bluetooth Speaker",
            brand: "Bose",
            departmentID: "electronics",
            categoryID: "audio",
            price: 119.00,
            originalPrice: 149.00,
            rating: 4.6,
            reviewCount: 18_900,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "speaker.wave.3",
            imageURL: "https://images.unsplash.com/photo-1545454675-3531b543be5d?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 108,
            searchKeywords: ["bose", "speaker", "bluetooth", "portable", "waterproof"],
            specifications: specs("Battery", "12 hours", "Water Rating", "IP67", "Weight", "1.3 lbs"),
            aboutItems: [
                "PositionIQ technology automatically detects speaker orientation and adjusts sound accordingly.",
                "IP67 rated waterproof and dustproof — drop-tested from 3 feet onto steel and built to survive.",
                "Bose-engineered transducer delivers clear, deep sound that cuts through noise outdoors."
            ],
            promotions: [promotion(id: "deal_bose_137", title: "Deal", detail: "Save 20% on Bose SoundLink Flex.", badgeText: "Deal")]
        ),
        product(
            id: "nintendo_switch_game_138",
            name: "Mario Kart 8 Deluxe — Nintendo Switch",
            brand: "Nintendo",
            departmentID: "electronics",
            categoryID: "gaming",
            price: 49.99,
            rating: 4.9,
            reviewCount: 156_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "gamecontroller.fill",
            imageURL: "https://images.unsplash.com/photo-1578303512597-81e6cc155b3e?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 109,
            searchKeywords: ["mario kart", "nintendo switch", "racing game", "multiplayer"],
            specifications: specs("Platform", "Nintendo Switch", "Players", "1-8 local / 2-12 online", "Rating", "ESRB Everyone"),
            aboutItems: [
                "The definitive Mario Kart experience with 48 base tracks plus 48 DLC tracks via the Booster Course Pass.",
                "Race as 42 characters across stunning HD circuits with anti-gravity, underwater, and glider sections.",
                "Local split-screen for up to 4 players and online multiplayer for up to 12 — the best-selling Switch game ever."
            ]
        ),

        // Home & Kitchen
        product(
            id: "vitamix_blender_139",
            name: "Vitamix E310 Explorian Blender, Professional-Grade",
            brand: "Vitamix",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 289.95,
            originalPrice: 349.95,
            rating: 4.7,
            reviewCount: 16_400,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "cup.and.saucer",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/ec/Vitamix_5200_Classic_Blender.jpg",
            popularityRank: 110,
            searchKeywords: ["blender", "vitamix", "smoothie", "professional", "kitchen"],
            specifications: specs("Motor", "2.0 HP", "Container", "48 oz", "Speeds", "10 variable + pulse"),
            aboutItems: [
                "Professional-grade 2.0 HP motor powers through the toughest ingredients for silky-smooth results every time.",
                "Aircraft-grade stainless steel blades create friction heat to make hot soups directly in the container.",
                "Self-cleaning — add a drop of dish soap and warm water, blend on high for 60 seconds, and rinse."
            ],
            promotions: [promotion(id: "save_vitamix_139", title: "Save $60", detail: "Save $60 on Vitamix E310 professional blender.", badgeText: "Save $60")]
        ),
        product(
            id: "electric_kettle_140",
            name: "Fellow Stagg EKG Electric Pour-Over Kettle",
            brand: "Fellow",
            departmentID: "home_kitchen",
            categoryID: "kitchen_appliances",
            price: 165.00,
            rating: 4.7,
            reviewCount: 8_940,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "mug",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/8e/Electric_kettle.jpg",
            popularityRank: 111,
            searchKeywords: ["electric kettle", "fellow", "pour over", "gooseneck", "coffee"],
            specifications: specs("Capacity", "0.9L", "Temp Range", "135°F-212°F", "Display", "LCD with stopwatch"),
            aboutItems: [
                "Precision pour spout and counterbalanced handle give you total control for a perfect pour-over every time.",
                "Variable temperature control from 135°F to 212°F with a built-in brew stopwatch on the LCD display.",
                "Hold mode keeps water at your target temperature for up to 60 minutes — no re-boiling needed."
            ]
        ),

        // Clothing
        product(
            id: "hanes_tshirt_pack_141",
            name: "Hanes Men's ComfortSoft Crew Neck T-Shirt (6-Pack)",
            brand: "Hanes",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 19.00,
            rating: 4.4,
            reviewCount: 186_500,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tshirt",
            imageURL: "https://images.unsplash.com/photo-1521572163474-6864f9cf17ab?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 112,
            searchKeywords: ["t-shirt", "hanes", "crew neck", "cotton", "basics"],
            specifications: specs("Material", "100% ring-spun cotton", "Pack", "6 shirts", "Fit", "Classic"),
            aboutItems: [
                "100% ring-spun cotton feels soft and smooth against the skin from the first wear.",
                "Lay-flat collar holds its shape wash after wash without stretching or curling.",
                "Tag-free design eliminates itchy labels — comfort you can feel all day long."
            ],
            variants: variants("hanes_tshirt_pack_141", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("hanes_tshirt_pack_141", name: "Color", values: ["White", "Black", "Assorted"])
        ),
        product(
            id: "carhartt_beanie_142",
            name: "Carhartt Knit Cuffed Beanie",
            brand: "Carhartt",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 16.99,
            rating: 4.8,
            reviewCount: 94_200,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tshirt",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/e/ec/Example_of_beanie.jpg",
            popularityRank: 113,
            searchKeywords: ["beanie", "carhartt", "winter hat", "knit cap"],
            specifications: specs("Material", "100% Acrylic", "Fit", "One size fits most", "Features", "Stretchable rib knit"),
            aboutItems: [
                "The iconic Carhartt beanie — a workwear staple that's become a streetwear must-have.",
                "100% acrylic rib knit retains warmth and holds its shape through rugged use and repeated washes.",
                "Fold-up cuff with embroidered Carhartt label — available in 30+ colors to match any style."
            ],
            variants: variants("carhartt_beanie_142", name: "Color", values: ["Black", "Coal Heather", "Dark Brown", "Brite Orange"])
        ),
        product(
            id: "birkenstock_arizona_143",
            name: "Birkenstock Arizona Soft Footbed Sandals",
            brand: "Birkenstock",
            departmentID: "clothing",
            categoryID: "womens_fashion",
            price: 109.95,
            rating: 4.7,
            reviewCount: 36_800,
            deliveryEstimate: "FREE delivery Friday",
            imageSystemName: "shoe",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/d/d3/Birkenstock_Arizona.jpg",
            popularityRank: 114,
            searchKeywords: ["birkenstock", "arizona", "sandals", "slides", "cork footbed"],
            specifications: specs("Footbed", "Soft cork-latex", "Upper", "Oiled nubuck leather", "Sole", "EVA"),
            aboutItems: [
                "Legendary contoured cork-latex footbed with soft cushioning layer molds to your foot over time.",
                "Two adjustable buckle straps for a fully customizable fit — premium oiled nubuck leather upper.",
                "Lightweight EVA sole provides shock absorption and flexibility for all-day walking comfort."
            ],
            variants: variants("birkenstock_arizona_143", name: "Size", values: ["6", "7", "8", "9", "10"]) +
                variants("birkenstock_arizona_143", name: "Color", values: ["Tobacco", "Mocha", "Black"])
        ),
        product(
            id: "under_armour_shorts_144",
            name: "Under Armour Men's Tech Graphic Shorts",
            brand: "Under Armour",
            departmentID: "clothing",
            categoryID: "mens_fashion",
            price: 25.00,
            rating: 4.6,
            reviewCount: 31_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "tshirt",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/0/09/Sports_shorts.jpg",
            popularityRank: 115,
            searchKeywords: ["shorts", "under armour", "athletic", "gym", "workout"],
            specifications: specs("Material", "100% Polyester", "Fit", "Loose", "Inseam", "10\""),
            aboutItems: [
                "Ultra-light HeatGear fabric is smooth, fast-drying, and wicks sweat away during intense workouts.",
                "Encased elastic waistband with internal drawcord delivers a comfortable, adjustable fit.",
                "Open hand pockets and a 10-inch inseam provide an easy, relaxed fit for the gym, court, or everyday wear."
            ],
            variants: variants("under_armour_shorts_144", name: "Size", values: ["S", "M", "L", "XL"]) +
                variants("under_armour_shorts_144", name: "Color", values: ["Black", "Academy Blue", "Pitch Gray"])
        ),

        // Groceries & Household
        product(
            id: "mixed_nuts_145",
            name: "Planters Deluxe Mixed Nuts with Sea Salt (27 oz)",
            brand: "Planters",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 14.98,
            rating: 4.6,
            reviewCount: 53_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "leaf",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/7/7d/Liat_Portal_for_Foodie_Disorder_-_Mixed_nuts_and_dried_fruit.jpg",
            popularityRank: 116,
            searchKeywords: ["mixed nuts", "planters", "cashews", "almonds", "snack"],
            specifications: specs("Weight", "27 oz", "Nuts", "Cashews, Almonds, Pecans, Pistachios, Hazelnuts", "Kosher", "Yes"),
            aboutItems: [
                "Premium mix of cashews, almonds, pecans, pistachios, and hazelnuts — no peanuts in this blend.",
                "Roasted with sea salt for a satisfying crunch and savory flavor straight from the resealable canister.",
                "6g of plant protein per serving — a wholesome, heart-healthy snack for home or on the go."
            ]
        ),
        product(
            id: "chamomile_tea_146",
            name: "Celestial Seasonings Sleepytime Herbal Tea (40 Count)",
            brand: "Celestial Seasonings",
            departmentID: "groceries",
            categoryID: "pantry_staples",
            price: 4.99,
            rating: 4.7,
            reviewCount: 72_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "cup.and.saucer",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/8/8c/Glass_of_chamomile_tea.jpg",
            popularityRank: 117,
            searchKeywords: ["tea", "chamomile", "herbal tea", "sleepytime", "caffeine free"],
            specifications: specs("Count", "40 tea bags", "Herbs", "Chamomile, spearmint, lemongrass", "Caffeine", "Caffeine-free"),
            aboutItems: [
                "A soothing blend of chamomile, spearmint, and lemongrass — the #1 selling specialty tea in America.",
                "Naturally caffeine-free with a gentle, minty flavor that helps you unwind before bed.",
                "40 individually wrapped tea bags in a recyclable box — steep 4-6 minutes for the perfect cup."
            ]
        ),
        product(
            id: "swiffer_wetjet_147",
            name: "Swiffer WetJet Hardwood Floor Spray Mop Starter Kit",
            brand: "Swiffer",
            departmentID: "groceries",
            categoryID: "household_essentials",
            price: 28.97,
            rating: 4.5,
            reviewCount: 89_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "sparkles",
            imageURL: "https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 118,
            searchKeywords: ["swiffer", "mop", "wetjet", "floor cleaner", "hardwood"],
            specifications: specs("Kit Includes", "1 mop, 5 pads, 1 cleaning solution", "Battery", "4 AA included", "Pad Size", "10\" x 8\""),
            aboutItems: [
                "All-in-one spray mop dissolves dirt and tough, sticky messes with a powerful cleaning solution.",
                "Dual-nozzle sprayer covers a wide area while the absorbent pad traps and locks away grime.",
                "Safe for all sealed floors including hardwood, laminate, tile, and vinyl — no bucket needed."
            ]
        ),

        // Office & Workspace
        product(
            id: "desk_fan_148",
            name: "Honeywell TurboForce Power Fan, Table/Floor (HT-900)",
            brand: "Honeywell",
            departmentID: "office",
            categoryID: "workspace",
            price: 17.99,
            rating: 4.6,
            reviewCount: 112_800,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "fan",
            imageURL: "https://images.unsplash.com/photo-1582139329536-e7284fece509?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 119,
            searchKeywords: ["fan", "desk fan", "honeywell", "turboforce", "office fan"],
            specifications: specs("Size", "11\" diameter", "Speeds", "3", "Tilt", "90° adjustable"),
            aboutItems: [
                "TurboForce power channels aerodynamic airflow up to 32 feet for effective room-wide circulation.",
                "3 speed settings with a quiet operation level ideal for bedrooms, offices, and dorm rooms.",
                "Compact 11-inch design with a removable grille for easy cleaning — wall-mountable for space savings."
            ]
        ),
        product(
            id: "phone_stand_149",
            name: "Lamicall Adjustable Cell Phone Stand for Desk",
            brand: "Lamicall",
            departmentID: "office",
            categoryID: "workspace",
            price: 12.99,
            rating: 4.6,
            reviewCount: 76_300,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "iphone",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/c/cb/Wireless_mobile_battery_that_doubles_as_a_smartphone_stand_-_1.jpg",
            popularityRank: 120,
            searchKeywords: ["phone stand", "desk stand", "lamicall", "phone holder"],
            specifications: specs("Material", "Aluminum alloy", "Compatibility", "4-8\" phones", "Angle", "270° adjustable"),
            aboutItems: [
                "Solid aluminum alloy construction with a weighted base provides rock-steady stability on any desk.",
                "270-degree adjustable angle lets you find the perfect viewing position for video calls, recipes, and reading.",
                "Fits all 4-8 inch smartphones with or without a case — compatible with iPhone, Samsung, and more."
            ]
        ),

        // Toys & Games
        product(
            id: "play_doh_set_150",
            name: "Play-Doh Modeling Compound 36-Pack of Colors",
            brand: "Play-Doh",
            departmentID: "toys",
            categoryID: "stem_toys",
            price: 19.99,
            rating: 4.8,
            reviewCount: 48_600,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "paintpalette",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/4/4e/2016_Nuernberger_Spielwarenmesse_-_Play-Doh_-_by_2eight_-_8SC3014.jpg",
            popularityRank: 121,
            searchKeywords: ["play-doh", "modeling clay", "kids crafts", "creative play"],
            specifications: specs("Colors", "36 different colors", "Weight", "3 oz per can", "Ages", "2+"),
            aboutItems: [
                "36 vibrant colors in 3-oz cans give kids a rainbow of creative possibilities in one mega value pack.",
                "Non-toxic, safe formula made primarily from water, salt, and flour — trusted by parents for over 65 years.",
                "Perfect for birthday party favors, classroom activities, stocking stuffers, and creative play at home."
            ]
        ),
        product(
            id: "uno_game_151",
            name: "UNO Card Game for 2-10 Players, Ages 7+",
            brand: "Mattel",
            departmentID: "toys",
            categoryID: "family_games",
            price: 5.99,
            rating: 4.8,
            reviewCount: 198_400,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "suit.heart",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/2/28/Baraja_de_UNO.JPG",
            popularityRank: 122,
            searchKeywords: ["uno", "card game", "family game", "travel game"],
            specifications: specs("Players", "2-10", "Ages", "7+", "Cards", "112"),
            aboutItems: [
                "The classic card game of matching colors and numbers — now the world's #1 card game with 150M+ copies sold.",
                "Draw Two, Skip, Reverse, and Wild cards add exciting twists that keep every round unpredictable.",
                "Compact and portable — perfect for road trips, vacations, game nights, and waiting rooms."
            ]
        ),

        // Pet Supplies
        product(
            id: "cat_fountain_152",
            name: "Catit Flower Cat Water Fountain (3L / 100 oz)",
            brand: "Catit",
            departmentID: "pet_supplies",
            categoryID: "cat_supplies",
            price: 29.99,
            rating: 4.4,
            reviewCount: 62_300,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "cat",
            imageURL: "https://images.unsplash.com/photo-1566777643984-2c3c8fdac7b5?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 123,
            searchKeywords: ["cat fountain", "water fountain", "catit", "pet fountain"],
            specifications: specs("Capacity", "3L (100 fl oz)", "Flow", "3 settings (gentle, bubbling, calm)", "Filter", "Dual-action carbon + foam"),
            aboutItems: [
                "Three water flow settings — gentle flower flow, bubbling top, and calm stream — encourage cats to drink more.",
                "Dual-action filter with activated carbon removes impurities and odors for fresher, cleaner water.",
                "100 oz capacity holds enough water for multiple cats and reduces refill frequency — BPA-free plastic."
            ]
        ),

        // Sports & Outdoors
        product(
            id: "trekking_poles_153",
            name: "TrailBuddy Trekking Poles — Lightweight Carbon Fiber (Pair)",
            brand: "TrailBuddy",
            departmentID: "sports_outdoors",
            categoryID: "outdoor_gear",
            price: 39.99,
            rating: 4.5,
            reviewCount: 24_600,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "figure.hiking",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/1/13/Walking_sticks%2C_Baltasound_pier_-_geograph.org.uk_-_6187180.jpg",
            popularityRank: 124,
            searchKeywords: ["trekking poles", "hiking poles", "walking sticks", "carbon fiber"],
            specifications: specs("Material", "Carbon fiber", "Weight", "7.6 oz each", "Height", "Adjustable 24.5\"-54\""),
            aboutItems: [
                "Ultralight carbon fiber poles weigh just 7.6 oz each — reduce knee strain by up to 25% on descents.",
                "Quick-lock clamp mechanism adjusts height from 24.5 to 54 inches and locks securely in seconds.",
                "Cork and EVA foam grips wick moisture and conform to your hands — includes snow baskets and rubber tips."
            ]
        ),
        product(
            id: "ab_roller_154",
            name: "Perfect Fitness Ab Carver Pro Roller",
            brand: "Perfect Fitness",
            departmentID: "sports_outdoors",
            categoryID: "fitness_gear",
            price: 24.99,
            originalPrice: 39.99,
            rating: 4.4,
            reviewCount: 42_100,
            deliveryEstimate: "FREE delivery Tomorrow",
            imageSystemName: "figure.core.training",
            imageURL: "https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=1200&h=1200&fit=crop&q=85&fm=jpg&auto=format",
            popularityRank: 125,
            searchKeywords: ["ab roller", "ab wheel", "core workout", "ab carver"],
            specifications: specs("Mechanism", "Carbon steel spring", "Width", "Ultra-wide tread", "Includes", "Foam knee pad"),
            aboutItems: [
                "Internal carbon steel spring provides resistance on the roll-out and assists on the return for a killer core burn.",
                "Ultra-wide tread and ergonomic handles stabilize your roll to engage obliques on angled movements.",
                "Includes a high-density foam knee pad — perfect for home gym ab workouts at any fitness level."
            ],
            promotions: [promotion(id: "save_roller_154", title: "Save 37%", detail: "Save 37% on Perfect Fitness Ab Carver Pro.", badgeText: "Save 37%")]
        ),

        // Beauty
        product(
            id: "sleep_mask_155",
            name: "Manta Sleep Mask — 100% Blackout, Zero Eye Pressure",
            brand: "Manta",
            departmentID: "beauty",
            categoryID: "skin_care",
            price: 35.00,
            rating: 4.5,
            reviewCount: 19_800,
            deliveryEstimate: "Currently unavailable",
            inStock: false,
            imageSystemName: "moon.zzz",
            imageURL: "https://upload.wikimedia.org/wikipedia/commons/a/a4/Different_Blindfolds_for_sleeping_and_resting.JPG",
            popularityRank: 126,
            searchKeywords: ["sleep mask", "eye mask", "manta", "blackout", "travel"],
            specifications: specs("Fit", "Adjustable head strap + eye cups", "Blackout", "100%", "Material", "Soft modal + micro-fleece"),
            aboutItems: [
                "Infinitely adjustable eye cups sit in their own deepened space — zero pressure on your eyelids or lashes.",
                "100% blackout in any sleeping position, including side sleepers, without a trace of light leakage.",
                "Machine-washable modal fabric is breathable and stays cool throughout the night."
            ]
        )
    ]

    // MARK: - Cart, Saved Items, Orders

    private static func seededCartItems(productLookup: [String: Product]) -> [CartItem] {
        [
            cartItem(productID: "paper_towels_046", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "ps5_charging_station_083", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "sunscreen_lotion_036", quantity: 2, selection: [:], lookup: productLookup),
            cartItem(productID: "dog_treats_065", quantity: 1, selection: ["Flavor": "Chicken"], lookup: productLookup),
            cartItem(productID: "scifi_novel_092", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "gel_pen_pack_051", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "detergent_pods_047", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "chamomile_tea_146", quantity: 2, selection: [:], lookup: productLookup),
            cartItem(productID: "mixed_nuts_145", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "trash_bags_099", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "lip_balm_pack_037", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "dental_chews_072", quantity: 1, selection: ["Dog Size": "Regular"], lookup: productLookup),
            cartItem(productID: "resistance_bands_075", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "phone_stand_149", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "sticky_notes_101", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "granola_pack_044", quantity: 1, selection: [:], lookup: productLookup),
            cartItem(productID: "play_doh_set_150", quantity: 1, selection: [:], lookup: productLookup),
        ].compactMap { $0 }
    }

    private static func seededSavedItems(productLookup: [String: Product]) -> [SavedItem] {
        [
            // Recent browsing — considering purchases
            savedItem(productID: "mechanical_keyboard_003", selection: ["Switch": "Brown", "Color": "Black"], savedAt: "2026-02-25T12:00:00Z", lookup: productLookup),
            savedItem(productID: "protein_powder_041", selection: ["Flavor": "Vanilla Ice Cream"], savedAt: "2026-02-24T11:00:00Z", lookup: productLookup),
            savedItem(productID: "pet_bed_067", selection: ["Size": "Large", "Color": "Gray"], savedAt: "2026-02-23T10:00:00Z", lookup: productLookup),
            savedItem(productID: "trail_backpack_077", selection: ["Color": "Moss"], savedAt: "2026-02-22T09:30:00Z", lookup: productLookup),
            savedItem(productID: "wireless_earbuds_088", selection: ["Color": "Graphite"], savedAt: "2026-02-21T14:15:00Z", lookup: productLookup),
            savedItem(productID: "cookware_set_011", selection: ["Color": "Graphite"], savedAt: "2026-02-19T16:30:00Z", lookup: productLookup),
            savedItem(productID: "desk_converter_052", selection: [:], savedAt: "2026-02-17T11:45:00Z", lookup: productLookup),
            savedItem(productID: "running_shoes_025", selection: ["Size": "10", "Color": "Black/White"], savedAt: "2026-02-15T08:20:00Z", lookup: productLookup),
            savedItem(productID: "usb_c_charger_002", selection: ["Pack": "1-Pack"], savedAt: "2026-02-13T19:00:00Z", lookup: productLookup),
            savedItem(productID: "organic_coffee_042", selection: [:], savedAt: "2026-02-11T07:30:00Z", lookup: productLookup),
            savedItem(productID: "trail_jacket_028", selection: ["Size": "L", "Color": "TNF Black"], savedAt: "2026-02-09T13:10:00Z", lookup: productLookup),
            savedItem(productID: "monitor_riser_055", selection: [:], savedAt: "2026-02-07T10:00:00Z", lookup: productLookup),

            // Home office upgrades — researching
            savedItem(productID: "usb_docking_station_056", selection: [:], savedAt: "2026-02-05T22:15:00Z", lookup: productLookup),
            savedItem(productID: "webcam_100", selection: [:], savedAt: "2026-02-05T22:10:00Z", lookup: productLookup),
            savedItem(productID: "noise_machine_122", selection: [:], savedAt: "2026-02-04T20:30:00Z", lookup: productLookup),
            savedItem(productID: "chair_cushion_050", selection: [:], savedAt: "2026-02-04T20:25:00Z", lookup: productLookup),
            savedItem(productID: "led_desk_lamp_135", selection: [:], savedAt: "2026-02-04T20:15:00Z", lookup: productLookup),

            // Gift ideas — browsed for friend's birthday
            savedItem(productID: "board_game_059", selection: [:], savedAt: "2026-02-01T14:00:00Z", lookup: productLookup),
            savedItem(productID: "card_game_102", selection: [:], savedAt: "2026-02-01T13:55:00Z", lookup: productLookup),
            savedItem(productID: "puzzle_061", selection: [:], savedAt: "2026-02-01T13:50:00Z", lookup: productLookup),
            savedItem(productID: "plush_bear_063", selection: [:], savedAt: "2026-02-01T13:45:00Z", lookup: productLookup),

            // Fitness goals — Jan browsing session
            savedItem(productID: "dumbbell_set_078", selection: [:], savedAt: "2026-01-28T19:00:00Z", lookup: productLookup),
            savedItem(productID: "ab_roller_154", selection: [:], savedAt: "2026-01-28T18:55:00Z", lookup: productLookup),
            savedItem(productID: "jump_rope_106", selection: [:], savedAt: "2026-01-28T18:50:00Z", lookup: productLookup),
            savedItem(productID: "foam_roller_080", selection: [:], savedAt: "2026-01-28T18:40:00Z", lookup: productLookup),

            // Camping trip planning
            savedItem(productID: "camping_tent_107", selection: [:], savedAt: "2026-01-20T11:30:00Z", lookup: productLookup),
            savedItem(productID: "camping_lantern_076", selection: [:], savedAt: "2026-01-20T11:25:00Z", lookup: productLookup),
            savedItem(productID: "trekking_poles_153", selection: [:], savedAt: "2026-01-20T11:20:00Z", lookup: productLookup),

            // Pet supplies — ongoing list
            savedItem(productID: "automatic_feeder_070", selection: [:], savedAt: "2026-01-15T09:00:00Z", lookup: productLookup),
            savedItem(productID: "grooming_brush_071", selection: [:], savedAt: "2026-01-15T08:55:00Z", lookup: productLookup),
            savedItem(productID: "cat_fountain_152", selection: [:], savedAt: "2026-01-15T08:50:00Z", lookup: productLookup),
            savedItem(productID: "leash_harness_068", selection: ["Size": "M", "Color": "Black"], savedAt: "2026-01-10T16:30:00Z", lookup: productLookup),

            // Beauty/grooming — maybe later
            savedItem(productID: "electric_toothbrush_096", selection: [:], savedAt: "2026-01-05T21:00:00Z", lookup: productLookup),
            savedItem(productID: "sleep_mask_155", selection: [:], savedAt: "2026-01-05T20:55:00Z", lookup: productLookup),
            savedItem(productID: "beard_trimmer_039", selection: [:], savedAt: "2025-12-30T14:00:00Z", lookup: productLookup),

            // Kitchen wish list — older saves
            savedItem(productID: "espresso_machine_012", selection: [:], savedAt: "2025-12-20T10:00:00Z", lookup: productLookup),
            savedItem(productID: "electric_kettle_140", selection: [:], savedAt: "2025-12-20T09:55:00Z", lookup: productLookup),
            savedItem(productID: "olive_oil_045", selection: [:], savedAt: "2025-12-15T08:30:00Z", lookup: productLookup),

            // Electronics wish list — older saves
            savedItem(productID: "apple_watch_se_136", selection: ["Color": "Midnight"], savedAt: "2025-12-10T19:00:00Z", lookup: productLookup),
            savedItem(productID: "bose_soundlink_flex_137", selection: [:], savedAt: "2025-12-08T15:30:00Z", lookup: productLookup),
            savedItem(productID: "power_bank_110", selection: [:], savedAt: "2025-11-28T12:00:00Z", lookup: productLookup),
            savedItem(productID: "smart_thermostat_091", selection: [:], savedAt: "2025-11-20T18:45:00Z", lookup: productLookup),
            savedItem(productID: "ring_doorbell_113", selection: [:], savedAt: "2025-11-20T18:40:00Z", lookup: productLookup),

            // Books — reading list
            savedItem(productID: "mystery_box_set_020", selection: [:], savedAt: "2025-11-15T22:00:00Z", lookup: productLookup),
            savedItem(productID: "fantasy_map_guide_022", selection: [:], savedAt: "2025-11-10T21:30:00Z", lookup: productLookup),
            savedItem(productID: "finance_book_093", selection: [:], savedAt: "2025-10-25T14:00:00Z", lookup: productLookup),
            savedItem(productID: "leadership_playbook_023", selection: [:], savedAt: "2025-10-20T09:15:00Z", lookup: productLookup),

            // Clothing — browsed but didn't commit
            savedItem(productID: "birkenstock_arizona_143", selection: ["Size": "10", "Color": "Tobacco"], savedAt: "2025-10-15T17:30:00Z", lookup: productLookup),
            savedItem(productID: "puffer_vest_095", selection: ["Size": "M", "Color": "Black"], savedAt: "2025-10-10T11:00:00Z", lookup: productLookup),
            savedItem(productID: "classic_jeans_030", selection: ["Size": "32x32", "Color": "Medium Stonewash"], savedAt: "2025-10-05T16:00:00Z", lookup: productLookup),
            savedItem(productID: "polo_shirt_031", selection: ["Size": "L", "Color": "Newport Navy"], savedAt: "2025-09-28T13:00:00Z", lookup: productLookup),
        ].compactMap { $0 }
    }

    private static func seededOrders(productLookup: [String: Product]) -> [Order] {
        [
            // ── Mar 2026 ──────────────────────────────────────────────

            // Vitamix blender out for delivery today
            order(
                id: "order_amz100253",
                orderNumber: "AMZ100253",
                status: .outForDelivery,
                createdAt: "2026-02-26T20:00:00Z",
                items: [("vitamix_blender_139", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Most recent: headphones shipped a couple days ago
            order(
                id: "order_amz100252",
                orderNumber: "AMZ100252",
                status: .shipped,
                createdAt: "2026-02-27T09:15:00Z",
                items: [("noise_canceling_headphones_001", 1, ["Color": "Black"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 20,
                productLookup: productLookup
            ),

            // Kitchen combo still preparing
            order(
                id: "order_amz100251",
                orderNumber: "AMZ100251",
                status: .preparingForShipment,
                createdAt: "2026-02-28T15:20:00Z",
                items: [
                    ("air_fryer_009", 1, ["Color": "Black"]),
                    ("storage_container_set_014", 1, [:])
                ],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Feb 2026 ──────────────────────────────────────────────

            // Skincare restock mid-Feb
            order(
                id: "order_amz100250",
                orderNumber: "AMZ100250",
                status: .delivered,
                createdAt: "2026-02-18T18:10:00Z",
                items: [("face_moisturizer_033", 2, ["Size": "1.7 oz"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 5,
                productLookup: productLookup
            ),

            // Pet supplies early Feb
            order(
                id: "order_amz100249",
                orderNumber: "AMZ100249",
                status: .delivered,
                createdAt: "2026-02-06T12:45:00Z",
                items: [("dog_treats_065", 1, ["Flavor": "Chicken"]), ("dental_chews_072", 1, ["Dog Size": "Regular"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Jan 2026 ──────────────────────────────────────────────

            // Cookware set shipped to office late Jan
            order(
                id: "order_amz100248",
                orderNumber: "AMZ100248",
                status: .delivered,
                createdAt: "2026-01-25T14:35:00Z",
                items: [("cookware_set_011", 1, ["Color": "Graphite"])],
                address: defaultAddresses[1],
                paymentMethod: defaultPaymentMethods[2],
                deliveryOption: deliveryOptions[1],
                discount: 15,
                productLookup: productLookup
            ),

            // Running gear mid-Jan (New Year's resolution purchase)
            order(
                id: "order_amz100247",
                orderNumber: "AMZ100247",
                status: .delivered,
                createdAt: "2026-01-12T08:00:00Z",
                items: [("running_shoes_025", 1, ["Size": "11", "Color": "Blue/Silver"]), ("crew_socks_029", 1, ["Size": "L"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 10,
                productLookup: productLookup
            ),

            // Planner + pens for the new year
            order(
                id: "order_amz100246",
                orderNumber: "AMZ100246",
                status: .delivered,
                createdAt: "2026-01-03T11:20:00Z",
                items: [("planner_notebook_053", 1, [:]), ("gel_pen_pack_051", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Dec 2025 ──────────────────────────────────────────────

            // Yoga mat + foam roller pre-holiday
            order(
                id: "order_amz100245",
                orderNumber: "AMZ100245",
                status: .delivered,
                createdAt: "2025-12-28T10:10:00Z",
                items: [("yoga_mat_073", 1, ["Color": "Teal"]), ("foam_roller_080", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Holiday gift orders mid-Dec
            order(
                id: "order_amz100244",
                orderNumber: "AMZ100244",
                status: .delivered,
                createdAt: "2025-12-16T19:45:00Z",
                items: [("building_blocks_057", 1, [:]), ("art_supplies_060", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Bluetooth speaker canceled early Dec
            order(
                id: "order_amz100243",
                orderNumber: "AMZ100243",
                status: .canceled,
                createdAt: "2025-12-08T16:30:00Z",
                items: [("bluetooth_speaker_005", 1, [:])],
                address: defaultAddresses[1],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[2],
                discount: 0,
                productLookup: productLookup
            ),

            // Coffee + cookbook (holiday entertaining prep)
            order(
                id: "order_amz100242",
                orderNumber: "AMZ100242",
                status: .delivered,
                createdAt: "2025-12-03T08:30:00Z",
                items: [("organic_coffee_042", 1, [:]), ("cookbook_019", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Nov 2025 ──────────────────────────────────────────────

            // Household essentials restock late Nov
            order(
                id: "order_amz100241",
                orderNumber: "AMZ100241",
                status: .delivered,
                createdAt: "2025-11-24T14:15:00Z",
                items: [("paper_towels_046", 1, [:]), ("detergent_pods_047", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Workspace upgrade mid-Nov
            order(
                id: "order_amz100240",
                orderNumber: "AMZ100240",
                status: .delivered,
                createdAt: "2025-11-14T10:40:00Z",
                items: [("led_desk_lamp_049", 1, [:]), ("monitor_riser_055", 1, [:])],
                address: defaultAddresses[1],
                paymentMethod: defaultPaymentMethods[2],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Atomic Habits + Five Minute Journal early Nov
            order(
                id: "order_amz100239",
                orderNumber: "AMZ100239",
                status: .delivered,
                createdAt: "2025-11-05T09:00:00Z",
                items: [("productivity_hardcover_018", 1, [:]), ("wellness_journal_024", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Oct 2025 ──────────────────────────────────────────────

            // Cat tree + cat toy (setting up for new apartment)
            order(
                id: "order_amz100238",
                orderNumber: "AMZ100238",
                status: .delivered,
                createdAt: "2025-10-14T11:30:00Z",
                items: [("cat_tree_121", 1, [:]), ("cat_toy_104", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 10,
                productLookup: productLookup
            ),

            // Electric toothbrush — returned (wrong color, reordered separately)
            order(
                id: "order_amz100237",
                orderNumber: "AMZ100237",
                status: .returned,
                createdAt: "2025-10-08T16:45:00Z",
                items: [("electric_toothbrush_096", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Basics restock early Oct — t-shirts + shorts
            order(
                id: "order_amz100236",
                orderNumber: "AMZ100236",
                status: .delivered,
                createdAt: "2025-10-02T08:15:00Z",
                items: [("hanes_tshirt_pack_141", 1, ["Size": "L", "Color": "White"]), ("under_armour_shorts_144", 2, ["Size": "L", "Color": "Black"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Sep 2025 ──────────────────────────────────────────────

            // Stanley tumbler + water bottle (hydration gear)
            order(
                id: "order_amz100235",
                orderNumber: "AMZ100235",
                status: .delivered,
                createdAt: "2025-09-28T14:00:00Z",
                items: [("stanley_tumbler_119", 1, ["Color": "Cream"]), ("water_bottle_074", 1, ["Color": "Black"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // AirPods Pro — birthday gift to self
            order(
                id: "order_amz100234",
                orderNumber: "AMZ100234",
                status: .delivered,
                createdAt: "2025-09-15T10:00:00Z",
                items: [("airpods_pro_108", 1, ["Case": "MagSafe (USB-C)"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Carhartt beanie + protein powder early Sep
            order(
                id: "order_amz100233",
                orderNumber: "AMZ100233",
                status: .delivered,
                createdAt: "2025-09-05T07:30:00Z",
                items: [("carhartt_beanie_142", 1, ["Color": "Black"]), ("protein_powder_041", 1, ["Flavor": "Double Rich Chocolate"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Aug 2025 ──────────────────────────────────────────────

            // Back to school/office supplies late Aug
            order(
                id: "order_amz100232",
                orderNumber: "AMZ100232",
                status: .delivered,
                createdAt: "2025-08-26T09:00:00Z",
                items: [("sticky_notes_101", 1, [:]), ("gel_pen_pack_051", 1, [:]), ("phone_stand_149", 1, [:])],
                address: defaultAddresses[1],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Household restock mid-Aug
            order(
                id: "order_amz100231",
                orderNumber: "AMZ100231",
                status: .delivered,
                createdAt: "2025-08-15T11:30:00Z",
                items: [("paper_towels_046", 1, [:]), ("trash_bags_099", 1, [:]), ("swiffer_wetjet_147", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Summer reading early Aug
            order(
                id: "order_amz100230",
                orderNumber: "AMZ100230",
                status: .delivered,
                createdAt: "2025-08-04T20:00:00Z",
                items: [("paperback_novel_017", 1, [:]), ("childrens_space_book_021", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Jul 2025 ──────────────────────────────────────────────

            // Summer outdoor gear late Jul
            order(
                id: "order_amz100229",
                orderNumber: "AMZ100229",
                status: .delivered,
                createdAt: "2025-07-22T14:30:00Z",
                items: [("sunscreen_lotion_036", 2, [:]), ("water_bottle_074", 1, ["Color": "Pacific"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Prime Day haul mid-Jul
            order(
                id: "order_amz100228",
                orderNumber: "AMZ100228",
                status: .delivered,
                createdAt: "2025-07-15T08:00:00Z",
                items: [("kindle_paperwhite_109", 1, [:]), ("usb_c_charger_002", 1, ["Pack": "2-Pack"]), ("lip_balm_pack_037", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[0],
                discount: 25,
                productLookup: productLookup
            ),

            // Pet supplies restock early Jul
            order(
                id: "order_amz100227",
                orderNumber: "AMZ100227",
                status: .delivered,
                createdAt: "2025-07-03T10:15:00Z",
                items: [("dog_food_105", 1, [:]), ("dog_treats_065", 1, ["Flavor": "Beef"]), ("cat_litter_066", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Jun 2025 ──────────────────────────────────────────────

            // Skincare summer prep late Jun
            order(
                id: "order_amz100226",
                orderNumber: "AMZ100226",
                status: .delivered,
                createdAt: "2025-06-24T17:00:00Z",
                items: [("face_moisturizer_033", 1, ["Size": "12 oz"]), ("vitamin_c_serum_034", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 3,
                productLookup: productLookup
            ),

            // Gaming accessories mid-Jun
            order(
                id: "order_amz100225",
                orderNumber: "AMZ100225",
                status: .delivered,
                createdAt: "2025-06-12T22:00:00Z",
                items: [("ps5_controller_084", 1, [:]), ("ps5_headset_085", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Household essentials early Jun
            order(
                id: "order_amz100224",
                orderNumber: "AMZ100224",
                status: .delivered,
                createdAt: "2025-06-05T09:30:00Z",
                items: [("detergent_pods_047", 1, [:]), ("paper_towels_046", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // ── May 2025 ──────────────────────────────────────────────

            // Birthday gift for friend late May
            order(
                id: "order_amz100223",
                orderNumber: "AMZ100223",
                status: .delivered,
                createdAt: "2025-05-28T13:00:00Z",
                items: [("board_game_059", 1, [:]), ("candle_set_112", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Protein powder reorder + snacks mid-May
            order(
                id: "order_amz100222",
                orderNumber: "AMZ100222",
                status: .delivered,
                createdAt: "2025-05-14T07:45:00Z",
                items: [("protein_powder_041", 1, ["Flavor": "Double Rich Chocolate"]), ("snack_box_048", 1, [:]), ("energy_drinks_098", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Mother's Day gift early May
            order(
                id: "order_amz100221",
                orderNumber: "AMZ100221",
                status: .delivered,
                createdAt: "2025-05-06T19:00:00Z",
                items: [("lounge_set_032", 1, ["Size": "M/L", "Color": "Dusty Rose"]), ("shampoo_duo_035", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Apr 2025 ──────────────────────────────────────────────

            // Spring cleaning supplies late Apr
            order(
                id: "order_amz100220",
                orderNumber: "AMZ100220",
                status: .delivered,
                createdAt: "2025-04-22T10:00:00Z",
                items: [("air_purifier_013", 1, [:]), ("trash_bags_099", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 10,
                productLookup: productLookup
            ),

            // Pet supplies restock mid-Apr
            order(
                id: "order_amz100219",
                orderNumber: "AMZ100219",
                status: .delivered,
                createdAt: "2025-04-10T14:30:00Z",
                items: [("dog_treats_065", 2, ["Flavor": "Chicken"]), ("dental_chews_072", 1, ["Dog Size": "Regular"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // New monitor + accessories early Apr
            order(
                id: "order_amz100218",
                orderNumber: "AMZ100218",
                status: .delivered,
                createdAt: "2025-04-02T16:00:00Z",
                items: [("monitor_27inch_004", 1, [:]), ("wireless_mouse_007", 1, ["Color": "Graphite"])],
                address: defaultAddresses[1],
                paymentMethod: defaultPaymentMethods[2],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // ── Mar 2025 ──────────────────────────────────────────────

            // Coffee + groceries late Mar
            order(
                id: "order_amz100217",
                orderNumber: "AMZ100217",
                status: .delivered,
                createdAt: "2025-03-25T08:00:00Z",
                items: [("organic_coffee_042", 1, [:]), ("olive_oil_045", 1, [:]), ("himalayan_salt_117", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Everyday clothing mid-Mar
            order(
                id: "order_amz100216",
                orderNumber: "AMZ100216",
                status: .delivered,
                createdAt: "2025-03-12T11:45:00Z",
                items: [("everyday_hoodie_026", 1, ["Size": "L", "Color": "Oxford Gray"]), ("crew_socks_029", 2, ["Size": "L"])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            ),

            // Hair care + grooming early Mar
            order(
                id: "order_amz100215",
                orderNumber: "AMZ100215",
                status: .delivered,
                createdAt: "2025-03-03T15:30:00Z",
                items: [("beard_trimmer_039", 1, [:]), ("hair_dryer_brush_040", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 5,
                productLookup: productLookup
            ),

            // ── Feb 2025 ──────────────────────────────────────────────

            // PS5 console + game late Feb
            order(
                id: "order_amz100214",
                orderNumber: "AMZ100214",
                status: .delivered,
                createdAt: "2025-02-24T20:00:00Z",
                items: [("ps5_digital_bundle_081", 1, [:]), ("nintendo_switch_game_138", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[1],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Valentine's Day order mid-Feb
            order(
                id: "order_amz100213",
                orderNumber: "AMZ100213",
                status: .delivered,
                createdAt: "2025-02-11T12:00:00Z",
                items: [("performance_leggings_027", 1, ["Size": "6", "Color": "Black"]), ("cleansing_balm_038", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[1],
                discount: 0,
                productLookup: productLookup
            ),

            // Household restock early Feb
            order(
                id: "order_amz100212",
                orderNumber: "AMZ100212",
                status: .delivered,
                createdAt: "2025-02-03T09:15:00Z",
                items: [("paper_towels_046", 1, [:]), ("sparkling_water_043", 1, [:]), ("detergent_pods_047", 1, [:])],
                address: defaultAddresses[0],
                paymentMethod: defaultPaymentMethods[0],
                deliveryOption: deliveryOptions[0],
                discount: 0,
                productLookup: productLookup
            )
        ]
    }

    // MARK: - User Reviews

    private static let seededUserReviews: [UserReview] = [

        // Running shoes — ordered Jan 12, delivered ~Jan 14, reviewed Jan 17
        UserReview(
            id: "review_running_shoes_025",
            productID: "running_shoes_025",
            authorName: "Jordan Avery",
            rating: 5,
            title: "Great cushioning right out of the box",
            body: "I started running again in the new year and these have been fantastic from day one. The arch support is solid without feeling stiff, and they handle both pavement and light trail without any issues. Easily the most comfortable pair I have owned in this price range.",
            reviewDate: date("2026-01-17T19:30:00Z"),
            isVerifiedPurchase: true
        ),

        // LED desk lamp — ordered Nov 14, delivered ~Nov 16, reviewed Nov 20
        UserReview(
            id: "review_led_desk_lamp_049",
            productID: "led_desk_lamp_049",
            authorName: "Jordan Avery",
            rating: 4,
            title: "Clean design, very functional",
            body: "The brightness range is impressive for the size and the color-temperature dial makes a big difference during late-night work sessions. Build quality feels premium. Only reason for four stars is the touch controls are a bit finicky when your hands are cold.",
            reviewDate: date("2025-11-20T21:15:00Z"),
            isVerifiedPurchase: true
        ),

        // Dog treats — ordered Feb 6, delivered ~Feb 8, reviewed Feb 11
        UserReview(
            id: "review_dog_treats_065",
            productID: "dog_treats_065",
            authorName: "Jordan Avery",
            rating: 5,
            title: "My dog goes absolutely nuts for these",
            body: "I have tried probably a dozen treat brands and these are the clear winner. The chicken flavor smells like actual food, not some processed mystery substance. My pup sits and waits patiently the moment she sees the bag come out. Will definitely reorder.",
            reviewDate: date("2026-02-11T10:45:00Z"),
            isVerifiedPurchase: true
        ),

        // Face moisturizer — ordered Feb 18, delivered ~Feb 20, reviewed Feb 23
        UserReview(
            id: "review_face_moisturizer_033",
            productID: "face_moisturizer_033",
            authorName: "Jordan Avery",
            rating: 4,
            title: "Lightweight and absorbs fast",
            body: "This is my second order so clearly I keep coming back. The formula is light enough for morning use under sunscreen and does not leave a greasy residue. I wish the 1.7 oz size lasted a bit longer for the price, but the quality is worth it.",
            reviewDate: date("2026-02-23T08:20:00Z"),
            isVerifiedPurchase: true
        ),

        // Yoga mat — ordered Dec 28, delivered ~Dec 30, reviewed Jan 2
        UserReview(
            id: "review_yoga_mat_073",
            productID: "yoga_mat_073",
            authorName: "Jordan Avery",
            rating: 3,
            title: "Decent mat but had a strong smell at first",
            body: "The grip and thickness are fine for home practice and it rolls up without curling at the edges. However, the chemical smell when I first unboxed it was pretty intense and took almost a week of airing out before I could use it comfortably. Performance is good once that fades.",
            reviewDate: date("2026-01-02T14:00:00Z"),
            isVerifiedPurchase: true
        ),

        // Cookware set — ordered Jan 25, delivered ~Jan 27, reviewed Jan 31
        UserReview(
            id: "review_cookware_set_011",
            productID: "cookware_set_011",
            authorName: "Jordan Avery",
            rating: 5,
            title: "Excellent set for the price",
            body: "I upgraded from a cheap nonstick set and the difference is night and day. Even heat distribution, comfortable handles, and the graphite finish looks great in my kitchen. Everything from scrambled eggs to a full stir-fry comes out perfectly. Highly recommend.",
            reviewDate: date("2026-01-31T17:00:00Z"),
            isVerifiedPurchase: true
        ),

        // Productivity hardcover — ordered Nov 5, delivered ~Nov 7, reviewed Nov 11
        UserReview(
            id: "review_productivity_hardcover_018",
            productID: "productivity_hardcover_018",
            authorName: "Jordan Avery",
            rating: 4,
            title: "Practical advice you can actually use",
            body: "I read this in about three sittings and immediately started applying a couple of the habit-stacking ideas at work. The writing is clear and there is very little filler compared to other books in the genre. Some chapters feel repetitive, but overall it delivered real value.",
            reviewDate: date("2025-11-11T20:30:00Z"),
            isVerifiedPurchase: true
        ),

        // Paper towels — ordered Nov 24, delivered ~Nov 26, reviewed Dec 1
        UserReview(
            id: "review_paper_towels_046",
            productID: "paper_towels_046",
            authorName: "Jordan Avery",
            rating: 5,
            title: "Subscribe and never think about it again",
            body: "I set these up on Subscribe and Save and it is the best grocery decision I have made. The select-a-size sheets are great because I usually only need a half sheet for small spills. Absorbency is leagues ahead of the generic brand I used to buy. Twelve family rolls last me about two months.",
            reviewDate: date("2025-12-01T09:00:00Z"),
            isVerifiedPurchase: true
        ),

        // Stanley tumbler — ordered Sep 28, delivered ~Sep 30, reviewed Oct 5
        UserReview(
            id: "review_stanley_tumbler_119",
            productID: "stanley_tumbler_119",
            authorName: "Jordan Avery",
            rating: 5,
            title: "I finally understand the hype",
            body: "I thought the Stanley craze was ridiculous until I actually used one. Ice at 7AM is still there at midnight. The handle is comfortable, it fits my car cupholder, and the FlowState lid is genuinely well designed. I keep it on my desk all day and drink way more water now. Worth every dollar.",
            reviewDate: date("2025-10-05T15:30:00Z"),
            isVerifiedPurchase: true
        ),

        // Cat tree — ordered Oct 14, delivered ~Oct 18, reviewed Oct 25
        UserReview(
            id: "review_cat_tree_121",
            productID: "cat_tree_121",
            authorName: "Jordan Avery",
            rating: 4,
            title: "Cats love it, assembly was tedious",
            body: "My two cats were climbing this within five minutes of finishing assembly. They fight over the top perch and the hammock is a favorite nap spot. The sisal posts are holding up well after a month. Took me about an hour to put together though, and the instructions could be clearer. The wall anchor is a nice safety touch.",
            reviewDate: date("2025-10-25T18:45:00Z"),
            isVerifiedPurchase: true
        ),

        // Protein powder — ordered via Subscribe & Save ongoing, reviewed after several months
        UserReview(
            id: "review_protein_powder_041",
            productID: "protein_powder_041",
            authorName: "Jordan Avery",
            rating: 5,
            title: "Gold standard for a reason",
            body: "I have been using this for about three months now post-workout and the Double Rich Chocolate flavor actually tastes good with just water. Mixes completely with a shaker bottle, no clumps. Twenty-four grams of protein per scoop is solid for the price. I have tried other brands and keep coming back to this one.",
            reviewDate: date("2026-02-05T07:30:00Z"),
            isVerifiedPurchase: true
        )
    ] + seededCommunityReviews

    // MARK: - Frequently Bought Together

    static let frequentlyBoughtTogether: [String: [String]] = [
        "noise_canceling_headphones_001": ["usb_c_charger_002", "wireless_mouse_007"],
        "usb_c_charger_002": ["usbc_hub_089", "noise_canceling_headphones_001"],
        "mechanical_keyboard_003": ["wireless_mouse_007", "monitor_riser_055"],
        "ps5_digital_bundle_081": ["ps5_controller_084", "ps5_charging_station_083"],
        "ps5_controller_084": ["ps5_charging_station_083", "ps5_headset_085"],
        "ps5_charging_station_083": ["ps5_controller_084", "ps5_external_storage_086"],
        "ps5_headset_085": ["ps5_controller_084", "ps5_external_storage_086"],
        "air_fryer_009": ["storage_container_set_014", "cookware_set_011"],
        "instant_pot_090": ["cookware_set_011", "storage_container_set_014"],
        "running_shoes_025": ["crew_socks_029", "water_bottle_074"],
        "adidas_ultraboost_114": ["crew_socks_029", "water_bottle_074"],
        "asics_gel_nimbus_123": ["crew_socks_029", "water_bottle_074"],
        "hoka_clifton_124": ["crew_socks_029", "yoga_mat_073"],
        "brooks_ghost_125": ["crew_socks_029", "water_bottle_074"],
        "nb_fresh_foam_126": ["crew_socks_029", "water_bottle_074"],
        "saucony_ride_127": ["crew_socks_029", "water_bottle_074"],
        "on_cloudmonster_128": ["crew_socks_029", "yoga_mat_073"],
        "nike_vomero_129": ["crew_socks_029", "water_bottle_074"],
        "nike_invincible_130": ["crew_socks_029", "water_bottle_074"],
        "brooks_adrenaline_131": ["crew_socks_029", "yoga_mat_073"],
        "hoka_bondi_132": ["crew_socks_029", "water_bottle_074"],
        "asics_kayano_133": ["crew_socks_029", "water_bottle_074"],
        "mizuno_wave_rider_134": ["crew_socks_029", "water_bottle_074"],
        "face_moisturizer_033": ["vitamin_c_serum_034", "sunscreen_lotion_036"],
        "vitamin_c_serum_034": ["face_moisturizer_033", "sunscreen_lotion_036"],
        "sunscreen_lotion_036": ["face_moisturizer_033", "lip_balm_pack_037"],
        "dog_treats_065": ["dental_chews_072", "dog_food_105"],
        "yoga_mat_073": ["resistance_bands_075", "foam_roller_080"],
        "led_desk_lamp_049": ["led_desk_lamp_135", "monitor_riser_055"],
        "led_desk_lamp_135": ["led_desk_lamp_049", "monitor_riser_055"],
        "gel_pen_pack_051": ["sticky_notes_101", "planner_notebook_053"],
        "paper_towels_046": ["detergent_pods_047", "trash_bags_099"],
        "protein_powder_041": ["water_bottle_074", "resistance_bands_075"],
        "kindle_paperwhite_109": ["scifi_novel_092", "finance_book_093"],
        "building_blocks_057": ["art_supplies_060", "magnetic_tiles_120"],
        "board_game_059": ["card_game_102", "puzzle_set_061"],
        "crocs_classic_116": ["crew_socks_029", "stanley_tumbler_119"],
        "stanley_tumbler_119": ["water_bottle_074", "protein_powder_041"],
        "apple_watch_se_136": ["usb_c_charger_002", "airpods_pro_108"],
        "bose_soundlink_flex_137": ["bluetooth_speaker_005", "usb_c_charger_002"],
        "vitamix_blender_139": ["cookware_set_011", "storage_container_set_014"],
        "electric_kettle_140": ["organic_coffee_042", "chamomile_tea_146"],
        "hanes_tshirt_pack_141": ["under_armour_shorts_144", "crew_socks_029"],
        "carhartt_beanie_142": ["trail_jacket_028", "everyday_hoodie_026"],
        "birkenstock_arizona_143": ["sunscreen_lotion_036", "crew_socks_029"],
        "mixed_nuts_145": ["granola_pack_044", "chamomile_tea_146"],
        "swiffer_wetjet_147": ["paper_towels_046", "trash_bags_099"],
        "cat_fountain_152": ["cat_litter_066", "cat_toy_104"],
        "cat_tree_121": ["cat_fountain_152", "scratching_post_069"],
        "trekking_poles_153": ["trail_backpack_077", "water_bottle_074"],
        "ab_roller_154": ["resistance_bands_075", "yoga_mat_073"],
        "uno_game_151": ["card_game_102", "board_game_059"],
        "play_doh_set_150": ["art_supplies_060", "building_blocks_057"],
        "sleep_mask_155": ["chamomile_tea_146", "noise_machine_122"],
    ]

    // MARK: - Deal of the Day Products

    static let dealOfTheDayProductIDs: [String] = [
        "noise_canceling_headphones_001",
        "air_fryer_009",
        "crocs_classic_116",
        "instant_pot_090",
        "dumbbell_set_078",
        "cordless_vacuum_010",
        "vitamix_blender_139",
        "ab_roller_154",
        "camping_tent_107",
        "bluetooth_speaker_005",
        "adidas_ultraboost_114",
        "stand_mixer_111",
    ]

    // MARK: - Featured Products

    static let amazonsChoiceProductIDs: Set<String> = [
        "noise_canceling_headphones_001",
        "air_fryer_009",
        "paper_towels_046",
        "gel_pen_pack_051",
        "dog_treats_065",
        "crocs_classic_116",
        "stanley_tumbler_119",
        "building_blocks_057",
        "instant_pot_090",
        "water_bottle_074",
        "detergent_pods_047",
        "resistance_bands_075",
        "hanes_tshirt_pack_141",
        "carhartt_beanie_142",
        "uno_game_151",
        "desk_fan_148",
        "swiffer_wetjet_147",
        "chamomile_tea_146",
        "face_moisturizer_033",
        "cat_litter_066",
        "yoga_mat_073",
        "leash_harness_068",
        "protein_powder_041",
        "everyday_hoodie_026",
        "crew_socks_029",
        "mixed_nuts_145",
        "phone_stand_149",
        "trash_bags_099",
    ]

    // MARK: - Subscribe & Save Eligible Products

    static let subscribeAndSaveProductIDs: Set<String> = [
        "paper_towels_046",
        "detergent_pods_047",
        "dog_treats_065",
        "dental_chews_072",
        "dog_food_105",
        "cat_litter_066",
        "protein_powder_041",
        "organic_coffee_042",
        "energy_drinks_098",
        "trash_bags_099",
        "snack_box_048",
        "water_filter_118",
        "face_moisturizer_033",
        "vitamin_c_serum_034",
        "sunscreen_lotion_036",
        "lip_balm_pack_037",
        "chamomile_tea_146",
        "mixed_nuts_145",
        "swiffer_wetjet_147",
        "granola_pack_044",
        "sparkling_water_043",
        "cat_food_103",
        "beard_trimmer_039",
        "face_mask_097",
        "electric_toothbrush_096",
    ]

    // MARK: - Community Reviews

    private static let seededCommunityReviews: [UserReview] = [
        // Sony headphones
        UserReview(id: "community_001", productID: "noise_canceling_headphones_001", authorName: "AudioPhile88", rating: 5, title: "Best ANC on the market, period", body: "Upgraded from the XM4 and the noise cancellation jump is significant. Airplane noise is completely gone. Sound quality is detailed and warm. Battery lasts me a full week of commuting. Worth every penny.", reviewDate: date("2026-02-14T08:30:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_002", productID: "noise_canceling_headphones_001", authorName: "TechReviewSam", rating: 4, title: "Great sound, mediocre call quality", body: "Music playback is phenomenal — rich bass, clear mids. However, people on calls say I sound slightly muffled in windy environments. The multipoint Bluetooth works flawlessly between my phone and laptop.", reviewDate: date("2026-01-22T14:15:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_003", productID: "noise_canceling_headphones_001", authorName: "commuter_daily", rating: 5, title: "40-hour battery is no joke", body: "I charge these once every 10 days with 3-4 hours of daily use. The comfort is excellent for extended wear and the folding design fits perfectly in my bag.", reviewDate: date("2026-02-03T11:00:00Z"), isVerifiedPurchase: true),

        // PS5 bundle
        UserReview(id: "community_004", productID: "ps5_digital_bundle_081", authorName: "GamerDad2026", rating: 5, title: "Finally got one — absolutely worth the wait", body: "Set up was a breeze. The SSD load times are genuinely mind-blowing coming from PS4. Fortnite bundle content was a nice bonus for my kids. Astro's Playroom really showcases the DualSense.", reviewDate: date("2026-02-20T19:45:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_005", productID: "ps5_digital_bundle_081", authorName: "DigitalOnly_FTW", rating: 4, title: "Love it, but miss having a disc drive", body: "Performance is incredible. Haptic feedback is next-gen. My only regret is going digital — I have a shelf of PS4 discs I can't play. If you're all-in on digital purchases, this is the way to go.", reviewDate: date("2026-01-30T22:10:00Z"), isVerifiedPurchase: true),

        // Air fryer
        UserReview(id: "community_006", productID: "air_fryer_009", authorName: "HealthyEats_KC", rating: 5, title: "Replaced my deep fryer and never looked back", body: "Chicken wings come out perfectly crispy. French fries taste almost identical to deep fried. Easy to clean, compact enough for a small kitchen counter. Game changer for meal prep.", reviewDate: date("2026-02-10T17:30:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_007", productID: "air_fryer_009", authorName: "BusyMomOf3", rating: 4, title: "Kids love it, wish it was bigger", body: "Makes after-school snacks in minutes. Nuggets, pizza rolls, sweet potato fries — everything comes out great. The 4-quart size is a bit small for a family of five though. Works perfectly for 2-3 servings.", reviewDate: date("2026-01-15T12:20:00Z"), isVerifiedPurchase: true),

        // Crocs
        UserReview(id: "community_008", productID: "crocs_classic_116", authorName: "NurseJess_RN", rating: 5, title: "12-hour hospital shifts in these", body: "I've tried every shoe brand during my nursing career. Crocs are the only ones that keep my feet comfortable through a full shift. Easy to clean after spills. Bought 3 pairs now.", reviewDate: date("2026-02-08T06:45:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_009", productID: "crocs_classic_116", authorName: "SneakerHead_Mike", rating: 5, title: "I was a hater, now I'm a convert", body: "I'll admit I made fun of Crocs for years. My girlfriend bought me a pair as a joke. Now I wear them literally every day around the house and to walk the dog. The comfort is unreal.", reviewDate: date("2026-01-28T16:00:00Z"), isVerifiedPurchase: true),

        // Instant Pot
        UserReview(id: "community_010", productID: "instant_pot_090", authorName: "MealPrep_Queen", rating: 5, title: "The kitchen appliance that does everything", body: "I've made chili, rice, yogurt, hard-boiled eggs, and pot roast all in the first week. The sauté function means you can brown meat right in the pot. Replaced my rice cooker and slow cooker.", reviewDate: date("2026-02-05T20:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_011", productID: "instant_pot_090", authorName: "CollegeKid_Tyler", rating: 4, title: "Dorm room lifesaver", body: "I can make real meals now instead of ramen every night. The learning curve is real though — my first attempt at rice was soup. Once you figure out water ratios, it's amazing. Worth watching YouTube tutorials first.", reviewDate: date("2026-01-20T21:30:00Z"), isVerifiedPurchase: true),

        // Stanley tumbler
        UserReview(id: "community_012", productID: "stanley_tumbler_119", authorName: "HydrationStation", rating: 5, title: "Ice still there 24 hours later", body: "Not exaggerating — I put ice in at 7am and it's still clinking around at 7am the next day. The straw makes it so easy to stay hydrated. Fits my car cup holder perfectly. Understand the hype now.", reviewDate: date("2026-02-12T09:15:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_013", productID: "stanley_tumbler_119", authorName: "FitnessCoach_Ali", rating: 4, title: "Great tumbler, heavy when full", body: "The 40oz size is perfect for my gym sessions. Quality is top notch and the lid doesn't leak in my bag. Only downside is it's pretty heavy when completely full — wouldn't recommend for small kids.", reviewDate: date("2026-01-25T15:40:00Z"), isVerifiedPurchase: true),

        // Paper towels
        UserReview(id: "community_014", productID: "paper_towels_046", authorName: "CleanFreak_Sara", rating: 5, title: "The only paper towels I'll buy", body: "I've tried every store brand and generic alternative. Nothing absorbs like Bounty. The select-a-size is brilliant — I use half sheets for small spills and save money. Subscribe & Save makes it even better.", reviewDate: date("2026-02-01T13:00:00Z"), isVerifiedPurchase: true),

        // Building blocks
        UserReview(id: "community_015", productID: "building_blocks_057", authorName: "Parent_of_Builders", rating: 5, title: "Best investment for creative play", body: "My 6-year-old has been building nonstop for two weeks. The variety of colors and special pieces (wheels, windows, doors) keep the builds interesting. Way better value than themed sets. The storage box is also genuinely useful.", reviewDate: date("2026-02-16T10:30:00Z"), isVerifiedPurchase: true),

        // Dog treats
        UserReview(id: "community_016", productID: "dog_treats_065", authorName: "DogMom_Sophie", rating: 5, title: "My golden retriever's absolute favorite", body: "We use these for training and they work like magic. Easy to break into smaller pieces for portion control. No upset stomach issues like we've had with other brands. Our vet approves.", reviewDate: date("2026-02-18T11:20:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_017", productID: "dog_treats_065", authorName: "TrainerPro_Mark", rating: 4, title: "Great training treats, wish the bag sealed better", body: "The treats themselves are excellent — right size, good smell, dogs love them. But the bag doesn't reseal very well after opening. I transfer them to a container now. Otherwise perfect.", reviewDate: date("2026-01-10T14:50:00Z"), isVerifiedPurchase: true),

        // Kindle
        UserReview(id: "community_018", productID: "kindle_paperwhite_109", authorName: "BookWorm_Emily", rating: 5, title: "Reading in bed has never been better", body: "The warm light is so much easier on my eyes than my phone screen. Battery lasts weeks, not days. Waterproof means I can read in the bath without paranoia. Best device purchase I've made in years.", reviewDate: date("2026-02-07T22:00:00Z"), isVerifiedPurchase: true),

        // Champion hoodie
        UserReview(id: "community_019", productID: "everyday_hoodie_026", authorName: "LayeredUp_Jake", rating: 5, title: "Best hoodie under $40, no question", body: "I own this in three colors now. The Powerblend fabric doesn't shrink or pill like cheaper hoodies. It's thick enough for fall but not too heavy for layering under a jacket. The kangaroo pocket is deep enough for my phone and keys. Absolute steal at this price.", reviewDate: date("2026-01-18T10:30:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_020", productID: "everyday_hoodie_026", authorName: "WFH_Rachel", rating: 4, title: "My work-from-home uniform", body: "I practically live in this hoodie during winter. Super cozy without being too bulky on video calls. Wish it came in more muted colors but the Oxford Gray is my go-to. Holds up great in the wash.", reviewDate: date("2026-02-04T16:45:00Z"), isVerifiedPurchase: true),

        // Lululemon leggings
        UserReview(id: "community_021", productID: "performance_leggings_027", authorName: "YogaDaily_Priya", rating: 5, title: "Worth every penny, I mean it", body: "I resisted paying this much for leggings for years. Then I tried Aligns and immediately understood. The Nulu fabric feels like wearing nothing. They stay up through vinyasa, barre, and even running errands. I have three pairs and want more.", reviewDate: date("2026-02-15T09:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_022", productID: "performance_leggings_027", authorName: "FitMom_Kelly", rating: 4, title: "Buttery soft but handle with care", body: "The fabric is absolutely incredible — like wearing butter. BUT they are delicate. I got a small snag from my cat's claws in the first week. Air dry only, no fabric softener. If you treat them right, they last. True Navy is gorgeous.", reviewDate: date("2026-01-29T14:20:00Z"), isVerifiedPurchase: true),

        // Nike Pegasus running shoes
        UserReview(id: "community_023", productID: "running_shoes_025", authorName: "MarathonMike_26", rating: 5, title: "My go-to daily trainer for 3 years running", body: "This is my fourth pair of Pegasus (38, 39, 40, now these). They just work. Responsive enough for tempo runs, cushioned enough for long runs, durable enough to hit 400+ miles. The Zoom Air unit makes a noticeable difference. If it ain't broke, don't fix it.", reviewDate: date("2026-02-22T07:15:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_024", productID: "running_shoes_025", authorName: "C25K_Beginner_Lisa", rating: 4, title: "Great starter running shoe", body: "Started my Couch to 5K journey in these and they've been kind to my beginner legs. Good cushioning on pavement, no blisters even on my first long run. Slightly narrow in the toe box for my wide feet but I went up half a size and they're perfect.", reviewDate: date("2026-01-08T18:30:00Z"), isVerifiedPurchase: true),

        // Resistance bands
        UserReview(id: "community_025", productID: "resistance_bands_075", authorName: "HomeFitness_Dani", rating: 5, title: "Replaced my gym membership honestly", body: "Between these bands and a few bodyweight exercises, I get a full workout at home. The five resistance levels mean I can progress over time. The carry bag makes them perfect for travel. At $11 this is the best fitness investment I've made.", reviewDate: date("2026-02-09T20:00:00Z"), isVerifiedPurchase: true),

        // Water bottle
        UserReview(id: "community_026", productID: "water_bottle_074", authorName: "HikerTrash_Ben", rating: 5, title: "Survived a 500-mile thru-hike", body: "Took this on the Colorado Trail. Dropped it off rocks, rolled it down scree fields, left it in freezing temps overnight. Not a single dent. Still keeps water cold for an entire hiking day in July heat. The wide mouth makes filtering water easy.", reviewDate: date("2026-01-20T12:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_027", productID: "water_bottle_074", authorName: "OfficeWorker_Jen", rating: 4, title: "Perfect desk companion, just heavy", body: "I keep this on my desk and it genuinely helps me drink more water. The 32oz size means fewer refill trips. Condensation-free exterior protects my desk. Only complaint is it's pretty heavy when full — definitely a two-hand lift sometimes.", reviewDate: date("2026-02-11T15:30:00Z"), isVerifiedPurchase: true),

        // Yoga mat
        UserReview(id: "community_028", productID: "yoga_mat_073", authorName: "StudioInstructor_Mei", rating: 5, title: "The only mat I recommend to my students", body: "After teaching yoga for 8 years and trying dozens of mats, the Manduka PRO is the one I always come back to. The density is unmatched — knees never hurt, even in long holds. It does take a few sessions to break in the surface, but once it does, the grip is outstanding. Lifetime guarantee is real.", reviewDate: date("2026-02-17T08:45:00Z"), isVerifiedPurchase: true),

        // Cookware set
        UserReview(id: "community_029", productID: "cookware_set_011", authorName: "HomeCook_Carlos", rating: 5, title: "Replaced my 15-year-old pans and no regrets", body: "The heat distribution is noticeably more even than my old set. Eggs slide right off without any oil. The Thermo-Spot indicator is actually useful — I used to always overheat my pan. Dishwasher safe is a huge plus for a lazy cook like me.", reviewDate: date("2026-01-14T19:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_030", productID: "cookware_set_011", authorName: "NewlywedKitchen_Aisha", rating: 4, title: "Great wedding registry pick", body: "We registered for this set and it's been amazing for our first kitchen. Everything we need in one box. The only reason for 4 stars is the handles get warm on the stovetop — always use a towel. Otherwise, excellent quality for the price.", reviewDate: date("2026-02-02T13:15:00Z"), isVerifiedPurchase: true),

        // Air purifier
        UserReview(id: "community_031", productID: "air_purifier_013", authorName: "AllergyDad_Steve", rating: 5, title: "My daughter can finally sleep through the night", body: "We've tried three different air purifiers and this Levoit is by far the best for the price. My daughter has bad allergies and since putting this in her room, she's sleeping through the night without congestion. The sleep mode is whisper quiet. Filter replacement is reasonable at every 6-8 months.", reviewDate: date("2026-02-13T21:00:00Z"), isVerifiedPurchase: true),

        // Protein powder
        UserReview(id: "community_032", productID: "protein_powder_041", authorName: "GymRat_Alex", rating: 5, title: "30 years of trust isn't a marketing gimmick", body: "I've used Gold Standard for over a decade. Double Rich Chocolate is still the best tasting protein powder on the market. Mixes clean, doesn't upset my stomach, and 24g protein per scoop is consistent. The Subscribe & Save price makes it even better.", reviewDate: date("2026-01-25T06:30:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_033", productID: "protein_powder_041", authorName: "PlantCurious_Sam", rating: 3, title: "Good quality but wish they had plant-based", body: "The product itself is fine — mixes well, tastes decent, good macros. I'm giving 3 stars because I'm transitioning to plant-based and wish ON would make a vegan version with the same quality. If you're fine with whey, this is the gold standard (pun intended).", reviewDate: date("2026-02-19T14:00:00Z"), isVerifiedPurchase: true),

        // ── Negative / Critical Reviews (Realism) ─────────────────

        // Cordless vacuum — 2 stars
        UserReview(id: "community_034", productID: "cordless_vacuum_010", authorName: "DisappointedDan_42", rating: 2, title: "Battery died after 8 months", body: "The suction and features are incredible when it works. But after 8 months of normal use (2-3 times per week), the battery barely holds a charge for 15 minutes. For $200+ I expected it to last longer. Customer service was unhelpful. Switched to a different brand.", reviewDate: date("2026-02-10T16:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_035", productID: "cordless_vacuum_010", authorName: "HonestReviewer_Kay", rating: 3, title: "Great vacuum, terrible battery life claims", body: "60 minutes of battery is wildly optimistic — that's on the lowest power setting where it barely picks up crumbs. On auto or boost mode, you get maybe 20-25 minutes. The laser is cool but gimmicky. It is a good vacuum overall, just manage your expectations.", reviewDate: date("2026-01-12T09:30:00Z"), isVerifiedPurchase: true),

        // Robot mop — 1 star
        UserReview(id: "community_036", productID: "robot_mop_015", authorName: "Frustrated_Buyer_101", rating: 1, title: "Spread dirty water everywhere", body: "This thing mopped my kitchen with dirty water and left streaks all over the hardwood. It also got stuck under my couch three times in one run. The self-emptying base is loud enough to wake up my baby. Returned within a week. Save your money and just use a Swiffer.", reviewDate: date("2026-01-20T22:00:00Z"), isVerifiedPurchase: true),

        // Espresso machine — 2 stars
        UserReview(id: "community_037", productID: "espresso_machine_012", authorName: "CoffeePurist_Marco", rating: 2, title: "Capsule system is a money pit", body: "The coffee it makes is decent but not great — nowhere near a real espresso machine. The real problem is the cost per cup. Each capsule is $1+ and you go through them fast. Over a year you'll spend more on pods than on a proper machine. The plastic waste is also concerning.", reviewDate: date("2026-02-05T07:00:00Z"), isVerifiedPurchase: true),

        // Smart home hub — 2 stars
        UserReview(id: "community_038", productID: "smart_home_hub_006", authorName: "PrivacyFirst_Nina", rating: 2, title: "Always listening, mediocre sound", body: "Returned this after a week. The sound quality is mediocre for $90 — a $30 Bluetooth speaker sounds better for music. And despite the 'mic off' button, I'm not comfortable with a microphone in my living room that's connected to the internet 24/7. Not worth the privacy trade-off.", reviewDate: date("2026-01-05T15:00:00Z"), isVerifiedPurchase: true),

        // Action camera — 1 star (out of stock frustration)
        UserReview(id: "community_039", productID: "action_camera_008", authorName: "WaitingForever_Tim", rating: 1, title: "Listed as available, been 'unavailable' for months", body: "I've been checking this listing every week for two months and it's never actually available. The 'Adventure Kit' bundle has been unavailable since I started looking. Just take the listing down if you don't have inventory. Frustrating experience.", reviewDate: date("2026-02-24T10:00:00Z"), isVerifiedPurchase: false),

        // Detergent pods — mixed
        UserReview(id: "community_040", productID: "detergent_pods_047", authorName: "LaundrySkeptic_Pat", rating: 3, title: "Work fine but overpriced per load", body: "They clean clothes well enough, and the convenience of not measuring is nice. But at $0.36 per load versus $0.12 for liquid detergent, you're paying 3x for convenience. The pods sometimes don't fully dissolve in cold water either. Switched back to liquid.", reviewDate: date("2026-02-15T12:30:00Z"), isVerifiedPurchase: true),

        // Mechanical keyboard — mixed
        UserReview(id: "community_041", productID: "mechanical_keyboard_003", authorName: "OfficeTypist_Greg", rating: 3, title: "Too loud for a shared office", body: "The typing feel is fantastic and the hot-swappable feature is great. But even with Brown switches, this keyboard is significantly louder than my old membrane board. My coworkers started giving me looks within a day. Had to switch back for the office and use it at home only.", reviewDate: date("2026-01-30T11:00:00Z"), isVerifiedPurchase: true),

        // ── Additional Positive Reviews ───────────────────────────

        // KitchenAid stand mixer
        UserReview(id: "community_042", productID: "stand_mixer_111", authorName: "BakerExtraordinaire", rating: 5, title: "Makes baking actually enjoyable", body: "I put off buying a stand mixer for years because of the price. Now I regret every year I waited. Bread dough, cookie batter, whipped cream — everything is effortless. The attachments are a game changer. I use the pasta roller attachment weekly now.", reviewDate: date("2026-02-12T18:00:00Z"), isVerifiedPurchase: true),
        UserReview(id: "community_043", productID: "stand_mixer_111", authorName: "WeddingCake_Lisa", rating: 5, title: "Worth saving up for", body: "Got this as a wedding gift and it's the most-used appliance in our kitchen. We've made everything from pizza dough to meringue. The Empire Red looks gorgeous on the counter. Ten speeds gives you so much control. This thing will outlast me.", reviewDate: date("2026-01-22T14:45:00Z"), isVerifiedPurchase: true),

        // Birkenstock
        UserReview(id: "community_044", productID: "birkenstock_arizona_143", authorName: "PodiatristApproved_Dr", rating: 5, title: "I recommend these to my patients", body: "As a podiatrist, I recommend Birkenstocks more than any other sandal. The cork footbed provides genuine arch support that prevents plantar fasciitis. The break-in period is real — give it 2 weeks. Once molded to your foot, nothing else compares.", reviewDate: date("2026-02-20T09:00:00Z"), isVerifiedPurchase: true),

        // Apple Watch SE
        UserReview(id: "community_045", productID: "apple_watch_se_136", authorName: "FirstWatch_Danny", rating: 4, title: "Perfect first Apple Watch, skip the Ultra", body: "Upgraded from a Fitbit and the Apple Watch SE does everything I need. Notifications, workouts, heart rate, Apple Pay. The always-on display is missing but honestly I just raise my wrist. Saved $300 over the Series 9 with no regret.", reviewDate: date("2026-02-18T17:30:00Z"), isVerifiedPurchase: true),

        // UNO
        UserReview(id: "community_046", productID: "uno_game_151", authorName: "GameNight_Family", rating: 5, title: "Destroys friendships, 10/10 would recommend", body: "Brought this on a family camping trip. My 7-year-old hit me with a Draw Four and then stacked another one. We've been playing every night since. For $6 you get infinite entertainment and memorable arguments. A must-have for every household.", reviewDate: date("2026-02-08T20:00:00Z"), isVerifiedPurchase: true),

        // Carhartt beanie
        UserReview(id: "community_047", productID: "carhartt_beanie_142", authorName: "ChicagoWinter_Mike", rating: 5, title: "Survived a Chicago winter, enough said", body: "If this beanie can keep my head warm during a -15°F polar vortex walk to the L, it can handle anything. I own four of these in different colors. They don't stretch out, don't pill, and the fold stays put. At $17, buy two.", reviewDate: date("2026-02-25T08:00:00Z"), isVerifiedPurchase: true),

        // Hanes t-shirts
        UserReview(id: "community_048", productID: "hanes_tshirt_pack_141", authorName: "BasicBro_Dave", rating: 4, title: "Best undershirts for the money", body: "I buy these every year. Six shirts for under $20 is unbeatable. They hold up through about 40-50 washes before the collars start to loosen. The ring-spun cotton is noticeably softer than the regular Hanes. Just size up if you want a relaxed fit.", reviewDate: date("2026-01-15T10:00:00Z"), isVerifiedPurchase: true),

        // Sheet set — negative
        UserReview(id: "community_049", productID: "sheet_set_016", authorName: "SleepQuality_Jess", rating: 2, title: "Pilling after 3 washes, disappointing for the price", body: "These sheets felt amazing the first night. By the third wash, tiny pills appeared all over the fitted sheet. For $150 I expect better durability. The sateen finish is nice but sateen sheets pill faster than percale. At this price point, I'd go with a different brand.", reviewDate: date("2026-02-03T23:00:00Z"), isVerifiedPurchase: true),

        // Monitor — mixed
        UserReview(id: "community_050", productID: "monitor_27inch_004", authorName: "DesignerEye_Chris", rating: 3, title: "Good for office work, bad for creative work", body: "For spreadsheets, email, and browsing, this monitor is perfectly fine. But the 99% sRGB claim is generous — side by side with my MacBook display, colors look washed out. The 60Hz refresh rate also feels laggy if you game at all. Fine for the price, just know the limitations.", reviewDate: date("2026-01-28T16:00:00Z"), isVerifiedPurchase: true),
    ]

    // MARK: - Customer Q&A

    static let customerQandA: [String: [(question: String, answer: String, asker: String, answerer: String)]] = [
        "noise_canceling_headphones_001": [
            (question: "Can you use these wired if the battery dies?", answer: "Yes! There's a 3.5mm audio cable included. You can plug in and keep listening even with a dead battery, though ANC won't work.", asker: "TravelBug_22", answerer: "Sony Official"),
            (question: "Do they work well with iPhones?", answer: "Absolutely. Full Bluetooth 5.3 support, multipoint connection, and the Sony Headphones app works great on iOS for EQ customization.", asker: "AppleFan_Mike", answerer: "AudioPhile88"),
        ],
        "ps5_digital_bundle_081": [
            (question: "Can I add a disc drive later?", answer: "No, the Digital Edition does not support an external disc drive. If you want disc capability, go with the Slim Disc model.", asker: "RetroGamer_99", answerer: "PlayStation"),
            (question: "Does it come with an HDMI cable?", answer: "Yes, it includes an HDMI 2.1 cable, power cord, USB cable, and DualSense controller.", asker: "FirstTimer_Dan", answerer: "GamerDad2026"),
        ],
        "air_fryer_009": [
            (question: "Can you cook frozen food directly without thawing?", answer: "Yes! That's one of the best features. Frozen fries, nuggets, and fish sticks go straight from the freezer. Just add 2-3 minutes to cooking time.", asker: "LazyChef_Tom", answerer: "HealthyEats_KC"),
        ],
        "instant_pot_090": [
            (question: "Is the inner pot dishwasher safe?", answer: "Yes, the stainless steel inner pot, lid, and sealing ring are all dishwasher safe. I just throw them in after every use.", asker: "CleanKitchen_Amy", answerer: "MealPrep_Queen"),
        ],
        "crocs_classic_116": [
            (question: "Do they run true to size?", answer: "They run about half a size large. I normally wear a 10 and the 9 fits perfectly. Crocs recommends sizing down if between sizes.", asker: "ShoeQuestion_Pat", answerer: "NurseJess_RN"),
        ],
        "stanley_tumbler_119": [
            (question: "Does it fit in a standard car cup holder?", answer: "Yes! It fits perfectly in my Honda Civic and Toyota RAV4 cup holders. The tapered bottom is designed for car cup holders.", asker: "Commuter_Dave", answerer: "HydrationStation"),
            (question: "Is the straw removable for cleaning?", answer: "Yes, the straw and the FlowState lid both come apart for thorough cleaning. I run mine through the dishwasher weekly with no issues.", asker: "CleanFreak_Anna", answerer: "FitnessCoach_Ali"),
        ],
        "vitamix_blender_139": [
            (question: "Can it crush ice for frozen drinks?", answer: "Absolutely. It demolishes ice in seconds. I make frozen margaritas and smoothie bowls regularly — no chunks ever. The 2.0 HP motor handles everything.", asker: "CocktailNerd_Ryan", answerer: "HomeCook_Carlos"),
        ],
        "protein_powder_041": [
            (question: "Which flavor is best for mixing with just water?", answer: "Double Rich Chocolate is the best with water by far. Vanilla Ice Cream is also good but better with milk. Strawberry Banana is fine but a bit artificial-tasting with water only.", asker: "GymNewbie_Jordan", answerer: "GymRat_Alex"),
        ],
        "running_shoes_025": [
            (question: "Are these good for flat feet?", answer: "I have flat feet and these work well with my custom orthotics — plenty of room inside. For severe overpronation though, you might want the Adrenaline GTS which has built-in support.", asker: "FlatFeet_Mike", answerer: "MarathonMike_26"),
            (question: "How many miles do these last before needing replacement?", answer: "I typically get 350-400 miles before the cushioning feels dead. I track my mileage with a running app. The outsole rubber holds up well — it's the midsole foam that wears out first.", asker: "MileTracker_Jen", answerer: "C25K_Beginner_Lisa"),
        ],
        "cordless_vacuum_010": [
            (question: "How long does the battery actually last on auto mode?", answer: "On auto mode, I get about 25-30 minutes consistently. The 60-minute claim is for eco mode only, which is basically the lowest power setting. For a typical apartment cleaning session, auto mode is plenty.", asker: "ApartmentDweller_99", answerer: "HonestReviewer_Kay"),
            (question: "Can you use it on thick carpet?", answer: "Works great on low-pile carpet and area rugs. On thick shag carpet it struggles a bit and drains the battery faster. I'd say it's 90% hard floor / 10% carpet optimized.", asker: "CarpetHome_Linda", answerer: "DisappointedDan_42"),
        ],
        "yoga_mat_073": [
            (question: "Does this mat slide on hardwood floors?", answer: "Not at all. The bottom has great grip on hardwood. It does move slightly on polished tile though. I do hot yoga on hardwood and it stays perfectly in place even when I'm sweating.", asker: "HomeYogi_Sarah", answerer: "StudioInstructor_Mei"),
            (question: "How long does the break-in period take?", answer: "About 5-7 sessions before the surface gets good grip. Some people scrub it with sea salt to speed up the process. After break-in, the grip is phenomenal even with sweaty hands.", asker: "NewToYoga_Dan", answerer: "StudioInstructor_Mei"),
        ],
        "mechanical_keyboard_003": [
            (question: "Which switch is best for office use?", answer: "Red switches are quieter than Brown, but honestly all mechanical keyboards are louder than membrane boards. If noise is a concern, add O-ring dampeners ($5 on here) to any switch type. I use Browns with O-rings and it's very tolerable.", asker: "QuietTyper_Amy", answerer: "OfficeTypist_Greg"),
            (question: "Does it work well with Mac?", answer: "Yes, natively via Bluetooth. The function row maps correctly to macOS. You can remap keys with VIA software if you want to swap Alt/Cmd positions. I use it daily with my MacBook Pro.", asker: "MacUser_Jason", answerer: "OfficeTypist_Greg"),
        ],
        "kindle_paperwhite_109": [
            (question: "Can you read library books on it?", answer: "Yes! Use the Libby app to borrow ebooks from your local library, then send them to your e-reader. It's completely free with a library card. I haven't bought a book in months.", asker: "BudgetReader_Tom", answerer: "BookWorm_Emily"),
            (question: "Is the 16GB enough for books?", answer: "More than enough if you're just reading books. A typical ebook is 1-3MB. You could store thousands of books on 16GB. Only go higher if you plan to download a lot of audiobooks, which are much larger.", asker: "StorageWorrier_Pat", answerer: "BookWorm_Emily"),
        ],
        "stand_mixer_111": [
            (question: "Is the 4.5-quart bowl big enough for bread?", answer: "It handles a standard loaf recipe fine (about 3-4 cups of flour). For double batches of bread dough, the motor works hard and the bowl is at capacity. If you bake bread frequently, consider the 5-quart Artisan model.", asker: "BreadBaker_Jamie", answerer: "BakerExtraordinaire"),
            (question: "Which color is best for resale value?", answer: "Empire Red and White hold their value best on the secondhand market. But honestly, these last 20+ years so resale isn't something you need to worry about much.", asker: "SmartShopper_Alex", answerer: "WeddingCake_Lisa"),
        ],
        "everyday_hoodie_026": [
            (question: "Does it shrink in the dryer?", answer: "Minimal shrinkage — that's the whole point of the Powerblend fabric. I wash mine on warm and tumble dry on medium. After 30+ washes it's maybe half an inch shorter. Way better than 100% cotton hoodies.", asker: "LaundryQs_Drew", answerer: "LayeredUp_Jake"),
        ],
        "water_bottle_074": [
            (question: "Does the powder coating chip?", answer: "After a year of daily use including dropping it on concrete twice, mine has a couple small chips on the bottom. The rest looks great. The chips are cosmetic only and don't affect insulation.", asker: "DurabilityCheck_Rob", answerer: "HikerTrash_Ben"),
        ],
        "birkenstock_arizona_143": [
            (question: "How long is the break-in period?", answer: "About 1-2 weeks of wearing them for a few hours at a time. The cork molds to your exact foot shape. Don't try to wear them all day right away or you'll get blisters. After break-in, they're the most comfortable sandals you'll ever own.", asker: "FirstBirks_Morgan", answerer: "PodiatristApproved_Dr"),
        ],
        "air_purifier_013": [
            (question: "How often do you need to replace the filter?", answer: "The app tells you when, but roughly every 6-8 months with daily use. Replacement filters are about $20. If you have pets or allergies, you might need to change it every 4-5 months. Still way cheaper than the Dyson filters.", asker: "AllergyMom_Karen", answerer: "AllergyDad_Steve"),
        ],
        "face_moisturizer_033": [
            (question: "Is this moisturizer enough for winter dryness?", answer: "It works well as a daily moisturizer year-round, but in harsh winter climates you might want to layer it under a heavier cream at night. During the day it's perfect — especially under sunscreen. The 12 oz bottle lasts about 3 months.", asker: "DryWinter_Sarah", answerer: "CleanFreak_Sara"),
        ],
        "carhartt_beanie_142": [
            (question: "Does it fit over big heads?", answer: "I have a 24-inch head circumference and it fits fine. The acrylic has good stretch. It might sit a bit higher on your head than on someone smaller, but it won't feel tight.", asker: "BigHead_Chris", answerer: "ChicagoWinter_Mike"),
        ],
        "performance_leggings_027": [
            (question: "Are these see-through when you bend over?", answer: "Not at all in Black or True Navy. I specifically tested in the gym with bright lights behind me. Dark Olive is also fine. Just don't size up — get your true size and the fabric coverage is perfect.", asker: "GymConfidence_Amy", answerer: "YogaDaily_Priya"),
        ],
        "camping_tent_107": [
            (question: "Can one person set this up alone?", answer: "Yes, it's designed for solo setup. The continuous pole sleeves and Insta-Clips make it genuinely easy. My first time took 15 minutes, now I can do it in under 10. Just stake the floor first for reference.", asker: "SoloCamper_Zoe", answerer: "HikerTrash_Ben"),
        ],
    ]

    // MARK: - Helpers

    private static func product(
        id: String,
        name: String,
        brand: String,
        departmentID: String,
        categoryID: String,
        price: Double,
        originalPrice: Double? = nil,
        rating: Double,
        reviewCount: Int,
        primeEligible: Bool = true,
        deliveryEstimate: String,
        inStock: Bool = true,
        sellerName: String? = nil,
        imageSystemName: String,
        imageURL: String? = nil,
        popularityRank: Int,
        isNewestArrival: Bool = false,
        releaseLabel: String? = nil,
        searchKeywords: [String] = [],
        specifications: [ProductSpecification],
        aboutItems: [String]? = nil,
        variants: [ProductVariant] = [],
        promotions: [Promotion] = []
    ) -> Product {
        let finalSeller = sellerName ?? "\(brand) Store"
        let categoryLabel = categoryName(for: categoryID)
        let defaultBullets = [
            "Designed by \(brand) for dependable everyday \(categoryLabel.lowercased()) use.",
            "Clear delivery, seller, and condition details for realistic shopping flows.",
            "Reliable fit for browse, cart, checkout, and order-history flows."
        ]
        let groupNames = Array(Set(variants.map(\.variantName))).sorted()
        let summary = groupNames.isEmpty ? nil : groupNames.joined(separator: " • ")
        let combinedKeywords = ([name, brand, categoryLabel, departmentName(for: departmentID)] + searchKeywords)
            .map { $0.lowercased() }

        return Product(
            id: id,
            productName: name,
            brand: brand,
            departmentID: departmentID,
            categoryID: categoryID,
            price: price,
            originalPrice: originalPrice,
            currency: "USD",
            rating: rating,
            reviewCount: reviewCount,
            primeEligible: primeEligible,
            deliveryEstimate: deliveryEstimate,
            variantSummary: summary,
            inStock: inStock,
            sellerName: finalSeller,
            condition: "New",
            imageSystemName: imageSystemName,
            imageURL: imageURL,
            aboutItems: aboutItems ?? defaultBullets,
            specifications: specifications,
            variants: variants,
            promotions: promotions,
            popularityRank: popularityRank,
            isNewestArrival: isNewestArrival,
            searchKeywords: combinedKeywords,
            releaseLabel: releaseLabel
        )
    }

    private static func specs(_ values: String...) -> [ProductSpecification] {
        stride(from: 0, to: values.count, by: 2).map { index in
            ProductSpecification(
                id: "spec_\(AccessibilityID.slug(values[index]))",
                title: values[index],
                value: values[index + 1]
            )
        }
    }

    private static func variants(
        _ productID: String,
        name: String,
        values: [String],
        unavailable: Set<String> = [],
        priceAdjustments: [String: Double] = [:]
    ) -> [ProductVariant] {
        values.map { value in
            ProductVariant(
                id: "\(productID)_\(AccessibilityID.slug(name))_\(AccessibilityID.slug(value))",
                variantName: name,
                variantValue: value,
                isAvailable: !unavailable.contains(value),
                priceAdjustment: priceAdjustments[value] ?? 0
            )
        }
    }

    private static func promotion(id: String, title: String, detail: String, badgeText: String) -> Promotion {
        Promotion(id: id, title: title, detail: detail, badgeText: badgeText)
    }

    private static func cartItem(
        productID: String,
        quantity: Int,
        selection: [String: String],
        lookup: [String: Product]
    ) -> CartItem? {
        guard let product = lookup[productID] else { return nil }
        let adjustment = variantPriceAdjustment(for: product, selection: selection)
        return CartItem(
            id: "cart_\(productID)_\(AccessibilityID.slug(Formatters.variantSummary(selection)))",
            productID: product.id,
            productName: product.productName,
            brand: product.brand,
            unitPrice: roundCurrency(product.price + adjustment),
            originalUnitPrice: product.originalPrice.map { roundCurrency($0 + adjustment) },
            currency: product.currency,
            quantity: quantity,
            primeEligible: product.primeEligible,
            deliveryEstimate: product.deliveryEstimate,
            selectedVariantValues: selection,
            sellerName: product.sellerName,
            imageSystemName: product.imageSystemName,
            inStock: product.inStock
        )
    }

    private static func savedItem(
        productID: String,
        selection: [String: String],
        savedAt: String,
        lookup: [String: Product]
    ) -> SavedItem? {
        guard let cartSnapshot = cartItem(productID: productID, quantity: 1, selection: selection, lookup: lookup) else { return nil }
        return SavedItem(
            id: "saved_\(productID)_\(AccessibilityID.slug(Formatters.variantSummary(selection)))",
            productID: cartSnapshot.productID,
            productName: cartSnapshot.productName,
            brand: cartSnapshot.brand,
            unitPrice: cartSnapshot.unitPrice,
            originalUnitPrice: cartSnapshot.originalUnitPrice,
            currency: cartSnapshot.currency,
            primeEligible: cartSnapshot.primeEligible,
            deliveryEstimate: cartSnapshot.deliveryEstimate,
            selectedVariantValues: selection,
            sellerName: cartSnapshot.sellerName,
            imageSystemName: cartSnapshot.imageSystemName,
            inStock: cartSnapshot.inStock,
            savedAt: date(savedAt)
        )
    }

    private static func order(
        id: String,
        orderNumber: String,
        status: OrderStatus,
        createdAt: String,
        items: [(String, Int, [String: String])],
        address: Address,
        paymentMethod: PaymentMethod,
        deliveryOption: DeliveryOption,
        discount: Double,
        productLookup: [String: Product]
    ) -> Order {
        let createdDate = date(createdAt)
        let orderItems = items.compactMap { productID, quantity, selection -> OrderItem? in
            guard let cartSnapshot = cartItem(productID: productID, quantity: quantity, selection: selection, lookup: productLookup) else { return nil }
            return OrderItem(
                id: "order_item_\(productID)_\(quantity)",
                productID: cartSnapshot.productID,
                productName: cartSnapshot.productName,
                brand: cartSnapshot.brand,
                unitPrice: cartSnapshot.unitPrice,
                originalUnitPrice: cartSnapshot.originalUnitPrice,
                currency: cartSnapshot.currency,
                quantity: quantity,
                selectedVariantValues: selection,
                imageSystemName: cartSnapshot.imageSystemName
            )
        }

        let itemSubtotal = roundCurrency(orderItems.reduce(0) { $0 + ($1.unitPrice * Double($1.quantity)) })
        let shippingCost = deliveryOption.additionalCost
        let taxBase = max(0, itemSubtotal + shippingCost - discount)
        let tax = roundCurrency(taxBase * 0.0825)
        let estimatedTotal = roundCurrency(itemSubtotal + shippingCost + tax - discount)
        let events = statusEvents(for: status, orderNumber: orderNumber, createdAt: createdDate)

        return Order(
            id: id,
            orderNumber: orderNumber,
            status: status,
            createdAt: createdDate,
            updatedAt: events.last?.timestamp ?? createdDate,
            items: orderItems,
            shippingAddress: address,
            paymentMethod: paymentMethod,
            deliveryOption: deliveryOption,
            itemSubtotal: itemSubtotal,
            shippingCost: shippingCost,
            tax: tax,
            discount: discount,
            estimatedTotal: estimatedTotal,
            sourceType: .seeded,
            statusEvents: events
        )
    }

    static func statusEvents(for status: OrderStatus, orderNumber: String, createdAt: Date) -> [OrderStatusEvent] {
        var events: [OrderStatusEvent] = [
            OrderStatusEvent(
                id: "\(orderNumber)_ordered",
                status: .ordered,
                timestamp: createdAt,
                summary: "Order placed"
            )
        ]

        let steps: [(OrderStatus, TimeInterval, String)] = [
            (.preparingForShipment, 2 * 60 * 60, "Preparing for shipment"),
            (.shipped, 16 * 60 * 60, "Package shipped"),
            (.outForDelivery, 44 * 60 * 60, "Out for delivery"),
            (.delivered, 50 * 60 * 60, "Package delivered"),
            (.canceled, 5 * 60 * 60, "Order canceled")
        ]

        for (stepStatus, offset, summary) in steps {
            if shouldInclude(stepStatus: stepStatus, for: status) {
                events.append(
                    OrderStatusEvent(
                        id: "\(orderNumber)_\(stepStatus.rawValue)",
                        status: stepStatus,
                        timestamp: createdAt.addingTimeInterval(offset),
                        summary: summary
                    )
                )
            }
        }

        return events.sorted { $0.timestamp < $1.timestamp }
    }

    private static func shouldInclude(stepStatus: OrderStatus, for finalStatus: OrderStatus) -> Bool {
        switch finalStatus {
        case .ordered:
            return false
        case .preparingForShipment:
            return stepStatus == .preparingForShipment
        case .shipped:
            return stepStatus == .preparingForShipment || stepStatus == .shipped
        case .outForDelivery:
            return stepStatus == .preparingForShipment || stepStatus == .shipped || stepStatus == .outForDelivery
        case .delivered:
            return stepStatus == .preparingForShipment || stepStatus == .shipped || stepStatus == .outForDelivery || stepStatus == .delivered
        case .canceled:
            return stepStatus == .canceled
        case .returned:
            return stepStatus == .preparingForShipment || stepStatus == .shipped || stepStatus == .outForDelivery || stepStatus == .delivered
        }
    }

    private static func variantPriceAdjustment(for product: Product, selection: [String: String]) -> Double {
        selection.reduce(0) { partial, entry in
            let variant = product.variants.first(where: { $0.variantName == entry.key && $0.variantValue == entry.value })
            return partial + (variant?.priceAdjustment ?? 0)
        }
    }

    private static func departmentName(for id: String) -> String {
        departments.first(where: { $0.id == id })?.name ?? id
    }

    private static func categoryName(for id: String) -> String {
        categories.first(where: { $0.id == id })?.name ?? id
    }

    private static func roundCurrency(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    private static func date(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        guard let value = formatter.date(from: string) else {
            print("[SeedData] Invalid seed date: \(string)")
            return Date()
        }
        return value
    }
}
