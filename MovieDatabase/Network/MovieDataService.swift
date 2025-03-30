//
//  MovieDataService.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import Foundation

// Responsible to read json and make data consumable
class MovieDataService {
    static let shared = MovieDataService() // Singleton

    private(set) var allMovies: [Movie] = []
    private(set) var uniqueYears: [String] = []
    private(set) var uniqueGenres: [String] = []
    private(set) var uniqueDirectors: [String] = []
    private(set) var uniqueActors: [String] = []

    private init() {
        loadMovies()
        prepareCategories()
    }

    private func loadMovies() {
        guard let url = Bundle.main.url(forResource: "movies", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: Could not find or load movies.json")
            return
        }

        do {
            let decoder = JSONDecoder()
            allMovies = try decoder.decode(Movies.self, from: data)
        } catch {
            print("Error: Could not decode movies.json: \(error)")
        }
    }

    private func prepareCategories() {
        var yearsSet = Set<String>()
        var genresSet = Set<String>()
        var directorsSet = Set<String>()
        var actorsSet = Set<String>()

        for movie in allMovies {
            // Avoid adding empty or N/A years
             if !movie.year.isEmpty && movie.year.lowercased() != "n/a" {
                 yearsSet.insert(movie.year)
             }
            
            // Use the helper function which handles optionals and splitting
            genresSet.formUnion(splitAndTrim(movie.genre))
            directorsSet.formUnion(splitAndTrim(movie.director))
            actorsSet.formUnion(splitAndTrim(movie.actors))
        }

        // Sort alphabetically for consistency
        uniqueYears = Array(yearsSet).sorted()
        uniqueGenres = Array(genresSet).sorted()
        uniqueDirectors = Array(directorsSet).sorted()
        uniqueActors = Array(actorsSet).sorted()
    }

    // Helper to split comma-separated strings and trim whitespace
    private func splitAndTrim(_ input: String?) -> [String] {
        guard let input = input else {
            return []
        }

        return input.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && $0.lowercased() != "n/a" }
    }

    // MARK: - APIs

    func movies(forYear year: String) -> [Movie] {
        return allMovies.filter { $0.year == year }
    }

    func movies(forGenre genre: String) -> [Movie] {
        return allMovies.filter { splitAndTrim($0.genre).contains(genre) }
    }

    func movies(forDirector director: String) -> [Movie] {
         return allMovies.filter { splitAndTrim($0.director).contains(director) }
    }

    func movies(forActor actor: String) -> [Movie] {
         return allMovies.filter { splitAndTrim($0.actors).contains(actor) }
    }

    func searchMovies(query: String) -> [Movie] {
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lowercasedQuery.isEmpty {
            return []
        }

        return allMovies.filter { movie in
            let titleMatch = movie.title.lowercased().contains(lowercasedQuery)
            let genreMatch = (movie.genre ?? "").lowercased().contains(lowercasedQuery)
            let directorMatch = (movie.director ?? "").lowercased().contains(lowercasedQuery)
            let actorMatch = (movie.actors ?? "").lowercased().contains(lowercasedQuery)

            return titleMatch || genreMatch || directorMatch || actorMatch
        }
    }
}
