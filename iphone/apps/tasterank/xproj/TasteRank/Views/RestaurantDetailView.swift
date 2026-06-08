import SwiftUI

struct RestaurantDetailView: View {
    @EnvironmentObject private var store: MockTasteRankStore
    let restaurant: Restaurant

    @State private var showingLogVisit = false
    @State private var showingAddToList = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                hero

                VStack(alignment: .leading, spacing: 6) {
                    Text(restaurant.name)
                        .font(MockTasteRankTheme.displayFont(size: 26))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)

                    Text(restaurant.cuisineDetails)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(MockTasteRankTheme.accent)

                    Text(restaurant.locationLine)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)

                    Text(restaurant.statusLine)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(MockTasteRankTheme.textSecondary)
                }

                HStack(spacing: 10) {
                    Button("Log visit") {
                        showingLogVisit = true
                    }
                    .buttonStyle(PrimaryActionButtonStyle())

                    Button("Save to list") {
                        showingAddToList = true
                    }
                    .buttonStyle(SecondaryActionButtonStyle())
                }

                Text(restaurant.blurb)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Recommended order")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MockTasteRankTheme.textPrimary)

                    ForEach(restaurant.dishes) { dish in
                        HStack {
                            Text(dish.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(MockTasteRankTheme.textPrimary)
                            Spacer()
                            Text("Must try")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(MockTasteRankTheme.accent)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(CardBackground(cornerRadius: 14))
                    }
                }

                if let latestLog = store.latestLog(for: restaurant.id), !latestLog.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your latest note")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                        Text(latestLog.notes)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(MockTasteRankTheme.textPrimary)
                            .padding(14)
                            .background(CardBackground(cornerRadius: 16))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(MockTasteRankTheme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingLogVisit) {
            LogVisitSheet(restaurant: restaurant)
                .environmentObject(store)
        }
        .sheet(isPresented: $showingAddToList) {
            AddToListSheet(restaurant: restaurant)
                .environmentObject(store)
        }
    }

    private var hero: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                ForEach(restaurant.photoAssetNames, id: \.self) { photo in
                    Image(photo)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .padding(.horizontal, 2)
                }
            }
            .frame(height: 230)
            .tabViewStyle(.page(indexDisplayMode: .always))

            TasteRankScoreBadge(score: restaurant.beliScore, diameter: 60)
                .padding(16)
        }
    }
}

private struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(MockTasteRankTheme.accent.opacity(configuration.isPressed ? 0.88 : 1))
            )
    }
}

private struct SecondaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(MockTasteRankTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(CardBackground(cornerRadius: 14))
            .opacity(configuration.isPressed ? 0.88 : 1)
    }
}

struct InfoPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(MockTasteRankTheme.textSecondary)
        }
        .padding(12)
        .background(CardBackground(cornerRadius: 14))
    }
}

struct LogVisitSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant

    @State private var rating = 8
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 14) {
                Text("How was \(restaurant.name)?")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(MockTasteRankTheme.textPrimary)

                RatingSelector(title: "Overall rating", rating: $rating)

                TextEditor(text: $notes)
                    .font(.system(size: 15))
                    .padding(10)
                    .frame(height: 160)
                    .background(CardBackground(cornerRadius: 16))

                Spacer()
            }
            .padding(16)
            .background(MockTasteRankTheme.background.ignoresSafeArea())
            .navigationTitle("Log Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.logVisit(
                            restaurantID: restaurant.id,
                            date: Date(),
                            rating: rating,
                            dishRatings: [],
                            notes: notes,
                            tags: []
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DishRatingRow: View {
    let name: String
    @Binding var rating: Int

    var body: some View {
        HStack {
            Text(name)
            Spacer()
            Stepper(value: $rating, in: 0...10) {
                Text("\(rating)")
            }
        }
    }
}

struct RatingSelector: View {
    let title: String
    @Binding var rating: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(MockTasteRankTheme.textPrimary)
            HStack(spacing: 6) {
                ForEach(1...10, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Text("\(value)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(rating == value ? Color.white : MockTasteRankTheme.textPrimary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(rating == value ? MockTasteRankTheme.accent : MockTasteRankTheme.surface)
                                    .overlay(
                                        Circle().stroke(MockTasteRankTheme.border, lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct AddToListSheet: View {
    @EnvironmentObject private var store: MockTasteRankStore
    @Environment(\.dismiss) private var dismiss
    let restaurant: Restaurant
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Create List") {
                    HStack(spacing: 10) {
                        TextField("New list name", text: $newListName)
                            .textInputAutocapitalization(.words)

                        Button("Create") {
                            let trimmed = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            store.createList(name: trimmed)
                            if let createdList = store.listCollections.first(where: { $0.name == trimmed }) {
                                store.toggleRestaurant(restaurant.id, in: createdList.id)
                            }
                            newListName = ""
                        }
                        .disabled(newListName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Your Lists") {
                ForEach(store.listCollections) { list in
                    Button {
                        store.toggleRestaurant(restaurant.id, in: list.id)
                    } label: {
                        HStack {
                            Text(list.name)
                            Spacer()
                            if store.isRestaurant(restaurant.id, in: list.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(MockTasteRankTheme.accent)
                            }
                        }
                    }
                    .foregroundStyle(MockTasteRankTheme.textPrimary)
                }
                }
            }
            .navigationTitle("Save to List")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PhotoCarouselView: View {
    let seed: String

    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(MockTasteRankTheme.accentSoft)
    }
}

#Preview {
    NavigationStack {
        RestaurantDetailView(restaurant: MockTasteRankStore().restaurants.first!)
            .environmentObject(MockTasteRankStore())
    }
}
