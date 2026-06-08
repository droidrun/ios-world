import Foundation

enum SeedData {
    static func foodDatabase(bundle: Bundle = .main) -> [FoodDatabaseEntry] {
        guard let url = bundle.url(forResource: "food_database", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([FoodDatabaseEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    static func seededExercises() -> [Exercise] {
        [
            Exercise(id: "exercise_001", exerciseName: "Running", durationMinutes: 30, caloriesBurned: 330, category: "Cardio"),
            Exercise(id: "exercise_002", exerciseName: "Walking", durationMinutes: 30, caloriesBurned: 120, category: "Cardio"),
            Exercise(id: "exercise_003", exerciseName: "Cycling", durationMinutes: 45, caloriesBurned: 370, category: "Cardio"),
            Exercise(id: "exercise_004", exerciseName: "Swimming", durationMinutes: 35, caloriesBurned: 300, category: "Cardio"),
            Exercise(id: "exercise_005", exerciseName: "Strength training", durationMinutes: 45, caloriesBurned: 220, category: "Strength"),
            Exercise(id: "exercise_006", exerciseName: "Yoga", durationMinutes: 40, caloriesBurned: 140, category: "Recovery"),
            Exercise(id: "exercise_007", exerciseName: "Elliptical", durationMinutes: 40, caloriesBurned: 320, category: "Cardio"),
            Exercise(id: "exercise_008", exerciseName: "HIIT", durationMinutes: 25, caloriesBurned: 280, category: "Cardio"),
            Exercise(id: "exercise_009", exerciseName: "Pilates", durationMinutes: 45, caloriesBurned: 180, category: "Recovery"),
            Exercise(id: "exercise_010", exerciseName: "Rowing", durationMinutes: 30, caloriesBurned: 260, category: "Cardio"),
            Exercise(id: "exercise_011", exerciseName: "Hiking", durationMinutes: 60, caloriesBurned: 410, category: "Cardio"),
            Exercise(id: "exercise_012", exerciseName: "Mobility flow", durationMinutes: 20, caloriesBurned: 70, category: "Recovery")
        ]
    }

    static func seededState(today: Date = Date(), bundle: Bundle = .main) -> FitnessAppState {
        let calendar = AppFormatters.calendar
        let normalizedToday = calendar.startOfDay(for: today)
        let foods = foodDatabase(bundle: bundle)
        let foodLookup = Dictionary(uniqueKeysWithValues: foods.map { ($0.id, $0) })

        let logs = seededLogs(baseDate: normalizedToday, foodLookup: foodLookup)
        let weights = seededWeights(baseDate: normalizedToday)
        let recentFoodIDs = logs
            .sorted { $0.date > $1.date }
            .flatMap { $0.mealEntries }
            .map(\.foodItem.id)
            .reduce(into: [String]()) { partialResult, foodID in
                if !partialResult.contains(foodID) {
                    partialResult.append(foodID)
                }
            }

        let goal = NutritionGoal(
            goalCalories: 2450,
            goalProtein: 170,
            goalCarbs: 250,
            goalFat: 75,
            targetWeight: 176,
            weeklyWeightChange: -0.7
        )

        return FitnessAppState(
            selectedTab: .today,
            userProfile: UserProfile(
                id: "profile_001",
                userName: "Jordan Avery",
                height: 70,
                weight: weights.first?.weight ?? 182.2,
                goalWeight: goal.targetWeight,
                activityLevel: "Moderately Active",
                dailyCalorieGoal: goal.goalCalories,
                unitSystem: .pounds
            ),
            nutritionGoal: goal,
            dailyLogs: logs.sorted { $0.date > $1.date },
            weightEntries: weights.sorted { $0.date > $1.date },
            foodDatabase: foods,
            exerciseCatalog: seededExercises(),
            recentFoodIDs: Array(recentFoodIDs.prefix(10)),
            pushNotificationsEnabled: true,
            reminderNotificationsEnabled: true,
            nextMealEntrySequence: 75,
            nextExerciseEntrySequence: 7,
            nextWeightEntrySequence: 9
        )
    }

    private static func seededLogs(baseDate: Date, foodLookup: [String: FoodDatabaseEntry]) -> [DailyLog] {
        let calendar = AppFormatters.calendar

        func date(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: -offset, to: baseDate) ?? baseDate
        }

        var mealSequence = 1
        var exerciseSequence = 1

        func meal(_ foodID: String, _ mealType: MealType, _ quantity: Double, _ entryDate: Date) -> MealEntry {
            defer { mealSequence += 1 }
            let entry = foodLookup[foodID] ?? FoodDatabaseEntry(
                id: foodID,
                foodName: foodID,
                servingSize: "1 serving",
                calories: 100,
                protein: 0,
                carbs: 0,
                fat: 0,
                fiber: 0,
                sodium: 0,
                category: "Fallback",
                searchKeywords: []
            )
            return MealEntry(
                id: String(format: "meal_entry_%03d", mealSequence),
                foodItem: entry.foodItem,
                mealType: mealType,
                quantity: quantity,
                date: entryDate
            )
        }

        func exercise(_ name: String, _ duration: Int, _ calories: Int, _ entryDate: Date) -> ExerciseEntry {
            defer { exerciseSequence += 1 }
            return ExerciseEntry(
                id: String(format: "exercise_entry_%03d", exerciseSequence),
                exerciseName: name,
                durationMinutes: duration,
                caloriesBurned: calories,
                date: entryDate
            )
        }

        let recentLogs = [
            DailyLog(
                id: AppFormatters.dateKey(for: date(0)),
                date: date(0),
                mealEntries: [
                    meal("food_011", .breakfast, 1.0, date(0)),
                    meal("food_009", .breakfast, 1.0, date(0)),
                    meal("food_007", .breakfast, 1.0, date(0)),
                    meal("food_028", .lunch, 1.0, date(0)),
                    meal("food_008", .lunch, 1.0, date(0)),
                    meal("food_006", .dinner, 1.0, date(0)),
                    meal("food_022", .dinner, 1.0, date(0)),
                    meal("food_062", .dinner, 1.0, date(0)),
                    meal("food_013", .snacks, 1.0, date(0)),
                    meal("food_012", .snacks, 1.0, date(0))
                ],
                exerciseEntries: [
                    exercise("Walking", 35, 140, date(0))
                ],
                waterCups: 6,
                stepCount: 8420
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(1)),
                date: date(1),
                mealEntries: [
                    meal("food_025", .breakfast, 1.0, date(1)),
                    meal("food_017", .breakfast, 1.0, date(1)),
                    meal("food_008", .breakfast, 1.0, date(1)),
                    meal("food_029", .lunch, 1.0, date(1)),
                    meal("food_006", .dinner, 1.0, date(1)),
                    meal("food_003", .dinner, 1.0, date(1)),
                    meal("food_010", .dinner, 1.5, date(1)),
                    meal("food_012", .snacks, 1.0, date(1))
                ],
                exerciseEntries: [
                    exercise("Running", 30, 330, date(1))
                ],
                waterCups: 8,
                stepCount: 10420
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(2)),
                date: date(2),
                mealEntries: [
                    meal("food_032", .breakfast, 1.0, date(2)),
                    meal("food_001", .lunch, 1.0, date(2)),
                    meal("food_022", .lunch, 1.0, date(2)),
                    meal("food_021", .lunch, 1.0, date(2)),
                    meal("food_030", .dinner, 1.0, date(2)),
                    meal("food_014", .dinner, 1.0, date(2)),
                    meal("food_010", .dinner, 1.0, date(2)),
                    meal("food_038", .snacks, 1.0, date(2))
                ],
                exerciseEntries: [
                    exercise("Strength training", 45, 220, date(2))
                ],
                waterCups: 7,
                stepCount: 9120
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(3)),
                date: date(3),
                mealEntries: [
                    meal("food_002", .breakfast, 1.0, date(3)),
                    meal("food_016", .lunch, 1.0, date(3)),
                    meal("food_034", .lunch, 1.0, date(3)),
                    meal("food_056", .dinner, 1.0, date(3)),
                    meal("food_057", .dinner, 1.0, date(3)),
                    meal("food_007", .snacks, 1.0, date(3))
                ],
                exerciseEntries: [
                    exercise("Yoga", 40, 140, date(3))
                ],
                waterCups: 6,
                stepCount: 7450
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(4)),
                date: date(4),
                mealEntries: [
                    meal("food_011", .breakfast, 1.0, date(4)),
                    meal("food_020", .breakfast, 1.0, date(4)),
                    meal("food_015", .lunch, 1.0, date(4)),
                    meal("food_031", .dinner, 1.0, date(4)),
                    meal("food_004", .dinner, 1.0, date(4)),
                    meal("food_058", .snacks, 1.0, date(4))
                ],
                exerciseEntries: [],
                waterCups: 6,
                stepCount: 8230
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(5)),
                date: date(5),
                mealEntries: [
                    meal("food_063", .breakfast, 1.0, date(5)),
                    meal("food_046", .breakfast, 1.0, date(5)),
                    meal("food_047", .breakfast, 1.0, date(5)),
                    meal("food_027", .lunch, 1.0, date(5)),
                    meal("food_050", .dinner, 1.0, date(5)),
                    meal("food_051", .dinner, 1.0, date(5)),
                    meal("food_042", .snacks, 1.0, date(5))
                ],
                exerciseEntries: [
                    exercise("Cycling", 50, 410, date(5))
                ],
                waterCups: 7,
                stepCount: 9540
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(6)),
                date: date(6),
                mealEntries: [
                    meal("food_012", .breakfast, 1.0, date(6)),
                    meal("food_009", .breakfast, 1.0, date(6)),
                    meal("food_053", .lunch, 1.0, date(6)),
                    meal("food_017", .lunch, 1.0, date(6)),
                    meal("food_054", .dinner, 1.0, date(6)),
                    meal("food_055", .dinner, 1.0, date(6)),
                    meal("food_004", .dinner, 1.0, date(6)),
                    meal("food_008", .snacks, 1.0, date(6))
                ],
                exerciseEntries: [],
                waterCups: 7,
                stepCount: 7810
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(7)),
                date: date(7),
                mealEntries: [
                    meal("food_064", .breakfast, 1.0, date(7)),
                    meal("food_028", .lunch, 1.0, date(7)),
                    meal("food_060", .dinner, 2.0, date(7)),
                    meal("food_059", .snacks, 2.0, date(7)),
                    meal("food_018", .snacks, 1.0, date(7))
                ],
                exerciseEntries: [
                    exercise("Swimming", 35, 300, date(7))
                ],
                waterCups: 8,
                stepCount: 9900
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(8)),
                date: date(8),
                mealEntries: [
                    meal("food_048", .breakfast, 1.0, date(8)),
                    meal("food_049", .breakfast, 1.0, date(8)),
                    meal("food_052", .lunch, 1.0, date(8)),
                    meal("food_006", .dinner, 1.0, date(8)),
                    meal("food_022", .dinner, 1.0, date(8)),
                    meal("food_010", .dinner, 1.0, date(8)),
                    meal("food_044", .snacks, 1.0, date(8))
                ],
                exerciseEntries: [],
                waterCups: 6,
                stepCount: 7110
            ),
            DailyLog(
                id: AppFormatters.dateKey(for: date(9)),
                date: date(9),
                mealEntries: [
                    meal("food_007", .breakfast, 1.0, date(9)),
                    meal("food_033", .breakfast, 1.0, date(9)),
                    meal("food_035", .breakfast, 1.0, date(9)),
                    meal("food_065", .lunch, 1.0, date(9)),
                    meal("food_001", .dinner, 1.0, date(9)),
                    meal("food_014", .dinner, 1.0, date(9)),
                    meal("food_021", .dinner, 1.0, date(9)),
                    meal("food_036", .snacks, 1.0, date(9)),
                    meal("food_037", .snacks, 1.0, date(9))
                ],
                exerciseEntries: [],
                waterCups: 7,
                stepCount: 8700
            )
        ]

        let generatedMealTemplates: [[(String, MealType, Double)]] = [
            [("food_066", .breakfast, 1.0), ("food_020", .breakfast, 1.0), ("food_068", .lunch, 1.0), ("food_069", .dinner, 1.0), ("food_076", .snacks, 1.0)],
            [("food_002", .breakfast, 1.0), ("food_017", .breakfast, 1.0), ("food_053", .lunch, 1.0), ("food_074", .dinner, 1.0), ("food_036", .snacks, 1.0)],
            [("food_067", .breakfast, 1.0), ("food_008", .breakfast, 1.0), ("food_070", .lunch, 1.0), ("food_056", .dinner, 1.0), ("food_073", .snacks, 1.0)],
            [("food_064", .breakfast, 1.0), ("food_043", .breakfast, 1.0), ("food_028", .lunch, 1.0), ("food_075", .dinner, 1.0), ("food_072", .snacks, 1.0)],
            [("food_063", .breakfast, 1.0), ("food_045", .breakfast, 1.0), ("food_027", .lunch, 1.0), ("food_031", .dinner, 1.0), ("food_058", .snacks, 1.0)],
            [("food_077", .breakfast, 1.0), ("food_009", .breakfast, 1.0), ("food_029", .lunch, 1.0), ("food_050", .dinner, 1.0), ("food_071", .snacks, 1.0)]
        ]

        let generatedExerciseTemplates: [(String, Int, Int)?] = [
            ("Walking", 40, 160),
            ("Strength training", 45, 220),
            nil,
            ("Cycling", 50, 410),
            ("Yoga", 35, 120),
            nil
        ]

        let historicalLogs = (10...29).map { offset -> DailyLog in
            let templateIndex = (offset - 10) % generatedMealTemplates.count
            let template = generatedMealTemplates[templateIndex]
            let entryDate = date(offset)

            let mealEntries = template.map { foodID, mealType, quantity in
                meal(foodID, mealType, quantity, entryDate)
            }

            let exerciseEntries: [ExerciseEntry]
            if let exerciseTemplate = generatedExerciseTemplates[templateIndex] {
                exerciseEntries = [
                    exercise(exerciseTemplate.0, exerciseTemplate.1, exerciseTemplate.2, entryDate)
                ]
            } else {
                exerciseEntries = []
            }

            return DailyLog(
                id: AppFormatters.dateKey(for: entryDate),
                date: entryDate,
                mealEntries: mealEntries,
                exerciseEntries: exerciseEntries,
                waterCups: 5 + (templateIndex % 4),
                stepCount: 6_900 + (templateIndex * 780) + ((offset % 3) * 220)
            )
        }

        return recentLogs + historicalLogs
    }

    private static func seededWeights(baseDate: Date) -> [WeightEntry] {
        let calendar = AppFormatters.calendar

        func date(_ offset: Int) -> Date {
            calendar.date(byAdding: .day, value: -offset, to: baseDate) ?? baseDate
        }

        let offsets = stride(from: 0, through: 28, by: 2)

        return offsets.enumerated().map { index, offset in
            WeightEntry(
                id: String(format: "weight_entry_%03d", index + 1),
                date: date(offset),
                weight: 182.2 + (Double(offset) * 0.26)
            )
        }
    }
}
