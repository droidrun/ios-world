//
//  AppState.swift
//  Cinephile
//
//  Created by Thomas Ricouard on 26/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import Foundation
import SwiftUIFlux

fileprivate var savePath: URL?
fileprivate let encoder = JSONEncoder()
fileprivate let decoder = JSONDecoder()

struct AppState: FluxState, Codable {
    var moviesState: MoviesState
    var peoplesState: PeoplesState
    
    
    init() {
        savePath = Self.makeSavePath()
        
        if let savePath = savePath,
            let data = try? Data(contentsOf: savePath),
            let savedState = try? decoder.decode(AppState.self, from: data) {
            self.moviesState = savedState.moviesState
            self.peoplesState = savedState.peoplesState
        } else {
            self.moviesState = MoviesState()
            self.peoplesState = PeoplesState()
        }
        
        //Adding a sample movie to id 0 so we can have placeholder movie rows.
        moviesState.movies[0] = sampleMovie
        // Ensure discover seed movies are always present in the movies dict so the
        // Discover screen can display them even when restoring from persisted state.
        for movie in discoverSeedMovies {
            if moviesState.movies[movie.id] == nil {
                moviesState.movies[movie.id] = movie
            }
        }
        peoplesState.peoples[0] = sampleCasts.first!
        peoplesState.peoples[1] = sampleCasts[1]
        peoplesState.peoplesMovies[0] = Set(sampleCasts.map { $0.id })
    }
    
    func archiveState() {
        let moviesState = self.moviesState
        let peoplesState = self.peoplesState
        DispatchQueue.global().async {
            let movies = moviesState.movies.filter { (arg) -> Bool in
                let (key, _) = arg
                return moviesState.seenlist.contains(key) ||
                    moviesState.wishlist.contains(key) ||
                    moviesState.customLists.contains(where: { (_, value) -> Bool in
                        value.movies.contains(key) ||
                            value.cover == key
                    })
            }
            let people = peoplesState.peoples.filter{ peoplesState.fanClub.contains($0.key) }
            var savingState = self
            savingState.moviesState.movies = movies
            savingState.peoplesState.peoples = people
            guard let data = try? encoder.encode(savingState) else {
                return
            }
            guard let savePath = savePath else {
                return
            }
            do {
                try data.write(to: savePath)
            } catch let error {
                print("Error while saving app state :\(error)")
            }
        }
       
    }
    
    func sizeOfArchivedState() -> String {
        guard let savePath = savePath else {
            return "0"
        }
        do {
            let resources = try savePath.resourceValues(forKeys:[.fileSizeKey])
            let formatter = ByteCountFormatter()
            formatter.allowedUnits = .useKB
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(resources.fileSize ?? 0))
        } catch {
            return "0"
        }
    }
    
    #if DEBUG
    init(moviesState: MoviesState, peoplesState: PeoplesState) {
        self.moviesState = moviesState
        self.peoplesState = peoplesState
    }
    #endif

    private static func makeSavePath() -> URL? {
        let fileManager = FileManager.default
        let ubiquityDirectory = fileManager.url(forUbiquityContainerIdentifier: nil)

        if let ubiquityDirectory = ubiquityDirectory {
            try? fileManager.startDownloadingUbiquitousItem(at: ubiquityDirectory)
            return ubiquityDirectory.appendingPathComponent("userData")
        }

        if let documentDirectory = try? fileManager.url(for: .documentDirectory,
                                                         in: .userDomainMask,
                                                         appropriateFor: nil,
                                                         create: true) {
            return documentDirectory.appendingPathComponent("userData")
        }

        return fileManager.temporaryDirectory.appendingPathComponent("userData")
    }
}
