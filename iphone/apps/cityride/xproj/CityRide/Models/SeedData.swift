import Foundation

struct SeedData {
    static let seedReferenceDate = Date()

    private struct SeedRouteTemplate {
        let id: String
        let pickupId: String
        let destinationId: String
        let baseETA: Int
        let basePrice: Double
        let routeLabel: String
    }

    static let rideTypes: [RideTypeDefinition] = [
        RideTypeDefinition(
            id: "standard",
            name: "CityRideX",
            category: .standard,
            seats: 4,
            serviceLabel: "Affordable everyday rides",
            priceMultiplier: 1.0,
            etaAdjustment: 0
        ),
        RideTypeDefinition(
            id: "comfort",
            name: "Comfort",
            category: .comfort,
            seats: 4,
            serviceLabel: "Newer cars with extra legroom",
            priceMultiplier: 1.28,
            etaAdjustment: 2
        ),
        RideTypeDefinition(
            id: "xl",
            name: "CityRideXL",
            category: .xl,
            seats: 6,
            serviceLabel: "Room for groups",
            priceMultiplier: 1.55,
            etaAdjustment: 3
        ),
        RideTypeDefinition(
            id: "green",
            name: "CityRide Green",
            category: .green,
            seats: 4,
            serviceLabel: "Lower-emission rides",
            priceMultiplier: 1.10,
            etaAdjustment: 1
        ),
        RideTypeDefinition(
            id: "black",
            name: "CityRide Black",
            category: .premium,
            seats: 4,
            serviceLabel: "Premium rides with top drivers",
            priceMultiplier: 2.75,
            etaAdjustment: -1
        )
    ]

    static let places: [LocationPlace] = [
        LocationPlace(id: "place_home", displayName: "Home", address: "410 Brannan St, San Francisco, CA", latitudePlaceholder: 37.7784, longitudePlaceholder: -122.3942),
        LocationPlace(id: "place_work", displayName: "Work", address: "201 Mission St, San Francisco, CA", latitudePlaceholder: 37.7919, longitudePlaceholder: -122.3957),
        LocationPlace(id: "place_airport", displayName: "Airport", address: "San Francisco International Airport (SFO)", latitudePlaceholder: 37.6213, longitudePlaceholder: -122.3790),
        LocationPlace(id: "place_downtown", displayName: "Downtown", address: "Union Square, San Francisco, CA", latitudePlaceholder: 37.7881, longitudePlaceholder: -122.4075),
        LocationPlace(id: "place_train_station", displayName: "Train Station", address: "Salesforce Transit Center, San Francisco, CA", latitudePlaceholder: 37.7893, longitudePlaceholder: -122.3952),
        LocationPlace(id: "place_pier39", displayName: "Pier 39", address: "Pier 39, San Francisco, CA", latitudePlaceholder: 37.8087, longitudePlaceholder: -122.4098),
        LocationPlace(id: "place_mission", displayName: "Mission District", address: "Mission Dolores Park, San Francisco, CA", latitudePlaceholder: 37.7596, longitudePlaceholder: -122.4269),
        LocationPlace(id: "place_chase", displayName: "Chase Center", address: "1 Warriors Way, San Francisco, CA", latitudePlaceholder: 37.7680, longitudePlaceholder: -122.3877),
        LocationPlace(id: "place_ferry", displayName: "Ferry Building", address: "1 Ferry Building, San Francisco, CA", latitudePlaceholder: 37.7955, longitudePlaceholder: -122.3937),
        LocationPlace(id: "place_golden_gate", displayName: "Golden Gate Park", address: "Golden Gate Park, San Francisco, CA", latitudePlaceholder: 37.7694, longitudePlaceholder: -122.4862),
        LocationPlace(id: "place_convention", displayName: "Convention Center", address: "747 Howard St, San Francisco, CA", latitudePlaceholder: 37.7849, longitudePlaceholder: -122.4010),
        LocationPlace(id: "place_castro", displayName: "Castro", address: "18th St & Castro St, San Francisco, CA", latitudePlaceholder: 37.7609, longitudePlaceholder: -122.4350),
        LocationPlace(id: "place_north_beach", displayName: "North Beach", address: "Columbus Ave, San Francisco, CA", latitudePlaceholder: 37.8039, longitudePlaceholder: -122.4102),
        LocationPlace(id: "place_presidio", displayName: "Presidio", address: "Presidio of San Francisco, CA", latitudePlaceholder: 37.7989, longitudePlaceholder: -122.4662),
        LocationPlace(id: "place_twin_peaks", displayName: "Twin Peaks", address: "Twin Peaks Blvd, San Francisco, CA", latitudePlaceholder: 37.7544, longitudePlaceholder: -122.4477),
        LocationPlace(id: "place_caltrain", displayName: "Caltrain Station", address: "700 4th St, San Francisco, CA", latitudePlaceholder: 37.7766, longitudePlaceholder: -122.3945),
        LocationPlace(id: "place_oracle_park", displayName: "Oracle Park", address: "24 Willie Mays Plaza, San Francisco, CA", latitudePlaceholder: 37.7786, longitudePlaceholder: -122.3893),
        LocationPlace(id: "place_haight", displayName: "Haight-Ashbury", address: "Haight St & Ashbury St, San Francisco, CA", latitudePlaceholder: 37.7692, longitudePlaceholder: -122.4481),
        LocationPlace(id: "place_soma", displayName: "SoMa", address: "Folsom St & 6th St, San Francisco, CA", latitudePlaceholder: 37.7785, longitudePlaceholder: -122.4056),
        LocationPlace(id: "place_fishermans_wharf", displayName: "Fisherman's Wharf", address: "Jefferson St, San Francisco, CA", latitudePlaceholder: 37.8080, longitudePlaceholder: -122.4177),
        LocationPlace(id: "place_marina", displayName: "Marina", address: "Chestnut St & Fillmore St, San Francisco, CA", latitudePlaceholder: 37.8005, longitudePlaceholder: -122.4362),
        LocationPlace(id: "place_hayes_valley", displayName: "Hayes Valley", address: "Hayes St & Octavia Blvd, San Francisco, CA", latitudePlaceholder: 37.7763, longitudePlaceholder: -122.4246),
        LocationPlace(id: "place_nob_hill", displayName: "Nob Hill", address: "California St & Powell St, San Francisco, CA", latitudePlaceholder: 37.7920, longitudePlaceholder: -122.4100),
        LocationPlace(id: "place_mission_bay", displayName: "Mission Bay", address: "4th St & Channel St, San Francisco, CA", latitudePlaceholder: 37.7726, longitudePlaceholder: -122.3876),
        LocationPlace(id: "place_pac_heights", displayName: "Pacific Heights", address: "Fillmore St & Sacramento St, San Francisco, CA", latitudePlaceholder: 37.7908, longitudePlaceholder: -122.4347),
        LocationPlace(id: "place_japantown", displayName: "Japantown", address: "Japan Center, San Francisco, CA", latitudePlaceholder: 37.7854, longitudePlaceholder: -122.4296),
        LocationPlace(id: "place_noe_valley", displayName: "Noe Valley", address: "24th St & Church St, San Francisco, CA", latitudePlaceholder: 37.7510, longitudePlaceholder: -122.4278),
        LocationPlace(id: "place_lower_haight", displayName: "Lower Haight", address: "Haight St & Fillmore St, San Francisco, CA", latitudePlaceholder: 37.7720, longitudePlaceholder: -122.4310),
        LocationPlace(id: "place_dogpatch", displayName: "Dogpatch", address: "3rd St & 22nd St, San Francisco, CA", latitudePlaceholder: 37.7580, longitudePlaceholder: -122.3882),
        LocationPlace(id: "place_inner_sunset", displayName: "Inner Sunset", address: "9th Ave & Irving St, San Francisco, CA", latitudePlaceholder: 37.7636, longitudePlaceholder: -122.4665),
        LocationPlace(id: "place_potrero", displayName: "Potrero Hill", address: "18th St & Connecticut St, San Francisco, CA", latitudePlaceholder: 37.7620, longitudePlaceholder: -122.3960),
        LocationPlace(id: "place_russian_hill", displayName: "Russian Hill", address: "Hyde St & Lombard St, San Francisco, CA", latitudePlaceholder: 37.8020, longitudePlaceholder: -122.4187),
        LocationPlace(id: "place_embarcadero", displayName: "Embarcadero", address: "Embarcadero & Folsom St, San Francisco, CA", latitudePlaceholder: 37.7912, longitudePlaceholder: -122.3904),
        LocationPlace(id: "place_ucsf", displayName: "UCSF Medical", address: "505 Parnassus Ave, San Francisco, CA", latitudePlaceholder: 37.7631, longitudePlaceholder: -122.4576),
        LocationPlace(id: "place_treasure_island", displayName: "Treasure Island", address: "Treasure Island, San Francisco, CA", latitudePlaceholder: 37.8235, longitudePlaceholder: -122.3708)
    ]

    private static let routeTemplates: [SeedRouteTemplate] = [
        // Home (SoMa/Brannan) <-> Work (Mission St) — short within-neighborhood ~1.2 mi
        SeedRouteTemplate(id: "home_work", pickupId: "place_home", destinationId: "place_work", baseETA: 8, basePrice: 12.80, routeLabel: "US-101 N"),
        SeedRouteTemplate(id: "work_home", pickupId: "place_work", destinationId: "place_home", baseETA: 11, basePrice: 14.20, routeLabel: "I-280 S"),

        // Work <-> Train Station — very short ~0.3 mi
        SeedRouteTemplate(id: "work_train", pickupId: "place_work", destinationId: "place_train_station", baseETA: 6, basePrice: 8.50, routeLabel: "Mission St"),

        // Home <-> Airport — long ~13 mi
        SeedRouteTemplate(id: "home_airport", pickupId: "place_home", destinationId: "place_airport", baseETA: 23, basePrice: 38.50, routeLabel: "US-101 S"),
        SeedRouteTemplate(id: "airport_home", pickupId: "place_airport", destinationId: "place_home", baseETA: 25, basePrice: 42.00, routeLabel: "US-101 N"),

        // Downtown <-> Airport — long ~13 mi
        SeedRouteTemplate(id: "downtown_airport", pickupId: "place_downtown", destinationId: "place_airport", baseETA: 22, basePrice: 36.50, routeLabel: "I-380 W"),
        SeedRouteTemplate(id: "airport_downtown", pickupId: "place_airport", destinationId: "place_downtown", baseETA: 24, basePrice: 40.00, routeLabel: "US-101 N"),

        // Train Station <-> Airport — long ~12 mi
        SeedRouteTemplate(id: "train_airport", pickupId: "place_train_station", destinationId: "place_airport", baseETA: 20, basePrice: 34.20, routeLabel: "I-280 S"),

        // Mission <-> Downtown — medium ~2.5 mi
        SeedRouteTemplate(id: "mission_downtown", pickupId: "place_mission", destinationId: "place_downtown", baseETA: 9, basePrice: 13.50, routeLabel: "Mission St"),

        // Downtown <-> Pier 39 — short-medium ~2 mi
        SeedRouteTemplate(id: "downtown_pier", pickupId: "place_downtown", destinationId: "place_pier39", baseETA: 10, basePrice: 11.80, routeLabel: "The Embarcadero"),

        // Work <-> Chase Center — short ~1 mi
        SeedRouteTemplate(id: "work_chase", pickupId: "place_work", destinationId: "place_chase", baseETA: 8, basePrice: 10.50, routeLabel: "3rd St"),
        SeedRouteTemplate(id: "chase_home", pickupId: "place_chase", destinationId: "place_home", baseETA: 12, basePrice: 11.20, routeLabel: "I-280 S"),

        // Home <-> Golden Gate Park — medium-long ~4 mi across city
        SeedRouteTemplate(id: "home_golden_gate", pickupId: "place_home", destinationId: "place_golden_gate", baseETA: 15, basePrice: 19.80, routeLabel: "Fell St"),

        // Ferry Building <-> Work — very short ~0.5 mi
        SeedRouteTemplate(id: "ferry_work", pickupId: "place_ferry", destinationId: "place_work", baseETA: 7, basePrice: 9.20, routeLabel: "Market St"),
        SeedRouteTemplate(id: "work_ferry", pickupId: "place_work", destinationId: "place_ferry", baseETA: 7, basePrice: 9.50, routeLabel: "Drumm St"),

        // Home <-> Convention Center — short ~0.8 mi
        SeedRouteTemplate(id: "home_convention", pickupId: "place_home", destinationId: "place_convention", baseETA: 13, basePrice: 10.80, routeLabel: "Market St"),

        // Convention Center <-> Airport — long ~12 mi
        SeedRouteTemplate(id: "convention_airport", pickupId: "place_convention", destinationId: "place_airport", baseETA: 19, basePrice: 33.50, routeLabel: "US-101 S"),

        // Castro <-> Downtown — medium ~2.5 mi
        SeedRouteTemplate(id: "castro_downtown", pickupId: "place_castro", destinationId: "place_downtown", baseETA: 11, basePrice: 14.80, routeLabel: "Market St"),

        // Work <-> North Beach — medium ~2 mi
        SeedRouteTemplate(id: "work_north_beach", pickupId: "place_work", destinationId: "place_north_beach", baseETA: 12, basePrice: 13.20, routeLabel: "The Embarcadero"),
        SeedRouteTemplate(id: "north_beach_home", pickupId: "place_north_beach", destinationId: "place_home", baseETA: 16, basePrice: 16.50, routeLabel: "US-101 S"),

        // Home <-> Oracle Park — short ~0.6 mi
        SeedRouteTemplate(id: "home_oracle", pickupId: "place_home", destinationId: "place_oracle_park", baseETA: 14, basePrice: 9.80, routeLabel: "3rd St"),
        SeedRouteTemplate(id: "oracle_home", pickupId: "place_oracle_park", destinationId: "place_home", baseETA: 15, basePrice: 10.20, routeLabel: "I-280 S"),

        // SoMa <-> Airport — long ~12 mi
        SeedRouteTemplate(id: "soma_airport", pickupId: "place_soma", destinationId: "place_airport", baseETA: 20, basePrice: 35.00, routeLabel: "US-101 S"),

        // Caltrain <-> Work — very short ~0.7 mi
        SeedRouteTemplate(id: "caltrain_work", pickupId: "place_caltrain", destinationId: "place_work", baseETA: 5, basePrice: 8.80, routeLabel: "King St"),
        SeedRouteTemplate(id: "work_caltrain", pickupId: "place_work", destinationId: "place_caltrain", baseETA: 6, basePrice: 9.20, routeLabel: "Townsend St"),

        // Presidio <-> Downtown — medium-long ~3.5 mi
        SeedRouteTemplate(id: "presidio_downtown", pickupId: "place_presidio", destinationId: "place_downtown", baseETA: 14, basePrice: 18.50, routeLabel: "Lombard St"),

        // Haight <-> Mission — short-medium ~1.5 mi
        SeedRouteTemplate(id: "haight_mission", pickupId: "place_haight", destinationId: "place_mission", baseETA: 8, basePrice: 11.50, routeLabel: "Duboce Ave"),

        // Fisherman's Wharf <-> Downtown — medium ~2.5 mi
        SeedRouteTemplate(id: "fishermans_wharf_downtown", pickupId: "place_fishermans_wharf", destinationId: "place_downtown", baseETA: 11, basePrice: 13.80, routeLabel: "The Embarcadero"),

        // Downtown <-> Twin Peaks — medium ~3 mi uphill
        SeedRouteTemplate(id: "downtown_twin_peaks", pickupId: "place_downtown", destinationId: "place_twin_peaks", baseETA: 13, basePrice: 16.20, routeLabel: "Market St"),

        // Marina routes — Home to Marina ~3 mi cross-city
        SeedRouteTemplate(id: "home_marina", pickupId: "place_home", destinationId: "place_marina", baseETA: 14, basePrice: 17.50, routeLabel: "Van Ness Ave"),
        SeedRouteTemplate(id: "marina_home", pickupId: "place_marina", destinationId: "place_home", baseETA: 15, basePrice: 18.80, routeLabel: "Van Ness Ave"),
        SeedRouteTemplate(id: "work_marina", pickupId: "place_work", destinationId: "place_marina", baseETA: 13, basePrice: 16.20, routeLabel: "The Embarcadero"),

        // Hayes Valley routes — Home to Hayes Valley ~1.5 mi
        SeedRouteTemplate(id: "home_hayes_valley", pickupId: "place_home", destinationId: "place_hayes_valley", baseETA: 8, basePrice: 11.80, routeLabel: "Market St"),
        SeedRouteTemplate(id: "hayes_valley_home", pickupId: "place_hayes_valley", destinationId: "place_home", baseETA: 9, basePrice: 12.50, routeLabel: "Valencia St"),
        SeedRouteTemplate(id: "hayes_valley_downtown", pickupId: "place_hayes_valley", destinationId: "place_downtown", baseETA: 8, basePrice: 10.80, routeLabel: "Market St"),

        // Nob Hill routes — Home to Nob Hill ~2 mi
        SeedRouteTemplate(id: "home_nob_hill", pickupId: "place_home", destinationId: "place_nob_hill", baseETA: 12, basePrice: 14.50, routeLabel: "Market St"),
        SeedRouteTemplate(id: "nob_hill_home", pickupId: "place_nob_hill", destinationId: "place_home", baseETA: 13, basePrice: 15.80, routeLabel: "Van Ness Ave"),

        // Mission Bay routes — Home to Mission Bay ~0.5 mi (very close)
        SeedRouteTemplate(id: "home_mission_bay", pickupId: "place_home", destinationId: "place_mission_bay", baseETA: 10, basePrice: 9.50, routeLabel: "3rd St"),
        SeedRouteTemplate(id: "mission_bay_home", pickupId: "place_mission_bay", destinationId: "place_home", baseETA: 11, basePrice: 10.20, routeLabel: "I-280 S"),
        SeedRouteTemplate(id: "work_mission_bay", pickupId: "place_work", destinationId: "place_mission_bay", baseETA: 6, basePrice: 8.80, routeLabel: "King St"),
        SeedRouteTemplate(id: "mission_bay_work", pickupId: "place_mission_bay", destinationId: "place_work", baseETA: 7, basePrice: 9.50, routeLabel: "3rd St"),

        // Pacific Heights routes — Home to Pac Heights ~3 mi
        SeedRouteTemplate(id: "home_pac_heights", pickupId: "place_home", destinationId: "place_pac_heights", baseETA: 15, basePrice: 17.80, routeLabel: "Van Ness Ave"),
        SeedRouteTemplate(id: "pac_heights_home", pickupId: "place_pac_heights", destinationId: "place_home", baseETA: 16, basePrice: 18.50, routeLabel: "Van Ness Ave"),

        // Noe Valley routes — Home to Noe Valley ~2 mi
        SeedRouteTemplate(id: "home_noe_valley", pickupId: "place_home", destinationId: "place_noe_valley", baseETA: 7, basePrice: 12.80, routeLabel: "Church St"),
        SeedRouteTemplate(id: "noe_valley_home", pickupId: "place_noe_valley", destinationId: "place_home", baseETA: 8, basePrice: 13.50, routeLabel: "Church St"),

        // Dogpatch routes — Home to Dogpatch ~1.5 mi
        SeedRouteTemplate(id: "home_dogpatch", pickupId: "place_home", destinationId: "place_dogpatch", baseETA: 9, basePrice: 10.50, routeLabel: "3rd St"),
        SeedRouteTemplate(id: "dogpatch_home", pickupId: "place_dogpatch", destinationId: "place_home", baseETA: 10, basePrice: 11.20, routeLabel: "I-280 S"),

        // Inner Sunset routes — Home to Inner Sunset ~5 mi across city
        SeedRouteTemplate(id: "home_inner_sunset", pickupId: "place_home", destinationId: "place_inner_sunset", baseETA: 16, basePrice: 21.50, routeLabel: "Lincoln Way"),
        SeedRouteTemplate(id: "inner_sunset_home", pickupId: "place_inner_sunset", destinationId: "place_home", baseETA: 17, basePrice: 22.80, routeLabel: "Lincoln Way"),

        // Potrero Hill routes — Home to Potrero ~1.2 mi
        SeedRouteTemplate(id: "home_potrero", pickupId: "place_home", destinationId: "place_potrero", baseETA: 8, basePrice: 10.80, routeLabel: "Potrero Ave"),
        SeedRouteTemplate(id: "potrero_home", pickupId: "place_potrero", destinationId: "place_home", baseETA: 9, basePrice: 11.50, routeLabel: "Potrero Ave"),

        // Cross-city connections
        SeedRouteTemplate(id: "marina_downtown", pickupId: "place_marina", destinationId: "place_downtown", baseETA: 11, basePrice: 15.20, routeLabel: "Van Ness Ave"),
        SeedRouteTemplate(id: "castro_home", pickupId: "place_castro", destinationId: "place_home", baseETA: 7, basePrice: 15.50, routeLabel: "Market St"),
        SeedRouteTemplate(id: "home_castro", pickupId: "place_home", destinationId: "place_castro", baseETA: 8, basePrice: 16.20, routeLabel: "Market St"),
        SeedRouteTemplate(id: "mission_home", pickupId: "place_mission", destinationId: "place_home", baseETA: 5, basePrice: 11.80, routeLabel: "Valencia St"),
        SeedRouteTemplate(id: "home_mission", pickupId: "place_home", destinationId: "place_mission", baseETA: 5, basePrice: 11.20, routeLabel: "Valencia St"),
        SeedRouteTemplate(id: "lower_haight_home", pickupId: "place_lower_haight", destinationId: "place_home", baseETA: 8, basePrice: 12.80, routeLabel: "Duboce Ave"),
        SeedRouteTemplate(id: "home_lower_haight", pickupId: "place_home", destinationId: "place_lower_haight", baseETA: 7, basePrice: 12.20, routeLabel: "Duboce Ave"),
        SeedRouteTemplate(id: "japantown_home", pickupId: "place_japantown", destinationId: "place_home", baseETA: 12, basePrice: 15.20, routeLabel: "Geary Blvd"),

        // Work <-> Airport — long ~13 mi
        SeedRouteTemplate(id: "airport_work", pickupId: "place_airport", destinationId: "place_work", baseETA: 24, basePrice: 41.00, routeLabel: "US-101 N"),
        SeedRouteTemplate(id: "work_airport", pickupId: "place_work", destinationId: "place_airport", baseETA: 22, basePrice: 37.50, routeLabel: "US-101 S"),

        // Nob Hill <-> Downtown — very short ~0.5 mi
        SeedRouteTemplate(id: "nob_hill_downtown", pickupId: "place_nob_hill", destinationId: "place_downtown", baseETA: 5, basePrice: 9.20, routeLabel: "Powell St"),

        // Russian Hill routes — Home to Russian Hill ~2.5 mi
        SeedRouteTemplate(id: "home_russian_hill", pickupId: "place_home", destinationId: "place_russian_hill", baseETA: 13, basePrice: 15.80, routeLabel: "Van Ness Ave"),
        SeedRouteTemplate(id: "russian_hill_home", pickupId: "place_russian_hill", destinationId: "place_home", baseETA: 14, basePrice: 16.50, routeLabel: "Van Ness Ave"),

        // Embarcadero routes — Home to Embarcadero ~1.2 mi
        SeedRouteTemplate(id: "home_embarcadero", pickupId: "place_home", destinationId: "place_embarcadero", baseETA: 7, basePrice: 10.20, routeLabel: "The Embarcadero"),
        SeedRouteTemplate(id: "embarcadero_home", pickupId: "place_embarcadero", destinationId: "place_home", baseETA: 8, basePrice: 11.00, routeLabel: "The Embarcadero"),
        SeedRouteTemplate(id: "work_embarcadero", pickupId: "place_work", destinationId: "place_embarcadero", baseETA: 5, basePrice: 8.50, routeLabel: "Market St"),

        // UCSF Medical routes — Home to UCSF ~4 mi across city
        SeedRouteTemplate(id: "home_ucsf", pickupId: "place_home", destinationId: "place_ucsf", baseETA: 15, basePrice: 18.50, routeLabel: "Market St"),
        SeedRouteTemplate(id: "ucsf_home", pickupId: "place_ucsf", destinationId: "place_home", baseETA: 16, basePrice: 19.20, routeLabel: "Market St"),

        // Treasure Island routes — Home to Treasure Island ~7 mi via Bay Bridge
        SeedRouteTemplate(id: "home_treasure_island", pickupId: "place_home", destinationId: "place_treasure_island", baseETA: 18, basePrice: 24.50, routeLabel: "I-80 W"),
        SeedRouteTemplate(id: "treasure_island_home", pickupId: "place_treasure_island", destinationId: "place_home", baseETA: 19, basePrice: 25.80, routeLabel: "I-80 E"),

        // Convention <-> Home — short ~0.8 mi
        SeedRouteTemplate(id: "convention_home", pickupId: "place_convention", destinationId: "place_home", baseETA: 14, basePrice: 11.50, routeLabel: "Market St")
    ]

    static let drivers: [Driver] = [
        Driver(id: "driver_alex", driverName: "Alex Rivera", rating: 4.98, phoneMask: "(415) ***-1182"),
        Driver(id: "driver_maya", driverName: "Maya Patel", rating: 4.87, phoneMask: "(628) ***-2204"),
        Driver(id: "driver_jordan", driverName: "Jordan Kim", rating: 4.97, phoneMask: "(510) ***-5519"),
        Driver(id: "driver_lucas", driverName: "Lucas Chen", rating: 4.82, phoneMask: "(415) ***-3380"),
        Driver(id: "driver_sophia", driverName: "Sophia Johnson", rating: 4.96, phoneMask: "(650) ***-9021"),
        Driver(id: "driver_emma", driverName: "Emma Brooks", rating: 4.78, phoneMask: "(415) ***-7441"),
        Driver(id: "driver_daniel", driverName: "Daniel Shah", rating: 4.94, phoneMask: "(925) ***-6148"),
        Driver(id: "driver_priya", driverName: "Priya Sharma", rating: 4.91, phoneMask: "(415) ***-8803"),
        Driver(id: "driver_marcus", driverName: "Marcus Thompson", rating: 4.73, phoneMask: "(510) ***-4492"),
        Driver(id: "driver_olivia", driverName: "Olivia Nguyen", rating: 4.99, phoneMask: "(650) ***-1127"),
        Driver(id: "driver_carlos", driverName: "Carlos Mendez", rating: 4.85, phoneMask: "(628) ***-3356"),
        Driver(id: "driver_aisha", driverName: "Aisha Williams", rating: 4.97, phoneMask: "(415) ***-5578"),
        Driver(id: "driver_kevin", driverName: "Kevin O'Brien", rating: 4.76, phoneMask: "(415) ***-2291"),
        Driver(id: "driver_fatima", driverName: "Fatima Al-Hassan", rating: 4.95, phoneMask: "(510) ***-7702"),
        Driver(id: "driver_raj", driverName: "Raj Kapoor", rating: 4.88, phoneMask: "(628) ***-1148"),
        Driver(id: "driver_jenny", driverName: "Jenny Liu", rating: 4.98, phoneMask: "(650) ***-3389"),
        Driver(id: "driver_tom", driverName: "Tom Nakamura", rating: 4.81, phoneMask: "(415) ***-6604"),
        Driver(id: "driver_sarah", driverName: "Sarah Mitchell", rating: 4.94, phoneMask: "(925) ***-4420"),
        Driver(id: "driver_diego", driverName: "Diego Vasquez", rating: 4.90, phoneMask: "(510) ***-8857"),
        Driver(id: "driver_anna", driverName: "Anna Kowalski", rating: 4.84, phoneMask: "(650) ***-5501")
    ]

    static let vehicles: [Vehicle] = [
        Vehicle(id: "vehicle_prius", make: "Toyota", model: "Prius", color: "Silver", licensePlate: "8UYR210"),
        Vehicle(id: "vehicle_camry", make: "Toyota", model: "Camry", color: "Black", licensePlate: "9JKT442"),
        Vehicle(id: "vehicle_model3", make: "Tesla", model: "Model 3", color: "White", licensePlate: "7EZN553"),
        Vehicle(id: "vehicle_accord", make: "Honda", model: "Accord", color: "Blue", licensePlate: "6PSM188"),
        Vehicle(id: "vehicle_suburban", make: "Chevrolet", model: "Suburban", color: "Gray", licensePlate: "5LVR906"),
        Vehicle(id: "vehicle_ioniq5", make: "Hyundai", model: "IONIQ 5", color: "Teal", licensePlate: "4WHP260"),
        Vehicle(id: "vehicle_escalade", make: "Cadillac", model: "Escalade", color: "Black", licensePlate: "3QNV814"),
        Vehicle(id: "vehicle_modely", make: "Tesla", model: "Model Y", color: "Midnight Blue", licensePlate: "8FHK901"),
        Vehicle(id: "vehicle_civic", make: "Honda", model: "Civic", color: "White", licensePlate: "7BNR344"),
        Vehicle(id: "vehicle_highlander", make: "Toyota", model: "Highlander", color: "Dark Green", licensePlate: "6TPS721"),
        Vehicle(id: "vehicle_leaf", make: "Nissan", model: "Leaf", color: "Pearl White", licensePlate: "5ZEV118"),
        Vehicle(id: "vehicle_ev6", make: "Kia", model: "EV6", color: "Glacier White", licensePlate: "4EVK590"),
        Vehicle(id: "vehicle_corolla", make: "Toyota", model: "Corolla", color: "Silver", licensePlate: "8MRJ672"),
        Vehicle(id: "vehicle_sonata", make: "Hyundai", model: "Sonata", color: "Phantom Black", licensePlate: "7VKP318"),
        Vehicle(id: "vehicle_rav4", make: "Toyota", model: "RAV4", color: "Lunar Rock", licensePlate: "6NXC945"),
        Vehicle(id: "vehicle_mach_e", make: "Ford", model: "Mustang Mach-E", color: "Carbonized Gray", licensePlate: "5EVM203"),
        Vehicle(id: "vehicle_outback", make: "Subaru", model: "Outback", color: "Autumn Green", licensePlate: "9TRW461"),
        Vehicle(id: "vehicle_bolt", make: "Chevrolet", model: "Bolt EUV", color: "Ice Blue", licensePlate: "3ZEV887"),
        Vehicle(id: "vehicle_crv", make: "Honda", model: "CR-V", color: "Radiant Red", licensePlate: "8HNB556"),
        Vehicle(id: "vehicle_s_class", make: "Mercedes-Benz", model: "S-Class", color: "Obsidian Black", licensePlate: "7LUX002"),
        Vehicle(id: "vehicle_atlas", make: "Volkswagen", model: "Atlas", color: "Pure White", licensePlate: "6VWG714")
    ]

    static let commuteShortcuts: [LocationPlace] = [
        place(withID: "place_work") ?? places[1],
        place(withID: "place_home") ?? places[0],
        place(withID: "place_downtown") ?? places[3],
        place(withID: "place_train_station") ?? places[4],
        place(withID: "place_airport") ?? places[2]
    ]

    static let travelAlerts: [TravelAlert] = [
        TravelAlert(id: "alert_1", title: "Airport traffic", message: "Expect heavier traffic near Terminal 3 between 4 PM and 7 PM.", severity: .warning),
        TravelAlert(id: "alert_2", title: "Downtown event", message: "Street closures near Union Square tonight. Pickups may be moved.", severity: .info),
        TravelAlert(id: "alert_3", title: "Rain advisory", message: "Rain may increase ETAs by 3 to 7 minutes through the evening commute.", severity: .warning),
        TravelAlert(id: "alert_4", title: "Terminal pickup update", message: "Airport pickups are now directed to Level 5 rideshare zone.", severity: .info),
        TravelAlert(id: "alert_5", title: "Oracle Park game day", message: "Giants game tonight. Expect surge pricing near the ballpark from 5 PM.", severity: .warning),
        TravelAlert(id: "alert_6", title: "Caltrain delay", message: "Train delays on the SF line may increase rideshare demand in SoMa.", severity: .info),
        TravelAlert(id: "alert_7", title: "High demand area", message: "Prices are higher than usual in the Financial District right now.", severity: .warning),
        TravelAlert(id: "alert_8", title: "Bay Bridge metering", message: "Metering lights active on the Bay Bridge. Expect delays for east bay destinations.", severity: .warning),
        TravelAlert(id: "alert_9", title: "UCSF pickup update", message: "UCSF Medical Center pickups are now directed to the Lot 2 rideshare zone.", severity: .info),
        TravelAlert(id: "alert_10", title: "Weekend marathon", message: "SF Marathon this Sunday. Road closures along The Embarcadero from 6 AM to 1 PM.", severity: .critical)
    ]

    static let savedPlaces: [SavedPlace] = [
        SavedPlace(id: "saved_home", type: .home, displayName: "Home", address: "410 Brannan St, San Francisco, CA", latitudePlaceholder: 37.7784, longitudePlaceholder: -122.3942),
        SavedPlace(id: "saved_work", type: .work, displayName: "Work", address: "201 Mission St, San Francisco, CA", latitudePlaceholder: 37.7919, longitudePlaceholder: -122.3957),
        SavedPlace(id: "saved_favorite_1", type: .favorite, displayName: "Airport", address: "San Francisco International Airport (SFO)", latitudePlaceholder: 37.6213, longitudePlaceholder: -122.3790),
        SavedPlace(id: "saved_favorite_2", type: .favorite, displayName: "Gym", address: "2 Embarcadero Ctr, San Francisco, CA", latitudePlaceholder: 37.7956, longitudePlaceholder: -122.3974),
        SavedPlace(id: "saved_favorite_3", type: .favorite, displayName: "Parents", address: "Lombard St, San Francisco, CA", latitudePlaceholder: 37.8003, longitudePlaceholder: -122.4192),
        SavedPlace(id: "saved_favorite_4", type: .favorite, displayName: "Doctor", address: "450 Sutter St, San Francisco, CA", latitudePlaceholder: 37.7892, longitudePlaceholder: -122.4076),
        SavedPlace(id: "saved_favorite_5", type: .favorite, displayName: "Caltrain", address: "700 4th St, San Francisco, CA", latitudePlaceholder: 37.7766, longitudePlaceholder: -122.3945),
        SavedPlace(id: "saved_favorite_6", type: .favorite, displayName: "Dentist", address: "490 Post St, San Francisco, CA", latitudePlaceholder: 37.7878, longitudePlaceholder: -122.4090),
        SavedPlace(id: "saved_favorite_7", type: .favorite, displayName: "Dog Park", address: "Stern Grove, San Francisco, CA", latitudePlaceholder: 37.7358, longitudePlaceholder: -122.4710),
        SavedPlace(id: "saved_favorite_8", type: .favorite, displayName: "UCSF", address: "505 Parnassus Ave, San Francisco, CA", latitudePlaceholder: 37.7631, longitudePlaceholder: -122.4576)
    ]

    static let promotions: [Promotion] = [
        Promotion(id: "promo_weekday", title: "Weekday commute", detail: "5% off rides to Work before 9 AM.", valueLabel: "5% off", isActive: true),
        Promotion(id: "promo_airport", title: "Airport saver", detail: "Flat-rate promo placeholder for airport rides.", valueLabel: "$4 off", isActive: true),
        Promotion(id: "promo_green", title: "Go green", detail: "Save on lower-emission options this week.", valueLabel: "10% off CityRide Green", isActive: true),
        Promotion(id: "promo_night", title: "Late night return", detail: "Discounted ride after 10 PM from downtown.", valueLabel: "$3 off", isActive: true),
        Promotion(id: "promo_refer", title: "Refer a friend", detail: "Share your code and both get $15 off.", valueLabel: "$15 credit", isActive: true),
        Promotion(id: "promo_first_comfort", title: "Try Comfort", detail: "First Comfort ride this month is 20% off.", valueLabel: "20% off", isActive: true),
        Promotion(id: "promo_xl_weekend", title: "XL weekend deal", detail: "15% off CityRideXL every Saturday this month.", valueLabel: "15% off XL", isActive: true),
        Promotion(id: "promo_spring_credits", title: "Spring into savings", detail: "Earn 2x ride credits on your next 3 rides.", valueLabel: "2x credits", isActive: true),
        Promotion(id: "promo_black_intro", title: "First Black ride", detail: "Try CityRide Black — your first ride is 30% off.", valueLabel: "30% off Black", isActive: true)
    ]

    static let passengerProfile = PassengerProfile(
        id: "passenger_1",
        firstName: "Jordan",
        lastName: "Avery",
        riderRating: 4.92,
        preferredLanguage: "English"
    )

    static let userProfile = UserProfile(
        id: "user_1",
        fullName: "Jordan Avery",
        email: "jordan.avery@email.com",
        phoneNumberMasked: "+1 (206) ***-0147",
        homeCity: "San Francisco",
        safetyToolkitEnabled: true
    )

    static let walletState = WalletState(
        paymentMethods: [
            PaymentMethod(id: "pm_visa_6645", providerName: "Chase Debit", type: .card, last4: "6645", cardLabel: "Chase Debit **** 6645", isDefault: true, isAvailable: true),
            PaymentMethod(id: "pm_visa_2095", providerName: "Freedom Unlimited", type: .card, last4: "2095", cardLabel: "Freedom Unlimited **** 2095", isDefault: false, isAvailable: true),
            PaymentMethod(id: "pm_venmo", providerName: "SplitPay", type: .card, last4: "0000", cardLabel: "SplitPay - Jordan-Avery", isDefault: false, isAvailable: true),
            PaymentMethod(id: "pm_cash", providerName: "Cash", type: .cash, last4: "", cardLabel: "Cash", isDefault: false, isAvailable: true),
            PaymentMethod(id: "pm_applepay", providerName: "Apple Pay", type: .applePay, last4: "", cardLabel: "Apple Pay", isDefault: false, isAvailable: true)
        ],
        promotions: promotions,
        rideCredits: 18.75,
        businessProfileEnabled: true,
        giftCardBalance: 40.0
    )

    static func place(withID id: String) -> LocationPlace? {
        places.first(where: { $0.id == id })
    }

    static func place(named name: String) -> LocationPlace? {
        places.first(where: { $0.displayName.caseInsensitiveCompare(name) == .orderedSame })
    }

    static func allRouteEstimates(sourceType: FareSourceType = .seeded, lastUpdated: Date = Date()) -> [RouteEstimate] {
        routeTemplates.reduce(into: [RouteEstimate]()) { partialResult, template in
            guard let pickup = place(withID: template.pickupId),
                  let destination = place(withID: template.destinationId) else {
                return
            }
            partialResult.append(contentsOf: routeEstimates(template: template, pickup: pickup, destination: destination, sourceType: sourceType, lastUpdated: lastUpdated))
        }
    }

    static func routeEstimates(pickup: LocationPlace, destination: LocationPlace, sourceType: FareSourceType = .seeded, lastUpdated: Date = Date()) -> [RouteEstimate] {
        if let matchingTemplate = routeTemplates.first(where: { $0.pickupId == pickup.id && $0.destinationId == destination.id }) {
            return routeEstimates(template: matchingTemplate, pickup: pickup, destination: destination, sourceType: sourceType, lastUpdated: lastUpdated)
        }

        // Generate a fallback estimate from coordinate distance so every pair has rides
        let latRad = pickup.latitudePlaceholder * .pi / 180
        let dlat = pickup.latitudePlaceholder - destination.latitudePlaceholder
        let dlon = pickup.longitudePlaceholder - destination.longitudePlaceholder
        let latMiles = dlat * 69.0
        let lonMiles = dlon * 69.0 * cos(latRad)
        let straightLineMiles = max(0.5, (latMiles * latMiles + lonMiles * lonMiles).squareRoot())
        // Circuity factor: city streets are windier, highways more direct
        let circuityFactor = straightLineMiles < 10 ? 1.4 : (straightLineMiles < 30 ? 1.3 : 1.2)
        let distanceMiles = straightLineMiles * circuityFactor

        // ETA: blended speed tiers (city → mixed → highway)
        let baseETA: Int
        if distanceMiles <= 10 {
            baseETA = max(5, Int((distanceMiles * 2.8).rounded()))
        } else if distanceMiles <= 30 {
            let cityMin = 10.0 * 2.8
            let mixedMin = (distanceMiles - 10.0) * 2.0
            baseETA = Int((cityMin + mixedMin).rounded())
        } else {
            let cityMin = 10.0 * 2.8
            let mixedMin = 20.0 * 2.0
            let hwMin = (distanceMiles - 30.0) * 1.2
            baseETA = Int((cityMin + mixedMin + hwMin).rounded())
        }

        // Pricing: base fare + service fee + per-mile + per-minute
        let rawPrice = 2.50 + 2.75 + 1.45 * distanceMiles + 0.30 * Double(baseETA)
        let basePrice = max(8.00, (rawPrice * 100).rounded() / 100)

        let routeLabel: String
        if distanceMiles > 30 {
            routeLabel = "Via highway"
        } else if distanceMiles > 10 {
            routeLabel = "Via main roads"
        } else {
            routeLabel = "Via city streets"
        }
        let fallback = SeedRouteTemplate(
            id: "\(pickup.id)_\(destination.id)",
            pickupId: pickup.id,
            destinationId: destination.id,
            baseETA: baseETA,
            basePrice: basePrice,
            routeLabel: routeLabel
        )
        return routeEstimates(template: fallback, pickup: pickup, destination: destination, sourceType: sourceType, lastUpdated: lastUpdated)
    }

    static func initialState(referenceDate: Date = seedReferenceDate) -> CityRideSimState {
        let home = place(withID: "place_home") ?? places[0]
        let work = place(withID: "place_work") ?? places[1]
        let downtown = place(withID: "place_downtown") ?? places[3]

        let activeTrip = seededActiveTrip(now: referenceDate)
        let upcomingTrips = seededUpcomingTrips(now: referenceDate)
        let pastTrips = seededPastTrips(now: referenceDate)
        let receipts = pastTrips.compactMap { trip in
            receipt(for: trip, generatedAt: trip.dropoffTime ?? referenceDate)
        }

        return CityRideSimState(
            userProfile: userProfile,
            passengerProfile: passengerProfile,
            places: places,
            suggestedDestinations: [work, downtown, place(withID: "place_airport") ?? places[2], place(withID: "place_train_station") ?? places[4], place(withID: "place_ucsf")].compactMap { $0 },
            recentDestinations: [place(withID: "place_chase"), place(withID: "place_ferry"), place(withID: "place_pier39"), place(withID: "place_work"), place(withID: "place_russian_hill"), place(withID: "place_embarcadero")].compactMap { $0 },
            savedPlaces: savedPlaces,
            travelAlerts: travelAlerts,
            walletState: walletState,
            trips: [activeTrip] + upcomingTrips + pastTrips,
            receipts: receipts,
            requestDraft: RequestDraft(
                pickup: home,
                destination: work,
                rideTiming: .now,
                reservedDate: referenceDate.addingTimeInterval(3600 * 3),
                selectedRideTypeId: "standard",
                sortOption: .lowestPrice,
                filterCategory: .all,
                maxETAMinutes: 45,
                lowerPriceOnly: false,
                promoCode: ""
            ),
            fareMode: .seeded,
            snapshotLocation: .bundled,
            currentSnapshotMetadata: nil,
            selectedPaymentMethodId: "pm_visa_6645",
            nextDriverIndex: 3,
            seedVersion: 1
        )
    }

    static func nextDriverVehicle(index: Int) -> (Driver, Vehicle) {
        let driver = drivers[index % drivers.count]
        let vehicle = vehicles[index % vehicles.count]
        return (driver, vehicle)
    }

    static func receipt(for trip: Trip, generatedAt: Date = Date()) -> RideReceipt? {
        guard trip.tripStatus == .tripCompleted else {
            return nil
        }

        let baseFare = (trip.estimatedPrice * 0.74 * 100).rounded() / 100
        let fees = (trip.estimatedPrice * 0.18 * 100).rounded() / 100
        let taxes = (trip.estimatedPrice * 0.08 * 100).rounded() / 100
        return RideReceipt(
            id: "receipt_\(trip.id)",
            tripId: trip.id,
            receiptTotal: ((baseFare + fees + taxes) * 100).rounded() / 100,
            baseFare: baseFare,
            fees: fees,
            taxes: taxes,
            currency: trip.currency,
            paymentMethodId: trip.paymentMethodId,
            generatedAt: generatedAt
        )
    }

    static func addRecentDestination(_ destination: LocationPlace, to existing: [LocationPlace]) -> [LocationPlace] {
        var updated = existing.filter { $0.id != destination.id }
        updated.insert(destination, at: 0)
        return Array(updated.prefix(8))
    }

    private static func routeEstimates(
        template: SeedRouteTemplate,
        pickup: LocationPlace,
        destination: LocationPlace,
        sourceType: FareSourceType,
        lastUpdated: Date
    ) -> [RouteEstimate] {
        var baseOptions = rideTypes.map { rideType in
            let eta = max(3, template.baseETA + rideType.etaAdjustment)
            let rawPrice = template.basePrice * rideType.priceMultiplier
            let roundedPrice = (rawPrice * 100).rounded() / 100
            return RouteEstimate(
                id: "\(template.id)_\(rideType.id)_\(sourceType.rawValue)",
                pickupName: pickup.displayName,
                destinationName: destination.displayName,
                rideType: rideType.name,
                rideTypeId: rideType.id,
                etaMinutes: eta,
                estimatedPrice: roundedPrice,
                currency: "USD",
                seats: rideType.seats,
                serviceLabel: rideType.serviceLabel,
                badges: [],
                category: rideType.category,
                routeLabel: template.routeLabel,
                sourceType: sourceType,
                lastUpdated: lastUpdated
            )
        }

        if let cheapestIndex = baseOptions.enumerated().min(by: { $0.element.estimatedPrice < $1.element.estimatedPrice })?.offset {
            baseOptions[cheapestIndex].badges.append(.cheapest)
        }
        if let fastestIndex = baseOptions.enumerated().min(by: { $0.element.etaMinutes < $1.element.etaMinutes })?.offset {
            baseOptions[fastestIndex].badges.append(.fastest)
        }
        if let popularIndex = baseOptions.firstIndex(where: { $0.rideTypeId == "standard" }) {
            baseOptions[popularIndex].badges.append(.popular)
        }

        return baseOptions
    }

    private static func seededActiveTrip(now: Date) -> Trip {
        let home = place(withID: "place_home") ?? places[0]
        let airport = place(withID: "place_airport") ?? places[2]
        let selection = routeEstimates(pickup: home, destination: airport).first(where: { $0.rideTypeId == "standard" }) ?? routeEstimates(pickup: home, destination: airport)[0]
        let assignment = nextDriverVehicle(index: 0)

        return Trip(
            id: "trip_active_1",
            pickupName: selection.pickupName,
            destinationName: selection.destinationName,
            rideType: selection.rideType,
            rideTypeId: selection.rideTypeId,
            etaMinutes: selection.etaMinutes,
            estimatedPrice: selection.estimatedPrice,
            currency: selection.currency,
            routeLabel: selection.routeLabel,
            tripStatus: .driverArriving,
            requestedAt: now.addingTimeInterval(-5 * 60),
            reservedFor: nil,
            pickupTime: nil,
            dropoffTime: nil,
            paymentMethodId: "pm_visa_6645",
            sourceType: .seeded,
            driver: assignment.0,
            vehicle: assignment.1,
            pickupNotes: "Meet at front entrance — 410 Brannan, unit 4B buzzer",
            dropoffNotes: "Terminal 2 departures — Delta check-in"
        )
    }

    private static func seededUpcomingTrips(now: Date) -> [Trip] {
        let work = place(withID: "place_work") ?? places[1]
        let train = place(withID: "place_train_station") ?? places[4]
        let home = place(withID: "place_home") ?? places[0]
        let airport = place(withID: "place_airport") ?? places[2]

        let firstSelection = routeEstimates(pickup: work, destination: train).first(where: { $0.rideTypeId == "comfort" }) ?? routeEstimates(pickup: work, destination: train)[0]
        let secondSelection = routeEstimates(pickup: home, destination: airport).first(where: { $0.rideTypeId == "standard" }) ?? routeEstimates(pickup: home, destination: airport)[0]

        let firstTrip = Trip(
            id: "trip_upcoming_1",
            pickupName: firstSelection.pickupName,
            destinationName: firstSelection.destinationName,
            rideType: firstSelection.rideType,
            rideTypeId: firstSelection.rideTypeId,
            etaMinutes: firstSelection.etaMinutes,
            estimatedPrice: firstSelection.estimatedPrice,
            currency: firstSelection.currency,
            routeLabel: firstSelection.routeLabel,
            tripStatus: .reserved,
            requestedAt: now.addingTimeInterval(-12 * 60),
            reservedFor: now.addingTimeInterval(2 * 3600),
            pickupTime: nil,
            dropoffTime: nil,
            paymentMethodId: "pm_visa_2095",
            sourceType: .seeded,
            driver: nil,
            vehicle: nil,
            pickupNotes: "Lobby pickup",
            dropoffNotes: nil
        )

        let secondTrip = Trip(
            id: "trip_upcoming_2",
            pickupName: secondSelection.pickupName,
            destinationName: secondSelection.destinationName,
            rideType: secondSelection.rideType,
            rideTypeId: secondSelection.rideTypeId,
            etaMinutes: secondSelection.etaMinutes,
            estimatedPrice: secondSelection.estimatedPrice,
            currency: secondSelection.currency,
            routeLabel: secondSelection.routeLabel,
            tripStatus: .reserved,
            requestedAt: now.addingTimeInterval(-40 * 60),
            reservedFor: now.addingTimeInterval(26 * 3600),
            pickupTime: nil,
            dropoffTime: nil,
            paymentMethodId: "pm_venmo",
            sourceType: .seeded,
            driver: nil,
            vehicle: nil,
            pickupNotes: "Terminal departures level",
            dropoffNotes: nil
        )

        let ucsf = place(withID: "place_ucsf") ?? places[0]
        let thirdSelection = routeEstimates(pickup: home, destination: ucsf).first(where: { $0.rideTypeId == "standard" }) ?? routeEstimates(pickup: home, destination: ucsf)[0]

        let thirdTrip = Trip(
            id: "trip_upcoming_3",
            pickupName: thirdSelection.pickupName,
            destinationName: thirdSelection.destinationName,
            rideType: thirdSelection.rideType,
            rideTypeId: thirdSelection.rideTypeId,
            etaMinutes: thirdSelection.etaMinutes,
            estimatedPrice: thirdSelection.estimatedPrice,
            currency: thirdSelection.currency,
            routeLabel: thirdSelection.routeLabel,
            tripStatus: .reserved,
            requestedAt: now.addingTimeInterval(-2 * 3600),
            reservedFor: now.addingTimeInterval(50 * 3600),
            pickupTime: nil,
            dropoffTime: nil,
            paymentMethodId: "pm_visa_6645",
            sourceType: .seeded,
            driver: nil,
            vehicle: nil,
            pickupNotes: "Front door — 410 Brannan",
            dropoffNotes: "UCSF main entrance — annual checkup"
        )

        return [firstTrip, secondTrip, thirdTrip]
    }

    // Each entry: (tripId, pickupPlaceId, destinationPlaceId, rideTypeId, driverIndex, status, daysAgo, hourOfDay)
    // daysAgo is relative to `now`; hourOfDay sets the dropoff/cancel hour for realism.
    private static let pastTripTemplates: [(String, String, String, String, Int, TripStatus, Int, Int)] = [
        // ── Recent trips (days 1-14) — matches the original 14 trips ──
        ("trip_past_1",  "place_work",       "place_home",              "standard",     1,  .tripCompleted, 1,  18),  // Weekday commute home
        ("trip_past_2",  "place_mission",     "place_downtown",          "green", 2,  .canceled,      2,  19),  // Canceled evening ride
        ("trip_past_3",  "place_downtown",    "place_pier39",            "comfort",   3,  .tripCompleted, 3,  14),  // Weekend afternoon tourist area
        ("trip_past_4",  "place_airport",     "place_home",              "xl",    4,  .tripCompleted, 4,  21),  // Late flight home from SFO
        ("trip_past_5",  "place_work",        "place_north_beach",       "standard",     5,  .tripCompleted, 5,  19),  // After-work dinner North Beach
        ("trip_past_6",  "place_chase",       "place_home",              "comfort",   6,  .tripCompleted, 6,  22),  // Home after Warriors game
        ("trip_past_7",  "place_home",        "place_oracle_park",       "standard",     7,  .tripCompleted, 7,  17),  // Heading to Giants game
        ("trip_past_8",  "place_oracle_park", "place_home",              "xl",    8,  .tripCompleted, 7,  22),  // Home after Giants game (same day)
        ("trip_past_9",  "place_caltrain",    "place_work",              "green", 9,  .tripCompleted, 8,   9),  // Morning Caltrain to work
        ("trip_past_10", "place_downtown",    "place_fishermans_wharf",  "comfort",  10,  .tripCompleted, 9,  13),  // Weekend Fisherman's Wharf
        ("trip_past_11", "place_haight",      "place_mission",           "standard",    11,  .canceled,     10,  15),  // Canceled Haight to Mission
        ("trip_past_12", "place_home",        "place_airport",           "black",     0,  .tripCompleted, 11,  6),  // Early morning Black to SFO
        ("trip_past_13", "place_airport",     "place_downtown",          "standard",     1,  .tripCompleted, 13, 20),  // Evening arrival from SFO
        ("trip_past_14", "place_soma",        "place_home",              "comfort",   2,  .tripCompleted, 14, 23),  // Late night SoMa to home

        // ── Expanded history (days 15-95) — going back to early December 2025 ──

        // Week 3 (mid Feb)
        ("trip_past_15", "place_home",        "place_work",              "standard",     3,  .tripCompleted, 16,  8),  // Monday morning commute
        ("trip_past_16", "place_work",        "place_home",              "standard",    12,  .tripCompleted, 16, 18),  // Same day evening commute home
        ("trip_past_17", "place_home",        "place_marina",            "comfort",  13,  .tripCompleted, 18, 20),  // Friday dinner in Marina
        ("trip_past_18", "place_marina",      "place_home",              "standard",    14,  .tripCompleted, 18, 23),  // Late return from Marina dinner

        // Week 4 (early-mid Feb)
        ("trip_past_19", "place_home",        "place_hayes_valley",      "standard",    15,  .tripCompleted, 21, 11),  // Saturday brunch Hayes Valley
        ("trip_past_20", "place_hayes_valley","place_home",              "standard",     4,  .tripCompleted, 21, 14),  // Return from brunch
        ("trip_past_21", "place_work",        "place_mission_bay",       "green", 5,  .tripCompleted, 23, 12),  // Midday to Mission Bay office
        ("trip_past_22", "place_home",        "place_work",              "standard",    16,  .tripCompleted, 24,  8),  // Morning commute
        ("trip_past_23", "place_work",        "place_home",              "comfort",  17,  .tripCompleted, 24, 19),  // Evening commute Comfort

        // Week 5 (late Jan / early Feb)
        ("trip_past_24", "place_home",        "place_nob_hill",          "standard",     6,  .tripCompleted, 28, 19),  // Dinner at Nob Hill restaurant
        ("trip_past_25", "place_nob_hill",    "place_home",              "comfort",   7,  .tripCompleted, 28, 22),  // Return from Nob Hill
        ("trip_past_26", "place_home",        "place_airport",           "standard",    18,  .tripCompleted, 30,  5),  // Early morning SFO run (airline flight)
        ("trip_past_27", "place_airport",     "place_home",              "xl",    8,  .tripCompleted, 33, 22),  // Return from trip, late arrival

        // Week 6-7 (mid-late Jan)
        ("trip_past_28", "place_home",        "place_work",              "standard",     9,  .tripCompleted, 35,  8),  // Morning commute
        ("trip_past_29", "place_work",        "place_castro",            "standard",    19,  .tripCompleted, 36, 19),  // Friday evening Castro
        ("trip_past_30", "place_castro",      "place_home",              "standard",    10,  .tripCompleted, 36, 23),  // Late night from Castro
        ("trip_past_31", "place_home",        "place_pac_heights",       "comfort",  20,  .tripCompleted, 38, 11),  // Weekend visit Pacific Heights
        ("trip_past_32", "place_pac_heights", "place_home",              "standard",    11,  .tripCompleted, 38, 15),  // Return from Pac Heights
        ("trip_past_33", "place_home",        "place_dogpatch",          "standard",    12,  .canceled,      40, 12),  // Canceled ride to Dogpatch

        // Week 8 (early Jan)
        ("trip_past_34", "place_home",        "place_work",              "standard",    13,  .tripCompleted, 44,  8),  // Monday commute
        ("trip_past_35", "place_work",        "place_home",              "standard",    14,  .tripCompleted, 44, 18),  // Evening commute
        ("trip_past_36", "place_home",        "place_inner_sunset",      "xl",   15,  .tripCompleted, 45, 10),  // Weekend errand Inner Sunset
        ("trip_past_37", "place_inner_sunset","place_home",              "standard",    16,  .tripCompleted, 45, 13),  // Return from Inner Sunset

        // Week 9-10 (late Dec / New Year)
        ("trip_past_38", "place_home",        "place_marina",            "black",    17,  .tripCompleted, 50, 20),  // New Year's Eve dinner (Black car)
        ("trip_past_39", "place_marina",      "place_home",              "black",    17,  .tripCompleted, 50, 24),  // NYE return (Black car, after midnight)
        ("trip_past_40", "place_home",        "place_mission",           "standard",    18,  .tripCompleted, 52, 19),  // Friday night Mission bar hop
        ("trip_past_41", "place_mission",     "place_home",              "standard",    19,  .tripCompleted, 52, 23),  // Late return from Mission

        // Week 10-11 (mid Dec)
        ("trip_past_42", "place_home",        "place_airport",           "comfort",  20,  .tripCompleted, 58,  7),  // Airport run for holiday travel
        ("trip_past_43", "place_airport",     "place_home",              "standard",     0,  .tripCompleted, 63, 21),  // Return from holiday trip
        ("trip_past_44", "place_home",        "place_work",              "standard",     1,  .tripCompleted, 65,  8),  // Back to work commute
        ("trip_past_45", "place_work",        "place_lower_haight",      "standard",     2,  .tripCompleted, 65, 18),  // Happy hour Lower Haight
        ("trip_past_46", "place_lower_haight","place_home",              "standard",     3,  .tripCompleted, 65, 21),  // Return from happy hour
        ("trip_past_47", "place_home",        "place_noe_valley",        "standard",     4,  .tripCompleted, 67, 10),  // Weekend Noe Valley farmers market
        ("trip_past_48", "place_noe_valley",  "place_home",              "standard",     5,  .tripCompleted, 67, 12),  // Return from farmers market

        // Week 12 (early Dec 2025)
        ("trip_past_49", "place_home",        "place_work",              "standard",     6,  .tripCompleted, 72,  8),  // Morning commute
        ("trip_past_50", "place_work",        "place_home",              "comfort",   7,  .tripCompleted, 72, 19),  // Evening commute
        ("trip_past_51", "place_home",        "place_potrero",           "standard",     8,  .tripCompleted, 74, 10),  // Saturday errand Potrero Hill
        ("trip_past_52", "place_potrero",     "place_home",              "standard",     9,  .tripCompleted, 74, 12),  // Return from Potrero
        ("trip_past_53", "place_home",        "place_japantown",         "standard",    10,  .tripCompleted, 76, 12),  // Lunch in Japantown
        ("trip_past_54", "place_japantown",   "place_home",              "standard",    11,  .tripCompleted, 76, 15),  // Return from Japantown
        ("trip_past_55", "place_home",        "place_work",              "standard",    12,  .tripCompleted, 79,  9),  // Late start commute
        ("trip_past_56", "place_work",        "place_airport",           "standard",    13,  .tripCompleted, 79, 16),  // Straight from work to SFO
        ("trip_past_57", "place_airport",     "place_home",              "comfort",  14,  .tripCompleted, 82, 23),  // Late night arrival from SFO

        // Oldest trips (late Nov / very early Dec)
        ("trip_past_58", "place_home",        "place_work",              "standard",    15,  .tripCompleted, 86,  8),  // Commute
        ("trip_past_59", "place_work",        "place_home",              "standard",    16,  .tripCompleted, 86, 18),  // Commute home
        ("trip_past_60", "place_home",        "place_nob_hill",          "black",    17,  .tripCompleted, 88, 19),  // Black car to fancy dinner
        ("trip_past_61", "place_nob_hill",    "place_home",              "black",    17,  .tripCompleted, 88, 23),  // Black car home after dinner
        ("trip_past_62", "place_home",        "place_mission",           "standard",    18,  .canceled,      90, 20),  // Canceled (changed plans)
        ("trip_past_63", "place_home",        "place_work",              "standard",    19,  .tripCompleted, 93,  8),  // Early Dec commute
        ("trip_past_64", "place_work",        "place_home",              "standard",    20,  .tripCompleted, 93, 18),  // Early Dec commute home
        ("trip_past_65", "place_home",        "place_golden_gate",       "xl",    0,  .tripCompleted, 95, 10),  // Weekend Golden Gate Park outing

        // ── Additional trips using new locations and filling gaps ──

        // Russian Hill dinner (mid Feb)
        ("trip_past_66", "place_home",        "place_russian_hill",      "standard",     1,  .tripCompleted, 15, 19),  // Friday dinner on Russian Hill
        ("trip_past_67", "place_russian_hill", "place_home",             "standard",     2,  .tripCompleted, 15, 22),  // Return from Russian Hill

        // Doctor's appointment at UCSF (late Jan)
        ("trip_past_68", "place_home",        "place_ucsf",             "standard",     3,  .tripCompleted, 20,  9),  // Morning appointment
        ("trip_past_69", "place_ucsf",        "place_home",             "standard",     4,  .tripCompleted, 20, 11),  // Return from doctor

        // Lunch at Embarcadero (early Feb)
        ("trip_past_70", "place_work",        "place_embarcadero",      "green", 5,  .tripCompleted, 25, 12),  // Quick lunch by the water
        ("trip_past_71", "place_embarcadero", "place_work",             "green", 6,  .tripCompleted, 25, 13),  // Back to office

        // Weekend trip to Treasure Island (late Jan)
        ("trip_past_72", "place_home",        "place_treasure_island",  "xl",    7,  .tripCompleted, 32, 14),  // Afternoon at Treasure Island
        ("trip_past_73", "place_treasure_island","place_home",           "xl",    8,  .tripCompleted, 32, 17),  // Return at sunset

        // Conference at Moscone (mid Jan)
        ("trip_past_74", "place_home",        "place_convention",       "comfort",   9,  .tripCompleted, 42,  8),  // Morning conference
        ("trip_past_75", "place_convention",  "place_home",             "standard",    10,  .tripCompleted, 42, 17)   // End of conference
    ]

    private static func pickupNoteFor(placeId: String, index: Int) -> String {
        let notes: [String]
        switch placeId {
        case "place_home":
            notes = ["Front door — 410 Brannan", "", "Brannan St entrance", "Unit 4B — text on arrival"]
        case "place_work":
            notes = ["Lobby at 201 Mission", "Side entrance — Fremont St", ""]
        case "place_airport":
            notes = ["Arrivals Level 1 — curbside", "Terminal 2 rideshare zone", "International Terminal pickup"]
        case "place_downtown":
            notes = ["Corner of Powell & Geary", "Outside Westfield Centre", ""]
        case "place_mission":
            notes = ["Near BART — 16th St exit", "Outside Dolores Park on 18th", ""]
        case "place_chase":
            notes = ["Gate A — Warriors Way", "Lot A rideshare zone"]
        case "place_oracle_park":
            notes = ["Willie Mays Plaza", "Lot A near King St"]
        case "place_marina":
            notes = ["Chestnut & Fillmore corner", ""]
        case "place_nob_hill":
            notes = ["Front of the Fairmont", "California & Powell cable car stop"]
        case "place_castro":
            notes = ["18th & Castro — near the theatre", ""]
        case "place_north_beach":
            notes = ["Columbus & Broadway corner", ""]
        case "place_soma":
            notes = ["Folsom & 6th — outside the bar", ""]
        case "place_haight":
            notes = ["In front of Amoeba Music", ""]
        case "place_caltrain":
            notes = ["4th & King platform exit", ""]
        case "place_ferry":
            notes = ["Main entrance — The Embarcadero side", ""]
        case "place_hayes_valley":
            notes = ["Hayes & Octavia — near the park", ""]
        case "place_pac_heights":
            notes = ["Fillmore & Sacramento corner", ""]
        case "place_noe_valley":
            notes = ["24th & Church — near the cafe", ""]
        case "place_lower_haight":
            notes = ["Haight & Fillmore — the pub side", ""]
        case "place_inner_sunset":
            notes = ["9th & Irving — near the bookshop", ""]
        case "place_potrero":
            notes = ["18th & Connecticut — near the brewery", ""]
        case "place_dogpatch":
            notes = ["3rd St & 22nd — outside the warehouse", ""]
        case "place_japantown":
            notes = ["Japan Center — Peace Plaza entrance", ""]
        case "place_convention":
            notes = ["Moscone Center — Howard St entrance", ""]
        case "place_russian_hill":
            notes = ["Hyde & Lombard — top of the crooked street", ""]
        case "place_embarcadero":
            notes = ["Embarcadero & Folsom — waterfront side", ""]
        case "place_ucsf":
            notes = ["Main entrance — 505 Parnassus", "Lot 2 rideshare pickup"]
        case "place_treasure_island":
            notes = ["Main gate — Avenue of the Palms", ""]
        default:
            notes = [""]
        }
        return notes[index % notes.count]
    }

    private static func dropoffNoteFor(placeId: String, index: Int) -> String {
        let notes: [String]
        switch placeId {
        case "place_home":
            notes = ["410 Brannan — front door", "", "Drop at the corner of Brannan & 3rd"]
        case "place_work":
            notes = ["201 Mission — lobby entrance", ""]
        case "place_airport":
            notes = ["Terminal 2 departures — Delta", "Domestic departures Level 3", "International departures"]
        case "place_downtown":
            notes = ["Union Square area", ""]
        case "place_pier39":
            notes = ["Entrance by the sea lions", ""]
        case "place_mission":
            notes = ["Dolores Park — south entrance", ""]
        case "place_oracle_park":
            notes = ["Willie Mays Plaza entrance", ""]
        case "place_north_beach":
            notes = ["Columbus Ave — near Tony's Pizza", ""]
        case "place_fishermans_wharf":
            notes = ["Jefferson St — near the crab stands", ""]
        case "place_marina":
            notes = ["Chestnut St — restaurant row", ""]
        case "place_nob_hill":
            notes = ["California & Powell", "Top of the Mark entrance"]
        case "place_castro":
            notes = ["The bar on the corner of 18th", ""]
        case "place_golden_gate":
            notes = ["Stanyan St — park main entrance", ""]
        case "place_inner_sunset":
            notes = ["9th & Irving", ""]
        case "place_noe_valley":
            notes = ["24th & Church — farmers market side", ""]
        case "place_lower_haight":
            notes = ["The pub on Haight & Fillmore", ""]
        case "place_japantown":
            notes = ["Japan Center — Peace Plaza", ""]
        case "place_dogpatch":
            notes = ["Near the brewery on 3rd", ""]
        case "place_potrero":
            notes = ["18th & Connecticut", ""]
        case "place_pac_heights":
            notes = ["Fillmore & Sacramento", ""]
        case "place_hayes_valley":
            notes = ["Hayes & Octavia", ""]
        case "place_convention":
            notes = ["Moscone Center — registration entrance", ""]
        case "place_mission_bay":
            notes = ["4th & Channel — UCSF campus side", ""]
        case "place_russian_hill":
            notes = ["Hyde & Lombard — crooked block", ""]
        case "place_embarcadero":
            notes = ["Embarcadero waterfront", ""]
        case "place_ucsf":
            notes = ["Main lobby — 505 Parnassus", ""]
        case "place_treasure_island":
            notes = ["Main gate", ""]
        default:
            notes = [""]
        }
        return notes[index % notes.count]
    }

    private static func seededPastTrips(now: Date) -> [Trip] {
        return pastTripTemplates.compactMap { template in
            let (tripId, pickupId, destinationId, rideTypeId, driverIdx, tripStatus, daysAgo, hourOfDay) = template
            let pickup = place(withID: pickupId)
            let destination = place(withID: destinationId)
            guard let pickup, let destination else { return nil }

            let option = routeEstimates(pickup: pickup, destination: destination)
                .first(where: { $0.rideTypeId == rideTypeId }) ?? routeEstimates(pickup: pickup, destination: destination).first
            guard let option else { return nil }

            let assignment = nextDriverVehicle(index: driverIdx)

            // Build a realistic dropoff time: daysAgo days before now, at the specified hour
            let dayOffset = Double(-daysAgo) * 86400
            let hourOffset = Double(hourOfDay - 12) * 3600  // seedReferenceDate is at noon UTC
            let dropoff = now.addingTimeInterval(dayOffset + hourOffset)

            let pickupTime = tripStatus == .tripCompleted ? dropoff.addingTimeInterval(Double(-option.etaMinutes - 14) * 60) : nil
            let requestedAt = (pickupTime ?? dropoff.addingTimeInterval(-6 * 60)).addingTimeInterval(-8 * 60)

            // Rotate payment methods with realistic distribution
            let paymentMethodId: String
            switch driverIdx % 8 {
            case 0, 1, 2, 7: paymentMethodId = "pm_visa_6645"
            case 3, 4:       paymentMethodId = "pm_visa_2095"
            case 5:          paymentMethodId = "pm_venmo"
            default:         paymentMethodId = "pm_applepay"
            }

            return Trip(
                id: tripId,
                pickupName: option.pickupName,
                destinationName: option.destinationName,
                rideType: option.rideType,
                rideTypeId: option.rideTypeId,
                etaMinutes: option.etaMinutes,
                estimatedPrice: option.estimatedPrice,
                currency: option.currency,
                routeLabel: option.routeLabel,
                tripStatus: tripStatus,
                requestedAt: requestedAt,
                reservedFor: nil,
                pickupTime: pickupTime,
                dropoffTime: dropoff,
                paymentMethodId: paymentMethodId,
                sourceType: .seeded,
                driver: assignment.0,
                vehicle: assignment.1,
                pickupNotes: tripStatus == .canceled ? "" : pickupNoteFor(placeId: pickupId, index: driverIdx),
                dropoffNotes: tripStatus == .canceled ? "" : dropoffNoteFor(placeId: destinationId, index: driverIdx)
            )
        }
    }
}
