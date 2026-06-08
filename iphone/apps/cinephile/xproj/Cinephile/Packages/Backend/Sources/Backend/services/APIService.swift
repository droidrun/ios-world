//
//  APIService.swift
//  Cinephile
//
//  Created by Thomas Ricouard on 06/06/2019.
//  Copyright © 2019 Thomas Ricouard. All rights reserved.
//

import Foundation

public struct APIService {
    let baseURL = URL(string: "https://api.themoviedb.org/3")!
    /// TMDB API key. Looked up from Info.plist (`TMDB_API_KEY`) so the key is
    /// not baked into source. Falls back to the original public demo key from
    /// the open-source Cinephile project for out-of-the-box benchmark runs;
    /// production/forked builds should override the Info.plist value and
    /// ideally rotate the fallback key below.
    let apiKey: String = {
        if let override = Bundle.main.object(forInfoDictionaryKey: "TMDB_API_KEY") as? String,
           !override.isEmpty {
            return override
        }
        return "1d9b898a212ea52e283351e521e17871"
    }()
    public static let shared = APIService()
    let decoder = JSONDecoder()
    
    public enum APIError: Error {
        case noResponse
        case jsonDecodingError(error: Error)
        case networkError(error: Error)
        case invalidRequest
    }
    
    public enum Endpoint {
        case popular, topRated, upcoming, nowPlaying, trending
        case movieDetail(movie: Int), recommended(movie: Int), similar(movie: Int), videos(movie: Int)
        case credits(movie: Int), review(movie: Int)
        case searchMovie, searchKeyword, searchPerson
        case popularPersons
        case personDetail(person: Int)
        case personMovieCredits(person: Int)
        case personImages(person: Int)
        case genres
        case discover
        
        func path() -> String {
            switch self {
            case .popular:
                return "movie/popular"
            case .popularPersons:
                return "person/popular"
            case .topRated:
                return "movie/top_rated"
            case .upcoming:
                return "movie/upcoming"
            case .nowPlaying:
                return "movie/now_playing"
            case .trending:
                return "trending/movie/day"
            case let .movieDetail(movie):
                return "movie/\(String(movie))"
            case let .videos(movie):
                return "movie/\(String(movie))/videos"
            case let .personDetail(person):
                return "person/\(String(person))"
            case let .credits(movie):
                return "movie/\(String(movie))/credits"
            case let .review(movie):
                return "movie/\(String(movie))/reviews"
            case let .recommended(movie):
                return "movie/\(String(movie))/recommendations"
            case let .similar(movie):
                return "movie/\(String(movie))/similar"
            case let .personMovieCredits(person):
                return "person/\(person)/movie_credits"
            case let .personImages(person):
                return "person/\(person)/images"
            case .searchMovie:
                return "search/movie"
            case .searchKeyword:
                return "search/keyword"
            case .searchPerson:
                return "search/person"
            case .genres:
                return "genre/movie/list"
            case .discover:
                return "discover/movie"
            }
        }
    }
    
    public func GET<T: Codable>(endpoint: Endpoint,
                         params: [String: String]?,
                         completionHandler: @escaping (Result<T, APIError>) -> Void) {
        let queryURL = baseURL.appendingPathComponent(endpoint.path())
        guard var components = URLComponents(url: queryURL, resolvingAgainstBaseURL: true) else {
            DispatchQueue.main.async {
                completionHandler(.failure(.noResponse))
            }
            return
        }
        let preferredLanguage = Locale.preferredLanguages.first ?? Locale.current.identifier
        components.queryItems = [
           URLQueryItem(name: "api_key", value: apiKey),
           URLQueryItem(name: "language", value: preferredLanguage)
        ]
        if let params = params {
            for (_, value) in params.enumerated() {
                components.queryItems?.append(URLQueryItem(name: value.key, value: value.value))
            }
        }
        guard let url = components.url else {
            DispatchQueue.main.async {
                completionHandler(.failure(.invalidRequest))
            }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async {
                    completionHandler(.failure(.networkError(error: error)))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completionHandler(.failure(.noResponse))
                }
                return
            }
            do {
                let object = try self.decoder.decode(T.self, from: data)
                DispatchQueue.main.async {
                    completionHandler(.success(object))
                }
            } catch let error {
                DispatchQueue.main.async {
                    #if DEBUG
                    print("JSON Decoding Error: \(error)")
                    #endif
                    completionHandler(.failure(.jsonDecodingError(error: error)))
                }
            }
        }
        task.resume()
    }
    
}
