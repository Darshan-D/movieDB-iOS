//
//  HomeViewController+UITableViewDataSource.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 30/03/25.
//

import UIKit

extension HomeViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return (currentDisplayMode == .categoryList) ? movieCategories.count : 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch currentDisplayMode {
        case .searchResults:
            return searchResults.count
        case .categoryList:
            // Return 0 if the section itself isn't expanded
            guard expandedSectionIndices.contains(section) else { return 0 }

            let categoryType = movieCategories[section]
            if categoryType == .allMovies {
                return movieDataService.allMovies.count
            }

            // Start with the count of values (e.g., number of years)
            let valueCount = categoryValues(forSection: section).count
            var totalRowCount = valueCount

            // If a value within this section is expanded, add the count of its movies
            if let currentExpandedValue = expandedValueState, currentExpandedValue.sectionIndex == section {
                totalRowCount += currentExpandedValue.moviesToShow.count
            }
            return totalRowCount
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch currentDisplayMode {
        case .searchResults:
            let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath) as! MovieTableViewCell
            guard indexPath.row < searchResults.count else { return UITableViewCell() }
            cell.configure(with: searchResults[indexPath.row])
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
            return cell

        case .categoryList:
            // Determine the type of cell i.e verify if it's category cell (eg - "Year") or value cell (eg - "2000")
            guard let rowContent = getCategoryListRowContent(for: indexPath) else {
                assertionFailure("Could not determine row content for indexPath: \(indexPath)")
                return UITableViewCell()
            }

            // Configure the cell based on the row content type
            switch rowContent {
            case .categoryValue(let value, _):
                let cell = tableView.dequeueReusableCell(withIdentifier: HomeViewController.categoryValueCellIdentifier, for: indexPath)
                cell.textLabel?.text = value
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
                return cell

            case .movieUnderValue(let movie), .allMoviesItem(let movie):
                let cell = tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath) as! MovieTableViewCell
                cell.configure(with: movie)
                cell.accessoryType = .disclosureIndicator
                cell.selectionStyle = .default
                return cell
            }
        }
    }
}
