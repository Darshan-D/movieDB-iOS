//
//  RatingControlView.swift
//  MovieDatabase
//
//  Created by Darshan Dodia on 29/03/25.
//

import Foundation
import UIKit

class RatingControlView: UIView {
    
    // MARK: - Properties
    
    private var availableRatings: [Rating] = []
    private let defaultRatingSource = "Internet Movie Database"
    
    // MARK: - UI Elements
    
    private lazy var segmentedControl: UISegmentedControl = {
        let control = UISegmentedControl()
        control.addTarget(self, action: #selector(ratingSourceChanged), for: .valueChanged)
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()
    
    private lazy var ratingLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.7
        label.text = "---"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var sourceLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        label.textColor = UIColor.secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 1
        label.text = "Select a source"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    
    // MARK: - Initializer
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private helpers
    
    private func addSubviews() {
        addSubview(segmentedControl)
        addSubview(ratingLabel)
        addSubview(sourceLabel)
    }
    
    private func setupConstraints() {
        let padding: CGFloat = 8
        
        NSLayoutConstraint.activate([
            segmentedControl.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            segmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding * 2),
            segmentedControl.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding * 2),
            
            ratingLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: padding * 1.5),
            ratingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            ratingLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: padding),
            ratingLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -padding),
            
            sourceLabel.topAnchor.constraint(equalTo: ratingLabel.bottomAnchor, constant: padding * 0.5),
            sourceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            sourceLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            sourceLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding)
        ])
    }
    
    private func updateRatingDisplay() {
        guard segmentedControl.selectedSegmentIndex != UISegmentedControl.noSegment,
              segmentedControl.selectedSegmentIndex < availableRatings.count else {
            ratingLabel.text = "---"
            sourceLabel.text = "Error"
            return
        }
        
        let selectedRating = availableRatings[segmentedControl.selectedSegmentIndex]
        ratingLabel.text = selectedRating.value
        sourceLabel.text = selectedRating.source
    }
    
    private func displayTitle(for source: String) -> String {
        switch source {
        case "Internet Movie Database": return "IMDb"
        case "Rotten Tomatoes": return "Tomatoes"
        case "Metacritic": return "Metacritic"
        default: return source
        }
    }
    
    // MARK: - API
    
    func configure(with ratings: [Rating]) {
        self.availableRatings = ratings
        segmentedControl.removeAllSegments()
        
        guard !ratings.isEmpty else {
            segmentedControl.isHidden = true
            ratingLabel.text = "N/A"
            sourceLabel.text = "No ratings available"
            return
        }
        
        segmentedControl.isHidden = false
        var defaultIndex = UISegmentedControl.noSegment
        
        for (index, rating) in ratings.enumerated() {
            let title = displayTitle(for: rating.source)
            segmentedControl.insertSegment(withTitle: title, at: index, animated: false)
            if rating.source == defaultRatingSource {
                defaultIndex = index
            }
        }
        
        segmentedControl.selectedSegmentIndex = (defaultIndex != UISegmentedControl.noSegment) ? defaultIndex : 0
        updateRatingDisplay()
    }
    
    // MARK: - Actions
    
    @objc private func ratingSourceChanged() {
        updateRatingDisplay()
    }
}
