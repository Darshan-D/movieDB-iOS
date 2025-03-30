//
//  ExpandedValueState.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

import Foundation

struct ExpandedValueState {
    let sectionIndex: Int
    // Index of the value (e.g., "2023") within its original data source array `values(for:)`
    let dataSourceValueIndex: Int
    let moviesToShow: [Movie]
}
