//
//  PhotosView.swift
//  Test
//
//  Created by Danil Otmakhov on 26.02.2025.
//

import UIKit

final class PhotosView: UIView {
    
    private let stackView = UIStackView()
    
    private let photoCornerRadius = 8.0
    private let photoSize = CGSize(width: 55.0, height: 66.0)
    private let photosSpacing = 8.0
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
    }
    
}

// MARK: - Private

private extension PhotosView {
    
    func setupView() {
        addSubview(stackView)
        stackView.axis = .horizontal
        stackView.spacing = photosSpacing
    }
    
}

// MARK: - Internal

extension PhotosView {
    
    func updatePhotos(_ photos: [UIImage]) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for image in photos {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = photoCornerRadius
            imageView.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(imageView)
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: photoSize.width),
                imageView.heightAnchor.constraint(equalToConstant: photoSize.height)
            ])
        }
    }
}

