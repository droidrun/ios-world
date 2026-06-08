//
//  MovieDetail.swift
//  Cinephile
//
//  Created by Thomas Ricouard on 09/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import SwiftUI
import SwiftUIFlux
import Combine
import UI

struct MovieDetail: ConnectedView {
    struct Props {
        let movie: Movie?
        let characters: [People]?
        let credits: [People]?
        let recommended: [Movie]?
        let similar: [Movie]?
        let reviewsCount: Int?
        let videos: [Video]?
    }
    
    let movieId: Int
    
    // MARK: View States
    @State var isAddSheetPresented = false
    @State var isCreateListFormPresented = false
    @State var isAddedToListBadgePresented = false
    @State var selectedPoster: ImageData?
        
    // MARK: Computed Props
    func map(state: AppState, dispatch: @escaping DispatchFunction) -> Props {
        var characters: [People]?
        var credits: [People]?
        var recommended: [Movie]?
        var similar: [Movie]?
        
        if let peopleIds = state.peoplesState.peoplesMovies[movieId]?.sorted() {
            let peoples = peopleIds.compactMap{ state.peoplesState.peoples[$0] }
            characters = peoples.filter{ $0.character != nil}
            credits = peoples.filter{ $0.department != nil }
            if let recommendedIds = state.moviesState.recommended[movieId] {
                recommended = recommendedIds.compactMap{ state.moviesState.movies[$0] }
            }
            if let simillarIds = state.moviesState.similar[movieId] {
                similar = simillarIds.compactMap{ state.moviesState.movies[$0] }
            }
        }
        return Props(movie: state.moviesState.movies[movieId],
                     characters: characters,
                     credits: credits,
                     recommended: recommended,
                     similar: similar,
                     reviewsCount: state.moviesState.reviews[movieId]?.count ?? nil,
                     videos: state.moviesState.videos[movieId])
    }
    
    // MARK: - Fetch
    func fetchMovieDetails() {
        store.dispatch(action: MoviesActions.FetchDetail(movie: movieId))
        store.dispatch(action: PeopleActions.FetchMovieCasts(movie: movieId))
        store.dispatch(action: MoviesActions.FetchRecommended(movie: movieId))
        store.dispatch(action: MoviesActions.FetchSimilar(movie: movieId))
        store.dispatch(action: MoviesActions.FetchMovieReviews(movie: movieId))
        store.dispatch(action: MoviesActions.FetchVideos(movie: movieId))
    }
    
    // MARK: - View actions
    func displaySavedBadge() {
        isAddedToListBadgePresented = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.isAddedToListBadgePresented = false
        }
    }
    
    func onAddButton() {
        isAddSheetPresented.toggle()
    }
    
    // MARK: - Body
    
    func peopleRow(role: String, people: People?) -> some View {
        Group {
            if people != nil {
                HStack(alignment: .center, spacing: 0) {
                    Text(role + ": ").font(.callout)
                    Text(people!.name).font(.body).foregroundColor(.secondary)
                }
            }
        }
    }
    
    func peopleRows(props: Props) -> some View {
        Group {
            peopleRow(role: "Director", people: props.credits?.filter{ $0.department == "Directing" }.first)
        }
    }

    func topSection(props: Props) -> some View {
        Section {
            MovieCoverRow(movieId: movieId)
            MovieButtonsRow(movieId: movieId, showCustomListSheet: $isAddSheetPresented)
            if props.reviewsCount ?? 0 > 0 {
                NavigationLink(destination: MovieReviews(movie: self.movieId)) {
                    Text("\(props.reviewsCount!) reviews")
                        .foregroundColor(.steam_blue)
                        .lineLimit(1)
                }
            }
            if let movie = props.movie, !movie.overview.isEmpty {
                MovieOverview(movie: movie)
            }
        }
    }

    func bottomSection(props: Props) -> some View {
        Section {
            if let keywords = props.movie?.keywords?.keywords, !keywords.isEmpty {
                MovieKeywords(keywords: keywords)
            }
            if props.characters?.isEmpty == false {
                MovieCrosslinePeopleRow(title: "Cast",
                                        peoples: props.characters ?? [])
            }
            if props.credits?.isEmpty == false {
                peopleRows(props: props)
                MovieCrosslinePeopleRow(title: "Crew",
                                        peoples: props.credits ?? [])
            }
            if props.similar?.isEmpty == false {
                MovieCrosslineRow(title: "Similar Movies", movies: props.similar ?? [])
            }
            if  props.recommended?.isEmpty == false {
                MovieCrosslineRow(title: "Recommended Movies", movies: props.recommended ?? [])
            }
            if let posters = props.movie?.images?.posters, !posters.isEmpty {
                MoviePostersRow(posters: posters.prefix(8).map{ $0 },
                                selectedPoster: $selectedPoster)
            }
            if let backdrops = props.movie?.images?.backdrops, !backdrops.isEmpty {
                MovieBackdropsRow(backdrops: backdrops.prefix(8).map{ $0 })
            }
        }
    }
    
    func body(props: Props) -> some View {
        Group {
            if let movie = props.movie {
                ZStack(alignment: .bottom) {
                    List {
                        topSection(props: props)
                        bottomSection(props: props)
                    }
                    .navigationBarTitle(Text(movie.userTitle), displayMode: .large)
                    .navigationBarItems(trailing: Button(action: onAddButton) {
                        Image(systemName: "text.badge.plus").imageScale(.large)
                    })
                    .sheet(isPresented: $isAddSheetPresented) {
                        MovieListSelectionSheet(movieId: self.movieId,
                                                movieTitle: movie.userTitle,
                                                onDismiss: {
                                                    self.isAddSheetPresented = false
                                                },
                                                onCreateList: {
                                                    self.isCreateListFormPresented = true
                                                },
                                                onSaved: {
                                                    self.displaySavedBadge()
                                                })
                            .environmentObject(store)
                    }
                    .sheet(isPresented: $isCreateListFormPresented,
                           content: { CustomListForm(editingListId: nil)
                            .environmentObject(store) })
                    .disabled(selectedPoster != nil)
                    .blur(radius: selectedPoster != nil ? 30 : 0)
                    .scaleEffect(selectedPoster != nil ? 0.8 : 1)

                    NotificationBadge(text: "Added successfully",
                                      color: .blue,
                                      show: $isAddedToListBadgePresented).padding(.bottom, 10)
                    ImagesCarouselView(posters: movie.images?.posters ?? [],
                                           selectedPoster: $selectedPoster)
                        .blur(radius: selectedPoster != nil ? 0 : 10)
                        .scaleEffect(selectedPoster != nil ? 1 : 1.2)
                        .opacity(selectedPoster != nil ? 1 : 0)
                        .allowsHitTesting(selectedPoster != nil)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            self.fetchMovieDetails()
        }
    }
    
    
}

struct MovieListSelectionSheet: ConnectedView {
    struct Props {
        let customLists: [CustomList]
        let wishlistContainsMovie: Bool
        let seenlistContainsMovie: Bool
    }

    let movieId: Int
    let movieTitle: String
    let onDismiss: () -> Void
    let onCreateList: () -> Void
    let onSaved: () -> Void

    func map(state: AppState, dispatch: @escaping DispatchFunction) -> Props {
        Props(customLists: state.moviesState.customLists
            .map { $0.value }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending },
              wishlistContainsMovie: state.moviesState.wishlist.contains(movieId),
              seenlistContainsMovie: state.moviesState.seenlist.contains(movieId))
    }

    private func toggleWishlist(props: Props) {
        if props.wishlistContainsMovie {
            store.dispatch(action: MoviesActions.RemoveFromWishlist(movie: movieId))
        } else {
            store.dispatch(action: MoviesActions.AddToWishlist(movie: movieId))
        }
        onSaved()
    }

    private func toggleSeenlist(props: Props) {
        if props.seenlistContainsMovie {
            store.dispatch(action: MoviesActions.RemoveFromSeenList(movie: movieId))
        } else {
            store.dispatch(action: MoviesActions.AddToSeenList(movie: movieId))
        }
        onSaved()
    }

    private func toggleCustomList(_ list: CustomList) {
        if list.movies.contains(movieId) {
            store.dispatch(action: MoviesActions.RemoveMovieFromCustomList(list: list.id, movie: movieId))
        } else {
            store.dispatch(action: MoviesActions.AddMovieToCustomList(list: list.id, movie: movieId))
        }
        onSaved()
    }

    func body(props: Props) -> some View {
        NavigationView {
            List {
                Section(header: Text("Quick Lists")) {
                    Button(action: { self.toggleWishlist(props: props) }) {
                        HStack {
                            Text(props.wishlistContainsMovie ? "Remove from wishlist" : "Add to wishlist")
                            Spacer()
                            Image(systemName: props.wishlistContainsMovie ? "checkmark.circle.fill" : "heart")
                                .foregroundColor(.pink)
                        }
                    }
                    Button(action: { self.toggleSeenlist(props: props) }) {
                        HStack {
                            Text(props.seenlistContainsMovie ? "Remove from seenlist" : "Add to seenlist")
                            Spacer()
                            Image(systemName: props.seenlistContainsMovie ? "checkmark.circle.fill" : "eye")
                                .foregroundColor(.green)
                        }
                    }
                }

                Section(header: Text("Custom Lists")) {
                    if props.customLists.isEmpty {
                        Text("No custom lists yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(props.customLists) { list in
                            Button(action: { self.toggleCustomList(list) }) {
                                HStack {
                                    Text(list.name)
                                    Spacer()
                                    Image(systemName: list.movies.contains(self.movieId) ? "checkmark.circle.fill" : "plus.circle")
                                        .foregroundColor(.steam_gold)
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(GroupedListStyle())
            .navigationBarTitle(Text(movieTitle), displayMode: .inline)
            .navigationBarItems(
                leading: Button("Done", action: onDismiss),
                trailing: Button("Create List") {
                    self.onDismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.onCreateList()
                    }
                }
            )
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MovieDetail_Previews : PreviewProvider {
    static var previews: some View {
        NavigationView {
            MovieDetail(movieId: sampleMovie.id).environmentObject(sampleStore)
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif
