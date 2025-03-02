//
//  PhotosViewerViewController.swift
//  Test
//
//  Created by Danil Otmakhov on 02.03.2025.
//

import UIKit

final class PhotosViewerViewController: UIViewController {

    private let photos: [UIImage]
    private var currentIndex: Int

    private let imageView = UIImageView()
    private let scrollView = UIScrollView()

    init(photos: [UIImage], startIndex: Int) {
        self.photos = photos
        self.currentIndex = startIndex
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        updateImage()
    }

    private func setupView() {
        view.backgroundColor = .black
        
        scrollView.frame = view.bounds
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.contentSize = view.bounds.size
        scrollView.delegate = self
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissViewer))
        view.addGestureRecognizer(tapGesture)

        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeLeft))
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)

        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
    }

    private func updateImage() {
        imageView.image = photos[currentIndex]
    }

    @objc private func dismissViewer() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func swipeLeft() {
        guard currentIndex < photos.count - 1 else { return }
        currentIndex += 1
        updateImage()
    }

    @objc private func swipeRight() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        updateImage()
    }
}

// MARK: - UIScrollViewDelegate

extension PhotosViewerViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
}
