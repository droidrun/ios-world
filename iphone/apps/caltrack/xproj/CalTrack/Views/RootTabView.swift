import SwiftUI

struct RootTabView: View {
    @ObservedObject var store: FitnessStore

    @StateObject private var dashboardViewModel: DashboardViewModel
    @StateObject private var foodLogViewModel: FoodLogViewModel
    @StateObject private var exerciseViewModel: ExerciseViewModel
    @StateObject private var progressViewModel: ProgressViewModel
    @StateObject private var profileViewModel: ProfileViewModel
    @StateObject private var goalsViewModel: GoalsViewModel
    @StateObject private var moreViewModel: MoreViewModel

    init(store: FitnessStore) {
        self.store = store
        _dashboardViewModel = StateObject(wrappedValue: DashboardViewModel(store: store))
        _foodLogViewModel = StateObject(wrappedValue: FoodLogViewModel(store: store))
        _exerciseViewModel = StateObject(wrappedValue: ExerciseViewModel(store: store))
        _progressViewModel = StateObject(wrappedValue: ProgressViewModel(store: store))
        _profileViewModel = StateObject(wrappedValue: ProfileViewModel(store: store))
        _goalsViewModel = StateObject(wrappedValue: GoalsViewModel(store: store))
        _moreViewModel = StateObject(wrappedValue: MoreViewModel(store: store))
    }

    var body: some View {
        TabView(selection: Binding(
            get: { store.state.selectedTab },
            set: { store.setSelectedTab($0) }
        )) {
            NavigationStack {
                DashboardView(
                    viewModel: dashboardViewModel,
                    foodLogViewModel: foodLogViewModel,
                    exerciseViewModel: exerciseViewModel
                )
            }
            .tabItem {
                Label("Today", systemImage: "doc.text.fill")
            }
            .tag(FitnessTab.today)
            .accessibilityIdentifier("tab_today")

            NavigationStack {
                ProgressTabView(viewModel: progressViewModel)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.bar.fill")
            }
            .tag(FitnessTab.progress)
            .accessibilityIdentifier("tab_progress")

            NavigationStack {
                MoreTabView(
                    profileViewModel: profileViewModel,
                    goalsViewModel: goalsViewModel,
                    moreViewModel: moreViewModel
                )
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle.fill")
            }
            .tag(FitnessTab.more)
            .accessibilityIdentifier("tab_more")
        }
        .tint(FitnessTheme.accent)
    }
}
