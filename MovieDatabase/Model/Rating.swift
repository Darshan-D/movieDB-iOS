//
//  Rating.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

// Represents a single rating source and value
struct Rating: Codable {
    let source: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case source = "Source"
        case value = "Value"
    }
}
