//
//  HomeViewController+UISearchResultsUpdating.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

import UIKit

extension HomeViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        let wasSearching = currentDisplayMode == .searchResults

        if searchText.isEmpty {
            // Transition back to category list if search is cleared
            if wasSearching {
                currentDisplayMode = .categoryList
                searchResults = []
                resetCategoryExpansionState()
                tableView.reloadData()
            }
        } else {
            // Update search results
            currentDisplayMode = .searchResults
            searchResults = movieDataService.searchMovies(query: searchText)
            tableView.reloadData()
        }
    }

    // Helper to reset all expansion state (sections and values)
    private func resetCategoryExpansionState() {
        expandedSectionIndices.removeAll()
        expandedValueState = nil
    }
}
