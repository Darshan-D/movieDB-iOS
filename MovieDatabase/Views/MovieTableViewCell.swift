//
//  MovieTableViewCell.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import UIKit

class MovieTableViewCell: UITableViewCell {
    
    // MARK: - Static constants
    
    static let identifier = "MovieTableViewCell"
    
    // MARK: - Lazy vars
    
    private lazy var posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 4
        imageView.image = UIImage(systemName: "film")
        imageView.tintColor = .placeholderText
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var yearLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 13, weight: .regular)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var labelStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, languageLabel, yearLabel])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.alignment = .leading
        return stackView
    }()
    
    private var imageLoadTask: URLSessionDataTask?
    
    // MARK: - Initializars
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
        accessoryType = .disclosureIndicator
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        contentView.addSubview(posterImageView)
        contentView.addSubview(labelStackView)
    }
    
    private func setupConstraints() {
        let verticalPadding: CGFloat = 10
        let horizontalPadding: CGFloat = 15
        let posterWidth: CGFloat = 60
        let posterHeight: CGFloat = posterWidth * 1.5
        
        NSLayoutConstraint.activate([
            posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalPadding),
            posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: verticalPadding),
            posterImageView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -verticalPadding),
            posterImageView.widthAnchor.constraint(equalToConstant: posterWidth),
            posterImageView.heightAnchor.constraint(equalToConstant: posterHeight),
            
            labelStackView.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: horizontalPadding),
            labelStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalPadding),
            labelStackView.topAnchor.constraint(equalTo: posterImageView.topAnchor),
            labelStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -verticalPadding),
        ])
    }
    
    // MARK: - Configuration
    
    func configure(with movie: Movie) {
        titleLabel.text = movie.title
        languageLabel.text = "Language: \(formatCommaSeparatedString(movie.language) ?? "N/A")"
        yearLabel.text = "Year: \(movie.year)"
        
        loadImage(from: movie.poster)
    }
    
    // MARK: - Image Loading
    
    private func loadImage(from urlString: String?) {
        // Cancel previous task if any
        imageLoadTask?.cancel()
        posterImageView.image = UIImage(systemName: "film")
        posterImageView.tintColor = .placeholderText
        
        
        guard let urlString = urlString,
              urlString.lowercased() != "n/a",
              let url = URL(string: urlString) else {
            return
        }
        
        imageLoadTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
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
    
    // MARK: - Private helpers
    
    private func formatCommaSeparatedString(_ input: String?) -> String? {
        guard let input = input, !input.isEmpty, input.lowercased() != "n/a" else {
            return nil
        }
        
        // Replace commas with ", " for better readability
        return input.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
