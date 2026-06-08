import Foundation

enum SeedData {
    static func cities() -> [City] {
        [
            City(id: "city_san_francisco", name: "San Francisco", stateCode: "CA"),
            City(id: "city_new_york", name: "New York", stateCode: "NY"),
            City(id: "city_los_angeles", name: "Los Angeles", stateCode: "CA"),
            City(id: "city_chicago", name: "Chicago", stateCode: "IL"),
            City(id: "city_boston", name: "Boston", stateCode: "MA"),
            City(id: "city_seattle", name: "Seattle", stateCode: "WA"),
            City(id: "city_catalina", name: "Catalina Island", stateCode: "CA")
        ]
    }

    static func neighborhoods() -> [Neighborhood] {
        [
            Neighborhood(id: "neighborhood_west_village", name: "West Village", cityID: "city_new_york"),
            Neighborhood(id: "neighborhood_soho", name: "SoHo", cityID: "city_new_york"),
            Neighborhood(id: "neighborhood_midtown", name: "Midtown", cityID: "city_new_york"),

            Neighborhood(id: "neighborhood_mission", name: "Mission", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_soma", name: "SoMa", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_marina", name: "Marina", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_hayes", name: "Hayes Valley", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_financial", name: "Financial District", cityID: "city_san_francisco"),

            Neighborhood(id: "neighborhood_silver_lake", name: "Silver Lake", cityID: "city_los_angeles"),
            Neighborhood(id: "neighborhood_west_hollywood", name: "West Hollywood", cityID: "city_los_angeles"),
            Neighborhood(id: "neighborhood_santa_monica", name: "Santa Monica", cityID: "city_los_angeles"),

            Neighborhood(id: "neighborhood_west_loop", name: "West Loop", cityID: "city_chicago"),
            Neighborhood(id: "neighborhood_river_north", name: "River North", cityID: "city_chicago"),
            Neighborhood(id: "neighborhood_wicker_park", name: "Wicker Park", cityID: "city_chicago"),

            Neighborhood(id: "neighborhood_back_bay", name: "Back Bay", cityID: "city_boston"),
            Neighborhood(id: "neighborhood_north_end", name: "North End", cityID: "city_boston"),
            Neighborhood(id: "neighborhood_seaport", name: "Seaport", cityID: "city_boston"),

            Neighborhood(id: "neighborhood_capitol_hill", name: "Capitol Hill", cityID: "city_seattle"),
            Neighborhood(id: "neighborhood_ballard", name: "Ballard", cityID: "city_seattle"),
            Neighborhood(id: "neighborhood_belltown", name: "Belltown", cityID: "city_seattle"),

            Neighborhood(id: "neighborhood_chinatown_sf", name: "Chinatown", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_inner_sunset", name: "Inner Sunset", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_nob_hill", name: "Nob Hill", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_north_beach", name: "North Beach", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_fillmore", name: "Fillmore", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_japantown", name: "Japantown", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_nopa", name: "NoPa", cityID: "city_san_francisco"),
            Neighborhood(id: "neighborhood_richmond", name: "Inner Richmond", cityID: "city_san_francisco"),

            Neighborhood(id: "neighborhood_greenwich_village", name: "Greenwich Village", cityID: "city_new_york"),
            Neighborhood(id: "neighborhood_les", name: "Lower East Side", cityID: "city_new_york"),
            Neighborhood(id: "neighborhood_williamsburg", name: "Williamsburg", cityID: "city_new_york"),
            Neighborhood(id: "neighborhood_chelsea", name: "Chelsea", cityID: "city_new_york"),

            Neighborhood(id: "neighborhood_avalon", name: "Avalon", cityID: "city_catalina"),
            Neighborhood(id: "neighborhood_two_harbors", name: "Two Harbors", cityID: "city_catalina")
        ]
    }

    static func restaurants() -> [Restaurant] {
        [
            Restaurant(
                id: "restaurant_001",
                name: "Le Jardin Moderne",
                cuisine: "French",
                neighborhoodID: "neighborhood_soho",
                cityID: "city_new_york",
                address: "42 Prince St, New York, NY",
                hours: ["Mon-Thu 5:00 PM - 10:00 PM", "Fri-Sat 5:00 PM - 11:00 PM", "Sun 5:00 PM - 9:30 PM"],
                priceTier: 4,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.5,
                distanceMiles: 0.6,
                shortDescription: "Seasonal French tasting menus with a chef's counter and curated wine pairings.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation time.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Chef's counter seats are communal for parties under 4.",
                    creditCardHold: "$50 per person hold required for peak times."
                ),
                menuHighlights: ["Dry-aged duck", "Black truffle tagliolini", "Mille-feuille"],
                photoCount: 12,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_002",
                name: "Hudson Grill House",
                cuisine: "American",
                neighborhoodID: "neighborhood_west_village",
                cityID: "city_new_york",
                address: "155 Hudson St, New York, NY",
                hours: ["Daily 4:30 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.2,
                shortDescription: "A lively brasserie with wood-fired mains and rooftop cocktail seating.",
                tags: [.popular, .outdoorSeating, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation time.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Outdoor seating is weather dependent.",
                    creditCardHold: "No credit card hold for standard dining room."
                ),
                menuHighlights: ["Prime rib", "Oyster platter", "Brown butter pie"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_003",
                name: "Cedar & Smoke",
                cuisine: "Mediterranean",
                neighborhoodID: "neighborhood_midtown",
                cityID: "city_new_york",
                address: "11 W 46th St, New York, NY",
                hours: ["Mon-Sat 5:00 PM - 10:00 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.6,
                distanceMiles: 1.8,
                shortDescription: "Charcoal-grilled mezze and modern Levantine dishes in a warm dining room.",
                tags: [.vegetarianFriendly, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Bar seats available for walk-ins when possible.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Lamb kofta", "Charred eggplant", "Pistachio baklava"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_004",
                name: "Golden Gate Izakaya",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "298 Valencia St, San Francisco, CA",
                hours: ["Daily 5:00 PM - 11:00 PM"],
                priceTier: 3,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 0.9,
                shortDescription: "A polished izakaya with robata specials, nigiri flights, and sake pairings.",
                tags: [.popular, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation time.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Counter seating recommended for full omakase menu.",
                    creditCardHold: "$25 per person for weekend omakase."
                ),
                menuHighlights: ["Binchotan skewers", "Bluefin nigiri", "Yuzu panna cotta"],
                photoCount: 14,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_005",
                name: "Harborline Seafood",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_marina",
                cityID: "city_san_francisco",
                address: "20 Marina Blvd, San Francisco, CA",
                hours: ["Sat-Sun 10:00 AM - 2:30 PM", "Tue-Sun 5:30 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.7,
                valueRating: 4.2,
                distanceMiles: 2.3,
                shortDescription: "Bayfront seafood house known for shellfish towers and seasonal tasting menus. Weekend brunch with marina views.",
                tags: [.newlyAdded, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Patio tables have a 2-hour dining window.",
                    creditCardHold: "$75 hold for patio prime sunset window."
                ),
                menuHighlights: ["Dungeness crab", "Cioppino", "Lemon tart"],
                photoCount: 11,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_006",
                name: "Fiore Trattoria",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_soma",
                cityID: "city_san_francisco",
                address: "451 Howard St, San Francisco, CA",
                hours: ["Daily 4:30 PM - 10:00 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.5,
                distanceMiles: 1.5,
                shortDescription: "Neighborhood trattoria with handmade pasta, natural wines, and late seating.",
                tags: [.vegetarianFriendly, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: false,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Parties over 6 are seated at shared banquettes.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Rigatoni alla vodka", "Burrata", "Tiramisu"],
                photoCount: 8,
                availabilityPattern: .standard
            ),

            // ── Benchmark diversification: additional SF restaurants ──
            // Added so DineSpot-reservation tasks can spread across more venues
            // instead of repeatedly targeting Harborline/Fiore/Golden Gate Izakaya.
            Restaurant(
                id: "restaurant_sf_mission_block",
                name: "Mission Block",
                cuisine: "New American",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "3120 Valencia St, San Francisco, CA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.4,
                shortDescription: "Neighborhood New American with a seasonal tasting menu and lively bar.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Patio seats released to waitlist if weather turns.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Sourdough pasta", "Dry-aged ribeye", "Olive oil cake"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_sf_marina_oyster",
                name: "Marina Oyster Club",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_marina",
                cityID: "city_san_francisco",
                address: "2250 Chestnut St, San Francisco, CA",
                hours: ["Sat-Sun 10:30 AM - 2:30 PM", "Tue-Sun 5:30 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.8,
                valueRating: 4.3,
                distanceMiles: 2.6,
                shortDescription: "Raw bar and oyster counter with bayfront seats and weekend brunch.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Brunch seating is first come, first seated on patio.",
                    creditCardHold: "$50 hold required for patio peak times."
                ),
                menuHighlights: ["Oyster platter", "Bay scallop crudo", "Crab benedict"],
                photoCount: 12,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_sf_hayes_bistro",
                name: "Hayes Valley Bistro",
                cuisine: "French",
                neighborhoodID: "neighborhood_hayes",
                cityID: "city_san_francisco",
                address: "556 Hayes St, San Francisco, CA",
                hours: ["Daily 5:30 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.5,
                ambianceRating: 4.7,
                valueRating: 4.2,
                distanceMiles: 1.8,
                shortDescription: "Classic bistro plates in a cozy Hayes Valley dining room.",
                tags: [.newlyAdded, .vegetarianFriendly, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Banquette seating for parties of 2-4.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Steak frites", "Mushroom tartine", "Crème brûlée"],
                photoCount: 8,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_sf_soma_rooftop",
                name: "SoMa Rooftop",
                cuisine: "New American",
                neighborhoodID: "neighborhood_soma",
                cityID: "city_san_francisco",
                address: "888 Brannan St, San Francisco, CA",
                hours: ["Sat-Sun 11:00 AM - 3:00 PM", "Daily 5:00 PM - 11:00 PM"],
                priceTier: 3,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.8,
                valueRating: 4.2,
                distanceMiles: 0.4,
                shortDescription: "Rooftop bar and grill with skyline views and shareable plates.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 2 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Rooftop is covered but may close for high wind.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Smash burger", "Grilled artichokes", "Frozen espresso martini"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_sf_embarcadero_grill",
                name: "Embarcadero Grill",
                cuisine: "Californian",
                neighborhoodID: "neighborhood_financial",
                cityID: "city_san_francisco",
                address: "1 Market St, San Francisco, CA",
                hours: ["Mon-Fri 11:30 AM - 2:00 PM", "Daily 5:00 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 0.9,
                shortDescription: "Fresh California grill with a waterfront patio and weekday lunch service.",
                tags: [.popular, .outdoorSeating, .vegetarianFriendly, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Outdoor patio has 8-top max; larger parties seated indoors.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Grilled halibut", "Roasted carrot salad", "Lemon ricotta cake"],
                photoCount: 11,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_007",
                name: "Pacifica Terrace",
                cuisine: "Californian",
                neighborhoodID: "neighborhood_santa_monica",
                cityID: "city_los_angeles",
                address: "112 Ocean Ave, Santa Monica, CA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.8,
                valueRating: 4.3,
                distanceMiles: 1.1,
                shortDescription: "Coastal California menu, sunset terrace seating, and seasonal produce focus.",
                tags: [.popular, .outdoorSeating, .vegetarianFriendly, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "Sunset terrace requests cannot be guaranteed.",
                    creditCardHold: "$35 hold per party after 7 PM."
                ),
                menuHighlights: ["Citrus halibut", "Charred carrots", "Olive oil cake"],
                photoCount: 13,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_008",
                name: "Nori Counter LA",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_west_hollywood",
                cityID: "city_los_angeles",
                address: "9048 Sunset Blvd, West Hollywood, CA",
                hours: ["Tue-Sun 6:00 PM - 11:00 PM"],
                priceTier: 4,
                rating: 4.9,
                foodRating: 5.0,
                serviceRating: 4.9,
                ambianceRating: 4.8,
                valueRating: 4.6,
                distanceMiles: 2.7,
                shortDescription: "Intimate omakase counter with two nightly seatings and chef-driven seasonal menus.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 48 hours before reservation.",
                    lateArrivalPolicy: "Guests arriving over 10 minutes late may miss courses.",
                    seatingNotes: "Entire party must be present to be seated.",
                    creditCardHold: "$100 per person hold required."
                ),
                menuHighlights: ["Hokkaido uni", "A5 wagyu", "Matcha custard"],
                photoCount: 7,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_009",
                name: "Olvera Social Club",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_silver_lake",
                cityID: "city_los_angeles",
                address: "1761 Sunset Blvd, Los Angeles, CA",
                hours: ["Daily 5:00 PM - 11:00 PM"],
                priceTier: 2,
                rating: 4.2,
                foodRating: 4.3,
                serviceRating: 4.1,
                ambianceRating: 4.4,
                valueRating: 4.3,
                distanceMiles: 1.9,
                shortDescription: "Modern Mexican small plates, agave cocktails, and a vibrant courtyard.",
                tags: [.newlyAdded, .outdoorSeating, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: false,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Courtyard requests are based on weather and capacity.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Birria tacos", "Ceviche tostada", "Churros"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_010",
                name: "Lakefront Room",
                cuisine: "American",
                neighborhoodID: "neighborhood_river_north",
                cityID: "city_chicago",
                address: "330 N Wabash Ave, Chicago, IL",
                hours: ["Mon-Sat 5:00 PM - 10:30 PM", "Sun 5:00 PM - 9:30 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.5,
                ambianceRating: 4.7,
                valueRating: 4.2,
                distanceMiles: 1.0,
                shortDescription: "Downtown steak-and-seafood destination with skyline views.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Window tables are first requested, first assigned.",
                    creditCardHold: "$40 hold for parties of 6+."
                ),
                menuHighlights: ["Prime strip", "Lobster risotto", "Butter cake"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_011",
                name: "Fulton Tasting Table",
                cuisine: "Contemporary",
                neighborhoodID: "neighborhood_west_loop",
                cityID: "city_chicago",
                address: "932 W Fulton St, Chicago, IL",
                hours: ["Wed-Sun 5:30 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.7,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 2.2,
                shortDescription: "Contemporary tasting room offering rotating chef's menu and beverage pairings.",
                tags: [.chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Full menu service starts promptly.",
                    seatingNotes: "Dietary restrictions must be shared 24 hours ahead.",
                    creditCardHold: "$75 per person hold required."
                ),
                menuHighlights: ["Smoked trout", "Venison loin", "Pear sorbet"],
                photoCount: 6,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_012",
                name: "Wicker Park Bistro",
                cuisine: "French",
                neighborhoodID: "neighborhood_wicker_park",
                cityID: "city_chicago",
                address: "1515 N Damen Ave, Chicago, IL",
                hours: ["Daily 4:30 PM - 10:00 PM"],
                priceTier: 2,
                rating: 4.1,
                foodRating: 4.2,
                serviceRating: 4.0,
                ambianceRating: 4.1,
                valueRating: 4.3,
                distanceMiles: 3.3,
                shortDescription: "Comfort-forward bistro classics and natural wine flights.",
                tags: [.barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: false,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Bar and lounge seats may be substituted for late reservations.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Steak frites", "Onion tart", "Chocolate pot de creme"],
                photoCount: 5,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_013",
                name: "Commonwealth Steakhouse",
                cuisine: "Steakhouse",
                neighborhoodID: "neighborhood_back_bay",
                cityID: "city_boston",
                address: "485 Boylston St, Boston, MA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.6,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 0.8,
                shortDescription: "Classic steakhouse with premium cuts and an extensive cellar.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Business attire encouraged in main dining room.",
                    creditCardHold: "$50 hold for reservations after 8 PM."
                ),
                menuHighlights: ["Bone-in ribeye", "Lobster mac", "Key lime pie"],
                photoCount: 8,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_014",
                name: "North End Osteria",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_north_end",
                cityID: "city_boston",
                address: "23 Salem St, Boston, MA",
                hours: ["Tue-Sun 5:00 PM - 10:00 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.6,
                distanceMiles: 1.6,
                shortDescription: "Cozy neighborhood osteria focused on regional Italian comfort dishes.",
                tags: [.vegetarianFriendly, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Patio seating unavailable during inclement weather.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Cacio e pepe", "Branzino", "Cannoli"],
                photoCount: 11,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_015",
                name: "Seaport Raw Bar",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_seaport",
                cityID: "city_boston",
                address: "87 Northern Ave, Boston, MA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.5,
                valueRating: 4.1,
                distanceMiles: 2.4,
                shortDescription: "Modern raw bar with harbor views and New England shellfish.",
                tags: [.outdoorSeating, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: false,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "Outdoor patio closes at 9:30 PM.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Oyster sampler", "Butter-poached cod", "Blueberry tart"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_016",
                name: "Rain City Izakaya",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_capitol_hill",
                cityID: "city_seattle",
                address: "721 E Pike St, Seattle, WA",
                hours: ["Daily 5:30 PM - 11:00 PM"],
                priceTier: 2,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.7,
                distanceMiles: 1.7,
                shortDescription: "Late-night skewers, sake cocktails, and energetic counter service.",
                tags: [.barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Counter reservations may be standing-room until first course.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Chicken yakitori", "Miso cod", "Sesame mochi"],
                photoCount: 7,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_017",
                name: "Ballard Hearth",
                cuisine: "Pacific Northwest",
                neighborhoodID: "neighborhood_ballard",
                cityID: "city_seattle",
                address: "5411 Ballard Ave NW, Seattle, WA",
                hours: ["Wed-Sun 5:00 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.8,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 3.8,
                shortDescription: "Wood-fired coastal cuisine with limited nightly seating.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "No guaranteed seating preference for waitlist confirmations.",
                    creditCardHold: "$40 hold required for prime slots."
                ),
                menuHighlights: ["Cedar plank salmon", "Foraged mushroom toast", "Hazelnut tart"],
                photoCount: 6,
                availabilityPattern: .waitlistOnly
            ),
            Restaurant(
                id: "restaurant_018",
                name: "Belltown Tapas Room",
                cuisine: "Spanish",
                neighborhoodID: "neighborhood_belltown",
                cityID: "city_seattle",
                address: "2222 1st Ave, Seattle, WA",
                hours: ["Daily 5:00 PM - 11:00 PM"],
                priceTier: 2,
                rating: 4.2,
                foodRating: 4.3,
                serviceRating: 4.1,
                ambianceRating: 4.3,
                valueRating: 4.4,
                distanceMiles: 2.0,
                shortDescription: "Bustling tapas spot with standing-room bar and late-night menu.",
                tags: [.newlyAdded, .barSeating, .vegetarianFriendly],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 8 minutes.",
                    seatingNotes: "Tapas counter may substitute dining room seating.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Patatas bravas", "Garlic prawns", "Basque cheesecake"],
                photoCount: 5,
                availabilityPattern: .waitlistOnly
            ),
            Restaurant(
                id: "restaurant_019",
                name: "Greenwich Omakase Loft",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_west_village",
                cityID: "city_new_york",
                address: "78 Perry St, New York, NY",
                hours: ["Tue-Sun 5:30 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.9,
                foodRating: 5.0,
                serviceRating: 4.8,
                ambianceRating: 4.9,
                valueRating: 4.6,
                distanceMiles: 1.4,
                shortDescription: "Refined omakase in a loft-style dining room with two nightly seatings.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 48 hours before reservation.",
                    lateArrivalPolicy: "Arrivals after 10 minutes may forfeit the first course.",
                    seatingNotes: "Entire party must arrive together for chef's counter seating.",
                    creditCardHold: "$125 per guest hold required."
                ),
                menuHighlights: ["Otoro flight", "Uni hand roll", "Miso black cod"],
                photoCount: 12,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_020",
                name: "Mercer Pasta Lab",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_soho",
                cityID: "city_new_york",
                address: "131 Mercer St, New York, NY",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.5,
                distanceMiles: 0.9,
                shortDescription: "Handmade pasta bar with rotating regional menus and late-night service.",
                tags: [.newlyAdded, .barSeating, .vegetarianFriendly, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "Counter seats have a 90-minute dining window.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Saffron tagliatelle", "Burrata crostini", "Olive oil gelato"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_021",
                name: "Ferry House Grill",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_soma",
                cityID: "city_san_francisco",
                address: "1 Ferry Building, San Francisco, CA",
                hours: ["Daily 5:00 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.6,
                valueRating: 4.2,
                distanceMiles: 1.1,
                shortDescription: "Waterfront seafood grill with market-driven specials and shellfish towers.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Outdoor seating is weather dependent.",
                    creditCardHold: "$35 hold required for sunset patio."
                ),
                menuHighlights: ["King salmon crudo", "Charred octopus", "Meyer lemon tart"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_022",
                name: "Presidio Hearth",
                cuisine: "Californian",
                neighborhoodID: "neighborhood_marina",
                cityID: "city_san_francisco",
                address: "1800 Chestnut St, San Francisco, CA",
                hours: ["Tue-Sun 5:00 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.8,
                valueRating: 4.4,
                distanceMiles: 2.7,
                shortDescription: "Fire-driven California cuisine with an intimate chef's tasting counter.",
                tags: [.chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Chef's tasting seats are prepaid and non-transferable within 24 hours.",
                    creditCardHold: "$85 per person hold required."
                ),
                menuHighlights: ["Coal-roasted carrots", "Dry-aged duck", "Mandarin semifreddo"],
                photoCount: 11,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_023",
                name: "Echo Park Supper Club",
                cuisine: "Contemporary",
                neighborhoodID: "neighborhood_silver_lake",
                cityID: "city_los_angeles",
                address: "1632 Sunset Blvd, Los Angeles, CA",
                hours: ["Wed-Mon 5:30 PM - 11:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.7,
                valueRating: 4.3,
                distanceMiles: 2.3,
                shortDescription: "Modern supper club with vinyl sets, playful cocktails, and seasonal small plates.",
                tags: [.newlyAdded, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "Booth requests are not guaranteed.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Charred broccoli Caesar", "Short rib agnolotti", "Toffee pudding"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_024",
                name: "Melrose Raw Counter",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_west_hollywood",
                cityID: "city_los_angeles",
                address: "8428 Melrose Ave, West Hollywood, CA",
                hours: ["Tue-Sun 6:00 PM - 11:00 PM"],
                priceTier: 4,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.4,
                distanceMiles: 2.9,
                shortDescription: "Minimalist omakase and hand-roll bar with premium fish flown in daily.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 48 hours before reservation.",
                    lateArrivalPolicy: "Late arrivals may lose seated service sequence.",
                    seatingNotes: "No substitutions for chef tasting menu.",
                    creditCardHold: "$110 per guest hold required."
                ),
                menuHighlights: ["Toro tasting", "Scallop hand roll", "Miso caramel flan"],
                photoCount: 8,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_025",
                name: "Canal Street Oyster Hall",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_river_north",
                cityID: "city_chicago",
                address: "324 N Canal St, Chicago, IL",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.3,
                distanceMiles: 1.4,
                shortDescription: "Lively oyster bar with chilled towers and a classic martini program.",
                tags: [.barSeating, .bookableOnline, .outdoorSeating],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 10 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "High-top and bar seating may be assigned at peak times.",
                    creditCardHold: "$25 hold for patio prime hours."
                ),
                menuHighlights: ["East coast oyster flight", "Lobster roll", "Key lime tart"],
                photoCount: 9,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_026",
                name: "Fulton Ember Room",
                cuisine: "Steakhouse",
                neighborhoodID: "neighborhood_west_loop",
                cityID: "city_chicago",
                address: "1023 W Fulton Market, Chicago, IL",
                hours: ["Tue-Sun 5:30 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.7,
                ambianceRating: 4.6,
                valueRating: 4.3,
                distanceMiles: 2.5,
                shortDescription: "Open-fire steakhouse featuring dry-aged cuts and cellar selections.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Booths are prioritized for parties of four or more.",
                    creditCardHold: "$60 hold required for bookings after 7 PM."
                ),
                menuHighlights: ["Dry-aged porterhouse", "Black garlic potatoes", "Chocolate torte"],
                photoCount: 10,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_027",
                name: "Beacon Cellar Dining",
                cuisine: "French",
                neighborhoodID: "neighborhood_back_bay",
                cityID: "city_boston",
                address: "515 Boylston St, Boston, MA",
                hours: ["Wed-Mon 5:00 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.8,
                ambianceRating: 4.6,
                valueRating: 4.2,
                distanceMiles: 1.0,
                shortDescription: "Elegant French dining room known for prix-fixe menus and old-world service.",
                tags: [.tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 12 minutes.",
                    seatingNotes: "Dining room dress code is smart casual.",
                    creditCardHold: "$55 per guest hold required for tasting menu."
                ),
                menuHighlights: ["Duck confit", "Lobster vol-au-vent", "Paris-brest"],
                photoCount: 11,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_028",
                name: "Seaport Kaisen House",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_seaport",
                cityID: "city_boston",
                address: "85 Seaport Blvd, Boston, MA",
                hours: ["Daily 5:30 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.4,
                distanceMiles: 2.1,
                shortDescription: "Seaport sushi and robata destination with harbor-facing lounge seating.",
                tags: [.barSeating, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Patio and dock views are request-only.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["King salmon nigiri", "Robata mushrooms", "Yuzu cheesecake"],
                photoCount: 8,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_029",
                name: "Harborline Chophouse",
                cuisine: "Steakhouse",
                neighborhoodID: "neighborhood_belltown",
                cityID: "city_seattle",
                address: "1903 1st Ave, Seattle, WA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.7,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 2.2,
                shortDescription: "Classic chophouse with harbor views, premium cuts, and old-fashioned service.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Window requests are prioritized by reservation time.",
                    creditCardHold: "$45 hold required for parties of 4+."
                ),
                menuHighlights: ["Prime ribeye", "King crab gratin", "Warm pecan tart"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_030",
                name: "Capitol Hill Noodle Atelier",
                cuisine: "Asian Fusion",
                neighborhoodID: "neighborhood_capitol_hill",
                cityID: "city_seattle",
                address: "410 15th Ave E, Seattle, WA",
                hours: ["Wed-Mon 5:30 PM - 10:30 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.5,
                distanceMiles: 1.9,
                shortDescription: "House-made noodles, small plates, and a high-demand late dinner crowd.",
                tags: [.newlyAdded, .vegetarianFriendly, .barSeating],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 8 minutes.",
                    seatingNotes: "Counter and communal tables are common during peak hours.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Dan dan noodles", "Crispy tofu", "Black sesame mousse"],
                photoCount: 7,
                availabilityPattern: .waitlistOnly
            ),
            Restaurant(
                id: "restaurant_031",
                name: "Avalon Catch House",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_avalon",
                cityID: "city_catalina",
                address: "120 Crescent Ave, Avalon, CA",
                hours: ["Wed-Mon 11:30 AM - 9:00 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.8,
                valueRating: 4.4,
                distanceMiles: 0.3,
                shortDescription: "Harbor-front seafood spot serving the day's catch with panoramic ocean views and craft cocktails.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation time.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Patio seating is first-come, first-served at lunch.",
                    creditCardHold: "$50 per person hold for sunset patio window."
                ),
                menuHighlights: ["Grilled swordfish", "Lobster tacos", "Coconut key lime pie"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_032",
                name: "Catalina Cantina",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_avalon",
                cityID: "city_catalina",
                address: "215 Sumner Ave, Avalon, CA",
                hours: ["Daily 11:00 AM - 10:00 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.6,
                distanceMiles: 0.5,
                shortDescription: "Colorful island cantina with fresh ceviche, wood-fired tacos, and a rooftop mezcal bar.",
                tags: [.vegetarianFriendly, .outdoorSeating, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 4 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Rooftop bar is walk-in only.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Baja fish tacos", "Mango ceviche", "Churro sundae"],
                photoCount: 8,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_033",
                name: "Harbor Reef Grill",
                cuisine: "American",
                neighborhoodID: "neighborhood_two_harbors",
                cityID: "city_catalina",
                address: "1 Harbor Reef Rd, Two Harbors, CA",
                hours: ["Thu-Mon 12:00 PM - 8:30 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 8.2,
                shortDescription: "Laid-back beachside grill between two coves, known for smoked brisket and island-brewed beer.",
                tags: [.newlyAdded, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "All seating is outdoors; weather-dependent closures possible.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Smoked brisket plate", "Grilled mahi-mahi", "S'mores brownie"],
                photoCount: 6,
                availabilityPattern: .standard
            ),

            // ── TasteRank cross-pollination: San Francisco ──
            Restaurant(
                id: "restaurant_tr_tartine",
                name: "Tartine Manufactory",
                cuisine: "Bakery",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "595 Alabama St, San Francisco, CA",
                hours: ["Daily 8:00 AM - 5:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 1.2,
                shortDescription: "An airy industrial space where the pastry case alone is worth the walk.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Communal tables available for walk-ins.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Morning Bun", "Country Bread", "Smoked Trout Tartine"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_la_taqueria",
                name: "La Taqueria",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "2889 Mission St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:00 PM"],
                priceTier: 1,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.5,
                shortDescription: "No-rice burrito gospel with strong opinions about salsa verde.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Counter seating only.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Super Burrito", "Carne Asada Taco", "Carnitas Plate"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_el_farolito",
                name: "El Farolito",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "2779 Mission St, San Francisco, CA",
                hours: ["Daily 10:00 AM - 3:00 AM"],
                priceTier: 1,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.2,
                distanceMiles: 1.4,
                shortDescription: "Late-night super burritos that reward indecision.",
                tags: [.bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Limited indoor seating; most orders are to-go.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Super Burrito", "Quesadilla Suiza", "Nachos"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_rich_table",
                name: "Rich Table",
                cuisine: "New American",
                neighborhoodID: "neighborhood_hayes",
                cityID: "city_san_francisco",
                address: "199 Gough St, San Francisco, CA",
                hours: ["Daily 5:30 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 2.0,
                shortDescription: "The sardine chips started a whole genre.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Bar seating available for walk-ins.",
                    creditCardHold: "$25 per person hold for weekend dinner."
                ),
                menuHighlights: ["Sardine Chips", "Porcini Doughnuts", "Dry-Aged Duck"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_souvla",
                name: "Souvla",
                cuisine: "Greek",
                neighborhoodID: "neighborhood_hayes",
                cityID: "city_san_francisco",
                address: "517 Hayes St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 10:00 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.1,
                distanceMiles: 2.1,
                shortDescription: "Fast-casual Greek with perfectly charred wraps.",
                tags: [.bookableOnline, .vegetarianFriendly],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Outdoor seating available.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Lamb Wrap", "Frozen Yogurt", "Greek Salad"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_mama",
                name: "Mama",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_marina",
                cityID: "city_san_francisco",
                address: "1701 Stockton St, San Francisco, CA",
                hours: ["Daily 5:00 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 2.5,
                shortDescription: "Cozy Marina Italian with handmade pasta.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Intimate dining room seats 40.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Rigatoni", "Burrata", "Tiramisu"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_sightglass",
                name: "Sightglass Coffee",
                cuisine: "Coffee",
                neighborhoodID: "neighborhood_soma",
                cityID: "city_san_francisco",
                address: "270 7th St, San Francisco, CA",
                hours: ["Daily 7:00 AM - 6:00 PM"],
                priceTier: 2,
                rating: 4.2,
                foodRating: 4.3,
                serviceRating: 4.1,
                ambianceRating: 4.2,
                valueRating: 4.0,
                distanceMiles: 1.3,
                shortDescription: "Third-wave coffee in a cathedral-like industrial space.",
                tags: [.bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Open seating throughout the space.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Single Origin Pour Over", "Affogato"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_zy",
                name: "Z & Y Restaurant",
                cuisine: "Chinese",
                neighborhoodID: "neighborhood_chinatown_sf",
                cityID: "city_san_francisco",
                address: "655 Jackson St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:30 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.2,
                distanceMiles: 2.2,
                shortDescription: "Fiery Sichuan flavors in the heart of Chinatown.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Large parties welcome with advance notice.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Spicy Boiled Fish", "Ma Po Tofu", "Dan Dan Noodles"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_nopalito",
                name: "Nopalito",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_nopa",
                cityID: "city_san_francisco",
                address: "306 Broderick St, San Francisco, CA",
                hours: ["Daily 11:30 AM - 10:00 PM"],
                priceTier: 2,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 2.3,
                shortDescription: "Organic Mexican with pozole that warms the soul.",
                tags: [.vegetarianFriendly, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Patio seating available weather permitting.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Pozole", "Tamales", "Churros"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_mister_jius",
                name: "Mister Jiu's",
                cuisine: "Chinese-American",
                neighborhoodID: "neighborhood_chinatown_sf",
                cityID: "city_san_francisco",
                address: "28 Waverly Pl, San Francisco, CA",
                hours: ["Tue-Sat 5:30 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.6,
                distanceMiles: 2.1,
                shortDescription: "Modern Chinese-American fine dining redefining Chinatown.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Tasting menu available at the bar.",
                    creditCardHold: "$50 per person hold for tasting menu."
                ),
                menuHighlights: ["Sesame Balls", "Hot & Sour Soup", "Lap Cheung Fried Rice"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_san_tung",
                name: "San Tung",
                cuisine: "Chinese",
                neighborhoodID: "neighborhood_inner_sunset",
                cityID: "city_san_francisco",
                address: "1031 Irving St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:30 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.1,
                distanceMiles: 3.0,
                shortDescription: "The dry-fried chicken wings are worth the perpetual line.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Expect a wait during peak hours.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Dry-Fried Chicken Wings", "Dan Dan Noodles", "Pot Stickers"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_nari",
                name: "Nari",
                cuisine: "Thai",
                neighborhoodID: "neighborhood_japantown",
                cityID: "city_san_francisco",
                address: "1625 Post St, San Francisco, CA",
                hours: ["Wed-Sun 5:00 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 2.4,
                shortDescription: "Elevated Thai tasting menus in Japantown.",
                tags: [.chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Chef's counter seats 8.",
                    creditCardHold: "$50 per person hold for tasting menu."
                ),
                menuHighlights: ["Khao Soi", "Larb", "Curry Puffs"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_burma_superstar",
                name: "Burma Superstar",
                cuisine: "Burmese",
                neighborhoodID: "neighborhood_richmond",
                cityID: "city_san_francisco",
                address: "309 Clement St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:30 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.2,
                distanceMiles: 3.2,
                shortDescription: "Tea leaf salad that launched a thousand cravings.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Waitlist available via app.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Tea Leaf Salad", "Samosa Soup", "Rainbow Salad"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_hog_island",
                name: "Hog Island Oyster Co.",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_financial",
                cityID: "city_san_francisco",
                address: "1 Ferry Building #11, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:00 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 2.0,
                shortDescription: "Sweetwater oysters straight from Tomales Bay.",
                tags: [.popular, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Bar seating is first come, first served.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Sweetwater Oysters", "Clam Chowder", "Grilled Cheese"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_flour_water",
                name: "Flour + Water",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "2401 Harrison St, San Francisco, CA",
                hours: ["Daily 5:30 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 1.3,
                shortDescription: "Handmade pasta and Neapolitan pizza in the Mission.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Pasta tasting menu available at the bar.",
                    creditCardHold: "$25 per person hold for weekend dinner."
                ),
                menuHighlights: ["Margherita Pizza", "Pappardelle", "Seasonal Pasta"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_kin_khao",
                name: "Kin Khao",
                cuisine: "Thai",
                neighborhoodID: "neighborhood_financial",
                cityID: "city_san_francisco",
                address: "55 Cyril Magnin St, San Francisco, CA",
                hours: ["Daily 5:30 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 1.8,
                shortDescription: "Bold, authentic Thai in the heart of downtown.",
                tags: [.bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Walk-ins welcome at the bar.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Khao Soi", "Crispy Rice Salad", "Green Curry"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_delfina",
                name: "Delfina",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "3621 18th St, San Francisco, CA",
                hours: ["Daily 5:30 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.1,
                shortDescription: "Neighborhood Italian that's been a Mission anchor for decades.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Heated patio available.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Spaghetti", "Buttermilk Panna Cotta", "Grilled Lamb"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_che_fico",
                name: "Che Fico",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_nopa",
                cityID: "city_san_francisco",
                address: "838 Divisadero St, San Francisco, CA",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.6,
                distanceMiles: 2.5,
                shortDescription: "Wood-fired Italian with a Ligurian soul.",
                tags: [.popular, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Bar seating available for walk-ins.",
                    creditCardHold: "$25 per person hold for weekend dinner."
                ),
                menuHighlights: ["Focaccia di Recco", "Cacio e Pepe", "Wood-Fired Lamb"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_lazy_bear",
                name: "Lazy Bear",
                cuisine: "New American",
                neighborhoodID: "neighborhood_mission",
                cityID: "city_san_francisco",
                address: "3416 19th St, San Francisco, CA",
                hours: ["Wed-Sun 6:00 PM - 10:00 PM"],
                priceTier: 4,
                rating: 4.9,
                foodRating: 5.0,
                serviceRating: 4.8,
                ambianceRating: 4.9,
                valueRating: 4.7,
                distanceMiles: 1.2,
                shortDescription: "Communal tasting menu in a converted warehouse.",
                tags: [.popular, .chefCounter, .tastingMenu, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 48 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Communal seating only; tasting menu is mandatory.",
                    creditCardHold: "$100 per person prepaid ticket."
                ),
                menuHighlights: ["Seasonal Tasting Menu", "Amuse-Bouche Series"],
                photoCount: 10,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_tr_zuni_cafe",
                name: "Zuni Cafe",
                cuisine: "American",
                neighborhoodID: "neighborhood_hayes",
                cityID: "city_san_francisco",
                address: "1658 Market St, San Francisco, CA",
                hours: ["Tue-Sun 11:30 AM - 10:00 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.8,
                shortDescription: "The roast chicken for two is a San Francisco institution.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Roast chicken requires 1 hour advance order.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Roast Chicken", "Caesar Salad", "Espresso Granita"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_state_bird",
                name: "State Bird Provisions",
                cuisine: "New American",
                neighborhoodID: "neighborhood_fillmore",
                cityID: "city_san_francisco",
                address: "1529 Fillmore St, San Francisco, CA",
                hours: ["Mon-Sat 5:30 PM - 10:00 PM"],
                priceTier: 3,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 2.6,
                shortDescription: "Dim sum-style service with wildly inventive small plates.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Dishes circulate on carts; choose as they pass.",
                    creditCardHold: "$25 per person hold for dinner."
                ),
                menuHighlights: ["State Bird (Quail)", "Garlic Bread", "Seasonal Pancake"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_swan_oyster",
                name: "Swan Oyster Depot",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_nob_hill",
                cityID: "city_san_francisco",
                address: "1517 Polk St, San Francisco, CA",
                hours: ["Mon-Sat 10:30 AM - 5:30 PM"],
                priceTier: 3,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.6,
                distanceMiles: 2.3,
                shortDescription: "Counter-only raw bar that's been shucking since 1912.",
                tags: [.popular, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 10 minutes.",
                    seatingNotes: "Counter seating only; 18 stools total.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Crab Back", "Oysters", "Smoked Trout Salad"],
                photoCount: 10,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_tr_dumpling_home",
                name: "Dumpling Home",
                cuisine: "Chinese",
                neighborhoodID: "neighborhood_soma",
                cityID: "city_san_francisco",
                address: "335 6th St, San Francisco, CA",
                hours: ["Daily 11:00 AM - 9:00 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.1,
                distanceMiles: 1.4,
                shortDescription: "Soup dumplings and scallion pancakes done right.",
                tags: [.bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Small space; parties of 4 max.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Soup Dumplings", "Pork Buns", "Scallion Pancake"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_marufuku",
                name: "Marufuku Ramen",
                cuisine: "Japanese",
                neighborhoodID: "neighborhood_japantown",
                cityID: "city_san_francisco",
                address: "1581 Webster St #235, San Francisco, CA",
                hours: ["Daily 11:00 AM - 10:00 PM"],
                priceTier: 2,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.2,
                distanceMiles: 2.4,
                shortDescription: "Rich Hakata-style tonkotsu in Japantown.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Counter and table seating available.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Hakata Tonkotsu Ramen", "Chicken Paitan", "Gyoza"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_tonys",
                name: "Tony's Pizza Napoletana",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_north_beach",
                cityID: "city_san_francisco",
                address: "1570 Stockton St, San Francisco, CA",
                hours: ["Daily 12:00 PM - 10:00 PM"],
                priceTier: 2,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 2.2,
                shortDescription: "World champion pizza in seven different styles.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Walk-ins and reservations both accepted.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Margherita", "Quattro Formaggi", "NY Style Slice"],
                photoCount: 10,
                availabilityPattern: .standard
            ),

            // ── TasteRank cross-pollination: New York ──
            Restaurant(
                id: "restaurant_tr_carbone",
                name: "Carbone",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_greenwich_village",
                cityID: "city_new_york",
                address: "181 Thompson St, New York, NY",
                hours: ["Daily 5:30 PM - 11:00 PM"],
                priceTier: 4,
                rating: 4.9,
                foodRating: 5.0,
                serviceRating: 4.8,
                ambianceRating: 4.9,
                valueRating: 4.7,
                distanceMiles: 1.5,
                shortDescription: "Red-sauce Italian elevated to an art form.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Jacket suggested; reservations book up weeks in advance.",
                    creditCardHold: "$50 per person hold required."
                ),
                menuHighlights: ["Spicy Rigatoni", "Veal Parm", "Italian Cheesecake"],
                photoCount: 10,
                availabilityPattern: .sparse
            ),
            Restaurant(
                id: "restaurant_tr_katzs",
                name: "Katz's Delicatessen",
                cuisine: "Deli",
                neighborhoodID: "neighborhood_les",
                cityID: "city_new_york",
                address: "205 E Houston St, New York, NY",
                hours: ["Daily 8:00 AM - 10:45 PM"],
                priceTier: 2,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 1.8,
                shortDescription: "Pastrami piled high since 1888.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Counter and table service available.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Pastrami on Rye", "Matzo Ball Soup", "Knish"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_lilia",
                name: "Lilia",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_williamsburg",
                cityID: "city_new_york",
                address: "567 Union Ave, Brooklyn, NY",
                hours: ["Daily 5:30 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.8,
                foodRating: 4.9,
                serviceRating: 4.7,
                ambianceRating: 4.8,
                valueRating: 4.6,
                distanceMiles: 3.0,
                shortDescription: "Handmade pasta that justifies the bridge crossing.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Patio seating available in summer.",
                    creditCardHold: "$25 per person hold required."
                ),
                menuHighlights: ["Mafaldini", "Sheep's Milk Ricotta", "Grilled Octopus"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_don_angie",
                name: "Don Angie",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_west_village",
                cityID: "city_new_york",
                address: "103 Greenwich Ave, New York, NY",
                hours: ["Daily 5:00 PM - 10:30 PM"],
                priceTier: 4,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 1.2,
                shortDescription: "Pinwheel lasagna and Italian-American creativity.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Cozy dining room; reservations strongly recommended.",
                    creditCardHold: "$25 per person hold for dinner."
                ),
                menuHighlights: ["Pinwheel Lasagna", "Chrysanthemum Salad", "Cherry Pepper Ribs"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_via_carota",
                name: "Via Carota",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_west_village",
                cityID: "city_new_york",
                address: "51 Grove St, New York, NY",
                hours: ["Daily 12:00 PM - 10:30 PM"],
                priceTier: 3,
                rating: 4.6,
                foodRating: 4.7,
                serviceRating: 4.5,
                ambianceRating: 4.6,
                valueRating: 4.4,
                distanceMiles: 1.1,
                shortDescription: "A West Village standard for rustic Italian.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 12 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "No reservations; walk-in only with waitlist.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Carciofi Fritti", "Insalata Verde", "Tortelli"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_los_tacos",
                name: "Los Tacos No. 1",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_chelsea",
                cityID: "city_new_york",
                address: "75 9th Ave, New York, NY",
                hours: ["Daily 11:00 AM - 10:00 PM"],
                priceTier: 1,
                rating: 4.4,
                foodRating: 4.5,
                serviceRating: 4.3,
                ambianceRating: 4.4,
                valueRating: 4.2,
                distanceMiles: 1.6,
                shortDescription: "The best quick tacos in Manhattan.",
                tags: [.bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Counter service inside Chelsea Market.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Adobada Taco", "Carne Asada Taco", "Nopal Taco"],
                photoCount: 10,
                availabilityPattern: .standard
            ),

            // ── TasteRank cross-pollination: Los Angeles ──
            Restaurant(
                id: "restaurant_tr_holbox",
                name: "Holbox",
                cuisine: "Mexican",
                neighborhoodID: "neighborhood_silver_lake",
                cityID: "city_los_angeles",
                address: "3655 S Grand Ave, Los Angeles, CA",
                hours: ["Daily 10:00 AM - 6:00 PM"],
                priceTier: 2,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 2.5,
                shortDescription: "Baja-style seafood from the Mercado la Paloma.",
                tags: [.popular, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Communal seating inside the mercado.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Ceviche Tostada", "Octopus Taco", "Fish Zarandeado"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_bestia",
                name: "Bestia",
                cuisine: "Italian",
                neighborhoodID: "neighborhood_silver_lake",
                cityID: "city_los_angeles",
                address: "2121 7th Pl, Los Angeles, CA",
                hours: ["Daily 5:00 PM - 11:00 PM"],
                priceTier: 3,
                rating: 4.7,
                foodRating: 4.8,
                serviceRating: 4.6,
                ambianceRating: 4.7,
                valueRating: 4.5,
                distanceMiles: 3.0,
                shortDescription: "Industrial-chic Italian with bold flavors.",
                tags: [.popular, .barSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 24 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Bar seating available for walk-ins.",
                    creditCardHold: "$25 per person hold for weekend dinner."
                ),
                menuHighlights: ["Fennel Sausage Pizza", "Bone Marrow", "Caramelized Coppa"],
                photoCount: 10,
                availabilityPattern: .standard
            ),

            // ── TasteRank cross-pollination: Catalina Island ──
            Restaurant(
                id: "restaurant_tr_avalon_seafood",
                name: "Avalon Seafood & Fish Market",
                cuisine: "Seafood",
                neighborhoodID: "neighborhood_avalon",
                cityID: "city_catalina",
                address: "Pleasure Pier, Avalon, CA",
                hours: ["Daily 11:00 AM - 8:00 PM"],
                priceTier: 2,
                rating: 4.3,
                foodRating: 4.4,
                serviceRating: 4.2,
                ambianceRating: 4.3,
                valueRating: 4.1,
                distanceMiles: 0.4,
                shortDescription: "Fresh-off-the-boat seafood on the Avalon waterfront.",
                tags: [.outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Outdoor pier seating; weather dependent.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Fish & Chips", "Poke Bowl", "Lobster Roll"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_descanso",
                name: "Descanso Beach Club",
                cuisine: "Mediterranean",
                neighborhoodID: "neighborhood_avalon",
                cityID: "city_catalina",
                address: "1 Descanso Canyon Rd, Avalon, CA",
                hours: ["Daily 11:00 AM - 9:00 PM"],
                priceTier: 3,
                rating: 4.5,
                foodRating: 4.6,
                serviceRating: 4.4,
                ambianceRating: 4.5,
                valueRating: 4.3,
                distanceMiles: 0.6,
                shortDescription: "Beachfront dining with island cocktails.",
                tags: [.popular, .outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 8 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Beach cabana seating available for groups.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Grilled Mahi-Mahi", "Mediterranean Platter", "Key Lime Pie"],
                photoCount: 10,
                availabilityPattern: .standard
            ),
            Restaurant(
                id: "restaurant_tr_harbor_reef",
                name: "Harbor Reef Restaurant",
                cuisine: "American",
                neighborhoodID: "neighborhood_two_harbors",
                cityID: "city_catalina",
                address: "Two Harbors, Catalina Island, CA",
                hours: ["Daily 11:00 AM - 8:00 PM"],
                priceTier: 2,
                rating: 4.2,
                foodRating: 4.3,
                serviceRating: 4.1,
                ambianceRating: 4.2,
                valueRating: 4.0,
                distanceMiles: 8.5,
                shortDescription: "Rustic island fare at the quieter end of Catalina.",
                tags: [.outdoorSeating, .bookableOnline],
                supportsWaitlist: true,
                supportsNotify: true,
                policy: RestaurantPolicy(
                    cancellationPolicy: "Cancel up to 6 hours before reservation.",
                    lateArrivalPolicy: "Table is held for 15 minutes.",
                    seatingNotes: "Outdoor deck with harbor views.",
                    creditCardHold: "No hold required."
                ),
                menuHighlights: ["Smoked Brisket", "Grilled Swordfish", "S'mores Sundae"],
                photoCount: 10,
                availabilityPattern: .standard
            )
        ]
    }

    // MARK: - Reviews

    static let reviews: [DinerReview] = [
        // restaurant_001 - Le Jardin Moderne
        DinerReview(id: "review_001_01", restaurantID: "restaurant_001", reviewerName: "Elena M.", date: makeDate(daysFromNow: -3, hour: 20), overallRating: 5.0, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 5.0, reviewText: "Every course was a masterpiece. The duck was perfectly aged and the truffle pasta was unforgettable. Will absolutely return.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_001_02", restaurantID: "restaurant_001", reviewerName: "David L.", date: makeDate(daysFromNow: -7, hour: 21), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Outstanding tasting menu. The wine pairings were curated with real thought. Service was attentive without being overbearing.", diningOccasion: "Business dinner"),
        DinerReview(id: "review_001_03", restaurantID: "restaurant_001", reviewerName: "Sophie T.", date: makeDate(daysFromNow: -12, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "The chef's counter experience is worth every penny. You can watch each dish being assembled. Mille-feuille was the highlight.", diningOccasion: "Date night"),
        DinerReview(id: "review_001_04", restaurantID: "restaurant_001", reviewerName: "Marcus W.", date: makeDate(daysFromNow: -18, hour: 20), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.9, reviewText: "One of the best French restaurants in the city. Presentation is stunning and the flavors are bold yet refined.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_001_05", restaurantID: "restaurant_001", reviewerName: "Rachel K.", date: makeDate(daysFromNow: -25, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Lovely ambiance and excellent food. The only slight miss was a longer wait between courses than expected.", diningOccasion: "Dinner with friends"),

        // restaurant_002 - Hudson Grill House
        DinerReview(id: "review_002_01", restaurantID: "restaurant_002", reviewerName: "James P.", date: makeDate(daysFromNow: -2, hour: 21), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "The prime rib was cooked to absolute perfection. Rooftop cocktails at sunset are a must. Great energy throughout.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_002_02", restaurantID: "restaurant_002", reviewerName: "Olivia S.", date: makeDate(daysFromNow: -6, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Really fun atmosphere. The oyster platter was incredibly fresh. Brown butter pie is a sleeper hit on the menu.", diningOccasion: "Date night"),
        DinerReview(id: "review_002_03", restaurantID: "restaurant_002", reviewerName: "Kevin R.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Solid neighborhood brasserie. Wood-fired mains are the standout. Friendly staff made the evening special.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_002_04", restaurantID: "restaurant_002", reviewerName: "Angela C.", date: makeDate(daysFromNow: -20, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Good food and nice rooftop space. It can get loud on weekends but the energy is part of the charm.", diningOccasion: "Birthday celebration"),

        // restaurant_003 - Cedar & Smoke
        DinerReview(id: "review_003_01", restaurantID: "restaurant_003", reviewerName: "Nadia H.", date: makeDate(daysFromNow: -4, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.3, ambianceRating: 4.5, reviewText: "The charred eggplant is smoky perfection. Lamb kofta was juicy and well-seasoned. Warm dining room feels like home.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_003_02", restaurantID: "restaurant_003", reviewerName: "Tom F.", date: makeDate(daysFromNow: -9, hour: 19), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.2, ambianceRating: 4.4, reviewText: "Great value for the quality. The mezze spread was generous and everything tasted authentic. Pistachio baklava was divine.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_003_03", restaurantID: "restaurant_003", reviewerName: "Priya G.", date: makeDate(daysFromNow: -15, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Solid Mediterranean fare in Midtown. The grilled dishes stand out. Bar seating was a nice option for a solo dinner.", diningOccasion: "Solo dining"),
        DinerReview(id: "review_003_04", restaurantID: "restaurant_003", reviewerName: "Chris B.", date: makeDate(daysFromNow: -22, hour: 19), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Satisfying meal overall. The vegetarian options are genuinely good here, not an afterthought. Would come back.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_003_05", restaurantID: "restaurant_003", reviewerName: "Laura V.", date: makeDate(daysFromNow: -28, hour: 18), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Surprised by how much I loved this place. The charcoal grill adds so much flavor. Definitely a hidden gem.", diningOccasion: "Date night"),

        // restaurant_004 - Golden Gate Izakaya
        DinerReview(id: "review_004_01", restaurantID: "restaurant_004", reviewerName: "Alex Y.", date: makeDate(daysFromNow: -2, hour: 22), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Best izakaya in the Mission. The binchotan skewers are exceptional and the sake selection is carefully curated.", diningOccasion: "Date night"),
        DinerReview(id: "review_004_02", restaurantID: "restaurant_004", reviewerName: "Megan D.", date: makeDate(daysFromNow: -8, hour: 21), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Bluefin nigiri melted on my tongue. Yuzu panna cotta was a perfect finish. Counter seating gives you the full experience.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_004_03", restaurantID: "restaurant_004", reviewerName: "Ryan J.", date: makeDate(daysFromNow: -13, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Omakase at the counter is the way to go. Chef's choices were creative and each course built on the last.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_004_04", restaurantID: "restaurant_004", reviewerName: "Hannah L.", date: makeDate(daysFromNow: -19, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Lively atmosphere with great food. The robata items are smoky and delicious. Sake pairing was well matched.", diningOccasion: "Casual dinner"),

        // restaurant_005 - Harborline Seafood
        DinerReview(id: "review_005_01", restaurantID: "restaurant_005", reviewerName: "Caroline A.", date: makeDate(daysFromNow: -5, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.8, reviewText: "The Dungeness crab is reason enough to visit. Bayfront views are stunning at sunset. Cioppino was rich and warming.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_005_02", restaurantID: "restaurant_005", reviewerName: "Brian N.", date: makeDate(daysFromNow: -10, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.7, reviewText: "Shellfish tower was spectacular. The patio dining experience is unmatched in the Marina. Lemon tart was a nice closer.", diningOccasion: "Date night"),
        DinerReview(id: "review_005_03", restaurantID: "restaurant_005", reviewerName: "Diana O.", date: makeDate(daysFromNow: -16, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.6, reviewText: "Beautiful setting and very fresh seafood. Prices are on the higher end but the quality matches. Service was gracious.", diningOccasion: "Business dinner"),
        DinerReview(id: "review_005_04", restaurantID: "restaurant_005", reviewerName: "Steven M.", date: makeDate(daysFromNow: -23, hour: 19), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.5, reviewText: "Great seafood spot but can be difficult to get a patio table. Inside is lovely too. Seasonal tasting menu was creative.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_005_05", restaurantID: "restaurant_005", reviewerName: "Michelle E.", date: makeDate(daysFromNow: -30, hour: 20), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.9, reviewText: "An ideal spot for a special night out. The bay views and impeccable seafood make this a standout in the city.", diningOccasion: "Special occasion"),

        // restaurant_006 - Fiore Trattoria
        DinerReview(id: "review_006_01", restaurantID: "restaurant_006", reviewerName: "Nina P.", date: makeDate(daysFromNow: -3, hour: 21), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "The rigatoni alla vodka is silky and rich. Burrata was perfectly creamy. Feels like a real neighborhood spot.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_006_02", restaurantID: "restaurant_006", reviewerName: "Frank Z.", date: makeDate(daysFromNow: -8, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Handmade pasta is always the right call here. Tiramisu was one of the best I have had. Natural wine list is fun.", diningOccasion: "Date night"),
        DinerReview(id: "review_006_03", restaurantID: "restaurant_006", reviewerName: "Grace H.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Solid trattoria with honest Italian cooking. Portions are generous and the outdoor seating is pleasant on warm evenings.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_006_04", restaurantID: "restaurant_006", reviewerName: "Adam W.", date: makeDate(daysFromNow: -21, hour: 18), overallRating: 4.1, foodRating: 4.2, serviceRating: 4.0, ambianceRating: 4.1, reviewText: "Good comfort Italian food at fair prices. Not the most refined but everything is well executed and satisfying.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_006_05", restaurantID: "restaurant_006", reviewerName: "Julia R.", date: makeDate(daysFromNow: -27, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Love this place for a weeknight dinner. The pasta is always on point and the staff remembers regulars. Great value.", diningOccasion: "Weeknight dinner"),

        // restaurant_tr_tartine - Tartine Manufactory
        DinerReview(id: "review_tr_tartine_01", restaurantID: "restaurant_tr_tartine", reviewerName: "Sarah K.", date: makeDate(daysFromNow: -4, hour: 10), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "The morning bun is legendary for a reason. Flaky, cardamom-scented, and perfectly caramelized. The space itself is gorgeous.", diningOccasion: "Weekend brunch"),
        DinerReview(id: "review_tr_tartine_02", restaurantID: "restaurant_tr_tartine", reviewerName: "James W.", date: makeDate(daysFromNow: -11, hour: 12), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Smoked trout tartine was incredible. Industrial space with great natural light. Line moves faster than you'd expect.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_tartine_03", restaurantID: "restaurant_tr_tartine", reviewerName: "Linda M.", date: makeDate(daysFromNow: -19, hour: 9), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Country bread is the best sourdough in the city. Seasonal galette was a surprise standout. Worth every penny.", diningOccasion: "Solo dining"),

        // restaurant_tr_la_taqueria - La Taqueria
        DinerReview(id: "review_tr_la_taqueria_01", restaurantID: "restaurant_tr_la_taqueria", reviewerName: "Mike R.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "The no-rice super burrito is life-changing. Perfectly grilled carne asada with just the right amount of salsa verde.", diningOccasion: "Quick bite"),
        DinerReview(id: "review_tr_la_taqueria_02", restaurantID: "restaurant_tr_la_taqueria", reviewerName: "Rosa D.", date: makeDate(daysFromNow: -9, hour: 18), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Carnitas plate was juicy and perfectly seasoned. Simple, no-frills, exactly what a taqueria should be.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_la_taqueria_03", restaurantID: "restaurant_tr_la_taqueria", reviewerName: "Derek T.", date: makeDate(daysFromNow: -17, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Best carne asada taco in the Mission, hands down. Cash only so come prepared. Worth every minute of the wait.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_el_farolito - El Farolito
        DinerReview(id: "review_tr_el_farolito_01", restaurantID: "restaurant_tr_el_farolito", reviewerName: "Priya L.", date: makeDate(daysFromNow: -2, hour: 22), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "The super burrito at 2 AM hits different. Massive, messy, and absolutely perfect late-night fuel.", diningOccasion: "Quick bite"),
        DinerReview(id: "review_tr_el_farolito_02", restaurantID: "restaurant_tr_el_farolito", reviewerName: "Carlos G.", date: makeDate(daysFromNow: -10, hour: 21), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Quesadilla suiza is loaded and cheesy. No-frills spot but the food speaks for itself. A Mission staple.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_el_farolito_03", restaurantID: "restaurant_tr_el_farolito", reviewerName: "Natalie F.", date: makeDate(daysFromNow: -22, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Nachos are surprisingly good here. Giant portions for the price. The green salsa is addictive.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_rich_table - Rich Table
        DinerReview(id: "review_tr_rich_table_01", restaurantID: "restaurant_tr_rich_table", reviewerName: "Vanessa H.", date: makeDate(daysFromNow: -5, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "The sardine chips are as iconic as everyone says. Porcini doughnuts were savory perfection. Every dish surprised us.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_rich_table_02", restaurantID: "restaurant_tr_rich_table", reviewerName: "Nathan B.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Dry-aged duck was cooked to a gorgeous medium rare. The creativity here is unmatched in Hayes Valley.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_rich_table_03", restaurantID: "restaurant_tr_rich_table", reviewerName: "Amy C.", date: makeDate(daysFromNow: -24, hour: 21), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Inventive without being gimmicky. Bar seating was a great way to watch the kitchen in action. Highly recommend.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_souvla - Souvla
        DinerReview(id: "review_tr_souvla_01", restaurantID: "restaurant_tr_souvla", reviewerName: "Brian E.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.3, reviewText: "Lamb wrap was juicy and perfectly charred. Frozen yogurt for dessert is a must. Fast, fresh, and consistently great.", diningOccasion: "Quick bite"),
        DinerReview(id: "review_tr_souvla_02", restaurantID: "restaurant_tr_souvla", reviewerName: "Tina P.", date: makeDate(daysFromNow: -12, hour: 18), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Greek salad was crisp and vibrant. Love the simple concept executed really well. Great quick lunch spot in Hayes.", diningOccasion: "Solo dining"),
        DinerReview(id: "review_tr_souvla_03", restaurantID: "restaurant_tr_souvla", reviewerName: "Leo N.", date: makeDate(daysFromNow: -21, hour: 20), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Solid fast-casual Greek. The chicken wrap was tender and well-seasoned. Not cheap for counter service but quality is there.", diningOccasion: "Casual dinner"),

        // restaurant_tr_mama - Mama
        DinerReview(id: "review_tr_mama_01", restaurantID: "restaurant_tr_mama", reviewerName: "Jessica A.", date: makeDate(daysFromNow: -6, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "The rigatoni is pure comfort food. Cozy room, candlelit tables, and the burrata appetizer was silky and fresh.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_mama_02", restaurantID: "restaurant_tr_mama", reviewerName: "Will S.", date: makeDate(daysFromNow: -15, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Tiramisu was the best I've had in San Francisco. Handmade pasta is clearly made with love. Intimate and charming.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_mama_03", restaurantID: "restaurant_tr_mama", reviewerName: "Keiko Y.", date: makeDate(daysFromNow: -23, hour: 21), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Sweet little Marina Italian spot. Pasta portions are generous and the wine list is thoughtful. A neighborhood gem.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_sightglass - Sightglass Coffee
        DinerReview(id: "review_tr_sightglass_01", restaurantID: "restaurant_tr_sightglass", reviewerName: "Hannah Q.", date: makeDate(daysFromNow: -4, hour: 9), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "The single origin pour over was exceptional. Cathedral-like space with tons of natural light. Perfect for working.", diningOccasion: "Solo dining"),
        DinerReview(id: "review_tr_sightglass_02", restaurantID: "restaurant_tr_sightglass", reviewerName: "Omar J.", date: makeDate(daysFromNow: -13, hour: 10), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Affogato here is next level. Espresso is rich and balanced. The industrial SoMa space has real character.", diningOccasion: "Weekend brunch"),
        DinerReview(id: "review_tr_sightglass_03", restaurantID: "restaurant_tr_sightglass", reviewerName: "Emily V.", date: makeDate(daysFromNow: -20, hour: 8), overallRating: 4.1, foodRating: 4.2, serviceRating: 4.0, ambianceRating: 4.1, reviewText: "Great third-wave coffee shop. Cold brew is smooth and not too acidic. Seating fills up fast on weekends though.", diningOccasion: "Quick bite"),

        // restaurant_tr_zy - Z & Y Restaurant
        DinerReview(id: "review_tr_zy_01", restaurantID: "restaurant_tr_zy", reviewerName: "Daniel Z.", date: makeDate(daysFromNow: -5, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.4, reviewText: "Spicy boiled fish had incredible depth of flavor. Bring your spice tolerance because they do not hold back here.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_zy_02", restaurantID: "restaurant_tr_zy", reviewerName: "Michelle O.", date: makeDate(daysFromNow: -14, hour: 20), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Ma po tofu was legit numbing and spicy. Dan dan noodles are a must-order. Best Sichuan in Chinatown.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_zy_03", restaurantID: "restaurant_tr_zy", reviewerName: "Greg P.", date: makeDate(daysFromNow: -26, hour: 18), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Generous portions and authentic flavors. Service is quick and no-nonsense. Great value for the quality.", diningOccasion: "Quick bite"),

        // restaurant_tr_nopalito - Nopalito
        DinerReview(id: "review_tr_nopalito_01", restaurantID: "restaurant_tr_nopalito", reviewerName: "Sofia R.", date: makeDate(daysFromNow: -7, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "The pozole is soul-warming. Everything uses organic ingredients and you can taste the difference. Churros were heavenly.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_nopalito_02", restaurantID: "restaurant_tr_nopalito", reviewerName: "Kevin L.", date: makeDate(daysFromNow: -16, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Tamales were perfectly wrapped and moist inside. This is elevated Mexican food that still feels authentic.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_nopalito_03", restaurantID: "restaurant_tr_nopalito", reviewerName: "Annie W.", date: makeDate(daysFromNow: -25, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Loved the patio seating. Fresh and flavorful Mexican dishes that go beyond the usual. Churros with chocolate were perfect.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_mister_jius - Mister Jiu's
        DinerReview(id: "review_tr_mister_jius_01", restaurantID: "restaurant_tr_mister_jius", reviewerName: "Rachel K.", date: makeDate(daysFromNow: -4, hour: 20), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.8, reviewText: "Sesame balls were crispy and light. Lap cheung fried rice was outrageously good. A modern Chinatown masterpiece.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_mister_jius_02", restaurantID: "restaurant_tr_mister_jius", reviewerName: "Thomas C.", date: makeDate(daysFromNow: -12, hour: 19), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Hot and sour soup had layers of complexity I didn't expect. The tasting menu is worth every dollar. Beautiful space.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_mister_jius_03", restaurantID: "restaurant_tr_mister_jius", reviewerName: "Nina S.", date: makeDate(daysFromNow: -22, hour: 21), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Brandon Jew is doing something really special here. Chinese-American fine dining that honors tradition while pushing forward.", diningOccasion: "Date night"),

        // restaurant_tr_san_tung - San Tung
        DinerReview(id: "review_tr_san_tung_01", restaurantID: "restaurant_tr_san_tung", reviewerName: "Raj P.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Dry-fried chicken wings are absolutely addictive. Sweet, crispy, and perfectly sauced. Worth the line every time.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_san_tung_02", restaurantID: "restaurant_tr_san_tung", reviewerName: "Lisa H.", date: makeDate(daysFromNow: -11, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Dan dan noodles were rich and spicy. Pot stickers had a great crispy bottom. Classic Sunset neighborhood spot.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_san_tung_03", restaurantID: "restaurant_tr_san_tung", reviewerName: "Chris M.", date: makeDate(daysFromNow: -20, hour: 18), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Everyone comes for the wings and rightfully so. Get there early or expect a wait. Solid Chinese comfort food.", diningOccasion: "Quick bite"),

        // restaurant_tr_nari - Nari
        DinerReview(id: "review_tr_nari_01", restaurantID: "restaurant_tr_nari", reviewerName: "Olivia T.", date: makeDate(daysFromNow: -6, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "The khao soi was transcendent. Rich coconut curry with handmade noodles. Elevated Thai at its absolute best.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_nari_02", restaurantID: "restaurant_tr_nari", reviewerName: "Victor G.", date: makeDate(daysFromNow: -15, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Larb was bright and herbaceous. Curry puffs were flaky and warming. Every course on the tasting menu was a revelation.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_nari_03", restaurantID: "restaurant_tr_nari", reviewerName: "Deborah N.", date: makeDate(daysFromNow: -28, hour: 21), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Chef's counter experience was intimate and special. Thai flavors I've never experienced at this level. Truly memorable.", diningOccasion: "Date night"),

        // restaurant_tr_burma_superstar - Burma Superstar
        DinerReview(id: "review_tr_burma_superstar_01", restaurantID: "restaurant_tr_burma_superstar", reviewerName: "Tanya B.", date: makeDate(daysFromNow: -4, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.4, reviewText: "Tea leaf salad is unlike anything else. The flavors are complex and addictive. I understand the cult following now.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_burma_superstar_02", restaurantID: "restaurant_tr_burma_superstar", reviewerName: "Paul W.", date: makeDate(daysFromNow: -13, hour: 20), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Samosa soup is the perfect comfort food. Rainbow salad was colorful and fresh. Waitlist app makes the line bearable.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_burma_superstar_03", restaurantID: "restaurant_tr_burma_superstar", reviewerName: "Mira J.", date: makeDate(daysFromNow: -23, hour: 18), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Burmese food done well with approachable flavors. Great for introducing friends to the cuisine. Generous portions.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_hog_island - Hog Island Oyster Co.
        DinerReview(id: "review_tr_hog_island_01", restaurantID: "restaurant_tr_hog_island", reviewerName: "Steve F.", date: makeDate(daysFromNow: -5, hour: 18), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.6, reviewText: "Sweetwater oysters were briny and perfect. Sitting at the Ferry Building bar watching the bay is an iconic SF experience.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_hog_island_02", restaurantID: "restaurant_tr_hog_island", reviewerName: "Dani L.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Clam chowder is thick, creamy, and loaded with clams. Grilled cheese with a dozen oysters is the perfect lunch.", diningOccasion: "Weekend brunch"),
        DinerReview(id: "review_tr_hog_island_03", restaurantID: "restaurant_tr_hog_island", reviewerName: "Marcus D.", date: makeDate(daysFromNow: -24, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Fresh oysters straight from Tomales Bay. You can taste the ocean. Bar seating fills up fast but the line moves.", diningOccasion: "Casual dinner"),

        // restaurant_tr_flour_water - Flour + Water
        DinerReview(id: "review_tr_flour_water_01", restaurantID: "restaurant_tr_flour_water", reviewerName: "Chloe A.", date: makeDate(daysFromNow: -3, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "The pappardelle was silky and rich. Margherita pizza had that perfect char. Pasta tasting menu at the bar is a must.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_flour_water_02", restaurantID: "restaurant_tr_flour_water", reviewerName: "Ian M.", date: makeDate(daysFromNow: -12, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Seasonal pasta changes kept things exciting. Every noodle is clearly handmade with care. One of the best in the Mission.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_flour_water_03", restaurantID: "restaurant_tr_flour_water", reviewerName: "Paula G.", date: makeDate(daysFromNow: -21, hour: 21), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Hard to get a reservation but worth the effort. The Neapolitan pizza alone justifies the hype. Warm, buzzy atmosphere.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_kin_khao - Kin Khao
        DinerReview(id: "review_tr_kin_khao_01", restaurantID: "restaurant_tr_kin_khao", reviewerName: "Ben Y.", date: makeDate(daysFromNow: -6, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "Khao soi was rich and deeply flavorful. Crispy rice salad had an amazing crunch. Boldest Thai food downtown.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_kin_khao_02", restaurantID: "restaurant_tr_kin_khao", reviewerName: "Andrea V.", date: makeDate(daysFromNow: -16, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Green curry had a beautiful balance of heat and coconut. Not dumbed-down Thai food. Real deal flavors.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_kin_khao_03", restaurantID: "restaurant_tr_kin_khao", reviewerName: "Jason T.", date: makeDate(daysFromNow: -27, hour: 21), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Everything on the menu packs flavor. Spice levels are authentic so order accordingly. Bar seating is great for walk-ins.", diningOccasion: "Solo dining"),

        // restaurant_tr_delfina - Delfina
        DinerReview(id: "review_tr_delfina_01", restaurantID: "restaurant_tr_delfina", reviewerName: "Maria E.", date: makeDate(daysFromNow: -5, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.6, reviewText: "The spaghetti is deceptively simple and absolutely perfect. Buttermilk panna cotta was a dreamy finish. A Mission classic.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_delfina_02", restaurantID: "restaurant_tr_delfina", reviewerName: "David K.", date: makeDate(daysFromNow: -13, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Grilled lamb was tender and herb-crusted beautifully. Heated patio was lovely. This place has been great for 25 years.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_delfina_03", restaurantID: "restaurant_tr_delfina", reviewerName: "Karen Z.", date: makeDate(daysFromNow: -22, hour: 18), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Neighborhood Italian done right. Nothing flashy, just exceptional ingredients and technique. A reliable favorite.", diningOccasion: "Casual dinner"),

        // restaurant_tr_che_fico - Che Fico
        DinerReview(id: "review_tr_che_fico_01", restaurantID: "restaurant_tr_che_fico", reviewerName: "Adriana F.", date: makeDate(daysFromNow: -4, hour: 20), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.8, reviewText: "Focaccia di Recco was mind-blowing. Crispy, cheesy, and unlike anything else in the city. Wood-fired everything is stellar.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_che_fico_02", restaurantID: "restaurant_tr_che_fico", reviewerName: "Jordan R.", date: makeDate(daysFromNow: -11, hour: 21), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Cacio e pepe was creamy and peppery perfection. The Ligurian-influenced menu sets this apart from other Italian spots.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_che_fico_03", restaurantID: "restaurant_tr_che_fico", reviewerName: "Grace L.", date: makeDate(daysFromNow: -19, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Wood-fired lamb was smoky and succulent. Bar seating gave us a front-row view of the kitchen. Worth every cent.", diningOccasion: "Anniversary"),

        // restaurant_tr_lazy_bear - Lazy Bear
        DinerReview(id: "review_tr_lazy_bear_01", restaurantID: "restaurant_tr_lazy_bear", reviewerName: "Alex Y.", date: makeDate(daysFromNow: -7, hour: 20), overallRating: 5.0, foodRating: 5.0, serviceRating: 4.9, ambianceRating: 5.0, reviewText: "A dinner party masquerading as a restaurant. The communal table and multi-course tasting menu are utterly unique in SF.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_lazy_bear_02", restaurantID: "restaurant_tr_lazy_bear", reviewerName: "Ingrid B.", date: makeDate(daysFromNow: -18, hour: 19), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.9, reviewText: "Every course was a conversation starter. The converted warehouse setting adds to the magic. Worth the ticket price.", diningOccasion: "Birthday celebration"),
        DinerReview(id: "review_tr_lazy_bear_03", restaurantID: "restaurant_tr_lazy_bear", reviewerName: "Robert H.", date: makeDate(daysFromNow: -29, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Amuse-bouche series alone was worth the visit. You sit with strangers and leave as friends. Truly one of a kind.", diningOccasion: "Anniversary"),

        // restaurant_tr_zuni_cafe - Zuni Cafe
        DinerReview(id: "review_tr_zuni_cafe_01", restaurantID: "restaurant_tr_zuni_cafe", reviewerName: "Stephanie W.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.6, reviewText: "The roast chicken for two is an SF institution for a reason. Crispy skin, juicy meat, and that bread salad underneath. Perfection.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_zuni_cafe_02", restaurantID: "restaurant_tr_zuni_cafe", reviewerName: "Felix D.", date: makeDate(daysFromNow: -10, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Caesar salad was bright and anchovy-forward. Espresso granita was the ideal light finish. A timeless SF spot.", diningOccasion: "Business dinner"),
        DinerReview(id: "review_tr_zuni_cafe_03", restaurantID: "restaurant_tr_zuni_cafe", reviewerName: "Monica J.", date: makeDate(daysFromNow: -20, hour: 18), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Remember to order the roast chicken an hour ahead. The triangular dining room has great energy. A true classic.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_state_bird - State Bird Provisions
        DinerReview(id: "review_tr_state_bird_01", restaurantID: "restaurant_tr_state_bird", reviewerName: "Peter N.", date: makeDate(daysFromNow: -5, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "The dim sum cart concept is genius. State bird quail was crispy and juicy. Garlic bread with burrata was outrageous.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_state_bird_02", restaurantID: "restaurant_tr_state_bird", reviewerName: "Yuki T.", date: makeDate(daysFromNow: -15, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Seasonal pancake was an unexpected delight. The cart service keeps things fun and surprising. Never a dull moment.", diningOccasion: "Birthday celebration"),
        DinerReview(id: "review_tr_state_bird_03", restaurantID: "restaurant_tr_state_bird", reviewerName: "Diane C.", date: makeDate(daysFromNow: -26, hour: 21), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Every dish that rolled by was more tempting than the last. Creative and playful without sacrificing flavor. A must-visit.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_swan_oyster - Swan Oyster Depot
        DinerReview(id: "review_tr_swan_oyster_01", restaurantID: "restaurant_tr_swan_oyster", reviewerName: "George B.", date: makeDate(daysFromNow: -4, hour: 12), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.8, reviewText: "Crab back was piled high and impossibly fresh. The counter guys are characters. This place is living SF history.", diningOccasion: "Solo dining"),
        DinerReview(id: "review_tr_swan_oyster_02", restaurantID: "restaurant_tr_swan_oyster", reviewerName: "Jenny O.", date: makeDate(daysFromNow: -14, hour: 11), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Oysters on the half shell were pristine. Smoked trout salad is the sleeper hit. Get there before they open or wait an hour.", diningOccasion: "Weekend brunch"),
        DinerReview(id: "review_tr_swan_oyster_03", restaurantID: "restaurant_tr_swan_oyster", reviewerName: "Tim E.", date: makeDate(daysFromNow: -25, hour: 13), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Only 18 stools and worth every minute in line. Cash only. The freshest seafood counter in America, bar none.", diningOccasion: "Special occasion"),

        // restaurant_tr_dumpling_home - Dumpling Home
        DinerReview(id: "review_tr_dumpling_home_01", restaurantID: "restaurant_tr_dumpling_home", reviewerName: "Ashley Q.", date: makeDate(daysFromNow: -6, hour: 19), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.3, reviewText: "Soup dumplings were perfectly wrapped with a flavorful broth inside. Scallion pancake was crispy and flaky.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_dumpling_home_02", restaurantID: "restaurant_tr_dumpling_home", reviewerName: "Ryan J.", date: makeDate(daysFromNow: -17, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Pork buns were fluffy and savory. Small cozy space so expect to wait at peak hours. Worth it for the dumplings.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_dumpling_home_03", restaurantID: "restaurant_tr_dumpling_home", reviewerName: "Crystal W.", date: makeDate(daysFromNow: -27, hour: 18), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Solid dumpling spot in SoMa. Everything is made fresh. Not fancy but the quality is consistently good.", diningOccasion: "Quick bite"),

        // restaurant_tr_marufuku - Marufuku Ramen
        DinerReview(id: "review_tr_marufuku_01", restaurantID: "restaurant_tr_marufuku", reviewerName: "Kyle S.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.4, reviewText: "Hakata tonkotsu broth was rich and silky. Noodles were perfectly al dente. Best ramen I've had outside of Japan.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_marufuku_02", restaurantID: "restaurant_tr_marufuku", reviewerName: "Sandra P.", date: makeDate(daysFromNow: -12, hour: 20), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Chicken paitan was lighter but still packed with umami. Gyoza had a beautiful crispy bottom. Always satisfying.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_marufuku_03", restaurantID: "restaurant_tr_marufuku", reviewerName: "Brandon F.", date: makeDate(daysFromNow: -23, hour: 18), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Long line but moves quickly. The pork belly chashu melts in your mouth. Solid Japantown ramen spot.", diningOccasion: "Solo dining"),

        // restaurant_tr_tonys - Tony's Pizza Napoletana
        DinerReview(id: "review_tr_tonys_01", restaurantID: "restaurant_tr_tonys", reviewerName: "Frank Z.", date: makeDate(daysFromNow: -4, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "Margherita was blistered and perfect. Seven pizza styles means everyone finds something they love. A North Beach gem.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_tonys_02", restaurantID: "restaurant_tr_tonys", reviewerName: "Lauren H.", date: makeDate(daysFromNow: -15, hour: 20), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Quattro formaggi was rich and cheesy. NY style slice was legit. World champion pizza and you can taste why.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_tonys_03", restaurantID: "restaurant_tr_tonys", reviewerName: "Patrick O.", date: makeDate(daysFromNow: -24, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Great pizza in a fun North Beach atmosphere. The Napoletana style is the standout. Come hungry and order multiple styles.", diningOccasion: "Birthday celebration"),

        // restaurant_tr_carbone - Carbone
        DinerReview(id: "review_tr_carbone_01", restaurantID: "restaurant_tr_carbone", reviewerName: "Elena M.", date: makeDate(daysFromNow: -2, hour: 21), overallRating: 5.0, foodRating: 5.0, serviceRating: 4.9, ambianceRating: 5.0, reviewText: "Spicy rigatoni lives up to the insane hype. Veal parm was massive and perfectly breaded. The throwback vibes are electric.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_carbone_02", restaurantID: "restaurant_tr_carbone", reviewerName: "Marcus W.", date: makeDate(daysFromNow: -10, hour: 20), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.9, reviewText: "Italian cheesecake was the smoothest I've ever had. Tableside Caesar was theatrical and delicious. Worth every dollar.", diningOccasion: "Anniversary"),
        DinerReview(id: "review_tr_carbone_03", restaurantID: "restaurant_tr_carbone", reviewerName: "Sophie T.", date: makeDate(daysFromNow: -19, hour: 19), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Red-sauce Italian elevated to fine dining. The suited waiters and retro decor transport you. Reservation is the hard part.", diningOccasion: "Date night"),

        // restaurant_tr_katzs - Katz's Delicatessen
        DinerReview(id: "review_tr_katzs_01", restaurantID: "restaurant_tr_katzs", reviewerName: "Matt R.", date: makeDate(daysFromNow: -3, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "Pastrami on rye is everything they say and more. Hand-carved, peppery, and piled impossibly high. A NYC pilgrimage.", diningOccasion: "Solo dining"),
        DinerReview(id: "review_tr_katzs_02", restaurantID: "restaurant_tr_katzs", reviewerName: "Diana O.", date: makeDate(daysFromNow: -11, hour: 18), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Matzo ball soup was deeply comforting. The ticket system is old-school and charming. Don't lose your ticket.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_katzs_03", restaurantID: "restaurant_tr_katzs", reviewerName: "Nadia H.", date: makeDate(daysFromNow: -22, hour: 20), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Knish was crispy outside and fluffy inside. This place has been doing it right since 1888. Touristy but justified.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_lilia - Lilia
        DinerReview(id: "review_tr_lilia_01", restaurantID: "restaurant_tr_lilia", reviewerName: "Caroline A.", date: makeDate(daysFromNow: -5, hour: 20), overallRating: 4.9, foodRating: 5.0, serviceRating: 4.8, ambianceRating: 4.8, reviewText: "Mafaldini with pink peppercorn and Parm was transcendent. Sheep's milk ricotta was pillowy. Worth crossing the bridge.", diningOccasion: "Special occasion"),
        DinerReview(id: "review_tr_lilia_02", restaurantID: "restaurant_tr_lilia", reviewerName: "Justin H.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.8, reviewText: "Grilled octopus was charred and tender. The converted auto body shop space is stunning. Missy Robbins is a genius.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_lilia_03", restaurantID: "restaurant_tr_lilia", reviewerName: "Beth S.", date: makeDate(daysFromNow: -25, hour: 21), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Every pasta dish was better than the last. Patio in summer is magical. One of the best Italian restaurants in Brooklyn.", diningOccasion: "Anniversary"),

        // restaurant_tr_don_angie - Don Angie
        DinerReview(id: "review_tr_don_angie_01", restaurantID: "restaurant_tr_don_angie", reviewerName: "Rebecca L.", date: makeDate(daysFromNow: -6, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "Pinwheel lasagna is as Instagram-famous as it is delicious. Layers of pasta, meat, and cheese rolled into art.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_don_angie_02", restaurantID: "restaurant_tr_don_angie", reviewerName: "Sean K.", date: makeDate(daysFromNow: -16, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Chrysanthemum salad was light and refreshing. Cherry pepper ribs were sticky and addictive. Creative Italian-American food.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_don_angie_03", restaurantID: "restaurant_tr_don_angie", reviewerName: "Lena Q.", date: makeDate(daysFromNow: -28, hour: 21), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Cozy Village spot with inventive takes on Italian-American classics. Every dish had a playful twist. Reservations are a must.", diningOccasion: "Birthday celebration"),

        // restaurant_tr_via_carota - Via Carota
        DinerReview(id: "review_tr_via_carota_01", restaurantID: "restaurant_tr_via_carota", reviewerName: "Hannah Q.", date: makeDate(daysFromNow: -4, hour: 19), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.6, reviewText: "Carciofi fritti were shatteringly crispy. Insalata verde was the freshest salad I've had in Manhattan. A West Village treasure.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_via_carota_02", restaurantID: "restaurant_tr_via_carota", reviewerName: "Tom F.", date: makeDate(daysFromNow: -13, hour: 20), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Tortelli were delicate and buttery. No reservations so prepare to wait but the walk-in system keeps things fair.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_via_carota_03", restaurantID: "restaurant_tr_via_carota", reviewerName: "Priya G.", date: makeDate(daysFromNow: -23, hour: 18), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Rustic Italian at its finest. The outdoor tables on Grove Street are pure West Village magic. Everything is seasonal.", diningOccasion: "Casual dinner"),

        // restaurant_tr_los_tacos - Los Tacos No. 1
        DinerReview(id: "review_tr_los_tacos_01", restaurantID: "restaurant_tr_los_tacos", reviewerName: "Jake B.", date: makeDate(daysFromNow: -2, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.4, reviewText: "Adobada taco was smoky and perfectly marinated. Best quick tacos in Manhattan. The line moves fast.", diningOccasion: "Quick bite"),
        DinerReview(id: "review_tr_los_tacos_02", restaurantID: "restaurant_tr_los_tacos", reviewerName: "Samantha R.", date: makeDate(daysFromNow: -9, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Carne asada taco was charred and juicy. Nopal taco surprised me with how flavorful it was. Chelsea Market gem.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_los_tacos_03", restaurantID: "restaurant_tr_los_tacos", reviewerName: "Chris B.", date: makeDate(daysFromNow: -18, hour: 20), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Simple, authentic, and affordable. Double corn tortillas, fresh salsa, and perfectly grilled meat. No fuss needed.", diningOccasion: "Solo dining"),

        // restaurant_tr_holbox - Holbox
        DinerReview(id: "review_tr_holbox_01", restaurantID: "restaurant_tr_holbox", reviewerName: "Eva D.", date: makeDate(daysFromNow: -5, hour: 18), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "Ceviche tostada was bursting with citrus and fresh seafood. Baja-style cooking done with real finesse. A mercado treasure.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_holbox_02", restaurantID: "restaurant_tr_holbox", reviewerName: "Marco T.", date: makeDate(daysFromNow: -14, hour: 19), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Octopus taco had a beautiful char and tender bite. Fish zarandeado was smoky perfection. Hidden in Mercado la Paloma.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_holbox_03", restaurantID: "restaurant_tr_holbox", reviewerName: "Amy C.", date: makeDate(daysFromNow: -24, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Fresh seafood at market prices. Communal seating is casual and fun. One of LA's best-kept seafood secrets.", diningOccasion: "Weekend brunch"),

        // restaurant_tr_bestia - Bestia
        DinerReview(id: "review_tr_bestia_01", restaurantID: "restaurant_tr_bestia", reviewerName: "Nicole V.", date: makeDate(daysFromNow: -3, hour: 20), overallRating: 4.8, foodRating: 4.9, serviceRating: 4.7, ambianceRating: 4.7, reviewText: "Fennel sausage pizza had the perfect chewy crust. Bone marrow was rich and decadent. Industrial space with great energy.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_bestia_02", restaurantID: "restaurant_tr_bestia", reviewerName: "Adam W.", date: makeDate(daysFromNow: -12, hour: 21), overallRating: 4.7, foodRating: 4.8, serviceRating: 4.6, ambianceRating: 4.7, reviewText: "Caramelized coppa was melt-in-your-mouth good. The Arts District location is buzzy and fun. LA Italian at its finest.", diningOccasion: "Birthday celebration"),
        DinerReview(id: "review_tr_bestia_03", restaurantID: "restaurant_tr_bestia", reviewerName: "Lily W.", date: makeDate(daysFromNow: -21, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.6, reviewText: "Every dish was bold and unapologetic. The bar program is excellent too. Make reservations well in advance.", diningOccasion: "Dinner with friends"),

        // restaurant_tr_avalon_seafood - Avalon Seafood & Fish Market
        DinerReview(id: "review_tr_avalon_seafood_01", restaurantID: "restaurant_tr_avalon_seafood", reviewerName: "Scott N.", date: makeDate(daysFromNow: -4, hour: 18), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.3, reviewText: "Fish and chips right on the pier with a harbor view. Doesn't get fresher than this. Perfect Catalina lunch.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_avalon_seafood_02", restaurantID: "restaurant_tr_avalon_seafood", reviewerName: "Kelly M.", date: makeDate(daysFromNow: -15, hour: 19), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.3, reviewText: "Poke bowl was vibrant and fresh. Lobster roll was loaded. Casual waterfront dining at its best.", diningOccasion: "Weekend brunch"),
        DinerReview(id: "review_tr_avalon_seafood_03", restaurantID: "restaurant_tr_avalon_seafood", reviewerName: "Dave R.", date: makeDate(daysFromNow: -26, hour: 18), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Simple seafood done right. Nothing fancy but the fish is straight off the boat. Outdoor pier seating is the move.", diningOccasion: "Solo dining"),

        // restaurant_tr_descanso - Descanso Beach Club
        DinerReview(id: "review_tr_descanso_01", restaurantID: "restaurant_tr_descanso", reviewerName: "Heather G.", date: makeDate(daysFromNow: -6, hour: 19), overallRating: 4.6, foodRating: 4.7, serviceRating: 4.5, ambianceRating: 4.5, reviewText: "Grilled mahi-mahi was tender and perfectly seasoned. Eating on the beach with the ocean right there is unforgettable.", diningOccasion: "Date night"),
        DinerReview(id: "review_tr_descanso_02", restaurantID: "restaurant_tr_descanso", reviewerName: "Rick E.", date: makeDate(daysFromNow: -16, hour: 18), overallRating: 4.5, foodRating: 4.6, serviceRating: 4.4, ambianceRating: 4.5, reviewText: "Mediterranean platter was generous and flavorful. Island cocktails were strong and refreshing. Beach cabana was a nice touch.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_descanso_03", restaurantID: "restaurant_tr_descanso", reviewerName: "Angela C.", date: makeDate(daysFromNow: -25, hour: 20), overallRating: 4.4, foodRating: 4.5, serviceRating: 4.3, ambianceRating: 4.4, reviewText: "Key lime pie was tangy and creamy. The beachfront setting makes everything taste better. A Catalina must-visit.", diningOccasion: "Special occasion"),

        // restaurant_tr_harbor_reef - Harbor Reef Restaurant
        DinerReview(id: "review_tr_harbor_reef_01", restaurantID: "restaurant_tr_harbor_reef", reviewerName: "Todd B.", date: makeDate(daysFromNow: -7, hour: 19), overallRating: 4.3, foodRating: 4.4, serviceRating: 4.2, ambianceRating: 4.2, reviewText: "Smoked brisket was tender and smoky. Eating on the deck overlooking the harbor is pure relaxation. Rustic island vibes.", diningOccasion: "Casual dinner"),
        DinerReview(id: "review_tr_harbor_reef_02", restaurantID: "restaurant_tr_harbor_reef", reviewerName: "Lisa H.", date: makeDate(daysFromNow: -18, hour: 18), overallRating: 4.2, foodRating: 4.3, serviceRating: 4.1, ambianceRating: 4.2, reviewText: "Grilled swordfish was fresh and simply prepared. Two Harbors is quiet and this place matches that laid-back energy.", diningOccasion: "Dinner with friends"),
        DinerReview(id: "review_tr_harbor_reef_03", restaurantID: "restaurant_tr_harbor_reef", reviewerName: "Greg P.", date: makeDate(daysFromNow: -29, hour: 19), overallRating: 4.1, foodRating: 4.2, serviceRating: 4.0, ambianceRating: 4.1, reviewText: "S'mores sundae was a fun way to end the meal. Not gourmet but honest island cooking with gorgeous harbor views.", diningOccasion: "Weekend brunch")
    ]

    // MARK: - Popular Dishes

    static let popularDishes: [PopularDish] = [
        // restaurant_001
        PopularDish(id: "dish_001_01", restaurantID: "restaurant_001", name: "Dry-aged duck", mentionCount: 187),
        PopularDish(id: "dish_001_02", restaurantID: "restaurant_001", name: "Black truffle tagliolini", mentionCount: 162),
        PopularDish(id: "dish_001_03", restaurantID: "restaurant_001", name: "Mille-feuille", mentionCount: 134),
        PopularDish(id: "dish_001_04", restaurantID: "restaurant_001", name: "Foie gras terrine", mentionCount: 98),

        // restaurant_002
        PopularDish(id: "dish_002_01", restaurantID: "restaurant_002", name: "Prime rib", mentionCount: 214),
        PopularDish(id: "dish_002_02", restaurantID: "restaurant_002", name: "Oyster platter", mentionCount: 178),
        PopularDish(id: "dish_002_03", restaurantID: "restaurant_002", name: "Brown butter pie", mentionCount: 145),
        PopularDish(id: "dish_002_04", restaurantID: "restaurant_002", name: "Rooftop burger", mentionCount: 112),

        // restaurant_003
        PopularDish(id: "dish_003_01", restaurantID: "restaurant_003", name: "Lamb kofta", mentionCount: 156),
        PopularDish(id: "dish_003_02", restaurantID: "restaurant_003", name: "Charred eggplant", mentionCount: 143),
        PopularDish(id: "dish_003_03", restaurantID: "restaurant_003", name: "Pistachio baklava", mentionCount: 121),
        PopularDish(id: "dish_003_04", restaurantID: "restaurant_003", name: "Mezze platter", mentionCount: 109),
        PopularDish(id: "dish_003_05", restaurantID: "restaurant_003", name: "Hummus trio", mentionCount: 87),

        // restaurant_004
        PopularDish(id: "dish_004_01", restaurantID: "restaurant_004", name: "Binchotan skewers", mentionCount: 198),
        PopularDish(id: "dish_004_02", restaurantID: "restaurant_004", name: "Bluefin nigiri", mentionCount: 176),
        PopularDish(id: "dish_004_03", restaurantID: "restaurant_004", name: "Yuzu panna cotta", mentionCount: 134),
        PopularDish(id: "dish_004_04", restaurantID: "restaurant_004", name: "Sake flight", mentionCount: 112),

        // restaurant_005
        PopularDish(id: "dish_005_01", restaurantID: "restaurant_005", name: "Dungeness crab", mentionCount: 223),
        PopularDish(id: "dish_005_02", restaurantID: "restaurant_005", name: "Cioppino", mentionCount: 189),
        PopularDish(id: "dish_005_03", restaurantID: "restaurant_005", name: "Shellfish tower", mentionCount: 167),
        PopularDish(id: "dish_005_04", restaurantID: "restaurant_005", name: "Lemon tart", mentionCount: 98),

        // restaurant_006
        PopularDish(id: "dish_006_01", restaurantID: "restaurant_006", name: "Rigatoni alla vodka", mentionCount: 201),
        PopularDish(id: "dish_006_02", restaurantID: "restaurant_006", name: "Burrata", mentionCount: 178),
        PopularDish(id: "dish_006_03", restaurantID: "restaurant_006", name: "Tiramisu", mentionCount: 156),
        PopularDish(id: "dish_006_04", restaurantID: "restaurant_006", name: "Pappardelle bolognese", mentionCount: 112),

        // restaurant_007
        PopularDish(id: "dish_007_01", restaurantID: "restaurant_007", name: "Citrus halibut", mentionCount: 189),
        PopularDish(id: "dish_007_02", restaurantID: "restaurant_007", name: "Charred carrots", mentionCount: 145),
        PopularDish(id: "dish_007_03", restaurantID: "restaurant_007", name: "Olive oil cake", mentionCount: 132),

        // restaurant_008
        PopularDish(id: "dish_008_01", restaurantID: "restaurant_008", name: "Hokkaido uni", mentionCount: 234),
        PopularDish(id: "dish_008_02", restaurantID: "restaurant_008", name: "A5 wagyu", mentionCount: 212),
        PopularDish(id: "dish_008_03", restaurantID: "restaurant_008", name: "Matcha custard", mentionCount: 156),
        PopularDish(id: "dish_008_04", restaurantID: "restaurant_008", name: "Toro hand roll", mentionCount: 145),

        // restaurant_009
        PopularDish(id: "dish_009_01", restaurantID: "restaurant_009", name: "Birria tacos", mentionCount: 198),
        PopularDish(id: "dish_009_02", restaurantID: "restaurant_009", name: "Ceviche tostada", mentionCount: 156),
        PopularDish(id: "dish_009_03", restaurantID: "restaurant_009", name: "Churros", mentionCount: 134),

        // restaurant_010
        PopularDish(id: "dish_010_01", restaurantID: "restaurant_010", name: "Prime strip", mentionCount: 210),
        PopularDish(id: "dish_010_02", restaurantID: "restaurant_010", name: "Lobster risotto", mentionCount: 178),
        PopularDish(id: "dish_010_03", restaurantID: "restaurant_010", name: "Butter cake", mentionCount: 143),

        // restaurant_011
        PopularDish(id: "dish_011_01", restaurantID: "restaurant_011", name: "Smoked trout", mentionCount: 167),
        PopularDish(id: "dish_011_02", restaurantID: "restaurant_011", name: "Venison loin", mentionCount: 145),
        PopularDish(id: "dish_011_03", restaurantID: "restaurant_011", name: "Pear sorbet", mentionCount: 112),

        // restaurant_012
        PopularDish(id: "dish_012_01", restaurantID: "restaurant_012", name: "Steak frites", mentionCount: 189),
        PopularDish(id: "dish_012_02", restaurantID: "restaurant_012", name: "Onion tart", mentionCount: 134),
        PopularDish(id: "dish_012_03", restaurantID: "restaurant_012", name: "Chocolate pot de creme", mentionCount: 121),

        // restaurant_013
        PopularDish(id: "dish_013_01", restaurantID: "restaurant_013", name: "Bone-in ribeye", mentionCount: 245),
        PopularDish(id: "dish_013_02", restaurantID: "restaurant_013", name: "Lobster mac", mentionCount: 189),
        PopularDish(id: "dish_013_03", restaurantID: "restaurant_013", name: "Key lime pie", mentionCount: 134),

        // restaurant_014
        PopularDish(id: "dish_014_01", restaurantID: "restaurant_014", name: "Cacio e pepe", mentionCount: 201),
        PopularDish(id: "dish_014_02", restaurantID: "restaurant_014", name: "Branzino", mentionCount: 167),
        PopularDish(id: "dish_014_03", restaurantID: "restaurant_014", name: "Cannoli", mentionCount: 143),

        // restaurant_015
        PopularDish(id: "dish_015_01", restaurantID: "restaurant_015", name: "Oyster sampler", mentionCount: 198),
        PopularDish(id: "dish_015_02", restaurantID: "restaurant_015", name: "Butter-poached cod", mentionCount: 156),
        PopularDish(id: "dish_015_03", restaurantID: "restaurant_015", name: "Blueberry tart", mentionCount: 112),

        // restaurant_016
        PopularDish(id: "dish_016_01", restaurantID: "restaurant_016", name: "Chicken yakitori", mentionCount: 178),
        PopularDish(id: "dish_016_02", restaurantID: "restaurant_016", name: "Miso cod", mentionCount: 156),
        PopularDish(id: "dish_016_03", restaurantID: "restaurant_016", name: "Sesame mochi", mentionCount: 98),

        // restaurant_017
        PopularDish(id: "dish_017_01", restaurantID: "restaurant_017", name: "Cedar plank salmon", mentionCount: 223),
        PopularDish(id: "dish_017_02", restaurantID: "restaurant_017", name: "Foraged mushroom toast", mentionCount: 189),
        PopularDish(id: "dish_017_03", restaurantID: "restaurant_017", name: "Hazelnut tart", mentionCount: 145),

        // restaurant_018
        PopularDish(id: "dish_018_01", restaurantID: "restaurant_018", name: "Patatas bravas", mentionCount: 201),
        PopularDish(id: "dish_018_02", restaurantID: "restaurant_018", name: "Garlic prawns", mentionCount: 167),
        PopularDish(id: "dish_018_03", restaurantID: "restaurant_018", name: "Basque cheesecake", mentionCount: 145),

        // restaurant_019
        PopularDish(id: "dish_019_01", restaurantID: "restaurant_019", name: "Otoro flight", mentionCount: 234),
        PopularDish(id: "dish_019_02", restaurantID: "restaurant_019", name: "Uni hand roll", mentionCount: 198),
        PopularDish(id: "dish_019_03", restaurantID: "restaurant_019", name: "Miso black cod", mentionCount: 167),

        // restaurant_020
        PopularDish(id: "dish_020_01", restaurantID: "restaurant_020", name: "Saffron tagliatelle", mentionCount: 189),
        PopularDish(id: "dish_020_02", restaurantID: "restaurant_020", name: "Burrata crostini", mentionCount: 156),
        PopularDish(id: "dish_020_03", restaurantID: "restaurant_020", name: "Olive oil gelato", mentionCount: 134),

        // restaurant_021
        PopularDish(id: "dish_021_01", restaurantID: "restaurant_021", name: "King salmon crudo", mentionCount: 198),
        PopularDish(id: "dish_021_02", restaurantID: "restaurant_021", name: "Charred octopus", mentionCount: 167),
        PopularDish(id: "dish_021_03", restaurantID: "restaurant_021", name: "Meyer lemon tart", mentionCount: 121),

        // restaurant_022
        PopularDish(id: "dish_022_01", restaurantID: "restaurant_022", name: "Coal-roasted carrots", mentionCount: 178),
        PopularDish(id: "dish_022_02", restaurantID: "restaurant_022", name: "Dry-aged duck", mentionCount: 156),
        PopularDish(id: "dish_022_03", restaurantID: "restaurant_022", name: "Mandarin semifreddo", mentionCount: 112),

        // restaurant_023
        PopularDish(id: "dish_023_01", restaurantID: "restaurant_023", name: "Charred broccoli Caesar", mentionCount: 167),
        PopularDish(id: "dish_023_02", restaurantID: "restaurant_023", name: "Short rib agnolotti", mentionCount: 145),
        PopularDish(id: "dish_023_03", restaurantID: "restaurant_023", name: "Toffee pudding", mentionCount: 121),

        // restaurant_024
        PopularDish(id: "dish_024_01", restaurantID: "restaurant_024", name: "Toro tasting", mentionCount: 223),
        PopularDish(id: "dish_024_02", restaurantID: "restaurant_024", name: "Scallop hand roll", mentionCount: 189),
        PopularDish(id: "dish_024_03", restaurantID: "restaurant_024", name: "Miso caramel flan", mentionCount: 134),

        // restaurant_025
        PopularDish(id: "dish_025_01", restaurantID: "restaurant_025", name: "East coast oyster flight", mentionCount: 210),
        PopularDish(id: "dish_025_02", restaurantID: "restaurant_025", name: "Lobster roll", mentionCount: 189),
        PopularDish(id: "dish_025_03", restaurantID: "restaurant_025", name: "Key lime tart", mentionCount: 112),

        // restaurant_026
        PopularDish(id: "dish_026_01", restaurantID: "restaurant_026", name: "Dry-aged porterhouse", mentionCount: 234),
        PopularDish(id: "dish_026_02", restaurantID: "restaurant_026", name: "Black garlic potatoes", mentionCount: 167),
        PopularDish(id: "dish_026_03", restaurantID: "restaurant_026", name: "Chocolate torte", mentionCount: 134),

        // restaurant_027
        PopularDish(id: "dish_027_01", restaurantID: "restaurant_027", name: "Duck confit", mentionCount: 198),
        PopularDish(id: "dish_027_02", restaurantID: "restaurant_027", name: "Lobster vol-au-vent", mentionCount: 167),
        PopularDish(id: "dish_027_03", restaurantID: "restaurant_027", name: "Paris-brest", mentionCount: 134),

        // restaurant_028
        PopularDish(id: "dish_028_01", restaurantID: "restaurant_028", name: "King salmon nigiri", mentionCount: 189),
        PopularDish(id: "dish_028_02", restaurantID: "restaurant_028", name: "Robata mushrooms", mentionCount: 145),
        PopularDish(id: "dish_028_03", restaurantID: "restaurant_028", name: "Yuzu cheesecake", mentionCount: 112),

        // restaurant_029
        PopularDish(id: "dish_029_01", restaurantID: "restaurant_029", name: "Prime ribeye", mentionCount: 245),
        PopularDish(id: "dish_029_02", restaurantID: "restaurant_029", name: "King crab gratin", mentionCount: 189),
        PopularDish(id: "dish_029_03", restaurantID: "restaurant_029", name: "Warm pecan tart", mentionCount: 134),

        // restaurant_030
        PopularDish(id: "dish_030_01", restaurantID: "restaurant_030", name: "Dan dan noodles", mentionCount: 198),
        PopularDish(id: "dish_030_02", restaurantID: "restaurant_030", name: "Crispy tofu", mentionCount: 156),
        PopularDish(id: "dish_030_03", restaurantID: "restaurant_030", name: "Black sesame mousse", mentionCount: 112),

        // restaurant_031
        PopularDish(id: "dish_031_01", restaurantID: "restaurant_031", name: "Grilled swordfish", mentionCount: 215),
        PopularDish(id: "dish_031_02", restaurantID: "restaurant_031", name: "Lobster tacos", mentionCount: 178),
        PopularDish(id: "dish_031_03", restaurantID: "restaurant_031", name: "Coconut key lime pie", mentionCount: 124),

        // restaurant_032
        PopularDish(id: "dish_032_01", restaurantID: "restaurant_032", name: "Baja fish tacos", mentionCount: 201),
        PopularDish(id: "dish_032_02", restaurantID: "restaurant_032", name: "Mango ceviche", mentionCount: 167),
        PopularDish(id: "dish_032_03", restaurantID: "restaurant_032", name: "Churro sundae", mentionCount: 109),

        // restaurant_033
        PopularDish(id: "dish_033_01", restaurantID: "restaurant_033", name: "Smoked brisket plate", mentionCount: 187),
        PopularDish(id: "dish_033_02", restaurantID: "restaurant_033", name: "Grilled mahi-mahi", mentionCount: 156),
        PopularDish(id: "dish_033_03", restaurantID: "restaurant_033", name: "S'mores brownie", mentionCount: 98),

        // ── TasteRank restaurants ──
        // restaurant_tr_tartine
        PopularDish(id: "dish_tr_tartine_01", restaurantID: "restaurant_tr_tartine", name: "Morning Bun", mentionCount: 198),
        PopularDish(id: "dish_tr_tartine_02", restaurantID: "restaurant_tr_tartine", name: "Country Bread", mentionCount: 172),
        PopularDish(id: "dish_tr_tartine_03", restaurantID: "restaurant_tr_tartine", name: "Smoked Trout Tartine", mentionCount: 145),

        // restaurant_tr_la_taqueria
        PopularDish(id: "dish_tr_la_taqueria_01", restaurantID: "restaurant_tr_la_taqueria", name: "Super Burrito", mentionCount: 245),
        PopularDish(id: "dish_tr_la_taqueria_02", restaurantID: "restaurant_tr_la_taqueria", name: "Carne Asada Taco", mentionCount: 189),
        PopularDish(id: "dish_tr_la_taqueria_03", restaurantID: "restaurant_tr_la_taqueria", name: "Carnitas Plate", mentionCount: 134),

        // restaurant_tr_el_farolito
        PopularDish(id: "dish_tr_el_farolito_01", restaurantID: "restaurant_tr_el_farolito", name: "Super Burrito", mentionCount: 210),
        PopularDish(id: "dish_tr_el_farolito_02", restaurantID: "restaurant_tr_el_farolito", name: "Quesadilla Suiza", mentionCount: 156),
        PopularDish(id: "dish_tr_el_farolito_03", restaurantID: "restaurant_tr_el_farolito", name: "Nachos", mentionCount: 112),

        // restaurant_tr_rich_table
        PopularDish(id: "dish_tr_rich_table_01", restaurantID: "restaurant_tr_rich_table", name: "Sardine Chips", mentionCount: 234),
        PopularDish(id: "dish_tr_rich_table_02", restaurantID: "restaurant_tr_rich_table", name: "Porcini Doughnuts", mentionCount: 198),
        PopularDish(id: "dish_tr_rich_table_03", restaurantID: "restaurant_tr_rich_table", name: "Dry-Aged Duck", mentionCount: 167),

        // restaurant_tr_souvla
        PopularDish(id: "dish_tr_souvla_01", restaurantID: "restaurant_tr_souvla", name: "Lamb Wrap", mentionCount: 178),
        PopularDish(id: "dish_tr_souvla_02", restaurantID: "restaurant_tr_souvla", name: "Frozen Yogurt", mentionCount: 145),
        PopularDish(id: "dish_tr_souvla_03", restaurantID: "restaurant_tr_souvla", name: "Greek Salad", mentionCount: 112),

        // restaurant_tr_mama
        PopularDish(id: "dish_tr_mama_01", restaurantID: "restaurant_tr_mama", name: "Rigatoni", mentionCount: 189),
        PopularDish(id: "dish_tr_mama_02", restaurantID: "restaurant_tr_mama", name: "Burrata", mentionCount: 167),
        PopularDish(id: "dish_tr_mama_03", restaurantID: "restaurant_tr_mama", name: "Tiramisu", mentionCount: 134),

        // restaurant_tr_sightglass
        PopularDish(id: "dish_tr_sightglass_01", restaurantID: "restaurant_tr_sightglass", name: "Single Origin Pour Over", mentionCount: 156),
        PopularDish(id: "dish_tr_sightglass_02", restaurantID: "restaurant_tr_sightglass", name: "Affogato", mentionCount: 123),
        PopularDish(id: "dish_tr_sightglass_03", restaurantID: "restaurant_tr_sightglass", name: "Cold Brew", mentionCount: 98),

        // restaurant_tr_zy
        PopularDish(id: "dish_tr_zy_01", restaurantID: "restaurant_tr_zy", name: "Spicy Boiled Fish", mentionCount: 201),
        PopularDish(id: "dish_tr_zy_02", restaurantID: "restaurant_tr_zy", name: "Ma Po Tofu", mentionCount: 178),
        PopularDish(id: "dish_tr_zy_03", restaurantID: "restaurant_tr_zy", name: "Dan Dan Noodles", mentionCount: 145),

        // restaurant_tr_nopalito
        PopularDish(id: "dish_tr_nopalito_01", restaurantID: "restaurant_tr_nopalito", name: "Pozole", mentionCount: 189),
        PopularDish(id: "dish_tr_nopalito_02", restaurantID: "restaurant_tr_nopalito", name: "Tamales", mentionCount: 156),
        PopularDish(id: "dish_tr_nopalito_03", restaurantID: "restaurant_tr_nopalito", name: "Churros", mentionCount: 123),

        // restaurant_tr_mister_jius
        PopularDish(id: "dish_tr_mister_jius_01", restaurantID: "restaurant_tr_mister_jius", name: "Sesame Balls", mentionCount: 212),
        PopularDish(id: "dish_tr_mister_jius_02", restaurantID: "restaurant_tr_mister_jius", name: "Hot & Sour Soup", mentionCount: 178),
        PopularDish(id: "dish_tr_mister_jius_03", restaurantID: "restaurant_tr_mister_jius", name: "Lap Cheung Fried Rice", mentionCount: 156),

        // restaurant_tr_san_tung
        PopularDish(id: "dish_tr_san_tung_01", restaurantID: "restaurant_tr_san_tung", name: "Dry-Fried Chicken Wings", mentionCount: 267),
        PopularDish(id: "dish_tr_san_tung_02", restaurantID: "restaurant_tr_san_tung", name: "Dan Dan Noodles", mentionCount: 178),
        PopularDish(id: "dish_tr_san_tung_03", restaurantID: "restaurant_tr_san_tung", name: "Pot Stickers", mentionCount: 134),

        // restaurant_tr_nari
        PopularDish(id: "dish_tr_nari_01", restaurantID: "restaurant_tr_nari", name: "Khao Soi", mentionCount: 198),
        PopularDish(id: "dish_tr_nari_02", restaurantID: "restaurant_tr_nari", name: "Larb", mentionCount: 167),
        PopularDish(id: "dish_tr_nari_03", restaurantID: "restaurant_tr_nari", name: "Curry Puffs", mentionCount: 123),

        // restaurant_tr_burma_superstar
        PopularDish(id: "dish_tr_burma_superstar_01", restaurantID: "restaurant_tr_burma_superstar", name: "Tea Leaf Salad", mentionCount: 278),
        PopularDish(id: "dish_tr_burma_superstar_02", restaurantID: "restaurant_tr_burma_superstar", name: "Samosa Soup", mentionCount: 189),
        PopularDish(id: "dish_tr_burma_superstar_03", restaurantID: "restaurant_tr_burma_superstar", name: "Rainbow Salad", mentionCount: 145),

        // restaurant_tr_hog_island
        PopularDish(id: "dish_tr_hog_island_01", restaurantID: "restaurant_tr_hog_island", name: "Sweetwater Oysters", mentionCount: 234),
        PopularDish(id: "dish_tr_hog_island_02", restaurantID: "restaurant_tr_hog_island", name: "Clam Chowder", mentionCount: 189),
        PopularDish(id: "dish_tr_hog_island_03", restaurantID: "restaurant_tr_hog_island", name: "Grilled Cheese", mentionCount: 145),

        // restaurant_tr_flour_water
        PopularDish(id: "dish_tr_flour_water_01", restaurantID: "restaurant_tr_flour_water", name: "Margherita Pizza", mentionCount: 223),
        PopularDish(id: "dish_tr_flour_water_02", restaurantID: "restaurant_tr_flour_water", name: "Pappardelle", mentionCount: 198),
        PopularDish(id: "dish_tr_flour_water_03", restaurantID: "restaurant_tr_flour_water", name: "Seasonal Pasta", mentionCount: 156),

        // restaurant_tr_kin_khao
        PopularDish(id: "dish_tr_kin_khao_01", restaurantID: "restaurant_tr_kin_khao", name: "Khao Soi", mentionCount: 189),
        PopularDish(id: "dish_tr_kin_khao_02", restaurantID: "restaurant_tr_kin_khao", name: "Crispy Rice Salad", mentionCount: 156),
        PopularDish(id: "dish_tr_kin_khao_03", restaurantID: "restaurant_tr_kin_khao", name: "Green Curry", mentionCount: 134),

        // restaurant_tr_delfina
        PopularDish(id: "dish_tr_delfina_01", restaurantID: "restaurant_tr_delfina", name: "Spaghetti", mentionCount: 201),
        PopularDish(id: "dish_tr_delfina_02", restaurantID: "restaurant_tr_delfina", name: "Buttermilk Panna Cotta", mentionCount: 167),
        PopularDish(id: "dish_tr_delfina_03", restaurantID: "restaurant_tr_delfina", name: "Grilled Lamb", mentionCount: 145),

        // restaurant_tr_che_fico
        PopularDish(id: "dish_tr_che_fico_01", restaurantID: "restaurant_tr_che_fico", name: "Focaccia di Recco", mentionCount: 234),
        PopularDish(id: "dish_tr_che_fico_02", restaurantID: "restaurant_tr_che_fico", name: "Cacio e Pepe", mentionCount: 198),
        PopularDish(id: "dish_tr_che_fico_03", restaurantID: "restaurant_tr_che_fico", name: "Wood-Fired Lamb", mentionCount: 156),

        // restaurant_tr_lazy_bear
        PopularDish(id: "dish_tr_lazy_bear_01", restaurantID: "restaurant_tr_lazy_bear", name: "Seasonal Tasting Menu", mentionCount: 245),
        PopularDish(id: "dish_tr_lazy_bear_02", restaurantID: "restaurant_tr_lazy_bear", name: "Amuse-Bouche Series", mentionCount: 198),
        PopularDish(id: "dish_tr_lazy_bear_03", restaurantID: "restaurant_tr_lazy_bear", name: "House Sourdough", mentionCount: 156),

        // restaurant_tr_zuni_cafe
        PopularDish(id: "dish_tr_zuni_cafe_01", restaurantID: "restaurant_tr_zuni_cafe", name: "Roast Chicken", mentionCount: 289),
        PopularDish(id: "dish_tr_zuni_cafe_02", restaurantID: "restaurant_tr_zuni_cafe", name: "Caesar Salad", mentionCount: 198),
        PopularDish(id: "dish_tr_zuni_cafe_03", restaurantID: "restaurant_tr_zuni_cafe", name: "Espresso Granita", mentionCount: 134),

        // restaurant_tr_state_bird
        PopularDish(id: "dish_tr_state_bird_01", restaurantID: "restaurant_tr_state_bird", name: "State Bird (Quail)", mentionCount: 256),
        PopularDish(id: "dish_tr_state_bird_02", restaurantID: "restaurant_tr_state_bird", name: "Garlic Bread", mentionCount: 198),
        PopularDish(id: "dish_tr_state_bird_03", restaurantID: "restaurant_tr_state_bird", name: "Seasonal Pancake", mentionCount: 145),

        // restaurant_tr_swan_oyster
        PopularDish(id: "dish_tr_swan_oyster_01", restaurantID: "restaurant_tr_swan_oyster", name: "Crab Back", mentionCount: 234),
        PopularDish(id: "dish_tr_swan_oyster_02", restaurantID: "restaurant_tr_swan_oyster", name: "Oysters", mentionCount: 212),
        PopularDish(id: "dish_tr_swan_oyster_03", restaurantID: "restaurant_tr_swan_oyster", name: "Smoked Trout Salad", mentionCount: 167),

        // restaurant_tr_dumpling_home
        PopularDish(id: "dish_tr_dumpling_home_01", restaurantID: "restaurant_tr_dumpling_home", name: "Soup Dumplings", mentionCount: 198),
        PopularDish(id: "dish_tr_dumpling_home_02", restaurantID: "restaurant_tr_dumpling_home", name: "Pork Buns", mentionCount: 156),
        PopularDish(id: "dish_tr_dumpling_home_03", restaurantID: "restaurant_tr_dumpling_home", name: "Scallion Pancake", mentionCount: 123),

        // restaurant_tr_marufuku
        PopularDish(id: "dish_tr_marufuku_01", restaurantID: "restaurant_tr_marufuku", name: "Hakata Tonkotsu Ramen", mentionCount: 223),
        PopularDish(id: "dish_tr_marufuku_02", restaurantID: "restaurant_tr_marufuku", name: "Chicken Paitan", mentionCount: 178),
        PopularDish(id: "dish_tr_marufuku_03", restaurantID: "restaurant_tr_marufuku", name: "Gyoza", mentionCount: 134),

        // restaurant_tr_tonys
        PopularDish(id: "dish_tr_tonys_01", restaurantID: "restaurant_tr_tonys", name: "Margherita", mentionCount: 245),
        PopularDish(id: "dish_tr_tonys_02", restaurantID: "restaurant_tr_tonys", name: "Quattro Formaggi", mentionCount: 189),
        PopularDish(id: "dish_tr_tonys_03", restaurantID: "restaurant_tr_tonys", name: "NY Style Slice", mentionCount: 156),

        // restaurant_tr_carbone
        PopularDish(id: "dish_tr_carbone_01", restaurantID: "restaurant_tr_carbone", name: "Spicy Rigatoni", mentionCount: 312),
        PopularDish(id: "dish_tr_carbone_02", restaurantID: "restaurant_tr_carbone", name: "Veal Parm", mentionCount: 256),
        PopularDish(id: "dish_tr_carbone_03", restaurantID: "restaurant_tr_carbone", name: "Italian Cheesecake", mentionCount: 189),

        // restaurant_tr_katzs
        PopularDish(id: "dish_tr_katzs_01", restaurantID: "restaurant_tr_katzs", name: "Pastrami on Rye", mentionCount: 345),
        PopularDish(id: "dish_tr_katzs_02", restaurantID: "restaurant_tr_katzs", name: "Matzo Ball Soup", mentionCount: 198),
        PopularDish(id: "dish_tr_katzs_03", restaurantID: "restaurant_tr_katzs", name: "Knish", mentionCount: 134),

        // restaurant_tr_lilia
        PopularDish(id: "dish_tr_lilia_01", restaurantID: "restaurant_tr_lilia", name: "Mafaldini", mentionCount: 267),
        PopularDish(id: "dish_tr_lilia_02", restaurantID: "restaurant_tr_lilia", name: "Sheep's Milk Ricotta", mentionCount: 198),
        PopularDish(id: "dish_tr_lilia_03", restaurantID: "restaurant_tr_lilia", name: "Grilled Octopus", mentionCount: 167),

        // restaurant_tr_don_angie
        PopularDish(id: "dish_tr_don_angie_01", restaurantID: "restaurant_tr_don_angie", name: "Pinwheel Lasagna", mentionCount: 289),
        PopularDish(id: "dish_tr_don_angie_02", restaurantID: "restaurant_tr_don_angie", name: "Chrysanthemum Salad", mentionCount: 178),
        PopularDish(id: "dish_tr_don_angie_03", restaurantID: "restaurant_tr_don_angie", name: "Cherry Pepper Ribs", mentionCount: 145),

        // restaurant_tr_via_carota
        PopularDish(id: "dish_tr_via_carota_01", restaurantID: "restaurant_tr_via_carota", name: "Carciofi Fritti", mentionCount: 234),
        PopularDish(id: "dish_tr_via_carota_02", restaurantID: "restaurant_tr_via_carota", name: "Insalata Verde", mentionCount: 198),
        PopularDish(id: "dish_tr_via_carota_03", restaurantID: "restaurant_tr_via_carota", name: "Tortelli", mentionCount: 156),

        // restaurant_tr_los_tacos
        PopularDish(id: "dish_tr_los_tacos_01", restaurantID: "restaurant_tr_los_tacos", name: "Adobada Taco", mentionCount: 212),
        PopularDish(id: "dish_tr_los_tacos_02", restaurantID: "restaurant_tr_los_tacos", name: "Carne Asada Taco", mentionCount: 189),
        PopularDish(id: "dish_tr_los_tacos_03", restaurantID: "restaurant_tr_los_tacos", name: "Nopal Taco", mentionCount: 134),

        // restaurant_tr_holbox
        PopularDish(id: "dish_tr_holbox_01", restaurantID: "restaurant_tr_holbox", name: "Ceviche Tostada", mentionCount: 198),
        PopularDish(id: "dish_tr_holbox_02", restaurantID: "restaurant_tr_holbox", name: "Octopus Taco", mentionCount: 167),
        PopularDish(id: "dish_tr_holbox_03", restaurantID: "restaurant_tr_holbox", name: "Fish Zarandeado", mentionCount: 134),

        // restaurant_tr_bestia
        PopularDish(id: "dish_tr_bestia_01", restaurantID: "restaurant_tr_bestia", name: "Fennel Sausage Pizza", mentionCount: 223),
        PopularDish(id: "dish_tr_bestia_02", restaurantID: "restaurant_tr_bestia", name: "Bone Marrow", mentionCount: 189),
        PopularDish(id: "dish_tr_bestia_03", restaurantID: "restaurant_tr_bestia", name: "Caramelized Coppa", mentionCount: 156),

        // restaurant_tr_avalon_seafood
        PopularDish(id: "dish_tr_avalon_seafood_01", restaurantID: "restaurant_tr_avalon_seafood", name: "Fish & Chips", mentionCount: 167),
        PopularDish(id: "dish_tr_avalon_seafood_02", restaurantID: "restaurant_tr_avalon_seafood", name: "Poke Bowl", mentionCount: 145),
        PopularDish(id: "dish_tr_avalon_seafood_03", restaurantID: "restaurant_tr_avalon_seafood", name: "Lobster Roll", mentionCount: 123),

        // restaurant_tr_descanso
        PopularDish(id: "dish_tr_descanso_01", restaurantID: "restaurant_tr_descanso", name: "Grilled Mahi-Mahi", mentionCount: 178),
        PopularDish(id: "dish_tr_descanso_02", restaurantID: "restaurant_tr_descanso", name: "Mediterranean Platter", mentionCount: 156),
        PopularDish(id: "dish_tr_descanso_03", restaurantID: "restaurant_tr_descanso", name: "Key Lime Pie", mentionCount: 123),

        // restaurant_tr_harbor_reef
        PopularDish(id: "dish_tr_harbor_reef_01", restaurantID: "restaurant_tr_harbor_reef", name: "Smoked Brisket", mentionCount: 156),
        PopularDish(id: "dish_tr_harbor_reef_02", restaurantID: "restaurant_tr_harbor_reef", name: "Grilled Swordfish", mentionCount: 134),
        PopularDish(id: "dish_tr_harbor_reef_03", restaurantID: "restaurant_tr_harbor_reef", name: "S'mores Sundae", mentionCount: 98)
    ]

    static func photoSeeds(for restaurant: Restaurant) -> [RestaurantPhotoSeed] {
        photoSeeds(for: restaurant.id, photoCount: restaurant.photoCount)
    }

    static func photoSeeds(for restaurantID: String, photoCount: Int) -> [RestaurantPhotoSeed] {
        let seed = numericID(for: restaurantID)
        let targetCount = max(6, min(max(photoCount, 6), 24))
        var items: [RestaurantPhotoSeed] = []
        items.reserveCapacity(targetCount)

        for index in 0..<targetCount {
            let scene = photoSceneTemplates[(seed + index) % photoSceneTemplates.count]
            let palette = photoPaletteTemplates[(seed * 3 + index) % photoPaletteTemplates.count]
            items.append(
                RestaurantPhotoSeed(
                    id: "photo_\(restaurantID)_\(index + 1)",
                    assetName: photoAssetCatalogNames[(seed + index) % photoAssetCatalogNames.count],
                    title: scene.title,
                    subtitle: scene.subtitle,
                    paletteHex: palette
                )
            )
        }

        return items
    }

    static func seededAvailability(for restaurants: [Restaurant]) -> [RestaurantAvailability] {
        restaurants.map { restaurant in
            let index = numericID(for: restaurant.id)
            let slots: [ReservationSlot]

            switch restaurant.availabilityPattern {
            case .standard:
                slots = standardSlots(restaurantID: restaurant.id, restaurantIndex: index)
            case .sparse:
                slots = sparseSlots(restaurantID: restaurant.id, restaurantIndex: index)
            case .waitlistOnly:
                slots = []
            }

            return RestaurantAvailability(
                restaurantID: restaurant.id,
                sourceType: .seeded,
                lastUpdated: Date(),
                supportsWaitlist: restaurant.supportsWaitlist,
                availableSlots: slots.sorted(by: { $0.date < $1.date })
            )
        }
    }

    static func seededReservations() -> [Reservation] {
        [
            Reservation(
                id: "reservation_seed_001",
                reservationCode: "RSV2001",
                restaurantID: "restaurant_001",
                date: makeDate(daysFromNow: 2, hour: 19, minute: 0),
                partySize: 2,
                status: .upcoming,
                diningPreference: "Indoor table",
                sourceType: .seeded,
                policySummary: "Cancel up to 24 hours before reservation time.",
                notes: "Anniversary dinner",
                createdAt: makeDate(daysFromNow: -5, hour: 10),
                updatedAt: makeDate(daysFromNow: -5, hour: 10)
            ),
            Reservation(
                id: "reservation_seed_002",
                reservationCode: "RSV2002",
                restaurantID: "restaurant_014",
                date: makeDate(daysFromNow: 5, hour: 18, minute: 30),
                partySize: 4,
                status: .upcoming,
                diningPreference: "Patio if available",
                sourceType: .seeded,
                policySummary: "Cancel up to 6 hours before reservation.",
                notes: "Client dinner",
                createdAt: makeDate(daysFromNow: -3, hour: 11),
                updatedAt: makeDate(daysFromNow: -3, hour: 11)
            ),
            Reservation(
                id: "reservation_seed_003",
                reservationCode: "RSV2004",
                restaurantID: "restaurant_010",
                date: makeDate(daysFromNow: 1, hour: 20, minute: 15),
                partySize: 3,
                status: .upcoming,
                diningPreference: "Booth preferred",
                sourceType: .seeded,
                policySummary: "Cancel up to 12 hours before reservation.",
                notes: "Pre-theater dinner",
                createdAt: makeDate(daysFromNow: -4, hour: 12),
                updatedAt: makeDate(daysFromNow: -4, hour: 12)
            ),
            Reservation(
                id: "reservation_seed_004",
                reservationCode: "RSV2005",
                restaurantID: "restaurant_016",
                date: makeDate(daysFromNow: 7, hour: 19, minute: 45),
                partySize: 2,
                status: .upcoming,
                diningPreference: "Counter seating",
                sourceType: .seeded,
                policySummary: "Cancel up to 6 hours before reservation.",
                notes: "",
                createdAt: makeDate(daysFromNow: -2, hour: 9),
                updatedAt: makeDate(daysFromNow: -2, hour: 9)
            ),
            Reservation(
                id: "reservation_seed_005",
                reservationCode: "RSV1801",
                restaurantID: "restaurant_004",
                date: makeDate(daysFromNow: -8, hour: 20, minute: 0),
                partySize: 2,
                status: .past,
                diningPreference: "Counter seating",
                sourceType: .seeded,
                policySummary: "Cancel up to 12 hours before reservation time.",
                notes: "",
                createdAt: makeDate(daysFromNow: -15, hour: 9),
                updatedAt: makeDate(daysFromNow: -8, hour: 22)
            ),
            Reservation(
                id: "reservation_seed_006",
                reservationCode: "RSV1702",
                restaurantID: "restaurant_010",
                date: makeDate(daysFromNow: -20, hour: 18, minute: 30),
                partySize: 3,
                status: .past,
                diningPreference: "Window table",
                sourceType: .seeded,
                policySummary: "Cancel up to 12 hours before reservation.",
                notes: "",
                createdAt: makeDate(daysFromNow: -30, hour: 12),
                updatedAt: makeDate(daysFromNow: -20, hour: 20)
            ),
            Reservation(
                id: "reservation_seed_007",
                reservationCode: "RSV1698",
                restaurantID: "restaurant_013",
                date: makeDate(daysFromNow: -11, hour: 19, minute: 0),
                partySize: 4,
                status: .past,
                diningPreference: "Quiet table",
                sourceType: .seeded,
                policySummary: "Cancel up to 24 hours before reservation.",
                notes: "Team celebration",
                createdAt: makeDate(daysFromNow: -18, hour: 10),
                updatedAt: makeDate(daysFromNow: -11, hour: 22)
            ),
            Reservation(
                id: "reservation_seed_008",
                reservationCode: "RSV1694",
                restaurantID: "restaurant_006",
                date: makeDate(daysFromNow: -27, hour: 18, minute: 45),
                partySize: 2,
                status: .past,
                diningPreference: "Patio if available",
                sourceType: .seeded,
                policySummary: "Cancel up to 6 hours before reservation.",
                notes: "",
                createdAt: makeDate(daysFromNow: -34, hour: 15),
                updatedAt: makeDate(daysFromNow: -27, hour: 20)
            ),
            Reservation(
                id: "reservation_seed_009",
                reservationCode: "RSV2003",
                restaurantID: "restaurant_007",
                date: makeDate(daysFromNow: 3, hour: 19, minute: 30),
                partySize: 2,
                status: .canceled,
                diningPreference: "Outdoor",
                sourceType: .seeded,
                policySummary: "Cancel up to 12 hours before reservation.",
                notes: "Canceled due to schedule conflict",
                createdAt: makeDate(daysFromNow: -2, hour: 14),
                updatedAt: makeDate(daysFromNow: -1, hour: 15)
            ),
            Reservation(
                id: "reservation_seed_010",
                reservationCode: "RSV2006",
                restaurantID: "restaurant_011",
                date: makeDate(daysFromNow: 6, hour: 20, minute: 0),
                partySize: 2,
                status: .canceled,
                diningPreference: "Chef's counter",
                sourceType: .seeded,
                policySummary: "Cancel up to 24 hours before reservation.",
                notes: "Guest canceled travel plans",
                createdAt: makeDate(daysFromNow: -1, hour: 9),
                updatedAt: makeDate(daysFromNow: 0, hour: 8)
            )
        ]
    }

    static func seededSavedRestaurants() -> [SavedRestaurant] {
        [
            SavedRestaurant(restaurantID: "restaurant_001", savedAt: makeDate(daysFromNow: -7, hour: 10)),
            SavedRestaurant(restaurantID: "restaurant_006", savedAt: makeDate(daysFromNow: -6, hour: 9)),
            SavedRestaurant(restaurantID: "restaurant_010", savedAt: makeDate(daysFromNow: -4, hour: 11)),
            SavedRestaurant(restaurantID: "restaurant_015", savedAt: makeDate(daysFromNow: -1, hour: 8)),
            SavedRestaurant(restaurantID: "restaurant_004", savedAt: makeDate(daysFromNow: -2, hour: 13)),
            SavedRestaurant(restaurantID: "restaurant_017", savedAt: makeDate(daysFromNow: -5, hour: 17)),
            SavedRestaurant(restaurantID: "restaurant_021", savedAt: makeDate(daysFromNow: -3, hour: 14)),
            SavedRestaurant(restaurantID: "restaurant_024", savedAt: makeDate(daysFromNow: -2, hour: 20)),
            SavedRestaurant(restaurantID: "restaurant_029", savedAt: makeDate(daysFromNow: -1, hour: 18))
        ]
    }

    static func seededAlerts() -> [DiningAlert] {
        [
            DiningAlert(
                id: "alert_001",
                title: "Policy update",
                message: "Le Jardin Moderne now requires a credit card hold for Friday prime-time reservations.",
                restaurantID: "restaurant_001",
                date: makeDate(daysFromNow: -1, hour: 9),
                isRead: false
            ),
            DiningAlert(
                id: "alert_002",
                title: "Waitlist opportunity",
                message: "A likely opening window is available tonight at Ballard Hearth between 8:00 PM and 9:00 PM.",
                restaurantID: "restaurant_017",
                date: makeDate(daysFromNow: 0, hour: 12),
                isRead: false
            ),
            DiningAlert(
                id: "alert_003",
                title: "Dining reminder",
                message: "Arrive at least 10 minutes early for your Golden Gate Izakaya reservation.",
                restaurantID: "restaurant_004",
                date: makeDate(daysFromNow: -2, hour: 17),
                isRead: true
            ),
            DiningAlert(
                id: "alert_004",
                title: "Table opened up",
                message: "A 7:30 PM table for 2 is now available at Nori Counter LA.",
                restaurantID: "restaurant_008",
                date: makeDate(daysFromNow: 0, hour: 14),
                isRead: false
            ),
            DiningAlert(
                id: "alert_005",
                title: "Reservation updated",
                message: "Your Lakefront Room reservation was moved to 8:15 PM.",
                restaurantID: "restaurant_010",
                date: makeDate(daysFromNow: -1, hour: 16),
                isRead: true
            ),
            DiningAlert(
                id: "alert_006",
                title: "Loyalty points posted",
                message: "You earned 240 points from your recent North End Osteria visit.",
                restaurantID: "restaurant_014",
                date: makeDate(daysFromNow: -3, hour: 13),
                isRead: false
            ),
            DiningAlert(
                id: "alert_007",
                title: "Service note",
                message: "Pacifica Terrace patio seating is currently weather-limited this evening.",
                restaurantID: "restaurant_007",
                date: makeDate(daysFromNow: 0, hour: 10),
                isRead: false
            ),
            DiningAlert(
                id: "alert_008",
                title: "Chef's counter release",
                message: "Additional chef's counter seats opened at Greenwich Omakase Loft.",
                restaurantID: "restaurant_019",
                date: makeDate(daysFromNow: 0, hour: 11),
                isRead: false
            ),
            DiningAlert(
                id: "alert_009",
                title: "Neighborhood favorite",
                message: "Mercer Pasta Lab added late-night reservations through 11:00 PM this weekend.",
                restaurantID: "restaurant_020",
                date: makeDate(daysFromNow: -1, hour: 19),
                isRead: true
            )
        ]
    }

    static func seededProfile(defaultCityID: String) -> UserProfile {
        UserProfile(
            id: "profile_001",
            fullName: "Jordan Avery",
            homeCityID: defaultCityID,
            email: "jordan.avery@email.com",
            notificationEnabled: true,
            promoNotificationsEnabled: false,
            dietaryPreference: "No shellfish",
            seatingPreference: "Window or patio",
            loyaltyTier: "Gold",
            savedCities: ["city_new_york", "city_san_francisco", "city_boston"],
            diningPreferences: [
                DiningPreference(id: "pref_occasion", title: "Occasion", value: "Business dinner"),
                DiningPreference(id: "pref_noise", title: "Noise level", value: "Moderate"),
                DiningPreference(id: "pref_pacing", title: "Course pacing", value: "Relaxed")
            ]
        )
    }

    static func seededRecentSearches() -> [String] {
        [
            "SoHo french",
            "outdoor seafood boston",
            "chef's counter los angeles",
            "quiet table chicago",
            "late night tapas seattle",
            "west hollywood omakase",
            "mission izakaya",
            "back bay steakhouse"
        ]
    }

    static func seededConfirmationSequence() -> Int {
        2006
    }

    static func seededWaitlistSequence() -> Int {
        303
    }

    static func defaultWaitlistEntries() -> [WaitlistEntry] {
        [
            WaitlistEntry(
                id: "WL301",
                restaurantID: "restaurant_017",
                requestType: .waitlist,
                date: makeDate(daysFromNow: 0, hour: 20),
                partySize: 2,
                preferredWindow: "8:00 PM - 9:30 PM",
                createdAt: makeDate(daysFromNow: -1, hour: 18, minute: 20),
                status: "Active"
            ),
            WaitlistEntry(
                id: "WL302",
                restaurantID: "restaurant_008",
                requestType: .notify,
                date: makeDate(daysFromNow: 2, hour: 19),
                partySize: 2,
                preferredWindow: "7:00 PM - 8:30 PM",
                createdAt: makeDate(daysFromNow: -1, hour: 11, minute: 10),
                status: "Active"
            ),
            WaitlistEntry(
                id: "WL303",
                restaurantID: "restaurant_013",
                requestType: .waitlist,
                date: makeDate(daysFromNow: 4, hour: 20),
                partySize: 4,
                preferredWindow: "7:30 PM - 9:30 PM",
                createdAt: makeDate(daysFromNow: -2, hour: 16, minute: 45),
                status: "Active"
            )
        ]
    }

    private static let photoSceneTemplates: [(title: String, subtitle: String)] = [
        ("Main Dining Room", "Warm lighting and full service"),
        ("Chef's Counter", "Front-row seats to the kitchen"),
        ("Patio Seating", "Open-air tables and city views"),
        ("Bar Lounge", "Cocktail-forward bar seating"),
        ("Private Nook", "Semi-private corner table"),
        ("Window Table", "Natural light and skyline backdrop"),
        ("Signature Dish", "Seasonal plating highlight"),
        ("Wine Cellar Room", "Intimate cellar-side dining"),
        ("Entrance Gallery", "Host stand and reception"),
        ("Open Kitchen", "Live-fire and pass action"),
        ("Tasting Menu Course", "Chef-curated progression"),
        ("Late-Night Scene", "Evening ambiance and crowd")
    ]

    private static let photoPaletteTemplates: [[String]] = [
        ["#6A503E", "#223B52", "#0E192A"],
        ["#355E4F", "#1A3048", "#0A1323"],
        ["#8C4E34", "#2D1D2A", "#130E18"],
        ["#4A3D2B", "#5A2F23", "#1B1C26"],
        ["#3F5D73", "#304A2D", "#101A29"],
        ["#7A6142", "#2E3C45", "#121826"],
        ["#6A2D2D", "#2A2E44", "#0C1220"],
        ["#4B6A3C", "#273D4D", "#101A27"],
        ["#6F4033", "#4F2B38", "#121621"],
        ["#5B6E4E", "#314760", "#131C2B"],
        ["#4F3B5E", "#293758", "#0D1524"],
        ["#3B5B68", "#20514A", "#0C1728"]
    ]

    private static let photoAssetCatalogNames: [String] = [
        "ds_photo_01",
        "ds_photo_02",
        "ds_photo_03",
        "ds_photo_04",
        "ds_photo_05",
        "ds_photo_06",
        "ds_photo_07",
        "ds_photo_08",
        "ds_photo_09",
        "ds_photo_10",
        "ds_photo_11",
        "ds_photo_12",
        "ds_photo_13",
        "ds_photo_14",
        "ds_photo_15",
        "ds_photo_16",
        "ds_photo_17",
        "ds_photo_18",
        "ds_photo_19",
        "ds_photo_20",
        "ds_photo_21",
        "ds_photo_22",
        "ds_photo_23",
        "ds_photo_24",
        "ds_photo_25",
        "ds_photo_26",
        "ds_photo_27",
        "ds_photo_28",
        "ds_photo_29",
        "ds_photo_30",
        "ds_photo_31",
        "ds_photo_32",
        "ds_photo_33",
        "ds_photo_34",
        "ds_photo_35"
    ]

    struct GeoPoint: Hashable {
        let latitude: Double
        let longitude: Double
    }

    static func coordinate(for restaurant: Restaurant) -> GeoPoint {
        restaurantCoordinates[restaurant.id] ?? cityCoordinate(for: restaurant.cityID)
    }

    static func cityCoordinate(for cityID: String) -> GeoPoint {
        cityCoordinates[cityID] ?? GeoPoint(latitude: 37.7749, longitude: -122.4194)
    }

    private static let cityCoordinates: [String: GeoPoint] = [
        "city_new_york": GeoPoint(latitude: 40.7411, longitude: -73.9897),
        "city_san_francisco": GeoPoint(latitude: 37.7749, longitude: -122.4194),
        "city_los_angeles": GeoPoint(latitude: 34.0522, longitude: -118.2437),
        "city_chicago": GeoPoint(latitude: 41.8781, longitude: -87.6298),
        "city_boston": GeoPoint(latitude: 42.3601, longitude: -71.0589),
        "city_seattle": GeoPoint(latitude: 47.6062, longitude: -122.3321),
        "city_catalina": GeoPoint(latitude: 33.3428, longitude: -118.3287)
    ]

    private static let restaurantCoordinates: [String: GeoPoint] = [
        "restaurant_001": GeoPoint(latitude: 40.7243, longitude: -74.0020),
        "restaurant_002": GeoPoint(latitude: 40.7267, longitude: -74.0094),
        "restaurant_003": GeoPoint(latitude: 40.7580, longitude: -73.9819),
        "restaurant_004": GeoPoint(latitude: 37.7686, longitude: -122.4220),
        "restaurant_005": GeoPoint(latitude: 37.8030, longitude: -122.4364),
        "restaurant_006": GeoPoint(latitude: 37.7895, longitude: -122.3959),
        "restaurant_007": GeoPoint(latitude: 34.0139, longitude: -118.4952),
        "restaurant_008": GeoPoint(latitude: 34.0918, longitude: -118.3906),
        "restaurant_009": GeoPoint(latitude: 34.0767, longitude: -118.2596),
        "restaurant_010": GeoPoint(latitude: 41.8866, longitude: -87.6263),
        "restaurant_011": GeoPoint(latitude: 41.8865, longitude: -87.6515),
        "restaurant_012": GeoPoint(latitude: 41.9097, longitude: -87.6776),
        "restaurant_013": GeoPoint(latitude: 42.3503, longitude: -71.0802),
        "restaurant_014": GeoPoint(latitude: 42.3653, longitude: -71.0553),
        "restaurant_015": GeoPoint(latitude: 42.3510, longitude: -71.0460),
        "restaurant_016": GeoPoint(latitude: 47.6144, longitude: -122.3123),
        "restaurant_017": GeoPoint(latitude: 47.6688, longitude: -122.3848),
        "restaurant_018": GeoPoint(latitude: 47.6136, longitude: -122.3476),
        "restaurant_019": GeoPoint(latitude: 40.7353, longitude: -74.0031),
        "restaurant_020": GeoPoint(latitude: 40.7234, longitude: -73.9982),
        "restaurant_021": GeoPoint(latitude: 37.7955, longitude: -122.3937),
        "restaurant_022": GeoPoint(latitude: 37.8010, longitude: -122.4357),
        "restaurant_023": GeoPoint(latitude: 34.0862, longitude: -118.2720),
        "restaurant_024": GeoPoint(latitude: 34.0829, longitude: -118.3749),
        "restaurant_025": GeoPoint(latitude: 41.8869, longitude: -87.6398),
        "restaurant_026": GeoPoint(latitude: 41.8865, longitude: -87.6512),
        "restaurant_027": GeoPoint(latitude: 42.3501, longitude: -71.0789),
        "restaurant_028": GeoPoint(latitude: 42.3499, longitude: -71.0446),
        "restaurant_029": GeoPoint(latitude: 47.6109, longitude: -122.3429),
        "restaurant_030": GeoPoint(latitude: 47.6333, longitude: -122.3138),
        "restaurant_031": GeoPoint(latitude: 33.3428, longitude: -118.3259),
        "restaurant_032": GeoPoint(latitude: 33.3441, longitude: -118.3274),
        "restaurant_033": GeoPoint(latitude: 33.4421, longitude: -118.5070),

        // TasteRank restaurants — San Francisco
        "restaurant_tr_tartine": GeoPoint(latitude: 37.7614, longitude: -122.4120),
        "restaurant_tr_la_taqueria": GeoPoint(latitude: 37.7517, longitude: -122.4181),
        "restaurant_tr_el_farolito": GeoPoint(latitude: 37.7527, longitude: -122.4183),
        "restaurant_tr_rich_table": GeoPoint(latitude: 37.7762, longitude: -122.4213),
        "restaurant_tr_souvla": GeoPoint(latitude: 37.7764, longitude: -122.4245),
        "restaurant_tr_mama": GeoPoint(latitude: 37.8003, longitude: -122.4095),
        "restaurant_tr_sightglass": GeoPoint(latitude: 37.7775, longitude: -122.4078),
        "restaurant_tr_zy": GeoPoint(latitude: 37.7964, longitude: -122.4073),
        "restaurant_tr_nopalito": GeoPoint(latitude: 37.7764, longitude: -122.4387),
        "restaurant_tr_mister_jius": GeoPoint(latitude: 37.7948, longitude: -122.4072),
        "restaurant_tr_san_tung": GeoPoint(latitude: 37.7636, longitude: -122.4685),
        "restaurant_tr_nari": GeoPoint(latitude: 37.7853, longitude: -122.4318),
        "restaurant_tr_burma_superstar": GeoPoint(latitude: 37.7828, longitude: -122.4636),
        "restaurant_tr_hog_island": GeoPoint(latitude: 37.7956, longitude: -122.3933),
        "restaurant_tr_flour_water": GeoPoint(latitude: 37.7589, longitude: -122.4128),
        "restaurant_tr_kin_khao": GeoPoint(latitude: 37.7858, longitude: -122.4084),
        "restaurant_tr_delfina": GeoPoint(latitude: 37.7616, longitude: -122.4242),
        "restaurant_tr_che_fico": GeoPoint(latitude: 37.7761, longitude: -122.4388),
        "restaurant_tr_lazy_bear": GeoPoint(latitude: 37.7598, longitude: -122.4200),
        "restaurant_tr_zuni_cafe": GeoPoint(latitude: 37.7759, longitude: -122.4213),
        "restaurant_tr_state_bird": GeoPoint(latitude: 37.7837, longitude: -122.4333),
        "restaurant_tr_swan_oyster": GeoPoint(latitude: 37.7911, longitude: -122.4204),
        "restaurant_tr_dumpling_home": GeoPoint(latitude: 37.7789, longitude: -122.4069),
        "restaurant_tr_marufuku": GeoPoint(latitude: 37.7852, longitude: -122.4310),
        "restaurant_tr_tonys": GeoPoint(latitude: 37.8004, longitude: -122.4093),

        // TasteRank restaurants — New York
        "restaurant_tr_carbone": GeoPoint(latitude: 40.7271, longitude: -74.0003),
        "restaurant_tr_katzs": GeoPoint(latitude: 40.7223, longitude: -73.9874),
        "restaurant_tr_lilia": GeoPoint(latitude: 40.7146, longitude: -73.9511),
        "restaurant_tr_don_angie": GeoPoint(latitude: 40.7375, longitude: -74.0008),
        "restaurant_tr_via_carota": GeoPoint(latitude: 40.7336, longitude: -74.0027),
        "restaurant_tr_los_tacos": GeoPoint(latitude: 40.7425, longitude: -74.0060),

        // TasteRank restaurants — Los Angeles
        "restaurant_tr_holbox": GeoPoint(latitude: 34.0178, longitude: -118.2780),
        "restaurant_tr_bestia": GeoPoint(latitude: 34.0373, longitude: -118.2335),

        // TasteRank restaurants — Catalina Island
        "restaurant_tr_avalon_seafood": GeoPoint(latitude: 33.3440, longitude: -118.3267),
        "restaurant_tr_descanso": GeoPoint(latitude: 33.3468, longitude: -118.3318),
        "restaurant_tr_harbor_reef": GeoPoint(latitude: 33.4426, longitude: -118.5075)
    ]

    // MARK: - Slot generation

    private static func standardSlots(restaurantID: String, restaurantIndex: Int) -> [ReservationSlot] {
        var slots: [ReservationSlot] = []
        let brunchHours = [10, 11, 12, 13]
        let dinnerHours = [17, 18, 19, 20, 21]
        let extendedHours = [16, 17, 18, 19, 20, 21, 22]
        let partySizes = [2, 4, 6, 8]
        let horizonDays = 14

        for dayOffset in 0..<horizonDays {
            // Weekend days (offset 0 = today; check if it's a weekend)
            let slotDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: Calendar.current.startOfDay(for: Date())) ?? Date()
            let weekday = Calendar.current.component(.weekday, from: slotDate)
            let isWeekend = (weekday == 1 || weekday == 7)  // Sunday=1, Saturday=7
            let hours: [Int]
            if isWeekend {
                hours = brunchHours + dinnerHours  // brunch + dinner on weekends
            } else if (restaurantIndex + dayOffset) % 5 == 0 {
                hours = extendedHours
            } else {
                hours = dinnerHours
            }
            for hour in hours {
                for partySize in partySizes {
                    let densityGate = (restaurantIndex * 7 + dayOffset * 5 + hour * 3 + partySize) % 10
                    guard densityGate >= 2 else { continue }

                    let minute = ((restaurantIndex + dayOffset + partySize) % 2 == 0) ? 0 : 30
                    let date = makeDate(daysFromNow: dayOffset, hour: hour, minute: minute)
                    guard date > Date().addingTimeInterval(-1800) else { continue }

                    let id = "seed_\(restaurantID)_\(timestampToken(date))_p\(partySize)"
                    slots.append(
                        ReservationSlot(
                            id: id,
                            restaurantID: restaurantID,
                            date: date,
                            partySize: partySize,
                            sourceType: .seeded,
                            isBookable: true
                        )
                    )
                }
            }
        }

        return slots
    }

    private static func sparseSlots(restaurantID: String, restaurantIndex: Int) -> [ReservationSlot] {
        var slots: [ReservationSlot] = []
        let slotPlans: [(Int, Int, Int)] = [
            (1, 18, 2),
            (2, 20, 2),
            (4, 19, 4),
            (6, 21, 2),
            (9, 20, 2),
            (12, 19, 4)
        ]

        for (dayOffset, hour, partySize) in slotPlans {
            let minute = ((restaurantIndex + hour) % 2 == 0) ? 0 : 30
            let date = makeDate(daysFromNow: dayOffset, hour: hour, minute: minute)
            let id = "seed_\(restaurantID)_\(timestampToken(date))_p\(partySize)"
            slots.append(
                ReservationSlot(
                    id: id,
                    restaurantID: restaurantID,
                    date: date,
                    partySize: partySize,
                    sourceType: .seeded,
                    isBookable: true
                )
            )
        }

        return slots
    }

    private static func numericID(for restaurantID: String) -> Int {
        // Prefer a trailing numeric segment (e.g. "restaurant_014" -> 14) so that
        // legacy call sites keep their existing photo/palette assignments.
        if let tail = restaurantID.split(separator: "_").last, let numeric = Int(tail) {
            return numeric
        }
        // Map known alphabetic IDs to reserved photo slots (31..35) so that each
        // city-specific SF restaurant gets a unique hero photo instead of all
        // collapsing to seed 0 (which previously made every SF entry share the
        // same ds_photo_01 hero image and palette).
        if let reserved = reservedNumericIDs[restaurantID] {
            return reserved
        }
        // Fall back to a stable non-zero hash derived from the full ID.
        var hash = 5381
        for scalar in restaurantID.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ Int(scalar.value)
        }
        let bucket = abs(hash) % 9_973
        return 31 + bucket
    }

    /// Reserved seed IDs for restaurants whose `id` has no numeric suffix. These
    /// are chosen to match dedicated photo assets ds_photo_31..ds_photo_35 via
    /// `numericID % photoAssetCatalogNames.count`.
    private static let reservedNumericIDs: [String: Int] = [
        "restaurant_sf_mission_block": 31,
        "restaurant_sf_marina_oyster": 32,
        "restaurant_sf_hayes_bistro": 33,
        "restaurant_sf_soma_rooftop": 34,
        "restaurant_sf_embarcadero_grill": 35,

        // SF tr_ restaurants: 25 restaurants → 25 available indices
        // (avoids {0,4,5,6,21,22,31,32,33,34} used by existing SF restaurants)
        "restaurant_tr_tartine": 1,
        "restaurant_tr_la_taqueria": 2,
        "restaurant_tr_el_farolito": 3,
        "restaurant_tr_rich_table": 7,
        "restaurant_tr_souvla": 8,
        "restaurant_tr_mama": 9,
        "restaurant_tr_sightglass": 10,
        "restaurant_tr_zy": 11,
        "restaurant_tr_nopalito": 12,
        "restaurant_tr_mister_jius": 13,
        "restaurant_tr_san_tung": 14,
        "restaurant_tr_nari": 15,
        "restaurant_tr_burma_superstar": 16,
        "restaurant_tr_hog_island": 17,
        "restaurant_tr_flour_water": 18,
        "restaurant_tr_kin_khao": 19,
        "restaurant_tr_delfina": 20,
        "restaurant_tr_che_fico": 23,
        "restaurant_tr_lazy_bear": 24,
        "restaurant_tr_zuni_cafe": 25,
        "restaurant_tr_state_bird": 26,
        "restaurant_tr_swan_oyster": 27,
        "restaurant_tr_dumpling_home": 28,
        "restaurant_tr_marufuku": 29,
        "restaurant_tr_tonys": 30,

        // NY tr_ restaurants: 6 restaurants
        // (avoids {1,2,3,19,20} used by existing NY restaurants)
        "restaurant_tr_carbone": 4,
        "restaurant_tr_katzs": 5,
        "restaurant_tr_lilia": 6,
        "restaurant_tr_don_angie": 7,
        "restaurant_tr_via_carota": 8,
        "restaurant_tr_los_tacos": 9,

        // LA tr_ restaurants: 2 restaurants
        // (avoids {7,8,9,23,24} used by existing LA restaurants)
        "restaurant_tr_holbox": 0,
        "restaurant_tr_bestia": 1,

        // Catalina tr_ restaurants: 3 restaurants
        // (avoids {31,32,33} used by existing Catalina restaurants)
        "restaurant_tr_avalon_seafood": 0,
        "restaurant_tr_descanso": 1,
        "restaurant_tr_harbor_reef": 2
    ]

    private static func timestampToken(_ date: Date) -> String {
        DateFormatters.timestampID.string(from: date)
    }

    static func makeDate(daysFromNow: Int, hour: Int, minute: Int = 0) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: Date())
        let dayDate = calendar.date(byAdding: .day, value: daysFromNow, to: start) ?? Date()
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: dayDate) ?? dayDate
    }
}
