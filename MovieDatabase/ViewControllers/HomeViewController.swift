//
//  ViewController.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import UIKit

class HomeViewController: UIViewController {

    // MARK: - Constants

    static let categoryValueCellIdentifier = "CategoryValueCell"
    static let customCategoryHeaderIdentifier = "CustomCategoryHeader"
    static let animationDuration: TimeInterval = 0.2

    // MARK: - Properties

    let movieCategories: [CategoryType] = CategoryType.allCases
    let movieDataService = MovieDataService.shared

    var currentDisplayMode: DisplayMode = .categoryList
    var searchResults: [Movie] = []
    // Indices of category sections whose contents (values or all movies) are visible
    var expandedSectionIndices: Set<Int> = Set()
    // Holds state if a specific "categoryValue" row is expanded to show movies
    var expandedValueState: ExpandedValueState? = nil

    // MARK: - Lazy vars
    
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.placeholder = "Search movies by title/genre/actor/director"
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: HomeViewController.categoryValueCellIdentifier)
        tableView.register(MovieTableViewCell.self, forCellReuseIdentifier: MovieTableViewCell.identifier)
        return tableView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupNavigationBar()
        setupTableViewLayout()
    }

    // MARK: - Setup
    
    private func setupNavigationBar() {
        title = "Movie Database"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupTableViewLayout() {
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Data Helpers
    
    /// Returns the list of specific values (like years, genres) for a category section.
    func categoryValues(forSection sectionIndex: Int) -> [String] {
        guard sectionIndex >= 0 && sectionIndex < movieCategories.count else { return [] }
        let categoryType = movieCategories[sectionIndex]
        switch categoryType {
        case .year: return movieDataService.uniqueYears
        case .genre: return movieDataService.uniqueGenres
        case .directors: return movieDataService.uniqueDirectors
        case .actors: return movieDataService.uniqueActors
        // All Movies section doesn't have "values" in this context
        case .allMovies: return []
        }
    }

    /// Returns the movies associated with a specific value (like "Action") within a category.
    func movies(forValue value: String, in categoryType: CategoryType) -> [Movie] {
        switch categoryType {
        case .year: return movieDataService.movies(forYear: value)
        case .genre: return movieDataService.movies(forGenre: value)
        case .directors: return movieDataService.movies(forDirector: value)
        case .actors: return movieDataService.movies(forActor: value)
        // Should not be called this way for All Movies
        case .allMovies: return []
        }
    }

    /// Determines the logical content type for a row at a given visual index path in category list mode.
    func getCategoryListRowContent(for indexPath: IndexPath) -> CategoryListRow? {
        let sectionIndex = indexPath.section
        let displayRowIndex = indexPath.row // Explicitly name the visual row index
        guard sectionIndex >= 0 && sectionIndex < movieCategories.count else { return nil }

        let categoryType = movieCategories[sectionIndex]

        // Handle "All Movies" section directly
        if categoryType == .allMovies {
            guard displayRowIndex >= 0 && displayRowIndex < movieDataService.allMovies.count else { return nil }
            return .allMoviesItem(movieDataService.allMovies[displayRowIndex])
        }

        // Handle other categories (Year, Genre, etc.)
        let values = categoryValues(forSection: sectionIndex)

        if let currentExpandedValue = expandedValueState, currentExpandedValue.sectionIndex == sectionIndex {
            let expandedDataSourceValueIdx = currentExpandedValue.dataSourceValueIndex
            let expandedMovieCount = currentExpandedValue.moviesToShow.count

            // Determine if the row is before, within, or after the expanded movie block
            if displayRowIndex >= 0 && displayRowIndex <= expandedDataSourceValueIdx { // Value row at or before expanded one
                guard displayRowIndex < values.count else { return nil }
                let isTheExpandedValue = (displayRowIndex == expandedDataSourceValueIdx)
                return .categoryValue(value: values[displayRowIndex], isExpanded: isTheExpandedValue)

            } else if displayRowIndex > expandedDataSourceValueIdx && displayRowIndex <= expandedDataSourceValueIdx + expandedMovieCount { // Movie row under the value
                let movieIndexWithinExpansion = displayRowIndex - expandedDataSourceValueIdx - 1
                guard movieIndexWithinExpansion >= 0 && movieIndexWithinExpansion < currentExpandedValue.moviesToShow.count else { return nil }
                return .movieUnderValue(currentExpandedValue.moviesToShow[movieIndexWithinExpansion])

            } else { // Value row after the expanded movie block
                let dataSourceValueIdx = displayRowIndex - expandedMovieCount
                guard dataSourceValueIdx >= 0 && dataSourceValueIdx < values.count else { return nil }
                return .categoryValue(value: values[dataSourceValueIdx], isExpanded: false)
            }
        } else { // No value is expanded in this section, so it must be a category value row
            guard displayRowIndex >= 0 && displayRowIndex < values.count else { return nil }
            return .categoryValue(value: values[displayRowIndex], isExpanded: false)
        }
    }
}
