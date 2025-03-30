//
//  MovieDetailViewController.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import UIKit

class MovieDetailViewController: UIViewController {

    // MARK: - Constants
    
    private static let verticalPadding: CGFloat = 16
    private static let horizontalPadding: CGFloat = 16
    private static let sectionSpacing: CGFloat = 24
    private static let elementSpacing: CGFloat = 8
    private static let posterMaxHeightMultiplier: CGFloat = 0.4
    private static let posterAspectRatio: CGFloat = 2.0 / 3.0

    // MARK: - Properties
    
    var movie: Movie!
    private var imageLoadTask: URLSessionDataTask?

    // MARK: - Lazy vars

    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = true
        return scrollView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = MovieDetailViewController.elementSpacing
        return stackView
    }()

    private lazy var posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground

        // Initialize with a place holder image
        imageView.image = UIImage(systemName: "film")
        imageView.tintColor = .placeholderText
        return imageView
    }()

    private lazy var titleLabel: UILabel = createLabel(
        font: .preferredFont(forTextStyle: .title1, compatibleWith: traitCollection).bold(),
        textColor: .label,
        alignment: .center,
        numberOfLines: 0
    )

    private lazy var releasedLabel: UILabel = createLabel(
        font: .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection),
        textColor: .secondaryLabel,
        alignment: .center
    )

    private lazy var genreLabel: UILabel = createLabel(
        font: .preferredFont(forTextStyle: .subheadline, compatibleWith: traitCollection),
        textColor: .secondaryLabel,
        alignment: .center,
        numberOfLines: 0
    )

    private lazy var plotHeaderLabel: UILabel = createHeaderLabel(text: "Plot Summary")

    private lazy var plotLabel: UILabel = createLabel(
        font: .preferredFont(forTextStyle: .body, compatibleWith: traitCollection),
        textColor: .label,
        alignment: .natural,
        numberOfLines: 0
    )

    private lazy var castHeaderLabel: UILabel = createHeaderLabel(text: "Cast & Crew")

    private lazy var castCrewLabel: UILabel = createLabel(
        font: .preferredFont(forTextStyle: .footnote, compatibleWith: traitCollection),
        textColor: .label,
        alignment: .natural,
        numberOfLines: 0
    )

    private lazy var ratingHeaderLabel: UILabel = createHeaderLabel(text: "Ratings")

    private lazy var ratingControlView: RatingControlView = {
        let view = RatingControlView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        guard movie != nil else {
            print("MovieDetailViewController initialized without a movie")
            return
        }

        view.backgroundColor = .systemBackground
        setupLayout()
        configureViewData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        imageLoadTask?.cancel()
    }

    // MARK: - Setup & Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        scrollView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: MovieDetailViewController.verticalPadding),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: MovieDetailViewController.horizontalPadding),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -MovieDetailViewController.horizontalPadding),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -MovieDetailViewController.verticalPadding),

            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(MovieDetailViewController.horizontalPadding * 2))
        ])

        contentStackView.addArrangedSubview(posterImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(releasedLabel)
        contentStackView.addArrangedSubview(genreLabel)
        contentStackView.addArrangedSubview(plotHeaderLabel)
        contentStackView.addArrangedSubview(plotLabel)
        contentStackView.addArrangedSubview(castHeaderLabel)
        contentStackView.addArrangedSubview(castCrewLabel)
        contentStackView.addArrangedSubview(ratingHeaderLabel)
        contentStackView.addArrangedSubview(ratingControlView)

        contentStackView.setCustomSpacing(MovieDetailViewController.sectionSpacing, after: posterImageView)
        contentStackView.setCustomSpacing(MovieDetailViewController.sectionSpacing, after: genreLabel)
        contentStackView.setCustomSpacing(MovieDetailViewController.sectionSpacing, after: plotLabel)
        contentStackView.setCustomSpacing(MovieDetailViewController.sectionSpacing, after: castCrewLabel)

         NSLayoutConstraint.activate([
            posterImageView.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: MovieDetailViewController.posterMaxHeightMultiplier)
        ])

    }

    // MARK: - Data Configuration

    private func configureViewData() {
        self.title = movie.title

        titleLabel.text = movie.title
        releasedLabel.text = "Released: \(movie.released ?? "N/A")"
        genreLabel.text = "Genre: \(formatCommaSeparatedString(movie.genre) ?? "N/A")"
        plotLabel.text = movie.plot ?? "Plot information not available."

        castCrewLabel.text = formatCastCrewString(director: movie.director, actors: movie.actors)

        ratingControlView.configure(with: movie.ratings ?? [])

        loadImage(from: movie.poster)
    }

    // MARK: - Image Loading

    private func loadImage(from urlString: String?) {
        imageLoadTask?.cancel()
        posterImageView.image = UIImage(systemName: "film")
        posterImageView.tintColor = .placeholderText

        guard let urlString = urlString,
              urlString.lowercased() != "n/a",
              let url = URL(string: urlString) else {
            return
        }

        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }

            // Check for task cancellation
            guard (error as? URLError)?.code != .cancelled else { return }

            guard error == nil, let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async {
                    self.posterImageView.image = UIImage(systemName: "exclamationmark.circle")
                    self.posterImageView.tintColor = .systemRed
                }
                
                return
            }

            DispatchQueue.main.async {
                self.posterImageView.image = image
            }
        }
        
        imageLoadTask?.resume()
    }

     // MARK: - Helper Methods

    private func createLabel(font: UIFont, textColor: UIColor, alignment: NSTextAlignment = .natural, numberOfLines: Int = 1) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = font
        label.textColor = textColor
        label.textAlignment = alignment
        label.numberOfLines = numberOfLines
        return label
    }

    private func createHeaderLabel(text: String) -> UILabel {
        let label = createLabel(
            font: .preferredFont(forTextStyle: .headline, compatibleWith: traitCollection),
            textColor: .label,
            alignment: .natural,
            numberOfLines: 1
        )
        
        label.text = text
        return label
    }

    // Helper to format comma-separated strings cleanly
    private func formatCommaSeparatedString(_ input: String?) -> String? {
        guard let input = input?.trimmingCharacters(in: .whitespacesAndNewlines),
              !input.isEmpty, input.lowercased() != "n/a" else {
            return nil
        }

        return input.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .joined(separator: ", ")
    }

    // Helper to format the combined cast/crew string
    private func formatCastCrewString(director: String?, actors: String?) -> String {
        var components: [String] = []
        if let formattedDirectors = formatCommaSeparatedString(director) {
            components.append("Director(s): \(formattedDirectors)")
        }
        if let formattedActors = formatCommaSeparatedString(actors) {
            components.append("Actors: \(formattedActors)")
        }
        return components.isEmpty ? "Cast & Crew: N/A" : components.joined(separator: "\n")
    }
}

// MARK: - UIFont Extension

extension UIFont {
    // Helper to easily get a bold version of a preferred font
    func bold() -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
