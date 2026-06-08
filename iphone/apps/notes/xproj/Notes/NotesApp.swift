import SwiftUI
import SwiftData

@main
struct NotesApp: App {
    let modelContainer: ModelContainer = ModelContainerFactory.make()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .task { NotesSeeder.populateIfEmpty(context: modelContainer.mainContext) }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Model container

/// Builds the SwiftData container, preferring on-disk storage and falling back
/// to an in-memory container if disk initialization fails (keeps the app
/// functional in restricted sandboxes).
private enum ModelContainerFactory {
    static func make() -> ModelContainer {
        let schema = Schema([Note.self, NoteFolder.self])
        if let disk = try? ModelContainer(for: schema, configurations: [
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        ]) {
            return disk
        }
        do {
            return try ModelContainer(for: schema, configurations: [
                ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            ])
        } catch {
            fatalError("NotesApp: failed to create in-memory ModelContainer fallback: \(error)")
        }
    }
}

// MARK: - Seed data

/// Populates a newly-created store with the demo folder graph.
/// Idempotent — inspects the folder count first and returns early if anything
/// is already persisted. The seed content is intentionally verbose so that
/// benchmark tasks can reliably reference specific titles ("Team Standup
/// Notes", "Shopping List", etc.) and folder names ("Work", "Personal").
enum NotesSeeder {
    static func populateIfEmpty(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<NoteFolder>())) ?? []
        guard existing.isEmpty else { return }

        let graph = SeedGraph.build()
        for folder in graph.folders { context.insert(folder) }
        for note in graph.notes { context.insert(note) }
        do {
            try context.save()
        } catch {
            #if DEBUG
            print("[NotesSeeder] Failed to save seed data: \(error)")
            #endif
        }
    }
}

/// Container for the materialized seed data. Building the graph as a value
/// before inserting lets us verify relationships without touching the store.
private struct SeedGraph {
    let folders: [NoteFolder]
    let notes: [Note]

    static func build() -> SeedGraph {
        let today = Date()
        let cal = Calendar.current

        func offsetDate(days: Int, hour: Int = 10, minute: Int = 30) -> Date {
            var value = cal.date(byAdding: .day, value: days, to: today) ?? today
            value = cal.date(bySettingHour: hour, minute: minute, second: 0, of: value) ?? value
            return value
        }
        func formattedOffset(_ days: Int) -> String {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM d"
            return fmt.string(from: cal.date(byAdding: .day, value: days, to: today) ?? today)
        }

        let portland = formattedOffset(8)
        let momsBirthday = formattedOffset(16)
        let giftOrderBy = formattedOffset(9)
        let standupDay = formattedOffset(-2)
        let apiDeadline = formattedOffset(19)
        let projectKickoff = formattedOffset(-14)
        let wireframeDate = formattedOffset(-4)
        let nextMeeting = formattedOffset(2)

        let notesFolder = NoteFolder(name: "Notes", sortOrder: 0)
        let workFolder = NoteFolder(name: "Work", sortOrder: 1)
        let personalFolder = NoteFolder(name: "Personal", sortOrder: 2)
        let recipesFolder = NoteFolder(name: "Recipes", sortOrder: 3)

        // --- Notes folder ---
        let shopping = Note(
            title: "Shopping List",
            body: """
            Groceries for this week:

            - Milk (oat)
            - Eggs (1 dozen)
            - Sourdough bread
            - Avocados (3)
            - Chicken breast
            - Pasta
            - Tomato sauce
            - Parmesan cheese
            - Greek yogurt
            - Bananas
            - Spinach
            - Olive oil

            Also need paper towels and dish soap
            """,
            createdDate: offsetDate(days: -1, hour: 9, minute: 15),
            modifiedDate: offsetDate(days: 0, hour: 8, minute: 45),
            isPinned: true
        )
        shopping.folder = notesFolder

        let wifi = Note(
            title: "Wifi Passwords",
            body: """
            Home: FrostyPaws2024!
            Office: Corp-Wifi-8832
            Mom & Dad's: WelcomeHome99
            Coffee shop (Bean There): beanthere_guest
            Gym: FitLife#2024
            """,
            createdDate: offsetDate(days: -45, hour: 14, minute: 0),
            modifiedDate: offsetDate(days: -12, hour: 16, minute: 30),
            isPinned: true
        )
        wifi.folder = notesFolder

        let packing = Note(
            title: "Travel Packing List",
            body: """
            Trip to Portland - \(portland)

            Essentials:
            - Passport
            - Phone charger + portable battery
            - Headphones
            - Toiletries bag
            - Medications

            Clothes:
            - 4 t-shirts
            - 2 pairs jeans
            - Rain jacket
            - Sneakers
            - Pajamas
            - Underwear/socks (5 days)

            Other:
            - Book (currently reading Dune)
            - Laptop + charger
            - Sunglasses
            - Water bottle
            """,
            createdDate: offsetDate(days: -3, hour: 20, minute: 0),
            modifiedDate: offsetDate(days: -2, hour: 11, minute: 15)
        )
        packing.folder = notesFolder

        let books = Note(
            title: "Books to Read",
            body: """
            Fiction:
            - Project Hail Mary - Andy Weir
            - Klara and the Sun - Kazuo Ishiguro
            - The Midnight Library - Matt Haig
            - Piranesi - Susanna Clarke

            Non-fiction:
            - Thinking, Fast and Slow - Daniel Kahneman
            - The Body Keeps the Score - Bessel van der Kolk
            - Atomic Habits - James Clear

            Currently reading: Dune by Frank Herbert (page 340)
            """,
            createdDate: offsetDate(days: -30, hour: 21, minute: 0),
            modifiedDate: offsetDate(days: -5, hour: 19, minute: 45)
        )
        books.folder = notesFolder

        let apartment = Note(
            title: "Apartment Notes",
            body: """
            Lease renewal is June 30
            Rent: $2,450/mo
            Landlord: Mike Chen (415) 555-0189

            Maintenance requests:
            - Kitchen faucet drips (submitted 2/15)
            - Bedroom window sticks

            Neighbor contact (upstairs): Sarah, unit 3B
            Package room code: 4472#
            """,
            createdDate: offsetDate(days: -60, hour: 10, minute: 0),
            modifiedDate: offsetDate(days: -8, hour: 14, minute: 20)
        )
        apartment.folder = notesFolder

        // --- Work folder ---
        let standup = Note(
            title: "Team Standup Notes",
            body: """
            \(standupDay) Standup

            Yesterday:
            - Finished auth flow refactor
            - Code review for PR #847
            - 1:1 with manager

            Today:
            - Start API migration v2 → v3
            - Write unit tests for auth module
            - Design review at 2pm

            Blockers:
            - Waiting on DevOps for staging deploy
            - Need API docs from backend team
            """,
            createdDate: offsetDate(days: -2, hour: 9, minute: 0),
            modifiedDate: offsetDate(days: 0, hour: 9, minute: 35),
            isPinned: true
        )
        standup.folder = workFolder

        let goals = Note(
            title: "Q1 2026 Goals",
            body: """
            Engineering Goals:
            1. Ship v3 API migration (deadline: \(apiDeadline))
            2. Reduce p95 latency to < 200ms
            3. Increase test coverage to 80%
            4. Onboard 2 new team members

            Personal Development:
            - Complete AWS certification
            - Give 1 tech talk
            - Mentor junior developer

            Status: On track for 1 & 4, behind on 2 & 3
            """,
            createdDate: offsetDate(days: -65, hour: 11, minute: 0),
            modifiedDate: offsetDate(days: -7, hour: 15, minute: 0)
        )
        goals.folder = workFolder

        let kickoff = Note(
            title: "Project Alpha - Kickoff",
            body: """
            Meeting with Sarah & design team
            Date: \(projectKickoff)

            Key decisions:
            - Using React Native for mobile
            - Backend stays on Node.js
            - Target launch: Q2 2026

            Action items:
            - Jordan: Set up repo & CI/CD pipeline
            - Sarah: Finalize wireframes by \(wireframeDate)
            - Dev team: Spike on push notification service

            Next meeting: \(nextMeeting) @ 10am
            """,
            createdDate: offsetDate(days: -7, hour: 10, minute: 0),
            modifiedDate: offsetDate(days: -7, hour: 11, minute: 30)
        )
        kickoff.folder = workFolder

        // --- Personal folder ---
        let gifts = Note(
            title: "Gift Ideas - Mom's Birthday",
            body: """
            Birthday: \(momsBirthday)

            Ideas:
            - Kindle Paperwhite (she mentioned wanting one)
            - Cooking class subscription
            - Cashmere scarf (blue or gray)
            - Photo book of family trip
            - Spa gift card ($150)

            Budget: ~$200
            Order by: \(giftOrderBy) to be safe
            """,
            createdDate: offsetDate(days: -10, hour: 20, minute: 0),
            modifiedDate: offsetDate(days: -4, hour: 18, minute: 30)
        )
        gifts.folder = personalFolder

        let workout = Note(
            title: "Workout Plan",
            body: """
            Weekly Schedule:

            Monday - Upper Body
            - Bench press 4x8
            - Overhead press 3x10
            - Rows 4x10
            - Bicep curls 3x12

            Wednesday - Lower Body
            - Squats 4x8
            - Romanian deadlifts 3x10
            - Leg press 3x12
            - Calf raises 4x15

            Friday - Full Body
            - Deadlifts 3x5
            - Pull-ups 3x max
            - Dips 3x12
            - Planks 3x60s

            Saturday - Cardio
            - 30 min run or bike
            - Stretching
            """,
            createdDate: offsetDate(days: -20, hour: 7, minute: 0),
            modifiedDate: offsetDate(days: -6, hour: 7, minute: 30)
        )
        workout.folder = personalFolder

        let movies = Note(
            title: "Movies & Shows to Watch",
            body: """
            Movies:
            - The Holdovers
            - Past Lives
            - Oppenheimer
            - Poor Things

            TV Shows:
            - Shogun (on ep 3)
            - The Bear S3
            - Slow Horses
            - Severance S2

            Documentaries:
            - 14 Peaks
            - The Last Dance (rewatch)
            """,
            createdDate: offsetDate(days: -15, hour: 21, minute: 30),
            modifiedDate: offsetDate(days: -3, hour: 22, minute: 0)
        )
        movies.folder = personalFolder

        // --- Recipes folder ---
        let banana = Note(
            title: "Banana Bread",
            body: """
            Mom's recipe

            Ingredients:
            - 3 ripe bananas
            - 1/3 cup melted butter
            - 3/4 cup sugar
            - 1 egg, beaten
            - 1 tsp vanilla
            - 1 tsp baking soda
            - Pinch of salt
            - 1 1/3 cups flour
            - Optional: chocolate chips, walnuts

            Directions:
            1. Preheat oven to 350°F
            2. Mash bananas, mix in butter
            3. Add sugar, egg, vanilla
            4. Mix in baking soda, salt, flour
            5. Pour into greased loaf pan
            6. Bake 60-65 minutes

            Tip: The riper the bananas, the better!
            """,
            createdDate: offsetDate(days: -90, hour: 15, minute: 0),
            modifiedDate: offsetDate(days: -14, hour: 16, minute: 0)
        )
        banana.folder = recipesFolder

        let pasta = Note(
            title: "Quick Garlic Pasta",
            body: """
            15-minute weeknight dinner

            Ingredients:
            - 1 lb spaghetti
            - 6 cloves garlic, sliced thin
            - 1/2 cup olive oil
            - Red pepper flakes
            - Parmesan cheese
            - Fresh parsley
            - Salt & pepper

            1. Boil pasta, reserve 1 cup pasta water
            2. Slowly cook garlic in olive oil until golden
            3. Add red pepper flakes
            4. Toss with drained pasta
            5. Add pasta water to loosen
            6. Top with parmesan and parsley
            """,
            createdDate: offsetDate(days: -40, hour: 18, minute: 30),
            modifiedDate: offsetDate(days: -40, hour: 18, minute: 30)
        )
        pasta.folder = recipesFolder

        // --- Trashed note ---
        let oldGrocery = Note(
            title: "Old Grocery List",
            body: "- Milk\n- Bread\n- Eggs\n- Butter",
            createdDate: offsetDate(days: -20, hour: 12, minute: 0),
            modifiedDate: offsetDate(days: -10, hour: 12, minute: 0)
        )
        oldGrocery.isInTrash = true
        oldGrocery.trashedDate = offsetDate(days: -10, hour: 12, minute: 0)
        oldGrocery.folder = notesFolder

        return SeedGraph(
            folders: [notesFolder, workFolder, personalFolder, recipesFolder],
            notes: [
                shopping, wifi, packing, books, apartment,
                standup, goals, kickoff,
                gifts, workout, movies,
                banana, pasta,
                oldGrocery
            ]
        )
    }
}
