//
//  HomeViewController+UITableViewDelegate.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

import UIKit

extension HomeViewController: UITableViewDelegate {

    // MARK: Header Configuration
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard currentDisplayMode == .categoryList else { return nil }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: HomeViewController.customCategoryHeaderIdentifier) as? CustomCategoryHeaderView ?? createCustomHeaderView(forSection: section)
        configureHeaderView(headerView, forSection: section)
        return headerView
    }

    private func createCustomHeaderView(forSection sectionIndex: Int) -> CustomCategoryHeaderView {
        let headerView = CustomCategoryHeaderView(reuseIdentifier: HomeViewController.customCategoryHeaderIdentifier)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleCategoryHeaderTap(_:)))
        headerView.addGestureRecognizer(tapGesture)
        return headerView
    }

    private func configureHeaderView(_ headerView: CustomCategoryHeaderView, forSection sectionIndex: Int) {
        guard sectionIndex >= 0 && sectionIndex < movieCategories.count else { return }
        headerView.titleLabel.text = movieCategories[sectionIndex].rawValue
        // Tag stores the section index
        headerView.tag = sectionIndex
        headerView.setExpanded(expandedSectionIndices.contains(sectionIndex))
    }
    
    // MARK: Header Interaction (Section Expand/Collapse)
    
    @objc private func handleCategoryHeaderTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let tappedHeaderView = gestureRecognizer.view as? CustomCategoryHeaderView,
              let sectionIndex = gestureRecognizer.view?.tag else { return }

        tableView.beginUpdates()

        let wasSectionExpanded = expandedSectionIndices.contains(sectionIndex)

        // If this section was expanded, collapse it first
        if wasSectionExpanded {
            // Determine all currently visible rows in this section before changing state
            let numberOfRowsToDelete = tableView.numberOfRows(inSection: sectionIndex)
            let indexPathsToDelete = (0..<numberOfRowsToDelete).map { rowIdx in
                IndexPath(row: rowIdx, section: sectionIndex)
            }

            // Update the state after calculating rows to delete
            expandedSectionIndices.remove(sectionIndex)

            if expandedValueState?.sectionIndex == sectionIndex {
                expandedValueState = nil
            }

            if !indexPathsToDelete.isEmpty {
                tableView.deleteRows(at: indexPathsToDelete, with: .fade)
            }

        } else {
            // We need to expand this section
            expandedSectionIndices.insert(sectionIndex)
            let categoryType = movieCategories[sectionIndex]
            let rowCount = (categoryType == .allMovies) ? movieDataService.allMovies.count : categoryValues(forSection: sectionIndex).count
            let indexPathsToInsert = (0..<rowCount).map { IndexPath(row: $0, section: sectionIndex) }
            if !indexPathsToInsert.isEmpty {
                tableView.insertRows(at: indexPathsToInsert, with: .fade)
            }
        }

        tableView.endUpdates()

        // Update the tapped header's arrow
        tappedHeaderView.setExpanded(!wasSectionExpanded)
    }
    

    // MARK: Row Selection (Value Expand/Collapse or Navigation)
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch currentDisplayMode {
        case .searchResults:
            guard indexPath.row < searchResults.count else { return }
            navigateToMovieDetail(for: searchResults[indexPath.row])

        case .categoryList:
            // Determine what kind of row was tapped
            guard let rowContent = getCategoryListRowContent(for: indexPath) else { return }

            switch rowContent {
            case .categoryValue:
                // Tapped a value row (e.g., "2023", "Action")
                // Find its original index in the data source array
                if let dataSourceIdx = findDataSourceValueIndex(forDisplayRow: indexPath.row, inSection: indexPath.section) {
                    // Toggle the expansion state for this value
                    toggleValueExpansion(dataSourceValueIndex: dataSourceIdx, inSection: indexPath.section)
                }
            case .movieUnderValue(let movie), .allMoviesItem(let movie):
                // Tapped a movie row
                navigateToMovieDetail(for: movie)
            }
        }
    }

    /// Translates a visual row index (in category list mode) to its original data source index within the `categoryValues(forSection:)` array, accounting for inserted movie rows.
    private func findDataSourceValueIndex(forDisplayRow displayRowIndex: Int, inSection sectionIndex: Int) -> Int? {
        // We only need this translation if the row is actually a categoryValue type.
        guard let rowContent = getCategoryListRowContent(for: IndexPath(row: displayRowIndex, section: sectionIndex)),
              case .categoryValue = rowContent else {
            // If it's not a value row (e.g., it's a movie row), it doesn't have a direct index
            // in the categoryValues array, so return nil.
            return nil
        }

        // If a value is expanded in this section, check if the tapped row is after the movies
        if let currentExpandedValue = expandedValueState, currentExpandedValue.sectionIndex == sectionIndex {
            let expandedValueIdx = currentExpandedValue.dataSourceValueIndex
            let movieCount = currentExpandedValue.moviesToShow.count

            // If the displayed row is positioned after the expanded value and its movies
            if displayRowIndex > expandedValueIdx + movieCount {
                // Subtract the number of inserted movie rows to get the original index
                return displayRowIndex - movieCount
            }
        }

        // Otherwise (no value expanded, or tapped row is at/before expanded value),
        // the display row index directly corresponds to the data source index.
        return displayRowIndex
    }


    // MARK: - Value Expand/Collapse Logic
    /// Handles expanding/collapsing the movie list under a specific category value row.
    private func toggleValueExpansion(dataSourceValueIndex: Int, inSection sectionIndex: Int) {

        if let previouslyExpanded = expandedValueState {
            if previouslyExpanded.sectionIndex == sectionIndex && previouslyExpanded.dataSourceValueIndex == dataSourceValueIndex {
                // If the tap is on the currently expanded value, collapse it
                collapseMoviesUnderValue(inSection: previouslyExpanded.sectionIndex)
            } else {
                // If the tap is on different value, collapse previously expanded value, then expand new one
                collapseMoviesUnderValue(inSection: previouslyExpanded.sectionIndex)
                expandMoviesUnderValue(atDataSourceIndex: dataSourceValueIndex, inSection: sectionIndex)
            }
        } else {
            // No value was previously expanded, just expand the new one
            expandMoviesUnderValue(atDataSourceIndex: dataSourceValueIndex, inSection: sectionIndex)
        }
    }

    /// Inserts movie rows below a specified value row.
    private func expandMoviesUnderValue(atDataSourceIndex dataSourceValueIndex: Int, inSection sectionIndex: Int) {
        guard sectionIndex >= 0 && sectionIndex < movieCategories.count else {
            return
        }
        
        let categoryType = movieCategories[sectionIndex]
        let values = categoryValues(forSection: sectionIndex)
        
        guard dataSourceValueIndex >= 0 && dataSourceValueIndex < values.count else {
            return
        }

        let value = values[dataSourceValueIndex]
        let movies = self.movies(forValue: value, in: categoryType)

        // Don't expand if there are no movies for this value
        guard !movies.isEmpty else {
            print("No movies found for \(categoryType.rawValue): \(value)")

            // Ensure state is nil if expansion attempt fails
            if expandedValueState?.sectionIndex == sectionIndex && expandedValueState?.dataSourceValueIndex == dataSourceValueIndex {
                 expandedValueState = nil
            }

            return
        }

        expandedValueState = ExpandedValueState(sectionIndex: sectionIndex,
                                                dataSourceValueIndex: dataSourceValueIndex,
                                                moviesToShow: movies)

        // Calculate index paths for the movie rows to be inserted
        let indexPathsToInsert = (0..<movies.count).map { movieIndexOffset in
            // Movies are inserted below the value row (index + 1)
            IndexPath(row: dataSourceValueIndex + 1 + movieIndexOffset, section: sectionIndex)
        }

        if !indexPathsToInsert.isEmpty {
            tableView.insertRows(at: indexPathsToInsert, with: .fade)
        }
    }

    /// Removes movie rows from below the currently expanded value row in a section.
    private func collapseMoviesUnderValue(inSection sectionIndex: Int) {
        // Ensure there is an expanded value in this section to collapse
        guard let currentExpandedValue = expandedValueState, currentExpandedValue.sectionIndex == sectionIndex else {
            return
        }

        let valueIdx = currentExpandedValue.dataSourceValueIndex
        let movieCount = currentExpandedValue.moviesToShow.count

        expandedValueState = nil

        // Calculate index paths for the movie rows to be removed
        let indexPathsToRemove = (0..<movieCount).map { movieIndexOffset in
            IndexPath(row: valueIdx + 1 + movieIndexOffset, section: sectionIndex)
        }

        if !indexPathsToRemove.isEmpty {
            tableView.deleteRows(at: indexPathsToRemove, with: .fade)
        }
    }

    // MARK: Navigation
    
    private func navigateToMovieDetail(for movie: Movie) {
        let detailVC = MovieDetailViewController()
        detailVC.movie = movie
        navigationController?.pushViewController(detailVC, animated: true)
    }
}
