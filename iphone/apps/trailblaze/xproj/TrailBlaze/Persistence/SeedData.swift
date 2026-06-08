import Foundation

enum SeedData {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        return calendar
    }()

    private static let anchorDate = Date()

    static func makeSeededData() -> SimulationData {
        let athletes = makeAthletes()
        let routes = makeRoutes()
        let segments = makeSegments()
        let activities = makeActivities(routes: routes, segments: segments)
        let clubs = makeClubs(athletes: athletes, activities: activities)
        let notifications = makeNotifications()
        let challenges = makeChallenges()

        return SimulationData(
            metadata: ActivitySnapshotMetadata(
                id: "metadata_seeded",
                name: "Default Activity Data",
                generatedAt: anchorDate,
                sourceType: "seeded",
                version: "1.0",
                lastUpdated: anchorDate,
                activityCount: activities.count,
                athleteCount: athletes.count
            ),
            currentUserAthleteId: "athlete_001",
            athletes: athletes,
            activities: activities,
            routes: routes,
            segments: segments,
            clubs: clubs,
            notifications: notifications,
            challenges: challenges
        )
    }

    static func mergedSnapshot(_ snapshot: ActivitySnapshot, fallback: SimulationData) -> SimulationData {
        SimulationData(
            metadata: snapshot.metadata,
            currentUserAthleteId: snapshot.currentUserAthleteId ?? fallback.currentUserAthleteId,
            athletes: snapshot.athletes,
            activities: snapshot.activities.sorted(by: { $0.startTime > $1.startTime }),
            routes: snapshot.routes,
            segments: snapshot.segments,
            clubs: snapshot.clubs ?? fallback.clubs,
            notifications: snapshot.notifications ?? fallback.notifications,
            challenges: snapshot.challenges ?? fallback.challenges
        )
    }

    private static func makeAthletes() -> [Athlete] {
        [
            Athlete(
                id: "athlete_001",
                name: "Jordan Avery",
                handle: "@jordanavery",
                city: BenchmarkLocation.city,
                bio: "Early starts in the Presidio, route scouting, and consistent mileage around the city.",
                followingCount: 188,
                followerCount: 251,
                achievements: ["10 Week Streak", "Local Legend", "2026 Climbing Goal"],
                personalRecords: ["5K 19:42", "10K 42:18", "Half Marathon 1:35:12"],
                isCurrentUser: true
            ),
            Athlete(
                id: "athlete_002",
                name: "Ava Torres",
                handle: "@ava_torres",
                city: "San Francisco, CA",
                bio: "Hill repeats, trail detours, and coffee-fueled long runs.",
                followingCount: 214,
                followerCount: 324,
                achievements: ["QOM Collector", "50K Finisher"],
                personalRecords: ["10K 41:55", "10 Mile 1:10:03"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_003",
                name: "Miles Chen",
                handle: "@mileschen",
                city: "San Francisco, CA",
                bio: "Fast group rides, headlands rollers, and post-ride pastry stops.",
                followingCount: 150,
                followerCount: 286,
                achievements: ["Century Ride", "Gran Fondo Silver"],
                personalRecords: ["40K TT 58:44", "Hawk Hill 15:21"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_004",
                name: "Priya Kapoor",
                handle: "@priyaonpace",
                city: "San Francisco, CA",
                bio: "Training for a spring marathon with a soft spot for tempo days and bridge views.",
                followingCount: 139,
                followerCount: 214,
                achievements: ["Spring Marathon", "Consistency King"],
                personalRecords: ["5K 20:11", "Marathon 3:18:50"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_005",
                name: "Luca Marino",
                handle: "@luca_rolls",
                city: "Oakland, CA",
                bio: "Road cyclist, gravel dabbler, and weekday commuter with a weakness for long coastal pulls.",
                followingCount: 108,
                followerCount: 171,
                achievements: ["Everesting Attempt", "Gran Fondo Gold"],
                personalRecords: ["20 Minute Power 312W", "Conzelman 17:48"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_006",
                name: "Elena Brooks",
                handle: "@elenabrooks",
                city: "San Francisco, CA",
                bio: "Sunrise walker turned hiker and route saver across the west side and waterfront.",
                followingCount: 91,
                followerCount: 122,
                achievements: ["Weekend Explorer", "30 Day Move Goal"],
                personalRecords: ["Coastal Trail Loop 1:09:14"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_007",
                name: "Leo Chen",
                handle: "@leochen",
                city: "San Francisco, CA",
                bio: "Fast finisher, even faster with route planning.",
                followingCount: 142,
                followerCount: 198,
                achievements: ["Sub-20 5K", "Segment Sniper"],
                personalRecords: ["5K 19:32", "10K 41:10"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_008",
                name: "Theo Nguyen",
                handle: "@theonguyen",
                city: "San Francisco, CA",
                bio: "Red-eye flights, sunrise runs.",
                followingCount: 95,
                followerCount: 167,
                achievements: ["Globe Trotter", "Early Bird Badge"],
                personalRecords: ["Half Marathon 1:28:44", "10K 43:05"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_009",
                name: "Diego Alvarez",
                handle: "@diegoalvarez",
                city: "San Francisco, CA",
                bio: "Playlists for every pace.",
                followingCount: 210,
                followerCount: 183,
                achievements: ["Monthly Century", "Social Butterfly", "100 Kudos Given"],
                personalRecords: ["5K 21:15", "Marathon 3:42:18"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_010",
                name: "Imani Brooks",
                handle: "@imanibrooks",
                city: "San Francisco, CA",
                bio: "Track intervals and trail repeats.",
                followingCount: 78,
                followerCount: 134,
                achievements: ["Track Tuesday Regular", "Trail Explorer"],
                personalRecords: ["800m 2:14", "5K 20:48"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_011",
                name: "Nora Bennett",
                handle: "@norabennett",
                city: "San Francisco, CA",
                bio: "TrailBlaze segments are just QA for legs.",
                followingCount: 156,
                followerCount: 201,
                achievements: ["Segment Hunter", "50 Mile Week", "Local Legend"],
                personalRecords: ["10K 39:55", "Half Marathon 1:26:30"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_012",
                name: "Arnav Srikanth",
                handle: "@arnavsrikanth",
                city: "San Francisco, CA",
                bio: "Trail runner, podcast pacer.",
                followingCount: 124,
                followerCount: 89,
                achievements: ["Trail 50K Finisher", "Podcast Mile Club"],
                personalRecords: ["50K 5:12:33", "Half Marathon 1:38:20"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_013",
                name: "Ravi Krishnan",
                handle: "@ravikrishnan",
                city: "San Jose, CA",
                bio: "Cricket intervals and hill repeats.",
                followingCount: 88,
                followerCount: 110,
                achievements: ["Hill Crusher", "Consistency King"],
                personalRecords: ["5K 22:04", "10K 46:18"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_014",
                name: "Finn O'Brien",
                handle: "@finnobrien",
                city: "Portland, OR",
                bio: "Wet roads, headwinds, no complaints.",
                followingCount: 245,
                followerCount: 312,
                achievements: ["Rain or Shine", "Year-Round Rider", "Century Ride"],
                personalRecords: ["40K TT 56:12", "Metric Century 2:48:30"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_015",
                name: "Yuna Park",
                handle: "@yunapark",
                city: "San Francisco, CA",
                bio: "Tempo queen and yoga convert.",
                followingCount: 176,
                followerCount: 228,
                achievements: ["Tempo Tuesday Streak", "Flexibility Goal"],
                personalRecords: ["5K 19:44", "10K 40:52", "Half Marathon 1:30:10"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_016",
                name: "Darius Cole",
                handle: "@dariuscole",
                city: "Oakland, CA",
                bio: "Gravel everything.",
                followingCount: 133,
                followerCount: 167,
                achievements: ["Gravel Century", "Dirty Dozen"],
                personalRecords: ["Gravel 100K 3:44:50", "Hawk Hill 16:02"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_017",
                name: "Maren Lund",
                handle: "@marenlund",
                city: "Seattle, WA",
                bio: "Nordic loops and coffee stops.",
                followingCount: 98,
                followerCount: 145,
                achievements: ["Winter Warrior", "Coffee Run Streak"],
                personalRecords: ["10K 44:30", "Half Marathon 1:37:55"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_018",
                name: "Sienna Voss",
                handle: "@siennavoss",
                city: "San Francisco, CA",
                bio: "Triathlon in progress.",
                followingCount: 212,
                followerCount: 276,
                achievements: ["Sprint Tri Finisher", "Olympic Tri Finisher", "Brick Day Survivor"],
                personalRecords: ["5K 21:00", "40K Bike 1:02:15"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_019",
                name: "Kenji Sato",
                handle: "@kenjisato",
                city: "San Francisco, CA",
                bio: "Zwift racer, outdoor daydreamer.",
                followingCount: 67,
                followerCount: 94,
                achievements: ["Zwift Cat B", "Virtual Century"],
                personalRecords: ["20 Minute Power 298W", "Alpe du Zwift 52:10"],
                isCurrentUser: false
            ),
            Athlete(
                id: "athlete_020",
                name: "Ingrid Holm",
                handle: "@ingridholm",
                city: "Boulder, CO",
                bio: "Ski season is base training.",
                followingCount: 155,
                followerCount: 189,
                achievements: ["Altitude Acclimated", "Vertical Mile"],
                personalRecords: ["Half Marathon 1:31:40", "10K 42:22"],
                isCurrentUser: false
            )
        ]
    }

    private static func makeRoutes() -> [Route] {
        [
            route(
                id: "route_001",
                name: "Presidio Tempo Loop",
                distanceKilometers: 10.2,
                elevationGainMeters: 148,
                estimatedTimeSeconds: 3120,
                popularityScore: 94,
                startLocation: "Crissy Field",
                segmentIds: ["segment_001", "segment_002"],
                recommendedActivityType: .run,
                isSaved: true,
                isBookmarked: true,
                path: [
                    (37.8040, -122.4640), (37.8035, -122.4615), (37.8025, -122.4590),
                    (37.8012, -122.4560), (37.7998, -122.4530), (37.7990, -122.4500),
                    (37.7995, -122.4468), (37.8010, -122.4445), (37.8030, -122.4438),
                    (37.8052, -122.4442), (37.8070, -122.4460), (37.8082, -122.4490),
                    (37.8090, -122.4525), (37.8093, -122.4558), (37.8088, -122.4590),
                    (37.8078, -122.4618), (37.8060, -122.4638), (37.8045, -122.4642)
                ],
                elevation: [18, 20, 28, 38, 52, 61, 70, 74, 68, 55, 45, 38, 33, 28, 24, 21, 19, 18]
            ),
            route(
                id: "route_002",
                name: "Golden Gate Coastal Ride",
                distanceKilometers: 42.5,
                elevationGainMeters: 612,
                estimatedTimeSeconds: 5820,
                popularityScore: 96,
                startLocation: "Ferry Building",
                segmentIds: ["segment_003"],
                recommendedActivityType: .ride,
                isSaved: true,
                isBookmarked: false,
                path: [
                    (37.7955, -122.3935), (37.7968, -122.3980), (37.7980, -122.4040),
                    (37.7995, -122.4100), (37.8015, -122.4170), (37.8040, -122.4260),
                    (37.8060, -122.4350), (37.8075, -122.4440), (37.8085, -122.4520),
                    (37.8080, -122.4600), (37.8065, -122.4660), (37.8070, -122.4720),
                    (37.8100, -122.4770), (37.8150, -122.4790), (37.8200, -122.4800),
                    (37.8260, -122.4820), (37.8320, -122.4845), (37.8400, -122.4880),
                    (37.8500, -122.4920), (37.8600, -122.4960), (37.8700, -122.5000),
                    (37.8800, -122.5060)
                ],
                elevation: [8, 10, 12, 15, 18, 22, 28, 36, 44, 52, 60, 68, 78, 88, 96, 92, 84, 78, 73, 58, 44, 38]
            ),
            route(
                id: "route_003",
                name: "Twin Peaks Climb",
                distanceKilometers: 14.7,
                elevationGainMeters: 401,
                estimatedTimeSeconds: 4560,
                popularityScore: 88,
                startLocation: "Mission Dolores Park",
                segmentIds: ["segment_004"],
                recommendedActivityType: .run,
                isSaved: false,
                isBookmarked: true,
                path: [
                    (37.7610, -122.4260), (37.7595, -122.4285), (37.7575, -122.4310),
                    (37.7555, -122.4340), (37.7540, -122.4370), (37.7528, -122.4400),
                    (37.7518, -122.4430), (37.7520, -122.4460), (37.7530, -122.4490),
                    (37.7545, -122.4510), (37.7555, -122.4530), (37.7560, -122.4505),
                    (37.7565, -122.4475), (37.7575, -122.4445), (37.7585, -122.4415),
                    (37.7595, -122.4380), (37.7600, -122.4345), (37.7608, -122.4310),
                    (37.7612, -122.4275)
                ],
                elevation: [21, 26, 32, 38, 45, 52, 62, 71, 80, 88, 90, 86, 78, 65, 52, 42, 35, 28, 24]
            ),
            route(
                id: "route_004",
                name: "Golden Gate Park Recovery Walk",
                distanceKilometers: 6.4,
                elevationGainMeters: 36,
                estimatedTimeSeconds: 4020,
                popularityScore: 84,
                startLocation: "Music Concourse",
                segmentIds: ["segment_005"],
                recommendedActivityType: .walk,
                isSaved: false,
                isBookmarked: false,
                path: [
                    (37.7702, -122.4862), (37.7698, -122.4830), (37.7695, -122.4795),
                    (37.7692, -122.4760), (37.7688, -122.4725), (37.7690, -122.4690),
                    (37.7695, -122.4655), (37.7700, -122.4620), (37.7705, -122.4590),
                    (37.7710, -122.4610), (37.7712, -122.4645), (37.7714, -122.4680),
                    (37.7716, -122.4720), (37.7714, -122.4755), (37.7712, -122.4790),
                    (37.7708, -122.4830), (37.7705, -122.4860)
                ],
                elevation: [9, 10, 10, 11, 12, 13, 13, 14, 14, 13, 12, 12, 11, 11, 10, 10, 9]
            ),
            route(
                id: "route_005",
                name: "Sunset to Hawk Hill Ride",
                distanceKilometers: 36.1,
                elevationGainMeters: 698,
                estimatedTimeSeconds: 6900,
                popularityScore: 91,
                startLocation: "Marina Green",
                segmentIds: ["segment_006"],
                recommendedActivityType: .ride,
                isSaved: true,
                isBookmarked: true,
                path: [
                    (37.8068, -122.4385), (37.8072, -122.4430), (37.8075, -122.4480),
                    (37.8074, -122.4530), (37.8070, -122.4575), (37.8065, -122.4620),
                    (37.8072, -122.4665), (37.8090, -122.4710), (37.8110, -122.4745),
                    (37.8140, -122.4772), (37.8175, -122.4790), (37.8220, -122.4810),
                    (37.8265, -122.4830), (37.8310, -122.4848), (37.8360, -122.4875),
                    (37.8410, -122.4910), (37.8455, -122.4945), (37.8500, -122.4978),
                    (37.8540, -122.5010), (37.8575, -122.5035)
                ],
                elevation: [14, 18, 24, 30, 36, 43, 52, 60, 67, 75, 82, 91, 100, 108, 104, 97, 88, 80, 74, 71]
            ),
            route(
                id: "route_006",
                name: "Embarcadero Shakeout",
                distanceKilometers: 7.6,
                elevationGainMeters: 42,
                estimatedTimeSeconds: 2580,
                popularityScore: 79,
                startLocation: "Oracle Park",
                segmentIds: [],
                recommendedActivityType: .run,
                isSaved: false,
                isBookmarked: true,
                path: [
                    (37.7785, -122.3910), (37.7798, -122.3895), (37.7815, -122.3892),
                    (37.7835, -122.3895), (37.7858, -122.3905), (37.7880, -122.3920),
                    (37.7905, -122.3938), (37.7928, -122.3955), (37.7950, -122.3968),
                    (37.7968, -122.3960), (37.7975, -122.3940), (37.7965, -122.3918),
                    (37.7945, -122.3905), (37.7920, -122.3895), (37.7895, -122.3892),
                    (37.7865, -122.3893), (37.7838, -122.3895), (37.7812, -122.3898),
                    (37.7790, -122.3906)
                ],
                elevation: [6, 7, 8, 9, 10, 11, 12, 12, 11, 11, 10, 10, 9, 9, 8, 7, 7, 6, 6]
            )
        ]
    }

    private static func makeSegments() -> [Segment] {
        [
            segment(id: "segment_001", name: "Lincoln Climb", distance: 1.2, grade: 4.8, routeId: "route_001"),
            segment(id: "segment_002", name: "Presidio Descent", distance: 0.9, grade: -3.2, routeId: "route_001"),
            segment(id: "segment_003", name: "Bridge to Hawk Hill", distance: 3.8, grade: 5.4, routeId: "route_002"),
            segment(id: "segment_004", name: "Twin Peaks East Ramp", distance: 2.4, grade: 6.1, routeId: "route_003"),
            segment(id: "segment_005", name: "JFK Drive Kick", distance: 0.7, grade: 1.1, routeId: "route_004"),
            segment(id: "segment_006", name: "Conzelman Grind", distance: 4.3, grade: 6.0, routeId: "route_005")
        ]
    }

    private static func makeActivities(routes: [Route], segments: [Segment]) -> [Activity] {
        [
            activity(id: "activity_001", athleteId: "athlete_001", title: "Presidio Tempo Before Work", distance: 10.2, duration: 2894, elevation: 151, type: .run, daysAgo: 0, hour: 6, minute: 12, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 18, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 624, comments: [comment("comment_001", athlete: "athlete_002", text: "That climb looked smooth."), comment("comment_002", athlete: "athlete_004", text: "Strong close over the last mile.")]),
            activity(id: "activity_002", athleteId: "athlete_002", title: "Twin Peaks Sunrise Repeats", distance: 13.4, duration: 4320, elevation: 322, type: .run, daysAgo: 0, hour: 7, minute: 5, routeId: "route_003", segmentIds: ["segment_004"], kudos: 31, currentUserKudo: true, sourceType: .friend, clubId: "club_001", calories: 788, comments: [comment("comment_003", athlete: "athlete_001", text: "That climb looks rough."), comment("comment_004", athlete: "athlete_006", text: "Saving this route for next week.")]),
            activity(id: "activity_003", athleteId: "athlete_003", title: "Golden Gate Lunch Ride", distance: 42.5, duration: 5734, elevation: 618, type: .ride, daysAgo: 1, hour: 12, minute: 18, routeId: "route_002", segmentIds: ["segment_003"], kudos: 24, currentUserKudo: false, sourceType: .friend, clubId: "club_002", calories: 903, comments: [comment("comment_005", athlete: "athlete_005", text: "Tailwind on the return?")]),
            activity(id: "activity_004", athleteId: "athlete_004", title: "Embarcadero Progression Run", distance: 8.9, duration: 2410, elevation: 64, type: .run, daysAgo: 1, hour: 18, minute: 10, routeId: "route_006", segmentIds: [], kudos: 16, currentUserKudo: false, sourceType: .friend, clubId: "club_001", calories: 508, comments: []),
            activity(id: "activity_005", athleteId: "athlete_005", title: "Sunset to Hawk Hill Endurance Ride", distance: 46.1, duration: 7120, elevation: 721, type: .ride, daysAgo: 2, hour: 8, minute: 22, routeId: "route_005", segmentIds: ["segment_006"], kudos: 37, currentUserKudo: true, sourceType: .friend, clubId: "club_002", calories: 1156, comments: [comment("comment_006", athlete: "athlete_003", text: "Perfect weather window on the bridge.")]),
            activity(id: "activity_006", athleteId: "athlete_006", title: "Golden Gate Park Sunset Walk", distance: 6.4, duration: 4020, elevation: 37, type: .walk, daysAgo: 2, hour: 18, minute: 40, routeId: "route_004", segmentIds: ["segment_005"], kudos: 9, currentUserKudo: false, sourceType: .friend, clubId: "club_003", calories: 301, comments: [comment("comment_007", athlete: "athlete_001", text: "Perfect reset lap.")]),
            activity(id: "activity_007", athleteId: "athlete_001", title: "Embarcadero Shakeout", distance: 7.6, duration: 2572, elevation: 45, type: .run, daysAgo: 2, hour: 7, minute: 14, routeId: "route_006", segmentIds: [], kudos: 6, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 248, comments: []),
            activity(id: "activity_008", athleteId: "athlete_003", title: "Indoor Endurance Blocks", distance: 28.0, duration: 3360, elevation: 0, type: .indoorRide, daysAgo: 3, hour: 19, minute: 2, routeId: nil, segmentIds: [], kudos: 13, currentUserKudo: false, sourceType: .friend, clubId: "club_002", calories: 702, comments: [comment("comment_008", athlete: "athlete_001", text: "Trainer season continues.")]),
            activity(id: "activity_009", athleteId: "athlete_004", title: "Long Run Through the Presidio", distance: 18.1, duration: 5900, elevation: 211, type: .run, daysAgo: 5, hour: 6, minute: 32, routeId: "route_001", segmentIds: ["segment_001"], kudos: 28, currentUserKudo: true, sourceType: .friend, clubId: "club_001", calories: 981, comments: [comment("comment_009", athlete: "athlete_002", text: "Split finish is excellent.")]),
            activity(id: "activity_010", athleteId: "athlete_002", title: "Presidio Progression Run", distance: 9.4, duration: 2750, elevation: 133, type: .run, daysAgo: 4, hour: 17, minute: 48, routeId: "route_001", segmentIds: ["segment_001"], kudos: 19, currentUserKudo: false, sourceType: .friend, clubId: "club_001", calories: 562, comments: []),
            activity(id: "activity_011", athleteId: "athlete_005", title: "Morning Bridge Spin", distance: 24.2, duration: 3324, elevation: 174, type: .ride, daysAgo: 5, hour: 9, minute: 16, routeId: "route_002", segmentIds: ["segment_003"], kudos: 14, currentUserKudo: false, sourceType: .club, clubId: "club_002", calories: 661, comments: [comment("comment_010", athlete: "athlete_003", text: "Fast line through the bridge approach.")]),
            activity(id: "activity_012", athleteId: "athlete_001", title: "Twin Peaks Threshold Session", distance: 14.7, duration: 4540, elevation: 409, type: .run, daysAgo: 4, hour: 6, minute: 8, routeId: "route_003", segmentIds: ["segment_004"], kudos: 22, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 850, comments: [comment("comment_011", athlete: "athlete_004", text: "That route still bites back.")]),
            activity(id: "activity_013", athleteId: "athlete_006", title: "Lands End Overlook Hike", distance: 7.3, duration: 5120, elevation: 286, type: .hike, daysAgo: 6, hour: 10, minute: 27, routeId: nil, segmentIds: [], kudos: 11, currentUserKudo: false, sourceType: .club, clubId: "club_003", calories: 402, comments: []),
            activity(id: "activity_014", athleteId: "athlete_003", title: "Marin Headlands Endurance Day", distance: 54.8, duration: 9850, elevation: 1270, type: .ride, daysAgo: 7, hour: 8, minute: 2, routeId: "route_005", segmentIds: ["segment_006"], kudos: 41, currentUserKudo: true, sourceType: .friend, clubId: "club_002", calories: 1394, comments: [comment("comment_012", athlete: "athlete_001", text: "Huge day out there.")]),
            activity(id: "activity_015", athleteId: "athlete_002", title: "Recovery Jog with Strides", distance: 6.5, duration: 2320, elevation: 68, type: .run, daysAgo: 8, hour: 6, minute: 41, routeId: "route_006", segmentIds: [], kudos: 12, currentUserKudo: false, sourceType: .friend, clubId: "club_001", calories: 397, comments: []),
            activity(id: "activity_016", athleteId: "athlete_001", title: "Saturday Long Run - Crissy Field", distance: 21.1, duration: 6240, elevation: 178, type: .run, daysAgo: 3, hour: 7, minute: 0, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 34, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 1280, comments: [comment("comment_013", athlete: "athlete_002", text: "Half marathon distance! Strong effort."), comment("comment_014", athlete: "athlete_004", text: "That negative split though.")]),
            activity(id: "activity_017", athleteId: "athlete_005", title: "Gravel Adventure - Coastal Route", distance: 62.3, duration: 11400, elevation: 890, type: .ride, daysAgo: 3, hour: 8, minute: 30, routeId: nil, segmentIds: [], kudos: 44, currentUserKudo: true, sourceType: .friend, clubId: "club_002", calories: 1820, comments: [comment("comment_015", athlete: "athlete_003", text: "Epic. Where did you find that route?")]),
            activity(id: "activity_018", athleteId: "athlete_006", title: "Neighborhood Evening Walk", distance: 4.2, duration: 2700, elevation: 12, type: .walk, daysAgo: 1, hour: 19, minute: 30, routeId: nil, segmentIds: [], kudos: 5, currentUserKudo: false, sourceType: .club, clubId: "club_003", calories: 188, comments: []),
            activity(id: "activity_019", athleteId: "athlete_004", title: "Tempo Tuesday - Marathon Pace", distance: 16.5, duration: 4350, elevation: 94, type: .run, daysAgo: 3, hour: 5, minute: 45, routeId: "route_006", segmentIds: [], kudos: 26, currentUserKudo: true, sourceType: .friend, clubId: "club_001", calories: 920, comments: [comment("comment_016", athlete: "athlete_001", text: "Splits are dialed in.")]),
            activity(id: "activity_020", athleteId: "athlete_003", title: "Zwift Race - Crit City", distance: 32.0, duration: 2880, elevation: 0, type: .indoorRide, daysAgo: 1, hour: 20, minute: 0, routeId: nil, segmentIds: [], kudos: 17, currentUserKudo: false, sourceType: .friend, clubId: "club_002", calories: 580, comments: [comment("comment_017", athlete: "athlete_005", text: "What category?")]),

            // MARK: - Historical activities (days 9–90) — Jordan Avery's training log

            // Week ~2 ago (days 9–13)
            activity(id: "activity_021", athleteId: "athlete_001", title: "Embarcadero Recovery Jog", distance: 6.8, duration: 2448, elevation: 38, type: .run, daysAgo: 9, hour: 7, minute: 5, routeId: "route_006", segmentIds: [], kudos: 8, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 420, comments: []),
            activity(id: "activity_022", athleteId: "athlete_001", title: "Golden Gate Park Walk", distance: 5.1, duration: 3570, elevation: 28, type: .walk, daysAgo: 10, hour: 12, minute: 20, routeId: "route_004", segmentIds: [], kudos: 4, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 238, comments: []),
            activity(id: "activity_023", athleteId: "athlete_001", title: "Presidio Tempo Intervals", distance: 10.4, duration: 2980, elevation: 155, type: .run, daysAgo: 11, hour: 6, minute: 18, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 14, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 640, comments: [comment("comment_018", athlete: "athlete_004", text: "Solid tempo work.")]),
            activity(id: "activity_024", athleteId: "athlete_001", title: "Sunset District Ride", distance: 36.8, duration: 5280, elevation: 412, type: .ride, daysAgo: 12, hour: 9, minute: 0, routeId: "route_005", segmentIds: ["segment_006"], kudos: 11, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 880, comments: []),
            activity(id: "activity_025", athleteId: "athlete_001", title: "Twin Peaks Hill Repeats", distance: 12.3, duration: 3936, elevation: 378, type: .run, daysAgo: 13, hour: 6, minute: 30, routeId: "route_003", segmentIds: ["segment_004"], kudos: 10, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 752, comments: [comment("comment_019", athlete: "athlete_002", text: "Those repeats are no joke.")]),

            // Week ~3 ago (days 15–20)
            activity(id: "activity_026", athleteId: "athlete_001", title: "Easy Embarcadero Shakeout", distance: 7.2, duration: 2592, elevation: 40, type: .run, daysAgo: 15, hour: 6, minute: 45, routeId: "route_006", segmentIds: [], kudos: 5, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 444, comments: []),
            activity(id: "activity_027", athleteId: "athlete_001", title: "Lands End Trail Hike", distance: 9.6, duration: 6720, elevation: 324, type: .hike, daysAgo: 16, hour: 8, minute: 15, routeId: nil, segmentIds: [], kudos: 12, currentUserKudo: false, sourceType: .personal, clubId: "club_003", calories: 538, comments: [comment("comment_020", athlete: "athlete_006", text: "Love that overlook section.")]),
            activity(id: "activity_028", athleteId: "athlete_001", title: "Golden Gate Bridge & Back Ride", distance: 44.2, duration: 6364, elevation: 628, type: .ride, daysAgo: 17, hour: 8, minute: 30, routeId: "route_002", segmentIds: ["segment_003"], kudos: 15, currentUserKudo: false, sourceType: .personal, clubId: "club_002", calories: 952, comments: [comment("comment_021", athlete: "athlete_003", text: "Bridge winds were brutal today.")]),
            activity(id: "activity_029", athleteId: "athlete_001", title: "Presidio Steady State Run", distance: 10.0, duration: 2950, elevation: 148, type: .run, daysAgo: 18, hour: 6, minute: 22, routeId: "route_001", segmentIds: ["segment_001"], kudos: 9, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 612, comments: []),
            activity(id: "activity_030", athleteId: "athlete_001", title: "Saturday Long Run - Marina to Fort Point", distance: 18.6, duration: 5766, elevation: 186, type: .run, daysAgo: 20, hour: 7, minute: 0, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 15, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 1128, comments: [comment("comment_022", athlete: "athlete_004", text: "Strong long run. Negative split?")]),

            // Week ~4 ago (days 22–27)
            activity(id: "activity_031", athleteId: "athlete_001", title: "Recovery Walk Along Embarcadero", distance: 4.8, duration: 3360, elevation: 14, type: .walk, daysAgo: 22, hour: 12, minute: 10, routeId: nil, segmentIds: [], kudos: 3, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 210, comments: []),
            activity(id: "activity_032", athleteId: "athlete_001", title: "Embarcadero Tempo Run", distance: 8.2, duration: 2460, elevation: 48, type: .run, daysAgo: 23, hour: 6, minute: 35, routeId: "route_006", segmentIds: [], kudos: 7, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 502, comments: []),
            activity(id: "activity_033", athleteId: "athlete_001", title: "Hawk Hill Climb Ride", distance: 38.4, duration: 5760, elevation: 710, type: .ride, daysAgo: 24, hour: 9, minute: 10, routeId: "route_005", segmentIds: ["segment_006"], kudos: 13, currentUserKudo: false, sourceType: .personal, clubId: "club_002", calories: 924, comments: [comment("comment_023", athlete: "athlete_005", text: "Conzelman never gets easier.")]),
            activity(id: "activity_034", athleteId: "athlete_001", title: "Twin Peaks Progression Run", distance: 13.8, duration: 4416, elevation: 388, type: .run, daysAgo: 25, hour: 6, minute: 15, routeId: "route_003", segmentIds: ["segment_004"], kudos: 10, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 810, comments: []),
            activity(id: "activity_035", athleteId: "athlete_001", title: "Saturday Long Run - Presidio to Baker Beach", distance: 19.4, duration: 6208, elevation: 204, type: .run, daysAgo: 27, hour: 7, minute: 0, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 14, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 1180, comments: [comment("comment_024", athlete: "athlete_002", text: "Baker Beach finish is the best reward.")]),

            // Week ~5-6 ago (days 30–40)
            activity(id: "activity_036", athleteId: "athlete_001", title: "Golden Gate Park Recovery Walk", distance: 5.8, duration: 4060, elevation: 32, type: .walk, daysAgo: 30, hour: 11, minute: 45, routeId: "route_004", segmentIds: [], kudos: 4, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 268, comments: []),
            activity(id: "activity_037", athleteId: "athlete_001", title: "Presidio Base Run", distance: 9.8, duration: 3038, elevation: 145, type: .run, daysAgo: 32, hour: 6, minute: 40, routeId: "route_001", segmentIds: ["segment_001"], kudos: 6, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 598, comments: []),
            activity(id: "activity_038", athleteId: "athlete_001", title: "Coastal Trail Hike", distance: 11.2, duration: 7840, elevation: 418, type: .hike, daysAgo: 34, hour: 9, minute: 0, routeId: nil, segmentIds: [], kudos: 8, currentUserKudo: false, sourceType: .personal, clubId: "club_003", calories: 628, comments: [comment("comment_025", athlete: "athlete_006", text: "That elevation is legit.")]),
            activity(id: "activity_039", athleteId: "athlete_001", title: "Golden Gate Ride - Easy Spin", distance: 32.6, duration: 5058, elevation: 480, type: .ride, daysAgo: 35, hour: 8, minute: 45, routeId: "route_002", segmentIds: ["segment_003"], kudos: 9, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 788, comments: []),
            activity(id: "activity_040", athleteId: "athlete_001", title: "Embarcadero Easy Run", distance: 7.4, duration: 2738, elevation: 42, type: .run, daysAgo: 37, hour: 6, minute: 50, routeId: "route_006", segmentIds: [], kudos: 5, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 456, comments: []),
            activity(id: "activity_041", athleteId: "athlete_001", title: "Saturday Long Run - Panhandle to Ocean Beach", distance: 17.8, duration: 5874, elevation: 168, type: .run, daysAgo: 38, hour: 7, minute: 10, routeId: nil, segmentIds: [], kudos: 12, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 1082, comments: [comment("comment_026", athlete: "athlete_004", text: "Ocean Beach headwind is free speed work.")]),
            activity(id: "activity_042", athleteId: "athlete_001", title: "Zwift Recovery Spin", distance: 22.0, duration: 2640, elevation: 0, type: .indoorRide, daysAgo: 40, hour: 19, minute: 30, routeId: nil, segmentIds: [], kudos: 3, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 440, comments: []),

            // Week ~7-8 ago (days 44–55)
            activity(id: "activity_043", athleteId: "athlete_001", title: "Presidio Morning Run", distance: 10.0, duration: 3100, elevation: 150, type: .run, daysAgo: 44, hour: 6, minute: 30, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 7, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 610, comments: []),
            activity(id: "activity_044", athleteId: "athlete_001", title: "Sunset to Hawk Hill Endurance Ride", distance: 48.5, duration: 7275, elevation: 735, type: .ride, daysAgo: 45, hour: 8, minute: 15, routeId: "route_005", segmentIds: ["segment_006"], kudos: 11, currentUserKudo: false, sourceType: .personal, clubId: "club_002", calories: 1100, comments: [comment("comment_027", athlete: "athlete_003", text: "Solid climbing day.")]),
            activity(id: "activity_045", athleteId: "athlete_001", title: "Embarcadero Shakeout Jog", distance: 6.4, duration: 2432, elevation: 36, type: .run, daysAgo: 47, hour: 7, minute: 0, routeId: "route_006", segmentIds: [], kudos: 4, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 394, comments: []),
            activity(id: "activity_046", athleteId: "athlete_001", title: "Afternoon Walk - Fisherman's Wharf", distance: 3.8, duration: 2660, elevation: 18, type: .walk, daysAgo: 48, hour: 14, minute: 30, routeId: nil, segmentIds: [], kudos: 2, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 178, comments: []),
            activity(id: "activity_047", athleteId: "athlete_001", title: "Twin Peaks Threshold Run", distance: 13.2, duration: 4356, elevation: 390, type: .run, daysAgo: 50, hour: 6, minute: 20, routeId: "route_003", segmentIds: ["segment_004"], kudos: 9, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 796, comments: []),
            activity(id: "activity_048", athleteId: "athlete_001", title: "Saturday Long Run - Presidio Loop", distance: 16.8, duration: 5712, elevation: 192, type: .run, daysAgo: 52, hour: 7, minute: 0, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 11, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 1022, comments: [comment("comment_028", athlete: "athlete_002", text: "Building that base nicely.")]),
            activity(id: "activity_049", athleteId: "athlete_001", title: "Golden Gate Park Ride", distance: 28.4, duration: 4544, elevation: 348, type: .ride, daysAgo: 55, hour: 9, minute: 30, routeId: "route_002", segmentIds: ["segment_003"], kudos: 7, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 692, comments: []),

            // Week ~9-10 ago (days 58–68)
            activity(id: "activity_050", athleteId: "athlete_001", title: "Embarcadero Base Run", distance: 7.6, duration: 2888, elevation: 44, type: .run, daysAgo: 58, hour: 6, minute: 55, routeId: "route_006", segmentIds: [], kudos: 5, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 468, comments: []),
            activity(id: "activity_051", athleteId: "athlete_001", title: "Lands End Hike with Friends", distance: 8.8, duration: 6160, elevation: 298, type: .hike, daysAgo: 60, hour: 10, minute: 0, routeId: nil, segmentIds: [], kudos: 10, currentUserKudo: false, sourceType: .personal, clubId: "club_003", calories: 498, comments: [comment("comment_029", athlete: "athlete_006", text: "Great group out there today.")]),
            activity(id: "activity_052", athleteId: "athlete_001", title: "Presidio Easy Run", distance: 9.6, duration: 3168, elevation: 140, type: .run, daysAgo: 62, hour: 6, minute: 35, routeId: "route_001", segmentIds: ["segment_001"], kudos: 6, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 586, comments: []),
            activity(id: "activity_053", athleteId: "athlete_001", title: "Hawk Hill Ride", distance: 40.2, duration: 6432, elevation: 682, type: .ride, daysAgo: 64, hour: 8, minute: 30, routeId: "route_005", segmentIds: ["segment_006"], kudos: 8, currentUserKudo: false, sourceType: .personal, clubId: "club_002", calories: 960, comments: []),
            activity(id: "activity_054", athleteId: "athlete_001", title: "Saturday Long Run - Crissy Field Out & Back", distance: 15.4, duration: 5390, elevation: 124, type: .run, daysAgo: 66, hour: 7, minute: 15, routeId: "route_001", segmentIds: ["segment_001"], kudos: 9, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 940, comments: [comment("comment_030", athlete: "athlete_004", text: "Consistent pacing across the board.")]),
            activity(id: "activity_055", athleteId: "athlete_001", title: "Recovery Walk - Marina Green", distance: 4.2, duration: 2940, elevation: 10, type: .walk, daysAgo: 68, hour: 12, minute: 0, routeId: nil, segmentIds: [], kudos: 2, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 196, comments: []),

            // Week ~11-13 ago (days 72–90)
            activity(id: "activity_056", athleteId: "athlete_001", title: "Embarcadero Slow Jog", distance: 7.0, duration: 2870, elevation: 40, type: .run, daysAgo: 72, hour: 7, minute: 10, routeId: "route_006", segmentIds: [], kudos: 4, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 432, comments: []),
            activity(id: "activity_057", athleteId: "athlete_001", title: "Golden Gate Coastal Ride", distance: 42.8, duration: 6634, elevation: 620, type: .ride, daysAgo: 74, hour: 9, minute: 0, routeId: "route_002", segmentIds: ["segment_003"], kudos: 7, currentUserKudo: false, sourceType: .personal, clubId: "club_002", calories: 920, comments: [comment("comment_031", athlete: "athlete_005", text: "Welcome back to the saddle.")]),
            activity(id: "activity_058", athleteId: "athlete_001", title: "Twin Peaks Aerobic Run", distance: 12.8, duration: 4480, elevation: 372, type: .run, daysAgo: 76, hour: 6, minute: 45, routeId: "route_003", segmentIds: ["segment_004"], kudos: 6, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 778, comments: []),
            activity(id: "activity_059", athleteId: "athlete_001", title: "Coastal Trail Long Hike", distance: 13.4, duration: 9380, elevation: 486, type: .hike, daysAgo: 78, hour: 8, minute: 30, routeId: nil, segmentIds: [], kudos: 9, currentUserKudo: false, sourceType: .personal, clubId: "club_003", calories: 682, comments: [comment("comment_032", athlete: "athlete_006", text: "That's a proper adventure.")]),
            activity(id: "activity_060", athleteId: "athlete_001", title: "Presidio Base Building Run", distance: 9.4, duration: 3196, elevation: 138, type: .run, daysAgo: 80, hour: 7, minute: 0, routeId: "route_001", segmentIds: ["segment_001"], kudos: 5, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 574, comments: []),
            activity(id: "activity_061", athleteId: "athlete_001", title: "Saturday Base Run - Easy Miles", distance: 14.2, duration: 5112, elevation: 116, type: .run, daysAgo: 82, hour: 7, minute: 30, routeId: "route_001", segmentIds: ["segment_001", "segment_002"], kudos: 8, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 866, comments: []),
            activity(id: "activity_062", athleteId: "athlete_001", title: "Embarcadero Walk - Lunch Break", distance: 3.4, duration: 2380, elevation: 12, type: .walk, daysAgo: 84, hour: 12, minute: 30, routeId: nil, segmentIds: [], kudos: 2, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 158, comments: []),
            activity(id: "activity_063", athleteId: "athlete_001", title: "Golden Gate Park Ride", distance: 26.8, duration: 4288, elevation: 332, type: .ride, daysAgo: 86, hour: 10, minute: 0, routeId: "route_002", segmentIds: ["segment_003"], kudos: 6, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 648, comments: []),
            activity(id: "activity_064", athleteId: "athlete_001", title: "Presidio Getting Started Run", distance: 8.8, duration: 3168, elevation: 130, type: .run, daysAgo: 88, hour: 7, minute: 15, routeId: "route_001", segmentIds: ["segment_001"], kudos: 4, currentUserKudo: false, sourceType: .personal, clubId: "club_001", calories: 538, comments: [comment("comment_033", athlete: "athlete_002", text: "Good to see you out there.")]),
            activity(id: "activity_065", athleteId: "athlete_001", title: "First Ride of the Block", distance: 30.2, duration: 5134, elevation: 440, type: .ride, daysAgo: 90, hour: 9, minute: 30, routeId: "route_005", segmentIds: ["segment_006"], kudos: 5, currentUserKudo: false, sourceType: .personal, clubId: nil, calories: 728, comments: [])
        ]
        .sorted(by: { $0.startTime > $1.startTime })
    }

    private static func makeClubs(athletes: [Athlete], activities: [Activity]) -> [Club] {
        let athleteLookup = Dictionary(uniqueKeysWithValues: athletes.map { ($0.id, $0.name) })

        return [
            Club(
                id: "club_001",
                name: "Bay Tempo Collective",
                description: "Weekday tempo efforts, bridge views, and long-run accountability across the city.",
                memberCount: 164,
                members: [
                    ClubMember(id: "clubmember_001", athleteId: "athlete_001", weeklyDistanceKilometers: 32.5, isAdmin: false),
                    ClubMember(id: "clubmember_002", athleteId: "athlete_002", weeklyDistanceKilometers: 42.7, isAdmin: true),
                    ClubMember(id: "clubmember_003", athleteId: "athlete_004", weeklyDistanceKilometers: 51.8, isAdmin: false)
                ],
                weeklyLeaderboard: [
                    leaderboardEntry(id: "leaderboard_301", athleteId: "athlete_004", athleteName: athleteLookup["athlete_004"] ?? "Priya Kapoor", rank: 1, timeSeconds: 0, weeklyDistance: 51.8),
                    leaderboardEntry(id: "leaderboard_302", athleteId: "athlete_002", athleteName: athleteLookup["athlete_002"] ?? "Ava Torres", rank: 2, timeSeconds: 0, weeklyDistance: 42.7),
                    leaderboardEntry(id: "leaderboard_303", athleteId: "athlete_001", athleteName: athleteLookup["athlete_001"] ?? "Jordan Avery", rank: 3, timeSeconds: 0, weeklyDistance: 32.5)
                ],
                activityIds: activities.filter { $0.clubId == "club_001" }.map(\.id),
                isJoined: true
            ),
            Club(
                id: "club_002",
                name: "Bay Bridge Riders",
                description: "Bridge repeats, headlands rollers, and weekday coffee spins.",
                memberCount: 213,
                members: [
                    ClubMember(id: "clubmember_004", athleteId: "athlete_003", weeklyDistanceKilometers: 152.4, isAdmin: true),
                    ClubMember(id: "clubmember_005", athleteId: "athlete_005", weeklyDistanceKilometers: 118.7, isAdmin: false)
                ],
                weeklyLeaderboard: [
                    leaderboardEntry(id: "leaderboard_304", athleteId: "athlete_003", athleteName: athleteLookup["athlete_003"] ?? "Miles Chen", rank: 1, timeSeconds: 0, weeklyDistance: 152.4),
                    leaderboardEntry(id: "leaderboard_305", athleteId: "athlete_005", athleteName: athleteLookup["athlete_005"] ?? "Luca Marino", rank: 2, timeSeconds: 0, weeklyDistance: 118.7),
                    leaderboardEntry(id: "leaderboard_306", athleteId: "athlete_001", athleteName: athleteLookup["athlete_001"] ?? "Jordan Avery", rank: 3, timeSeconds: 0, weeklyDistance: 61.2)
                ],
                activityIds: activities.filter { $0.clubId == "club_002" }.map(\.id),
                isJoined: false
            ),
            Club(
                id: "club_003",
                name: "City Walk + Hike",
                description: "Recovery walks, overlook hikes, and easy weekend movement around the waterfront and west side.",
                memberCount: 92,
                members: [
                    ClubMember(id: "clubmember_006", athleteId: "athlete_006", weeklyDistanceKilometers: 26.8, isAdmin: true)
                ],
                weeklyLeaderboard: [
                    leaderboardEntry(id: "leaderboard_307", athleteId: "athlete_006", athleteName: athleteLookup["athlete_006"] ?? "Elena Brooks", rank: 1, timeSeconds: 0, weeklyDistance: 26.8),
                    leaderboardEntry(id: "leaderboard_308", athleteId: "athlete_001", athleteName: athleteLookup["athlete_001"] ?? "Jordan Avery", rank: 2, timeSeconds: 0, weeklyDistance: 11.6)
                ],
                activityIds: activities.filter { $0.clubId == "club_003" }.map(\.id),
                isJoined: false
            )
        ]
    }

    private static func makeNotifications() -> [Notification] {
        [
            Notification(id: "notification_001", kind: .kudos, title: "Ava gave you kudos", body: "Ava Torres gave kudos to Presidio Tempo Before Work.", createdAt: timestamp(daysAgo: 0, hour: 9, minute: 10), isRead: false, relatedActivityId: "activity_001", relatedClubId: nil),
            Notification(id: "notification_002", kind: .commentReply, title: "Priya replied to your activity", body: "Priya Kapoor: \"That route is a perfect threshold loop.\"", createdAt: timestamp(daysAgo: 1, hour: 12, minute: 4), isRead: false, relatedActivityId: "activity_012", relatedClubId: nil),
            Notification(id: "notification_003", kind: .challenge, title: "Challenge progress updated", body: "You are 60% of the way to the March Ten Days Active Challenge.", createdAt: timestamp(daysAgo: 1, hour: 8, minute: 0), isRead: true, relatedActivityId: nil, relatedClubId: nil),
            Notification(id: "notification_004", kind: .clubAnnouncement, title: "SF Tempo Collective posted", body: "Saturday long run starts at 7:00 AM from Crissy Field.", createdAt: timestamp(daysAgo: 2, hour: 18, minute: 18), isRead: true, relatedActivityId: nil, relatedClubId: "club_001"),
            Notification(id: "notification_005", kind: .weeklySummary, title: "Weekly training summary", body: "You logged 32.5 km across 3 activities this week.", createdAt: timestamp(daysAgo: 3, hour: 7, minute: 30), isRead: true, relatedActivityId: nil, relatedClubId: nil),
            Notification(id: "notification_006", kind: .clubAnnouncement, title: "Bay Bridge Riders opened signups", body: "Spring mileage challenge signups are open for this weekend's ride.", createdAt: timestamp(daysAgo: 4, hour: 16, minute: 44), isRead: true, relatedActivityId: nil, relatedClubId: "club_002")
        ]
    }

    private static func makeChallenges() -> [Challenge] {
        [
            Challenge(id: "challenge_001", title: "March Ten Days Active Challenge", subtitle: "Do 10 minutes of activity for 10 days this month", progress: 6, goal: 10, reward: "10x badge", isCompleted: false),
            Challenge(id: "challenge_002", title: "March 400-minute x Runna", subtitle: "Accumulate 400 minutes of running this month", progress: 148, goal: 400, reward: "Runna badge", isCompleted: false),
            Challenge(id: "challenge_003", title: "UltraSwim 33.3", subtitle: "Swim 33.3 miles virtually this month", progress: 9.8, goal: 33.3, reward: "Ultraswim badge", isCompleted: false)
        ]
    }

    private static func route(
        id: String,
        name: String,
        distanceKilometers: Double,
        elevationGainMeters: Double,
        estimatedTimeSeconds: Int,
        popularityScore: Int,
        startLocation: String,
        segmentIds: [String],
        recommendedActivityType: ActivityType,
        isSaved: Bool,
        isBookmarked: Bool,
        path: [(Double, Double)],
        elevation: [Double]
    ) -> Route {
        Route(
            id: id,
            name: name,
            distanceKilometers: distanceKilometers,
            elevationGainMeters: elevationGainMeters,
            estimatedTimeSeconds: estimatedTimeSeconds,
            popularityScore: popularityScore,
            startLocation: startLocation,
            points: path.enumerated().map { index, point in
                RoutePoint(id: "\(id)_point_\(index + 1)", latitude: point.0, longitude: point.1)
            },
            elevationProfile: elevation,
            segmentIds: segmentIds,
            isSaved: isSaved,
            isBookmarked: isBookmarked,
            recommendedActivityType: recommendedActivityType
        )
    }

    private static func segment(id: String, name: String, distance: Double, grade: Double, routeId: String) -> Segment {
        let leaderboardNames = [
            "Ava Torres", "Miles Chen", "Priya Kapoor", "Luca Marino", "Jordan Avery",
            "Elena Brooks", "Leo Chen", "Theo Nguyen", "Diego Alvarez", "Imani Brooks",
            "Nora Bennett", "Arnav Srikanth", "Ravi Krishnan", "Finn O'Brien", "Yuna Park",
            "Darius Cole", "Maren Lund", "Sienna Voss", "Kenji Sato", "Ingrid Holm"
        ]

        let baseTime = Int(distance * 210) + Int(max(grade, 0) * 22)

        let entries = leaderboardNames.enumerated().map { index, athleteName in
            LeaderboardEntry(
                id: "\(id)_entry_\(index + 1)",
                athleteId: "leader_\(index + 1)",
                athleteName: athleteName,
                timeSeconds: baseTime + (index * 9),
                rank: index + 1
            )
        }

        return Segment(
            id: id,
            name: name,
            distanceKilometers: distance,
            gradePercent: grade,
            routeId: routeId,
            leaderboard: entries
        )
    }

    private static func activity(
        id: String,
        athleteId: String,
        title: String,
        distance: Double,
        duration: Int,
        elevation: Double,
        type: ActivityType,
        daysAgo: Int,
        hour: Int,
        minute: Int,
        routeId: String?,
        segmentIds: [String],
        kudos: Int,
        currentUserKudo: Bool,
        sourceType: ActivityContext,
        clubId: String?,
        calories: Int,
        comments: [Comment]
    ) -> Activity {
        let startTime = timestamp(daysAgo: daysAgo, hour: hour, minute: minute)
        let pace = max(Int((Double(duration) / max(distance, 0.1)).rounded()), 1)
        let splits = makeSplits(
            activityId: id,
            distanceKilometers: distance,
            durationSeconds: duration,
            splitDistance: type == .ride || type == .indoorRide ? 5.0 : 1.0
        )
        let segmentResults = segmentIds.enumerated().map { index, segmentId in
            SegmentResult(
                id: "\(id)_segment_\(index + 1)",
                segmentId: segmentId,
                timeSeconds: max(120, Int(Double(duration) * (0.08 + (Double(index) * 0.03)))),
                rank: index + 3
            )
        }

        return Activity(
            id: id,
            athleteId: athleteId,
            title: title,
            distanceKilometers: distance,
            durationSeconds: duration,
            elevationGainMeters: elevation,
            avgPaceSecondsPerKilometer: pace,
            startTime: startTime,
            activityType: type,
            routeId: routeId,
            segmentResults: segmentResults,
            kudosCount: kudos,
            hasCurrentUserKudo: currentUserKudo,
            comments: comments,
            sourceType: sourceType,
            clubId: clubId,
            calories: calories,
            splits: splits,
            lastUpdated: startTime
        )
    }

    private static func makeSplits(activityId: String, distanceKilometers: Double, durationSeconds: Int, splitDistance: Double) -> [ActivitySplit] {
        let splitCount = max(Int(ceil(distanceKilometers / splitDistance)), 1)
        let baseDuration = durationSeconds / splitCount
        let remainder = durationSeconds % splitCount
        let lastDistance = distanceKilometers - (Double(splitCount - 1) * splitDistance)

        return (0..<splitCount).map { index in
            ActivitySplit(
                id: "\(activityId)_split_\(index + 1)",
                index: index + 1,
                distanceKilometers: index == splitCount - 1 ? max(lastDistance, 0.1) : splitDistance,
                durationSeconds: baseDuration + (index < remainder ? 1 : 0)
            )
        }
    }

    private static func comment(_ id: String, athlete: String, text: String) -> Comment {
        Comment(id: id, athleteId: athlete, message: text, createdAt: anchorDate)
    }

    private static func timestamp(daysAgo: Int, hour: Int, minute: Int) -> Date {
        calendar.date(byAdding: .day, value: -daysAgo, to: anchorDate)?
            .setting(hour: hour, minute: minute, second: 0, calendar: calendar) ?? anchorDate
    }

    private static func leaderboardEntry(
        id: String,
        athleteId: String,
        athleteName: String,
        rank: Int,
        timeSeconds: Int,
        weeklyDistance: Double
    ) -> LeaderboardEntry {
        let derivedTime = timeSeconds == 0 ? max(60, Int((weeklyDistance * 180).rounded())) : timeSeconds
        return LeaderboardEntry(id: id, athleteId: athleteId, athleteName: athleteName, timeSeconds: derivedTime, rank: rank)
    }
}

private extension Date {
    func setting(hour: Int, minute: Int, second: Int, calendar: Calendar) -> Date {
        calendar.date(
            bySettingHour: hour,
            minute: minute,
            second: second,
            of: self
        ) ?? self
    }
}
