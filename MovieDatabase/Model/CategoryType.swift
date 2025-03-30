//
//  CategoryType.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import Foundation

// Represents main categories on the home screen
enum CategoryType: String, CaseIterable {
    case year = "Year"
    case genre = "Genre"
    case directors = "Directors"
    case actors = "Actors"
    case allMovies = "All Movies"
}
