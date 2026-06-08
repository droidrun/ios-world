import Foundation

struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = 2862933555777941757 &* state &+ 3037000493
        return state
    }
}

enum SeedData {
    private struct ListingBlueprint {
        let section: String
        let row: String
        let seatRange: String
        let quantityAvailable: Int
        let price: Double
        let fees: Double
        let deliveryType: DeliveryType
        let dealScore: Int
        let imageStyle: ListingImageStyle?
        let viewDescription: String?

        init(
            section: String,
            row: String,
            seatRange: String,
            quantityAvailable: Int,
            price: Double,
            fees: Double,
            deliveryType: DeliveryType,
            dealScore: Int,
            imageStyle: ListingImageStyle? = nil,
            viewDescription: String? = nil
        ) {
            self.section = section
            self.row = row
            self.seatRange = seatRange
            self.quantityAvailable = quantityAvailable
            self.price = price
            self.fees = fees
            self.deliveryType = deliveryType
            self.dealScore = dealScore
            self.imageStyle = imageStyle
            self.viewDescription = viewDescription
        }
    }

    private static func stableUUID(_ seed: Int) -> UUID {
        let hex = String(format: "%012x", seed)
        return UUID(uuidString: "00000000-0000-0000-0000-\(hex)") ?? UUID()
    }

    /// Shift applied so all seed dates stay relative to "now" instead of the hardcoded anchor.
    private static let dateShift: TimeInterval = {
        var anchor = DateComponents()
        anchor.calendar = Calendar(identifier: .gregorian)
        anchor.timeZone = TimeZone.current
        anchor.year = 2026; anchor.month = 3; anchor.day = 10
        anchor.hour = 0; anchor.minute = 0
        let anchorDate = anchor.date ?? Date()
        return Date().timeIntervalSince(anchorDate)
    }()

    private static func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone.current
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        let raw = components.date ?? Date()
        return raw.addingTimeInterval(dateShift)
    }

    static func makeVenues() -> [Venue] {
        [
            Venue(id: stableUUID(1000), name: "Chase Center", city: "San Francisco", address: "1 Warriors Way", capacity: 18064, imageName: "city_arena"),
            Venue(id: stableUUID(1001), name: "SAP Center at San Jose", city: "San Jose", address: "525 W Santa Clara St", capacity: 17562, imageName: "sap_center"),
            Venue(id: stableUUID(1002), name: "Oracle Park", city: "San Francisco", address: "24 Willie Mays Plaza", capacity: 41915, imageName: "oracle_park"),
            Venue(id: stableUUID(1003), name: "Stanford Stadium", city: "Stanford", address: "625 Nelson Rd", capacity: 50000, imageName: "stanford_stadium"),
            Venue(id: stableUUID(1004), name: "Bill Graham Civic Auditorium", city: "San Francisco", address: "99 Grove St", capacity: 8500, imageName: "bill_graham"),
            Venue(id: stableUUID(1005), name: "Shoreline Amphitheatre", city: "Mountain View", address: "1 Amphitheatre Pkwy", capacity: 22000, imageName: "shoreline"),
            Venue(id: stableUUID(1006), name: "Orpheum Theatre", city: "San Francisco", address: "1192 Market St", capacity: 2200, imageName: "orpheum"),
            Venue(id: stableUUID(1007), name: "Punch Line San Francisco", city: "San Francisco", address: "444 Battery St", capacity: 182, imageName: "punch_line"),
            Venue(id: stableUUID(1008), name: "Oakland Arena", city: "Oakland", address: "7000 Coliseum Way", capacity: 19000, imageName: "oakland_arena"),
            Venue(id: stableUUID(1009), name: "Levi's Stadium", city: "Santa Clara", address: "4900 Marie P DeBartolo Way", capacity: 68500, imageName: "levis_stadium"),
            Venue(id: stableUUID(1010), name: "Fox Theater", city: "Oakland", address: "1807 Telegraph Ave", capacity: 2800, imageName: "fox_theater"),
            Venue(id: stableUUID(1011), name: "The Warfield", city: "San Francisco", address: "982 Market St", capacity: 2300, imageName: "the_warfield"),
            Venue(id: stableUUID(1012), name: "Great American Music Hall", city: "San Francisco", address: "859 O'Farrell St", capacity: 600, imageName: "gamh"),
            Venue(id: stableUUID(1013), name: "The Fillmore", city: "San Francisco", address: "1805 Geary Blvd", capacity: 1150, imageName: "the_fillmore"),
            Venue(id: stableUUID(1014), name: "Davies Symphony Hall", city: "San Francisco", address: "201 Van Ness Ave", capacity: 2743, imageName: "davies_symphony"),
            Venue(id: stableUUID(1015), name: "The Masonic", city: "San Francisco", address: "1111 California St", capacity: 3300, imageName: "the_masonic"),
            Venue(id: stableUUID(1016), name: "Frost Amphitheater", city: "Stanford", address: "351 Lasuen St", capacity: 8500, imageName: "frost_amphitheater")
        ]
    }

    static func makePerformers() -> [Performer] {
        [
            Performer(id: stableUUID(2000), name: "Golden State Warriors", category: .sports, imageName: "warriors", eventCount: 41),
            Performer(id: stableUUID(2001), name: "Chicago Bulls", category: .sports, imageName: "bulls", eventCount: 41),
            Performer(id: stableUUID(2002), name: "St. Louis Blues", category: .sports, imageName: "blues", eventCount: 27),
            Performer(id: stableUUID(2003), name: "San Jose Sharks", category: .sports, imageName: "sharks", eventCount: 28),
            Performer(id: stableUUID(2004), name: "New York Yankees", category: .sports, imageName: "yankees", eventCount: 44),
            Performer(id: stableUUID(2005), name: "San Francisco Giants", category: .sports, imageName: "giants", eventCount: 40),
            Performer(id: stableUUID(2006), name: "BTS", category: .concerts, imageName: "bts", eventCount: 9),
            Performer(id: stableUUID(2007), name: "Harry Styles", category: .concerts, imageName: "harry_styles", eventCount: 30),
            Performer(id: stableUUID(2008), name: "Lady Gaga", category: .concerts, imageName: "lady_gaga", eventCount: 16),
            Performer(id: stableUUID(2009), name: "OneRepublic", category: .concerts, imageName: "one_republic", eventCount: 3),
            Performer(id: stableUUID(2010), name: "The Chainsmokers", category: .concerts, imageName: "chainsmokers", eventCount: 3),
            Performer(id: stableUUID(2011), name: "Hamilton", category: .theater, imageName: "hamilton", eventCount: 14),
            Performer(id: stableUUID(2012), name: "Nate Bargatze", category: .comedy, imageName: "nate_bargatze", eventCount: 5),
            Performer(id: stableUUID(2013), name: "Pittsburgh Pirates", category: .sports, imageName: "pirates", eventCount: 36),
            Performer(id: stableUUID(2014), name: "Cleveland Cavaliers", category: .sports, imageName: "cavaliers", eventCount: 38),
            Performer(id: stableUUID(2015), name: "San Diego Padres", category: .sports, imageName: "padres", eventCount: 35),
            Performer(id: stableUUID(2016), name: "Atlanta Braves", category: .sports, imageName: "braves", eventCount: 37),
            Performer(id: stableUUID(2017), name: "Rod Stewart", category: .concerts, imageName: "rod_stewart", eventCount: 6),
            Performer(id: stableUUID(2018), name: "Wicked", category: .theater, imageName: "wicked", eventCount: 18),
            Performer(id: stableUUID(2019), name: "John Mulaney", category: .comedy, imageName: "john_mulaney", eventCount: 8),
            Performer(id: stableUUID(2020), name: "Los Angeles Lakers", category: .sports, imageName: "lakers", eventCount: 41),
            Performer(id: stableUUID(2021), name: "Boston Celtics", category: .sports, imageName: "celtics", eventCount: 41),
            Performer(id: stableUUID(2022), name: "Taylor Swift", category: .concerts, imageName: "taylor_swift", eventCount: 52),
            Performer(id: stableUUID(2023), name: "Bad Bunny", category: .concerts, imageName: "bad_bunny", eventCount: 28),
            Performer(id: stableUUID(2024), name: "Drake", category: .concerts, imageName: "drake", eventCount: 18),
            Performer(id: stableUUID(2025), name: "Dave Chappelle", category: .comedy, imageName: "dave_chappelle", eventCount: 12),
            Performer(id: stableUUID(2026), name: "Ali Wong", category: .comedy, imageName: "ali_wong", eventCount: 9),
            Performer(id: stableUUID(2027), name: "Dear Evan Hansen", category: .theater, imageName: "dear_evan_hansen", eventCount: 16),
            Performer(id: stableUUID(2028), name: "The Lion King", category: .theater, imageName: "lion_king", eventCount: 22),
            Performer(id: stableUUID(2029), name: "Los Angeles Dodgers", category: .sports, imageName: "dodgers", eventCount: 40),
            Performer(id: stableUUID(2030), name: "Denver Nuggets", category: .sports, imageName: "nuggets", eventCount: 41),
            Performer(id: stableUUID(2031), name: "Phoenix Suns", category: .sports, imageName: "suns", eventCount: 41),
            Performer(id: stableUUID(2032), name: "Billie Eilish", category: .concerts, imageName: "billie_eilish", eventCount: 24),
            Performer(id: stableUUID(2033), name: "Kendrick Lamar", category: .concerts, imageName: "kendrick_lamar", eventCount: 18),
            Performer(id: stableUUID(2034), name: "SZA", category: .concerts, imageName: "sza", eventCount: 22),
            Performer(id: stableUUID(2035), name: "Olivia Rodrigo", category: .concerts, imageName: "olivia_rodrigo", eventCount: 30),
            Performer(id: stableUUID(2036), name: "The Phantom of the Opera", category: .theater, imageName: "phantom_opera", eventCount: 20),
            Performer(id: stableUUID(2037), name: "Trevor Noah", category: .comedy, imageName: "trevor_noah", eventCount: 10),
            Performer(id: stableUUID(2038), name: "Milwaukee Bucks", category: .sports, imageName: "bucks", eventCount: 41),
            Performer(id: stableUUID(2039), name: "Minnesota Timberwolves", category: .sports, imageName: "timberwolves", eventCount: 41),
            Performer(id: stableUUID(2040), name: "Colorado Rockies", category: .sports, imageName: "rockies", eventCount: 36),
            Performer(id: stableUUID(2041), name: "San Francisco 49ers", category: .sports, imageName: "49ers", eventCount: 10),
            Performer(id: stableUUID(2042), name: "Doja Cat", category: .concerts, imageName: "doja_cat", eventCount: 15),
            Performer(id: stableUUID(2043), name: "Post Malone", category: .concerts, imageName: "post_malone", eventCount: 20),
            Performer(id: stableUUID(2044), name: "Hasan Minhaj", category: .comedy, imageName: "hasan_minhaj", eventCount: 7),
            Performer(id: stableUUID(2045), name: "Sebastian Maniscalco", category: .comedy, imageName: "sebastian_maniscalco", eventCount: 8),
            Performer(id: stableUUID(2046), name: "Beetlejuice", category: .theater, imageName: "beetlejuice", eventCount: 14),
            Performer(id: stableUUID(2047), name: "Chicago (Musical)", category: .theater, imageName: "chicago_musical", eventCount: 16)
        ]
    }

    static func makeEvents(venues: [Venue], performers: [Performer]) -> [Event] {
        let venueByID = Dictionary(uniqueKeysWithValues: venues.map { ($0.id, $0) })
        let performerByID = Dictionary(uniqueKeysWithValues: performers.map { ($0.id, $0) })

        func performer(_ id: Int) -> Performer {
            performerByID[stableUUID(id)] ?? Performer(
                id: stableUUID(id),
                name: "Unknown",
                category: .concerts,
                imageName: "fallback",
                eventCount: 0
            )
        }

        func venue(_ id: Int) -> Venue {
            venueByID[stableUUID(id)] ?? Venue(
                id: stableUUID(id),
                name: "TicketBox Venue",
                city: "San Francisco",
                address: "",
                capacity: 0,
                imageName: "fallback"
            )
        }

        return [
            Event(
                id: stableUUID(3000),
                title: "Chicago Bulls at Golden State Warriors",
                date: makeDate(2026, 3, 10, 19, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2001), performer(2000)],
                imageName: "featured_warriors",
                description: "Featured game night at Chase Center with lower bowl deals and instant mobile delivery.",
                listings: makeListings(
                    eventID: stableUUID(3000),
                    eventSeed: 3000,
                    count: 148,
                    category: .sports,
                    sectionPool: ["106", "107", "109", "112", "118", "210", "214", "219"],
                    priceRange: 42...260
                )
            ),
            Event(
                id: stableUUID(3001),
                title: "Blues at Sharks",
                date: makeDate(2026, 3, 6, 19, 0),
                venueID: venue(1001).id,
                city: venue(1001).city,
                category: .sports,
                performers: [performer(2002), performer(2003)],
                imageName: "sharks_map",
                description: "Tonight at SAP Center. Compare map pricing, filter by fees, and grab instant transfer tickets.",
                listings: makeListings(
                    eventID: stableUUID(3001),
                    eventSeed: 3001,
                    count: 327,
                    category: .sports,
                    sectionPool: ["101", "103", "106", "110", "114", "118", "120", "124", "126", "203", "214", "215", "216", "217", "220", "221", "224", "225", "228"],
                    priceRange: 30...210,
                    manual: [
                        ListingBlueprint(section: "225", row: "16", seatRange: "1-4", quantityAvailable: 4, price: 30, fees: 7, deliveryType: .instant, dealScore: 98, imageStyle: .cornerView, viewDescription: "Upper corner view with clear sightline of both nets."),
                        ListingBlueprint(section: "225", row: "15", seatRange: "1-4", quantityAvailable: 4, price: 32, fees: 7, deliveryType: .instant, dealScore: 97, imageStyle: .cornerView, viewDescription: "Corner upper bowl seats close to the shoot-twice side."),
                        ListingBlueprint(section: "224", row: "13", seatRange: "1-4", quantityAvailable: 4, price: 33, fees: 7, deliveryType: .instant, dealScore: 96, imageStyle: .cornerView, viewDescription: "High-value corner section with a full-ice angle."),
                        ListingBlueprint(section: "217", row: "11", seatRange: "1-2", quantityAvailable: 2, price: 34, fees: 7, deliveryType: .mobile, dealScore: 92, imageStyle: .clubLevel, viewDescription: "Club-side upper section with shorter concourse lines."),
                        ListingBlueprint(section: "220", row: "8", seatRange: "1-4", quantityAvailable: 4, price: 34, fees: 7, deliveryType: .mobile, dealScore: 91, imageStyle: .behindGoal, viewDescription: "Behind-goal view on the Sharks attack-twice end."),
                        ListingBlueprint(section: "228", row: "9", seatRange: "1-4", quantityAvailable: 4, price: 37, fees: 8, deliveryType: .instant, dealScore: 90, imageStyle: .behindGoal, viewDescription: "Upper end view with a clear angle on the crease."),
                        ListingBlueprint(section: "214", row: "6", seatRange: "1-2", quantityAvailable: 2, price: 41, fees: 8, deliveryType: .transfer, dealScore: 86, imageStyle: .clubLevel, viewDescription: "Center-ice upper bowl seats with balanced sightlines.")
                    ]
                )
            ),
            Event(
                id: stableUUID(3002),
                title: "New York Yankees at San Francisco Giants",
                date: makeDate(2026, 3, 25, 18, 45),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2004), performer(2005)],
                imageName: "oracle_baseball",
                description: "A marquee interleague matchup on the waterfront with premium Oracle Park inventory.",
                listings: makeListings(
                    eventID: stableUUID(3002),
                    eventSeed: 3002,
                    count: 211,
                    category: .sports,
                    sectionPool: ["101", "109", "115", "122", "130", "202", "208", "221", "LB", "VR"],
                    priceRange: 159...420
                )
            ),
            Event(
                id: stableUUID(3003),
                title: "BTS",
                date: makeDate(2026, 5, 16, 20, 0),
                venueID: venue(1003).id,
                city: venue(1003).city,
                category: .concerts,
                performers: [performer(2006)],
                imageName: "bts_stadium",
                description: "Massive stadium production with floor, lower bowl, and verified resale tickets.",
                listings: makeListings(
                    eventID: stableUUID(3003),
                    eventSeed: 3003,
                    count: 91,
                    category: .concerts,
                    sectionPool: ["Floor A", "Floor B", "106", "117", "121", "206", "215", "GA"],
                    priceRange: 262...680
                )
            ),
            Event(
                id: stableUUID(3004),
                title: "Harry Styles",
                date: makeDate(2026, 6, 12, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2007)],
                imageName: "harry_styles_stage",
                description: "Recommended for you based on your favorites and music listening.",
                listings: makeListings(
                    eventID: stableUUID(3004),
                    eventSeed: 3004,
                    count: 133,
                    category: .concerts,
                    sectionPool: ["Floor", "109", "111", "115", "118", "212", "218"],
                    priceRange: 124...490
                )
            ),
            Event(
                id: stableUUID(3005),
                title: "Lady Gaga",
                date: makeDate(2026, 7, 2, 20, 30),
                venueID: venue(1008).id,
                city: venue(1008).city,
                category: .concerts,
                performers: [performer(2008)],
                imageName: "lady_gaga_stage",
                description: "Arena pop production with VIP floor access, club seats, and resale value alerts.",
                listings: makeListings(
                    eventID: stableUUID(3005),
                    eventSeed: 3005,
                    count: 146,
                    category: .concerts,
                    sectionPool: ["Floor", "114", "117", "121", "210", "214", "217"],
                    priceRange: 118...530
                )
            ),
            Event(
                id: stableUUID(3006),
                title: "OneRepublic",
                date: makeDate(2026, 4, 18, 20, 0),
                venueID: venue(1004).id,
                city: venue(1004).city,
                category: .concerts,
                performers: [performer(2009)],
                imageName: "one_republic_stage",
                description: "Three Bay Area dates remain. Lower level and club seats are moving quickly.",
                listings: makeListings(
                    eventID: stableUUID(3006),
                    eventSeed: 3006,
                    count: 72,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "106", "110", "Balcony", "GA"],
                    priceRange: 74...225
                )
            ),
            Event(
                id: stableUUID(3007),
                title: "The Chainsmokers",
                date: makeDate(2026, 4, 22, 20, 0),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2010)],
                imageName: "chainsmokers_stage",
                description: "Outdoor amphitheater set with lawn passes, reserved sections, and fast mobile tickets.",
                listings: makeListings(
                    eventID: stableUUID(3007),
                    eventSeed: 3007,
                    count: 68,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "201", "Lawn", "GA"],
                    priceRange: 58...210
                )
            ),
            Event(
                id: stableUUID(3008),
                title: "Hamilton",
                date: makeDate(2026, 5, 1, 19, 30),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2011)],
                imageName: "hamilton_marquee",
                description: "Broadway seating with orchestra and mezzanine inventory in the city.",
                listings: makeListings(
                    eventID: stableUUID(3008),
                    eventSeed: 3008,
                    count: 57,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 109...340
                )
            ),
            Event(
                id: stableUUID(3009),
                title: "Nate Bargatze",
                date: makeDate(2026, 5, 9, 20, 0),
                venueID: venue(1007).id,
                city: venue(1007).city,
                category: .comedy,
                performers: [performer(2012)],
                imageName: "comedy_stage",
                description: "Club show inventory with small-room seating and instant delivery.",
                listings: makeListings(
                    eventID: stableUUID(3009),
                    eventSeed: 3009,
                    count: 34,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 54...140
                )
            ),
            Event(
                id: stableUUID(3010),
                title: "Cleveland Cavaliers at Golden State Warriors",
                date: makeDate(2026, 4, 2, 19, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2014), performer(2000)],
                imageName: "warriors_featured",
                description: "High-demand NBA matchup with lower bowl deals and instant ticket transfer.",
                listings: makeListings(
                    eventID: stableUUID(3010),
                    eventSeed: 3010,
                    count: 102,
                    category: .sports,
                    sectionPool: ["104", "108", "111", "116", "210", "217"],
                    priceRange: 115...375
                )
            ),
            Event(
                id: stableUUID(3011),
                title: "Pittsburgh Pirates at San Francisco Giants",
                date: makeDate(2026, 4, 8, 18, 45),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2013), performer(2005)],
                imageName: "oracle_baseball",
                description: "Weeknight baseball at Oracle Park with inventory from the bleachers to the club level.",
                listings: makeListings(
                    eventID: stableUUID(3011),
                    eventSeed: 3011,
                    count: 88,
                    category: .sports,
                    sectionPool: ["101", "120", "127", "LB", "VR", "Bleachers"],
                    priceRange: 24...168
                )
            ),
            Event(
                id: stableUUID(3012),
                title: "Rod Stewart",
                date: makeDate(2026, 4, 28, 19, 30),
                venueID: venue(1004).id,
                city: venue(1004).city,
                category: .concerts,
                performers: [performer(2017)],
                imageName: "rod_stewart_stage",
                description: "Legacy tour stop with premium floor access and fan-club inventory.",
                listings: makeListings(
                    eventID: stableUUID(3012),
                    eventSeed: 3012,
                    count: 49,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "105", "112", "Balcony"],
                    priceRange: 84...260
                )
            ),
            Event(
                id: stableUUID(3013),
                title: "San Diego Padres at San Francisco Giants",
                date: makeDate(2026, 4, 15, 18, 45),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2015), performer(2005)],
                imageName: "oracle_baseball",
                description: "Midweek rivalry game at Oracle Park with lower box, club, and bleacher inventory.",
                listings: makeListings(
                    eventID: stableUUID(3013),
                    eventSeed: 3013,
                    count: 124,
                    category: .sports,
                    sectionPool: ["101", "104", "115", "120", "127", "LB", "VR", "Bleachers"],
                    priceRange: 31...210
                )
            ),
            Event(
                id: stableUUID(3014),
                title: "Harry Styles Night 2",
                date: makeDate(2026, 6, 13, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2007)],
                imageName: "harry_styles_stage",
                description: "Second Chase Center date with more floor and lower-bowl resale inventory.",
                listings: makeListings(
                    eventID: stableUUID(3014),
                    eventSeed: 3014,
                    count: 118,
                    category: .concerts,
                    sectionPool: ["Floor", "106", "111", "114", "118", "212", "219"],
                    priceRange: 132...520
                )
            ),
            Event(
                id: stableUUID(3015),
                title: "Wicked",
                date: makeDate(2026, 5, 22, 19, 30),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2018)],
                imageName: "hamilton_marquee",
                description: "Popular touring Broadway run with orchestra, front mezzanine, and balcony seats.",
                listings: makeListings(
                    eventID: stableUUID(3015),
                    eventSeed: 3015,
                    count: 61,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 89...280
                )
            ),
            Event(
                id: stableUUID(3016),
                title: "John Mulaney",
                date: makeDate(2026, 4, 11, 20, 0),
                venueID: venue(1007).id,
                city: venue(1007).city,
                category: .comedy,
                performers: [performer(2019)],
                imageName: "comedy_stage",
                description: "Stand-up set with front-table inventory, side sections, and instant mobile tickets.",
                listings: makeListings(
                    eventID: stableUUID(3016),
                    eventSeed: 3016,
                    count: 46,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 72...185
                )
            ),
            Event(
                id: stableUUID(3017),
                title: "Atlanta Braves at San Francisco Giants",
                date: makeDate(2026, 5, 3, 13, 5),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2016), performer(2005)],
                imageName: "oracle_baseball",
                description: "Sunday afternoon baseball on the bay with shaded club inventory and bleacher deals.",
                listings: makeListings(
                    eventID: stableUUID(3017),
                    eventSeed: 3017,
                    count: 132,
                    category: .sports,
                    sectionPool: ["101", "109", "115", "122", "130", "LB", "VR", "Bleachers"],
                    priceRange: 38...196
                )
            ),
            Event(
                id: stableUUID(3018),
                title: "The Chainsmokers DJ Set",
                date: makeDate(2026, 5, 30, 21, 0),
                venueID: venue(1004).id,
                city: venue(1004).city,
                category: .concerts,
                performers: [performer(2010)],
                imageName: "chainsmokers_stage",
                description: "Late-night downtown set with floor access, premium bowl seats, and instant transfer.",
                listings: makeListings(
                    eventID: stableUUID(3018),
                    eventSeed: 3018,
                    count: 84,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "104", "112", "Balcony", "GA"],
                    priceRange: 66...245
                )
            ),
            Event(
                id: stableUUID(3019),
                title: "Rod Stewart Encore",
                date: makeDate(2026, 4, 29, 19, 30),
                venueID: venue(1004).id,
                city: venue(1004).city,
                category: .concerts,
                performers: [performer(2017)],
                imageName: "rod_stewart_stage",
                description: "Added Bay Area date with lower bowl inventory and a fresh batch of fan resale seats.",
                listings: makeListings(
                    eventID: stableUUID(3019),
                    eventSeed: 3019,
                    count: 58,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "105", "112", "Balcony"],
                    priceRange: 88...265
                )
            ),
            Event(
                id: stableUUID(3020),
                title: "OneRepublic Acoustic Night",
                date: makeDate(2026, 4, 19, 20, 0),
                venueID: venue(1004).id,
                city: venue(1004).city,
                category: .concerts,
                performers: [performer(2009)],
                imageName: "one_republic_stage",
                description: "An extra intimate downtown show with floor, reserved bowl, and balcony options.",
                listings: makeListings(
                    eventID: stableUUID(3020),
                    eventSeed: 3020,
                    count: 77,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "106", "110", "Balcony", "GA"],
                    priceRange: 69...235
                )
            ),
            Event(
                id: stableUUID(3021),
                title: "Lakers at Warriors",
                date: makeDate(2026, 3, 7, 19, 30),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2020), performer(2000)],
                imageName: "warriors_featured",
                description: "Tonight's marquee matchup at Chase Center. Lower bowl inventory moving fast.",
                listings: makeListings(
                    eventID: stableUUID(3021),
                    eventSeed: 3021,
                    count: 186,
                    category: .sports,
                    sectionPool: ["104", "107", "109", "112", "116", "118", "210", "214", "219"],
                    priceRange: 89...520
                )
            ),
            Event(
                id: stableUUID(3022),
                title: "Celtics at Warriors",
                date: makeDate(2026, 3, 8, 17, 30),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2021), performer(2000)],
                imageName: "warriors_featured",
                description: "Tomorrow's primetime clash with Boston. Premium courtside and club seats available.",
                listings: makeListings(
                    eventID: stableUUID(3022),
                    eventSeed: 3022,
                    count: 164,
                    category: .sports,
                    sectionPool: ["106", "108", "111", "115", "118", "211", "215", "220"],
                    priceRange: 105...580
                )
            ),
            Event(
                id: stableUUID(3023),
                title: "Taylor Swift | The Eras Tour",
                date: makeDate(2026, 7, 19, 18, 30),
                venueID: venue(1009).id,
                city: venue(1009).city,
                category: .concerts,
                performers: [performer(2022)],
                imageName: "taylor_swift_stage",
                description: "Stadium production with floor, lower bowl, and upper deck inventory. High demand — prices fluctuating.",
                listings: makeListings(
                    eventID: stableUUID(3023),
                    eventSeed: 3023,
                    count: 245,
                    category: .concerts,
                    sectionPool: ["Floor A", "Floor B", "Floor C", "112", "118", "124", "130", "215", "225", "GA"],
                    priceRange: 380...1850
                )
            ),
            Event(
                id: stableUUID(3024),
                title: "Bad Bunny",
                date: makeDate(2026, 5, 10, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2023)],
                imageName: "bad_bunny_stage",
                description: "Arena concert with floor, lower, and upper bowl sections. Instant delivery available.",
                listings: makeListings(
                    eventID: stableUUID(3024),
                    eventSeed: 3024,
                    count: 142,
                    category: .concerts,
                    sectionPool: ["Floor", "106", "111", "115", "118", "212", "218"],
                    priceRange: 135...480
                )
            ),
            Event(
                id: stableUUID(3025),
                title: "Drake",
                date: makeDate(2026, 6, 5, 20, 30),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2024)],
                imageName: "drake_stage",
                description: "Full production arena show at Chase Center with VIP floor and club level seats.",
                listings: makeListings(
                    eventID: stableUUID(3025),
                    eventSeed: 3025,
                    count: 158,
                    category: .concerts,
                    sectionPool: ["Floor", "108", "112", "116", "210", "216"],
                    priceRange: 118...550
                )
            ),
            Event(
                id: stableUUID(3026),
                title: "Dave Chappelle",
                date: makeDate(2026, 3, 14, 20, 0),
                venueID: venue(1011).id,
                city: venue(1011).city,
                category: .comedy,
                performers: [performer(2025)],
                imageName: "comedy_stage",
                description: "Intimate club show at The Warfield. Limited inventory — front sections selling fast.",
                listings: makeListings(
                    eventID: stableUUID(3026),
                    eventSeed: 3026,
                    count: 42,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 165...425
                )
            ),
            Event(
                id: stableUUID(3027),
                title: "Ali Wong",
                date: makeDate(2026, 3, 21, 19, 30),
                venueID: venue(1012).id,
                city: venue(1012).city,
                category: .comedy,
                performers: [performer(2026)],
                imageName: "comedy_stage",
                description: "Stand-up special taping at Great American Music Hall. Small venue, high demand.",
                listings: makeListings(
                    eventID: stableUUID(3027),
                    eventSeed: 3027,
                    count: 28,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 95...280
                )
            ),
            Event(
                id: stableUUID(3028),
                title: "Dear Evan Hansen",
                date: makeDate(2026, 4, 5, 14, 0),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2027)],
                imageName: "theater_marquee",
                description: "Matinee showing with orchestra and mezzanine inventory at the Orpheum.",
                listings: makeListings(
                    eventID: stableUUID(3028),
                    eventSeed: 3028,
                    count: 52,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 78...265
                )
            ),
            Event(
                id: stableUUID(3029),
                title: "The Lion King",
                date: makeDate(2026, 4, 12, 19, 30),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2028)],
                imageName: "theater_marquee",
                description: "Award-winning musical with full orchestra and balcony seating available.",
                listings: makeListings(
                    eventID: stableUUID(3029),
                    eventSeed: 3029,
                    count: 64,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 92...310
                )
            ),
            Event(
                id: stableUUID(3030),
                title: "Dodgers at Giants",
                date: makeDate(2026, 3, 9, 13, 5),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2029), performer(2005)],
                imageName: "oracle_baseball",
                description: "Sunday rivalry game on the waterfront. Club level and bleacher inventory available.",
                listings: makeListings(
                    eventID: stableUUID(3030),
                    eventSeed: 3030,
                    count: 198,
                    category: .sports,
                    sectionPool: ["101", "109", "115", "122", "130", "202", "208", "221", "LB", "VR", "Bleachers"],
                    priceRange: 42...245
                )
            ),
            Event(
                id: stableUUID(3031),
                title: "Nuggets at Warriors",
                date: makeDate(2026, 3, 28, 19, 30),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2030), performer(2000)],
                imageName: "warriors_featured",
                description: "Western Conference showdown at Chase Center. Lower bowl deals and club seats available.",
                listings: makeListings(
                    eventID: stableUUID(3031),
                    eventSeed: 3031,
                    count: 174,
                    category: .sports,
                    sectionPool: ["104", "107", "110", "114", "117", "210", "215", "220"],
                    priceRange: 95...465
                )
            ),
            Event(
                id: stableUUID(3032),
                title: "Suns at Warriors",
                date: makeDate(2026, 4, 6, 17, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2031), performer(2000)],
                imageName: "warriors_featured",
                description: "Sunday matinee at Chase Center with premium courtside and upper bowl value seats.",
                listings: makeListings(
                    eventID: stableUUID(3032),
                    eventSeed: 3032,
                    count: 156,
                    category: .sports,
                    sectionPool: ["106", "109", "112", "116", "118", "211", "216", "219"],
                    priceRange: 82...410
                )
            ),
            Event(
                id: stableUUID(3033),
                title: "Billie Eilish",
                date: makeDate(2026, 5, 23, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2032)],
                imageName: "billie_eilish_stage",
                description: "Arena show at Chase Center with floor, lower bowl, and upper deck inventory.",
                listings: makeListings(
                    eventID: stableUUID(3033),
                    eventSeed: 3033,
                    count: 168,
                    category: .concerts,
                    sectionPool: ["Floor", "106", "110", "114", "118", "212", "217"],
                    priceRange: 145...560
                )
            ),
            Event(
                id: stableUUID(3034),
                title: "Kendrick Lamar",
                date: makeDate(2026, 6, 21, 20, 30),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2033)],
                imageName: "kendrick_stage",
                description: "Outdoor amphitheater headliner with pit, reserved, and lawn passes.",
                listings: makeListings(
                    eventID: stableUUID(3034),
                    eventSeed: 3034,
                    count: 195,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 98...385
                )
            ),
            Event(
                id: stableUUID(3035),
                title: "SZA",
                date: makeDate(2026, 7, 11, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2034)],
                imageName: "sza_stage",
                description: "Full production arena show with floor access, club seats, and instant delivery.",
                listings: makeListings(
                    eventID: stableUUID(3035),
                    eventSeed: 3035,
                    count: 152,
                    category: .concerts,
                    sectionPool: ["Floor", "108", "112", "116", "210", "215", "218"],
                    priceRange: 128...495
                )
            ),
            Event(
                id: stableUUID(3036),
                title: "Olivia Rodrigo",
                date: makeDate(2026, 5, 31, 19, 30),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .concerts,
                performers: [performer(2035)],
                imageName: "olivia_rodrigo_stage",
                description: "Intimate theater show at The Masonic with floor and balcony inventory.",
                listings: makeListings(
                    eventID: stableUUID(3036),
                    eventSeed: 3036,
                    count: 86,
                    category: .concerts,
                    sectionPool: ["Floor", "101", "102", "Balcony", "GA"],
                    priceRange: 112...380
                )
            ),
            Event(
                id: stableUUID(3037),
                title: "The Phantom of the Opera",
                date: makeDate(2026, 4, 19, 19, 30),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2036)],
                imageName: "theater_marquee",
                description: "Classic Broadway touring production with orchestra and balcony seating.",
                listings: makeListings(
                    eventID: stableUUID(3037),
                    eventSeed: 3037,
                    count: 58,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 85...295
                )
            ),
            Event(
                id: stableUUID(3038),
                title: "Trevor Noah",
                date: makeDate(2026, 4, 25, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2037)],
                imageName: "comedy_stage",
                description: "Stand-up set at The Masonic with floor seating and balcony options.",
                listings: makeListings(
                    eventID: stableUUID(3038),
                    eventSeed: 3038,
                    count: 72,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 78...225
                )
            ),
            Event(
                id: stableUUID(3039),
                title: "Billie Eilish Night 2",
                date: makeDate(2026, 5, 24, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2032)],
                imageName: "billie_eilish_stage",
                description: "Second night at Chase Center with added floor and lower bowl resale inventory.",
                listings: makeListings(
                    eventID: stableUUID(3039),
                    eventSeed: 3039,
                    count: 144,
                    category: .concerts,
                    sectionPool: ["Floor", "107", "111", "115", "118", "213", "218"],
                    priceRange: 138...545
                )
            ),
            Event(
                id: stableUUID(3040),
                title: "Kendrick Lamar",
                date: makeDate(2026, 6, 22, 20, 30),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2033)],
                imageName: "kendrick_stage",
                description: "Added second night at Shoreline with fresh pit and lawn inventory.",
                listings: makeListings(
                    eventID: stableUUID(3040),
                    eventSeed: 3040,
                    count: 182,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 92...370
                )
            ),
            Event(
                id: stableUUID(3041),
                title: "Bucks at Warriors",
                date: makeDate(2026, 3, 18, 19, 30),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2038), performer(2000)],
                imageName: "warriors_featured",
                description: "Midweek NBA action at Chase Center with lower bowl and club seat inventory.",
                listings: makeListings(
                    eventID: stableUUID(3041),
                    eventSeed: 3041,
                    count: 138,
                    category: .sports,
                    sectionPool: ["104", "108", "112", "116", "210", "215", "220"],
                    priceRange: 72...345
                )
            ),
            Event(
                id: stableUUID(3042),
                title: "Timberwolves at Warriors",
                date: makeDate(2026, 3, 22, 17, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .sports,
                performers: [performer(2039), performer(2000)],
                imageName: "warriors_featured",
                description: "Saturday matinee at Chase Center. Upper bowl deals and instant delivery available.",
                listings: makeListings(
                    eventID: stableUUID(3042),
                    eventSeed: 3042,
                    count: 146,
                    category: .sports,
                    sectionPool: ["106", "109", "113", "117", "211", "216", "219"],
                    priceRange: 68...310
                )
            ),
            Event(
                id: stableUUID(3043),
                title: "Colorado Rockies at San Francisco Giants",
                date: makeDate(2026, 5, 6, 18, 45),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2040), performer(2005)],
                imageName: "oracle_baseball",
                description: "Midweek baseball at Oracle Park with bleacher deals and club level inventory.",
                listings: makeListings(
                    eventID: stableUUID(3043),
                    eventSeed: 3043,
                    count: 96,
                    category: .sports,
                    sectionPool: ["101", "115", "120", "127", "LB", "VR", "Bleachers"],
                    priceRange: 18...145
                )
            ),
            Event(
                id: stableUUID(3044),
                title: "Doja Cat",
                date: makeDate(2026, 6, 14, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2042)],
                imageName: "doja_cat_stage",
                description: "Arena pop show at Chase Center with floor, lower bowl, and upper deck inventory.",
                listings: makeListings(
                    eventID: stableUUID(3044),
                    eventSeed: 3044,
                    count: 155,
                    category: .concerts,
                    sectionPool: ["Floor", "106", "110", "114", "118", "212", "218"],
                    priceRange: 108...445
                )
            ),
            Event(
                id: stableUUID(3045),
                title: "Post Malone",
                date: makeDate(2026, 7, 5, 20, 0),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2043)],
                imageName: "post_malone_stage",
                description: "Summer amphitheater show at Shoreline with pit, reserved, and lawn inventory.",
                listings: makeListings(
                    eventID: stableUUID(3045),
                    eventSeed: 3045,
                    count: 188,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 85...350
                )
            ),
            Event(
                id: stableUUID(3046),
                title: "Hasan Minhaj",
                date: makeDate(2026, 4, 4, 20, 0),
                venueID: venue(1007).id,
                city: venue(1007).city,
                category: .comedy,
                performers: [performer(2044)],
                imageName: "comedy_stage",
                description: "Intimate club set at Punch Line with front table and standing room options.",
                listings: makeListings(
                    eventID: stableUUID(3046),
                    eventSeed: 3046,
                    count: 32,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 62...165
                )
            ),
            Event(
                id: stableUUID(3047),
                title: "Sebastian Maniscalco",
                date: makeDate(2026, 5, 17, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2045)],
                imageName: "comedy_stage",
                description: "Arena-scale stand-up at The Masonic with floor and balcony seating.",
                listings: makeListings(
                    eventID: stableUUID(3047),
                    eventSeed: 3047,
                    count: 78,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 88...245
                )
            ),
            Event(
                id: stableUUID(3048),
                title: "Beetlejuice",
                date: makeDate(2026, 5, 15, 19, 30),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2046)],
                imageName: "theater_marquee",
                description: "Hit Broadway touring show with orchestra and mezzanine inventory at the Orpheum.",
                listings: makeListings(
                    eventID: stableUUID(3048),
                    eventSeed: 3048,
                    count: 55,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 72...255
                )
            ),
            Event(
                id: stableUUID(3049),
                title: "Chicago (Musical)",
                date: makeDate(2026, 6, 7, 14, 0),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2047)],
                imageName: "theater_marquee",
                description: "Matinee performance of the classic Broadway revival at the Orpheum.",
                listings: makeListings(
                    eventID: stableUUID(3049),
                    eventSeed: 3049,
                    count: 48,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 65...230
                )
            ),
            Event(
                id: stableUUID(3050),
                title: "Bad Bunny",
                date: makeDate(2026, 6, 28, 20, 0),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2023)],
                imageName: "bad_bunny_stage",
                description: "Summer outdoor show at Shoreline Amphitheatre with pit and lawn passes.",
                listings: makeListings(
                    eventID: stableUUID(3050),
                    eventSeed: 3050,
                    count: 176,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 110...420
                )
            ),
            Event(
                id: stableUUID(3051),
                title: "Ali Wong",
                date: makeDate(2026, 4, 17, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2026)],
                imageName: "comedy_stage",
                description: "Stand-up special at The Masonic with floor and balcony inventory.",
                listings: makeListings(
                    eventID: stableUUID(3051),
                    eventSeed: 3051,
                    count: 66,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 92...265
                )
            ),
            Event(
                id: stableUUID(3052),
                title: "Dave Chappelle",
                date: makeDate(2026, 5, 2, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2025)],
                imageName: "comedy_stage",
                description: "Second Bay Area date at The Masonic. Front sections selling fast.",
                listings: makeListings(
                    eventID: stableUUID(3052),
                    eventSeed: 3052,
                    count: 74,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 155...410
                )
            ),
            Event(
                id: stableUUID(3053),
                title: "Taylor Swift | The Eras Tour",
                date: makeDate(2026, 7, 20, 18, 30),
                venueID: venue(1009).id,
                city: venue(1009).city,
                category: .concerts,
                performers: [performer(2022)],
                imageName: "taylor_swift_stage",
                description: "Second night at Levi's Stadium. Floor and lower bowl resale inventory available.",
                listings: makeListings(
                    eventID: stableUUID(3053),
                    eventSeed: 3053,
                    count: 232,
                    category: .concerts,
                    sectionPool: ["Floor A", "Floor B", "Floor C", "112", "118", "124", "130", "215", "225", "GA"],
                    priceRange: 395...1920
                )
            ),
            Event(
                id: stableUUID(3054),
                title: "Hamilton",
                date: makeDate(2026, 5, 3, 14, 0),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2011)],
                imageName: "hamilton_marquee",
                description: "Saturday matinee showing with fresh orchestra and mezzanine resale seats.",
                listings: makeListings(
                    eventID: stableUUID(3054),
                    eventSeed: 3054,
                    count: 52,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 115...355
                )
            ),
            Event(
                id: stableUUID(3055),
                title: "Drake",
                date: makeDate(2026, 7, 18, 20, 0),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2024)],
                imageName: "drake_stage",
                description: "Outdoor headliner at Shoreline with pit, reserved sections, and lawn passes.",
                listings: makeListings(
                    eventID: stableUUID(3055),
                    eventSeed: 3055,
                    count: 192,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 95...410
                )
            ),
            Event(
                id: stableUUID(3056),
                title: "Wicked",
                date: makeDate(2026, 5, 24, 14, 0),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2018)],
                imageName: "hamilton_marquee",
                description: "Saturday matinee with orchestra and balcony seating at the Orpheum.",
                listings: makeListings(
                    eventID: stableUUID(3056),
                    eventSeed: 3056,
                    count: 58,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 92...290
                )
            ),
            Event(
                id: stableUUID(3057),
                title: "Dodgers at Giants",
                date: makeDate(2026, 5, 12, 18, 45),
                venueID: venue(1002).id,
                city: venue(1002).city,
                category: .sports,
                performers: [performer(2029), performer(2005)],
                imageName: "oracle_baseball",
                description: "Midseason rivalry series at Oracle Park. Premium club and bleacher inventory.",
                listings: makeListings(
                    eventID: stableUUID(3057),
                    eventSeed: 3057,
                    count: 215,
                    category: .sports,
                    sectionPool: ["101", "109", "115", "122", "130", "202", "208", "221", "LB", "VR", "Bleachers"],
                    priceRange: 52...285
                )
            ),
            Event(
                id: stableUUID(3058),
                title: "John Mulaney",
                date: makeDate(2026, 5, 9, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2019)],
                imageName: "comedy_stage",
                description: "Upgraded venue — stand-up set at The Masonic with floor and balcony options.",
                listings: makeListings(
                    eventID: stableUUID(3058),
                    eventSeed: 3058,
                    count: 76,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 82...210
                )
            ),
            Event(
                id: stableUUID(3059),
                title: "SZA",
                date: makeDate(2026, 8, 2, 19, 30),
                venueID: venue(1016).id,
                city: venue(1016).city,
                category: .concerts,
                performers: [performer(2034)],
                imageName: "sza_stage",
                description: "Outdoor summer show at Frost Amphitheater with reserved and lawn seating.",
                listings: makeListings(
                    eventID: stableUUID(3059),
                    eventSeed: 3059,
                    count: 112,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "201", "Lawn", "GA"],
                    priceRange: 105...365
                )
            ),
            Event(
                id: stableUUID(3060),
                title: "Olivia Rodrigo",
                date: makeDate(2026, 6, 1, 19, 30),
                venueID: venue(1013).id,
                city: venue(1013).city,
                category: .concerts,
                performers: [performer(2035)],
                imageName: "olivia_rodrigo_stage",
                description: "Intimate second show at The Fillmore with standing room and reserved balcony.",
                listings: makeListings(
                    eventID: stableUUID(3060),
                    eventSeed: 3060,
                    count: 62,
                    category: .concerts,
                    sectionPool: ["Floor", "Balcony", "GA"],
                    priceRange: 118...395
                )
            ),
            Event(
                id: stableUUID(3061),
                title: "Nate Bargatze",
                date: makeDate(2026, 4, 10, 20, 0),
                venueID: venue(1015).id,
                city: venue(1015).city,
                category: .comedy,
                performers: [performer(2012)],
                imageName: "comedy_stage",
                description: "Bigger room show at The Masonic with floor, center, and balcony seating.",
                listings: makeListings(
                    eventID: stableUUID(3061),
                    eventSeed: 3061,
                    count: 68,
                    category: .comedy,
                    sectionPool: ["Front", "Center", "Side", "GA"],
                    priceRange: 64...175
                )
            ),
            Event(
                id: stableUUID(3062),
                title: "Lady Gaga",
                date: makeDate(2026, 7, 3, 20, 30),
                venueID: venue(1008).id,
                city: venue(1008).city,
                category: .concerts,
                performers: [performer(2008)],
                imageName: "lady_gaga_stage",
                description: "Second night at Oakland Arena. Fresh floor and club level resale inventory.",
                listings: makeListings(
                    eventID: stableUUID(3062),
                    eventSeed: 3062,
                    count: 139,
                    category: .concerts,
                    sectionPool: ["Floor", "114", "117", "121", "210", "214", "217"],
                    priceRange: 122...540
                )
            ),
            Event(
                id: stableUUID(3063),
                title: "The Lion King",
                date: makeDate(2026, 4, 13, 14, 0),
                venueID: venue(1006).id,
                city: venue(1006).city,
                category: .theater,
                performers: [performer(2028)],
                imageName: "theater_marquee",
                description: "Sunday matinee — great for families. Orchestra and balcony seats available.",
                listings: makeListings(
                    eventID: stableUUID(3063),
                    eventSeed: 3063,
                    count: 60,
                    category: .theater,
                    sectionPool: ["Orchestra", "Front Mezz", "Rear Mezz", "Balcony"],
                    priceRange: 88...305
                )
            ),
            Event(
                id: stableUUID(3064),
                title: "Post Malone",
                date: makeDate(2026, 7, 6, 20, 0),
                venueID: venue(1005).id,
                city: venue(1005).city,
                category: .concerts,
                performers: [performer(2043)],
                imageName: "post_malone_stage",
                description: "Second night at Shoreline with added lawn and pit inventory.",
                listings: makeListings(
                    eventID: stableUUID(3064),
                    eventSeed: 3064,
                    count: 174,
                    category: .concerts,
                    sectionPool: ["Pit", "101", "102", "103", "201", "202", "Lawn", "GA"],
                    priceRange: 82...340
                )
            ),
            Event(
                id: stableUUID(3065),
                title: "Doja Cat",
                date: makeDate(2026, 6, 15, 20, 0),
                venueID: venue(1000).id,
                city: venue(1000).city,
                category: .concerts,
                performers: [performer(2042)],
                imageName: "doja_cat_stage",
                description: "Second Chase Center date with more floor and lower bowl resale inventory.",
                listings: makeListings(
                    eventID: stableUUID(3065),
                    eventSeed: 3065,
                    count: 148,
                    category: .concerts,
                    sectionPool: ["Floor", "107", "111", "115", "118", "213", "217"],
                    priceRange: 112...460
                )
            )
        ]
    }

    static func makePastTickets() -> [TicketArchiveItem] {
        [
            TicketArchiveItem(
                id: stableUUID(4000),
                title: "Padres\nat Braves",
                date: makeDate(2024, 5, 17, 19, 20),
                style: .padresAtBraves,
                pricePaid: 124,
                venueName: "Truist Park",
                section: "142",
                row: "8",
                seatRange: "5-6"
            ),
            TicketArchiveItem(
                id: stableUUID(4001),
                title: "Giants\nat Dodgers",
                date: makeDate(2024, 8, 3, 18, 10),
                style: .giantsAtDodgers,
                pricePaid: 156,
                venueName: "Dodger Stadium",
                section: "118",
                row: "12",
                seatRange: "3-4"
            ),
            TicketArchiveItem(
                id: stableUUID(4002),
                title: "Rockies\nat Giants",
                date: makeDate(2025, 9, 13, 13, 5),
                style: .giantsVsRockies,
                pricePaid: 68,
                venueName: "Oracle Park",
                section: "210",
                row: "14",
                seatRange: "1-2"
            ),
            TicketArchiveItem(
                id: stableUUID(4003),
                title: "Padres\nat Giants",
                date: makeDate(2025, 9, 26, 18, 45),
                style: .giantsVsPadres,
                pricePaid: 92,
                venueName: "Oracle Park",
                section: "126",
                row: "6",
                seatRange: "7-8"
            ),
            TicketArchiveItem(
                id: stableUUID(4004),
                title: "Suns at\nWarriors",
                date: makeDate(2025, 10, 22, 19, 0),
                style: .warriorsVsSuns,
                pricePaid: 185,
                venueName: "Chase Center",
                section: "108",
                row: "10",
                seatRange: "9-10"
            ),
            TicketArchiveItem(
                id: stableUUID(4005),
                title: "Dave Chappelle",
                date: makeDate(2025, 11, 1, 20, 0),
                style: .comedyMasonic,
                pricePaid: 135,
                venueName: "Masonic Auditorium",
                section: "Orchestra",
                row: "F",
                seatRange: "12-13"
            ),
            TicketArchiveItem(
                id: stableUUID(4006),
                title: "Khruangbin",
                date: makeDate(2025, 11, 13, 20, 30),
                style: .concertFillmore,
                pricePaid: 89,
                venueName: "The Fillmore",
                section: "GA",
                row: "-",
                seatRange: "-"
            ),
            TicketArchiveItem(
                id: stableUUID(4007),
                title: "Nuggets at\nWarriors",
                date: makeDate(2025, 12, 5, 19, 0),
                style: .warriorsVsNuggets,
                pricePaid: 210,
                venueName: "Chase Center",
                section: "214",
                row: "3",
                seatRange: "15-16"
            ),
            TicketArchiveItem(
                id: stableUUID(4008),
                title: "Tyler, the Creator",
                date: makeDate(2025, 12, 13, 20, 0),
                style: .concertChaseCenter,
                pricePaid: 175,
                venueName: "Chase Center",
                section: "Floor",
                row: "AA",
                seatRange: "22-23"
            ),
            TicketArchiveItem(
                id: stableUUID(4009),
                title: "Hamilton",
                date: makeDate(2026, 1, 10, 14, 0),
                style: .theaterOrpheum,
                pricePaid: 198,
                venueName: "Orpheum Theatre",
                section: "Mezzanine",
                row: "B",
                seatRange: "8-9"
            ),
            TicketArchiveItem(
                id: stableUUID(4010),
                title: "Dodgers at\nGiants",
                date: makeDate(2026, 1, 25, 13, 5),
                style: .giantsVsDodgers,
                pricePaid: 142,
                venueName: "Oracle Park",
                section: "132",
                row: "18",
                seatRange: "11-12"
            ),
            TicketArchiveItem(
                id: stableUUID(4011),
                title: "Clippers at\nWarriors",
                date: makeDate(2026, 2, 11, 19, 30),
                style: .warriorsVsClippers,
                pricePaid: 165,
                venueName: "Chase Center",
                section: "110",
                row: "7",
                seatRange: "1-2"
            ),
            TicketArchiveItem(
                id: stableUUID(4012),
                title: "Wicked",
                date: makeDate(2025, 10, 18, 19, 30),
                style: .theaterOrpheum,
                pricePaid: 178,
                venueName: "Orpheum Theatre",
                section: "Mezzanine",
                row: "B",
                seatRange: "8-9"
            ),
            TicketArchiveItem(
                id: stableUUID(4013),
                title: "Suns at\nWarriors",
                date: makeDate(2026, 1, 4, 17, 0),
                style: .warriorsVsSuns,
                pricePaid: 195,
                venueName: "Chase Center",
                section: "108",
                row: "10",
                seatRange: "9-10"
            ),
            TicketArchiveItem(
                id: stableUUID(4014),
                title: "Nuggets at\nWarriors",
                date: makeDate(2026, 2, 22, 19, 30),
                style: .warriorsVsNuggets,
                pricePaid: 225,
                venueName: "Chase Center",
                section: "214",
                row: "3",
                seatRange: "15-16"
            ),
            TicketArchiveItem(
                id: stableUUID(4015),
                title: "Ali Wong",
                date: makeDate(2025, 9, 6, 20, 0),
                style: .comedyMasonic,
                pricePaid: 112,
                venueName: "Masonic Auditorium",
                section: "Orchestra",
                row: "F",
                seatRange: "12-13"
            ),
            TicketArchiveItem(
                id: stableUUID(4016),
                title: "The Lion King",
                date: makeDate(2025, 12, 20, 14, 0),
                style: .theaterOrpheum,
                pricePaid: 155,
                venueName: "Orpheum Theatre",
                section: "Mezzanine",
                row: "B",
                seatRange: "8-9"
            ),
            TicketArchiveItem(
                id: stableUUID(4017),
                title: "Padres at\nGiants",
                date: makeDate(2025, 8, 15, 18, 45),
                style: .giantsVsPadres,
                pricePaid: 78,
                venueName: "Oracle Park",
                section: "126",
                row: "6",
                seatRange: "7-8"
            ),
            TicketArchiveItem(
                id: stableUUID(4018),
                title: "Billie Eilish",
                date: makeDate(2025, 11, 22, 20, 0),
                style: .concertChaseCenter,
                pricePaid: 245,
                venueName: "Chase Center",
                section: "Floor",
                row: "AA",
                seatRange: "22-23"
            ),
            TicketArchiveItem(
                id: stableUUID(4019),
                title: "Dear Evan\nHansen",
                date: makeDate(2025, 10, 5, 14, 0),
                style: .theaterOrpheum,
                pricePaid: 132,
                venueName: "Orpheum Theatre",
                section: "Mezzanine",
                row: "B",
                seatRange: "8-9"
            ),
            TicketArchiveItem(
                id: stableUUID(4020),
                title: "Dodgers at\nGiants",
                date: makeDate(2025, 7, 12, 13, 5),
                style: .giantsVsDodgers,
                pricePaid: 138,
                venueName: "Oracle Park",
                section: "132",
                row: "18",
                seatRange: "11-12"
            ),
            TicketArchiveItem(
                id: stableUUID(4021),
                title: "Kendrick Lamar",
                date: makeDate(2025, 8, 30, 20, 30),
                style: .concertFillmore,
                pricePaid: 195,
                venueName: "The Fillmore",
                section: "GA",
                row: "-",
                seatRange: "-"
            ),
            TicketArchiveItem(
                id: stableUUID(4022),
                title: "Nate Bargatze",
                date: makeDate(2026, 1, 17, 20, 0),
                style: .comedyMasonic,
                pricePaid: 85,
                venueName: "Masonic Auditorium",
                section: "Orchestra",
                row: "F",
                seatRange: "12-13"
            )
        ]
    }

    static func defaultRecentSearches(events: [Event], performers: [Performer], venues: [Venue]) -> [SearchRecord] {
        let performerByID = Dictionary(uniqueKeysWithValues: performers.map { ($0.id, $0) })
        let venueByID = Dictionary(uniqueKeysWithValues: venues.map { ($0.id, $0) })
        let eventByID = Dictionary(uniqueKeysWithValues: events.map { ($0.id, $0) })

        let warriors = performerByID[stableUUID(2000)]
        let hamilton = eventByID[stableUUID(3008)]
        let oraclePark = venueByID[stableUUID(1002)]
        let billieEilish = performerByID[stableUUID(2032)]
        let chaseCenter = venueByID[stableUUID(1000)]
        let taylorSwift = eventByID[stableUUID(3023)]

        return [
            SearchRecord(
                id: stableUUID(5000),
                title: warriors?.name ?? "Golden State Warriors",
                subtitle: warriors?.category.rawValue ?? "Sports",
                imageName: warriors?.imageName ?? "warriors",
                kind: .performer,
                referenceID: warriors?.id
            ),
            SearchRecord(
                id: stableUUID(5001),
                title: hamilton?.title ?? "Hamilton",
                subtitle: hamilton.flatMap { venueByID[$0.venueID]?.name } ?? "Orpheum Theatre",
                imageName: hamilton?.imageName ?? "hamilton_marquee",
                kind: .event,
                referenceID: hamilton?.id
            ),
            SearchRecord(
                id: stableUUID(5002),
                title: oraclePark?.name ?? "Oracle Park",
                subtitle: oraclePark?.city ?? "San Francisco",
                imageName: oraclePark?.imageName ?? "oracle_park",
                kind: .venue,
                referenceID: oraclePark?.id
            ),
            SearchRecord(
                id: stableUUID(5004),
                title: billieEilish?.name ?? "Billie Eilish",
                subtitle: billieEilish?.category.rawValue ?? "Concerts",
                imageName: billieEilish?.imageName ?? "billie_eilish",
                kind: .performer,
                referenceID: billieEilish?.id
            ),
            SearchRecord(
                id: stableUUID(5005),
                title: chaseCenter?.name ?? "Chase Center",
                subtitle: chaseCenter?.city ?? "San Francisco",
                imageName: chaseCenter?.imageName ?? "city_arena",
                kind: .venue,
                referenceID: chaseCenter?.id
            ),
            SearchRecord(
                id: stableUUID(5006),
                title: taylorSwift?.title ?? "Taylor Swift | The Eras Tour",
                subtitle: taylorSwift.flatMap { venueByID[$0.venueID]?.name } ?? "Levi's Stadium",
                imageName: taylorSwift?.imageName ?? "taylor_swift_stage",
                kind: .event,
                referenceID: taylorSwift?.id
            )
        ]
    }

    static func searchSuggestions() -> [SearchSuggestion] {
        SearchSuggestionKind.allCases.map {
            SearchSuggestion(id: $0, title: $0.title, systemImage: $0.systemImage, kind: $0)
        }
    }

    static func defaultRecentlyViewedEvents() -> [UUID] {
        [
            stableUUID(3033),
            stableUUID(3011),
            stableUUID(3008),
            stableUUID(3031),
            stableUUID(3004),
            stableUUID(3001)
        ]
    }

    static func defaultFavoriteEventIDs() -> [UUID] {
        [
            stableUUID(3001),
            stableUUID(3004),
            stableUUID(3008),
            stableUUID(3033),
            stableUUID(3023)
        ]
    }

    static func defaultFavoritePerformerIDs() -> [UUID] {
        [
            stableUUID(2002),
            stableUUID(2007),
            stableUUID(2008),
            stableUUID(2032),
            stableUUID(2022)
        ]
    }

    static func defaultFavoriteVenueIDs() -> [UUID] {
        [
            stableUUID(1000),
            stableUUID(1001),
            stableUUID(1006),
            stableUUID(1005)
        ]
    }

    static func defaultPromoCodes() -> [PromoCode] {
        let now = Date()
        return [
            PromoCode(
                id: stableUUID(6100),
                code: "WELCOME10",
                title: "$10 off your next order",
                detail: "Automatically applies on eligible orders over $75.",
                discountAmount: 10,
                minimumSpend: 75,
                expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now,
                isRedeemed: true,
                isConsumed: false
            ),
            PromoCode(
                id: stableUUID(6101),
                code: "BAYAREA15",
                title: "$15 off Bay Area events",
                detail: "Good on sports and concert purchases over $150.",
                discountAmount: 15,
                minimumSpend: 150,
                expiresAt: Calendar.current.date(byAdding: .day, value: 21, to: now) ?? now,
                isRedeemed: true,
                isConsumed: false
            ),
            PromoCode(
                id: stableUUID(6104),
                code: "PREMIUM25",
                title: "$25 off premium seats",
                detail: "Used on a recent theater order.",
                discountAmount: 25,
                minimumSpend: 200,
                expiresAt: Calendar.current.date(byAdding: .day, value: -2, to: now) ?? now,
                isRedeemed: true,
                isConsumed: true
            )
        ]
    }

    static func promoCatalog() -> [PromoCode] {
        let now = Date()
        return [
            PromoCode(
                id: stableUUID(6100),
                code: "WELCOME10",
                title: "$10 off your next order",
                detail: "Automatically applies on eligible orders over $75.",
                discountAmount: 10,
                minimumSpend: 75,
                expiresAt: Calendar.current.date(byAdding: .day, value: 14, to: now) ?? now,
                isRedeemed: true,
                isConsumed: false
            ),
            PromoCode(
                id: stableUUID(6101),
                code: "BAYAREA15",
                title: "$15 off Bay Area events",
                detail: "Good on sports and concert purchases over $150.",
                discountAmount: 15,
                minimumSpend: 150,
                expiresAt: Calendar.current.date(byAdding: .day, value: 21, to: now) ?? now,
                isRedeemed: true,
                isConsumed: false
            ),
            PromoCode(
                id: stableUUID(6102),
                code: "LOWERBOWL20",
                title: "$20 off lower bowl seats",
                detail: "Redeem this code for orders over $225 before fees.",
                discountAmount: 20,
                minimumSpend: 225,
                expiresAt: Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now,
                isRedeemed: false,
                isConsumed: false
            ),
            PromoCode(
                id: stableUUID(6103),
                code: "LATECHECKOUT12",
                title: "$12 off tonight's events",
                detail: "Valid on same-day orders over $90.",
                discountAmount: 12,
                minimumSpend: 90,
                expiresAt: Calendar.current.date(byAdding: .day, value: 3, to: now) ?? now,
                isRedeemed: false,
                isConsumed: false
            )
        ]
    }

    static func defaultOrders(events: [Event], venues: [Venue]) -> [Order] {
        guard let sharksEvent = events.first(where: { $0.id == stableUUID(3001) }),
              let sharksListing = sharksEvent.listings.first,
              let sharksVenue = venues.first(where: { $0.id == sharksEvent.venueID }),
              let hamiltonEvent = events.first(where: { $0.id == stableUUID(3008) }),
              let hamiltonListing = hamiltonEvent.listings.first(where: { $0.section == "Orchestra" }) ?? hamiltonEvent.listings.first,
              let hamiltonVenue = venues.first(where: { $0.id == hamiltonEvent.venueID }) else {
            return []
        }

        let now = Date()
        let sharksCreatedAt = Calendar.current.date(byAdding: .minute, value: -4, to: now) ?? now
        let sharksEstimatedDelivery = Calendar.current.date(byAdding: .minute, value: 6, to: now) ?? now
        let sharksItem = CartItem(
            id: stableUUID(6200),
            listingID: sharksListing.id,
            eventID: sharksEvent.id,
            eventTitle: sharksEvent.title,
            venueName: sharksVenue.name,
            city: sharksEvent.city,
            eventDate: sharksEvent.date,
            section: sharksListing.section,
            row: sharksListing.row,
            seatRange: "1-2",
            quantityAvailable: sharksListing.quantityAvailable,
            pricePerTicket: sharksListing.price,
            feesPerTicket: sharksListing.fees,
            deliveryType: sharksListing.deliveryType,
            quantity: 2
        )
        let sharksTotal = (sharksListing.price + sharksListing.fees) * 2

        let hamiltonCreatedAt = Calendar.current.date(byAdding: .minute, value: -52, to: now) ?? now
        let hamiltonEstimatedDelivery = Calendar.current.date(byAdding: .minute, value: -18, to: now) ?? now
        let hamiltonItem = CartItem(
            id: stableUUID(6206),
            listingID: hamiltonListing.id,
            eventID: hamiltonEvent.id,
            eventTitle: hamiltonEvent.title,
            venueName: hamiltonVenue.name,
            city: hamiltonEvent.city,
            eventDate: hamiltonEvent.date,
            section: hamiltonListing.section,
            row: hamiltonListing.row,
            seatRange: hamiltonListing.seatRange,
            quantityAvailable: hamiltonListing.quantityAvailable,
            pricePerTicket: hamiltonListing.price,
            feesPerTicket: hamiltonListing.fees,
            deliveryType: hamiltonListing.deliveryType,
            quantity: 2
        )
        let hamiltonSubtotal = (hamiltonListing.price + hamiltonListing.fees) * 2
        let hamiltonDiscount = 25.0

        return [
            Order(
                id: stableUUID(6201),
                orderNumber: "SG-842193",
                items: [sharksItem],
                createdAt: sharksCreatedAt,
                estimatedDelivery: sharksEstimatedDelivery,
                deliveryMethod: .instant,
                contactMethod: .email,
                appliedPromoCode: nil,
                discountAmount: nil,
                totalPaid: sharksTotal
            ),
            Order(
                id: stableUUID(6207),
                orderNumber: "SG-663508",
                items: [hamiltonItem],
                createdAt: hamiltonCreatedAt,
                estimatedDelivery: hamiltonEstimatedDelivery,
                deliveryMethod: .instant,
                contactMethod: .email,
                appliedPromoCode: "PREMIUM25",
                discountAmount: hamiltonDiscount,
                totalPaid: max(0, hamiltonSubtotal - hamiltonDiscount)
            )
        ]
    }

    static func importedMLBOrder(events: [Event], venues: [Venue]) -> Order? {
        guard let event = events.first(where: { $0.id == stableUUID(3011) }),
              let listing = event.listings.first(where: { $0.section == "LB" }) ?? event.listings.first,
              let venue = venues.first(where: { $0.id == event.venueID }) else {
            return nil
        }

        let now = Date()
        let createdAt = Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        let estimatedDelivery = Calendar.current.date(byAdding: .minute, value: -15, to: now) ?? now
        let item = CartItem(
            id: stableUUID(6202),
            listingID: listing.id,
            eventID: event.id,
            eventTitle: event.title,
            venueName: venue.name,
            city: event.city,
            eventDate: event.date,
            section: listing.section,
            row: listing.row,
            seatRange: listing.seatRange,
            quantityAvailable: listing.quantityAvailable,
            pricePerTicket: listing.price,
            feesPerTicket: listing.fees,
            deliveryType: .mobile,
            quantity: 2
        )

        return Order(
            id: stableUUID(6203),
            orderNumber: "SG-551044",
            items: [item],
            createdAt: createdAt,
            estimatedDelivery: estimatedDelivery,
            deliveryMethod: .mobileTransfer,
            contactMethod: .email,
            appliedPromoCode: nil,
            discountAmount: nil,
            totalPaid: (listing.price + listing.fees) * 2
        )
    }

    static func recoverableConcertOrder(events: [Event], venues: [Venue]) -> Order? {
        guard let event = events.first(where: { $0.id == stableUUID(3012) }),
              let listing = event.listings.first,
              let venue = venues.first(where: { $0.id == event.venueID }) else {
            return nil
        }

        let now = Date()
        let createdAt = Calendar.current.date(byAdding: .minute, value: -1, to: now) ?? now
        let estimatedDelivery = Calendar.current.date(byAdding: .minute, value: 9, to: now) ?? now
        let item = CartItem(
            id: stableUUID(6204),
            listingID: listing.id,
            eventID: event.id,
            eventTitle: event.title,
            venueName: venue.name,
            city: event.city,
            eventDate: event.date,
            section: listing.section,
            row: listing.row,
            seatRange: listing.seatRange,
            quantityAvailable: listing.quantityAvailable,
            pricePerTicket: listing.price,
            feesPerTicket: listing.fees,
            deliveryType: listing.deliveryType,
            quantity: 2
        )

        return Order(
            id: stableUUID(6205),
            orderNumber: "SG-193580",
            items: [item],
            createdAt: createdAt,
            estimatedDelivery: estimatedDelivery,
            deliveryMethod: listing.isInstant ? .instant : .mobileTransfer,
            contactMethod: .email,
            appliedPromoCode: nil,
            discountAmount: nil,
            totalPaid: (listing.price + listing.fees) * 2
        )
    }

    /// Public overload without manual blueprints, callable from outside SeedData.
    static func makeListings(
        eventID: UUID,
        eventSeed: Int,
        count: Int,
        category: EventCategory,
        sectionPool: [String],
        priceRange: ClosedRange<Int>
    ) -> [TicketListing] {
        makeListings(
            eventID: eventID,
            eventSeed: eventSeed,
            count: count,
            category: category,
            sectionPool: sectionPool,
            priceRange: priceRange,
            manual: []
        )
    }

    private static func makeListings(
        eventID: UUID,
        eventSeed: Int,
        count: Int,
        category: EventCategory,
        sectionPool: [String],
        priceRange: ClosedRange<Int>,
        manual: [ListingBlueprint]
    ) -> [TicketListing] {
        var generator = SeededGenerator(seed: UInt64(eventSeed))
        var listings: [TicketListing] = manual.enumerated().map { index, blueprint in
            let presentation = listingPresentation(
                section: blueprint.section,
                category: category,
                overrideStyle: blueprint.imageStyle,
                overrideDescription: blueprint.viewDescription
            )
            return TicketListing(
                id: stableUUID(700000 + (eventSeed * 1000) + index),
                eventID: eventID,
                section: blueprint.section,
                row: blueprint.row,
                seatRange: blueprint.seatRange,
                quantityAvailable: blueprint.quantityAvailable,
                price: blueprint.price,
                fees: blueprint.fees,
                deliveryType: blueprint.deliveryType,
                dealScore: blueprint.dealScore,
                imageStyle: presentation.style,
                viewDescription: presentation.description
            )
        }

        for index in manual.count..<count {
            let section = sectionPool[index % sectionPool.count]
            let isGeneralAdmission = section.contains("GA") || section.contains("Pit") || section.contains("Lawn") || section.contains("Floor")
            let row = isGeneralAdmission ? "GA" : "\(Int.random(in: 1...24, using: &generator))"
            let quantityAvailable = Int.random(in: 1...4, using: &generator)
            let seatRange: String
            if isGeneralAdmission {
                seatRange = "1-\(quantityAvailable)"
            } else {
                let startSeat = Int.random(in: 1...12, using: &generator)
                seatRange = "\(startSeat)-\(startSeat + quantityAvailable - 1)"
            }

            let price = Double(Int.random(in: priceRange.lowerBound...priceRange.upperBound, using: &generator))
            let feePercent = Double(Int.random(in: 14...22, using: &generator)) / 100
            let fees = max(7, (price * feePercent).rounded())
            let deliveryType: DeliveryType = {
                let roll = Int.random(in: 0...100, using: &generator)
                if roll < 55 { return .instant }
                if roll < 85 { return .mobile }
                return .transfer
            }()
            let dealScore = Int.random(in: 74...99, using: &generator)
            let presentation = listingPresentation(section: section, category: category)

            listings.append(
                TicketListing(
                    id: stableUUID(700000 + (eventSeed * 1000) + index),
                    eventID: eventID,
                    section: section,
                    row: row,
                    seatRange: seatRange,
                    quantityAvailable: quantityAvailable,
                    price: price,
                    fees: fees,
                    deliveryType: deliveryType,
                    dealScore: dealScore,
                    imageStyle: presentation.style,
                    viewDescription: presentation.description
                )
            )
        }

        return listings.sorted { lhs, rhs in
            if lhs.price == rhs.price {
                return lhs.dealScore > rhs.dealScore
            }
            return lhs.price < rhs.price
        }
    }

    static func listingPresentation(
        section: String,
        category: EventCategory,
        overrideStyle: ListingImageStyle? = nil,
        overrideDescription: String? = nil
    ) -> (style: ListingImageStyle, description: String) {
        if let overrideStyle, let overrideDescription {
            return (overrideStyle, overrideDescription)
        }

        let token = section.lowercased()

        switch category {
        case .sports:
            if token.contains("lb") || token.contains("vr") {
                return (.dugout, "Premium club sightline close to the action.")
            }
            if token.contains("bleachers") {
                return (.behindPlate, "Outfield bleacher perspective with a full-field view.")
            }
            if token.hasPrefix("10") || token.hasPrefix("11") || token.hasPrefix("12") {
                return (.centerCourt, "Lower bowl seats with a centered angle on the floor.")
            }
            if token.hasPrefix("21") || token.hasPrefix("22") {
                return (.cornerView, "Upper bowl value seats with a broad view of play.")
            }
            return (.clubLevel, "Elevated sideline view with easy concourse access.")
        case .concerts:
            if token.contains("pit") || token.contains("floor") {
                return (.floor, "On-the-floor access close to the stage production.")
            }
            if token.contains("lawn") {
                return (.lawn, "Lawn seating with a full view of the stage and screens.")
            }
            if token.contains("ga") {
                return (.generalAdmission, "General admission entry with standing-room flexibility.")
            }
            if token.contains("balcony") {
                return (.balcony, "Balcony seats with an elevated overview of the stage.")
            }
            return (.sideStage, "Reserved bowl seating with a clean angle on the stage.")
        case .theater:
            if token.contains("orchestra") {
                return (.orchestra, "Center orchestra sightline near the stage.")
            }
            if token.contains("front mezz") {
                return (.balcony, "Front mezzanine seats with a direct view of the set.")
            }
            return (.balcony, "Rear balcony seating with a full-stage perspective.")
        case .comedy:
            if token.contains("front") {
                return (.orchestra, "Front table seating close to the performer.")
            }
            if token.contains("side") {
                return (.balcony, "Side table view with a partial stage angle.")
            }
            if token.contains("ga") {
                return (.generalAdmission, "Standing-room access near the back of the room.")
            }
            return (.clubLevel, "Centered small-room view with clear sightlines.")
        }
    }
}
