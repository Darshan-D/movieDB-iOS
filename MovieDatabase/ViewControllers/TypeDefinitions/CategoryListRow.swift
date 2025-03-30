//
//  CategoryListRow.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

import Foundation

// Type of row content when displaying categories
enum CategoryListRow {
    // Represents sub menu i.e "2023", "Action"
    case categoryValue(value: String, isExpanded: Bool)
    
    // Movie shown below an expanded value
    case movieUnderValue(Movie)
    
    // Movie shown in the "All Movies" section
    case allMoviesItem(Movie)
}
