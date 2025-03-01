import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?
    /// Замыкание, вызываемое при обновлении.
    var onRefreshComplete: (() -> Void)?
    
    private var isPullToRefresh: Bool = false

    private var state: State
    private let reviewsProvider: ReviewsProvider
    private let ratingRenderer: RatingRenderer
    private let decoder: JSONDecoder

    init(
        state: State = State(),
        reviewsProvider: ReviewsProvider = ReviewsProvider(),
        ratingRenderer: RatingRenderer = RatingRenderer(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.state = state
        self.reviewsProvider = reviewsProvider
        self.ratingRenderer = ratingRenderer
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

}

// MARK: - Internal

extension ReviewsViewModel {

    typealias State = ReviewsViewModelState

    /// Метод получения отзывов.
    func getReviews() {
        guard state.shouldLoad else { return }
        state.shouldLoad = false
        reviewsProvider.getReviews(completion: gotReviews)
    }
    
    func refreshReviews() {
        isPullToRefresh = true
        state.items = []
        state.offset = 0
        state.shouldLoad = true
        onStateChange?(state)
        getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewModel {
    
    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            updateState(reviews)
        } catch {
            print(error.localizedDescription)
            state.shouldLoad = true
        }
        onStateChange?(state)
        
        if isPullToRefresh {
            onRefreshComplete?()
            isPullToRefresh = false
        }
    }
    
    func updateState(_ reviews: Reviews) {
        state.items += reviews.items[0..<min(state.limit, reviews.count - state.offset)].map(makeReviewItem)
        state.offset += min(state.limit, reviews.count - state.offset)
        state.shouldLoad = state.items.count < reviews.count
        
        if !state.shouldLoad {
            let totalReviewsConfig = makeTotalReviewsItem(reviews)
            state.items.append(totalReviewsConfig)
        }
    }

    /// Метод, вызываемый при нажатии на кнопку "Показать полностью...".
    /// Снимает ограничение на количество строк текста отзыва (раскрывает текст).
    func showMoreReview(with id: UUID) {
        guard
            let index = state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == id }),
            var item = state.items[index] as? ReviewCellConfig
        else { return }
        item.maxLines = .zero
        state.items[index] = item
        onStateChange?(state)
    }
    
    func fetchAvatar(from avatarUrl: String, _ configID: UUID) {
        ImageProvider.shared.fetchImage(from: avatarUrl) { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let image):
                if let index = state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == configID }),
                   var updatedItem = state.items[index] as? ReviewCellConfig {
                    updatedItem.updateAvatar(with: image)
                    state.items[index] = updatedItem
                    onStateChange?(state)
                }
            case .failure:
                break
            }
        }
    }
    
    func fetchPhotos(from urls: [String], configID: UUID) {
        var fetchedImages = [UIImage]()
        
        let dispatchGroup = DispatchGroup()
        
        for url in urls {
            dispatchGroup.enter()
            ImageProvider.shared.fetchImage(from: url) { result in
                switch result {
                case .success(let image):
                    fetchedImages.append(image)
                case .failure:
                    break
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if let index = self.state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == configID }),
               var updatedItem = self.state.items[index] as? ReviewCellConfig {
                updatedItem.updatePhotos(with: fetchedImages)
                self.state.items[index] = updatedItem
                self.onStateChange?(self.state)
            }
        }
    }


}

// MARK: - Items

private extension ReviewsViewModel {
    
    func makeReviewItem(_ review: Review) -> ReviewCellConfig {
        let avatar = UIImage(named: "userpick")!
        let userName = "\(review.firstName) \(review.lastName)".attributed(font: .username)
        let ratingImage = ratingRenderer.ratingImage(review.rating)
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let config = ReviewCellConfig(
            avatar: avatar,
            userName: userName,
            ratingImage: ratingImage,
            photos: nil,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview
        )
        
        if let avatarUrl = review.avatarUrl {
            fetchAvatar(from: avatarUrl, config.id)
        }
        
        if let photoUrls = review.photoUrls {
            fetchPhotos(from: photoUrls, configID: config.id)
        }
        
        return config
    }
    
    func makeTotalReviewsItem(_ reviews: Reviews) -> TotalReviewsCellConfig {
        let countText = "\(reviews.count) отзывов".attributed(font: .reviewCount, color: .reviewCount)
        let config = TotalReviewsCellConfig(countText: countText)
        return config
    }

}

// MARK: - UITableViewDataSource

extension ReviewsViewModel: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        state.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let config = state.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: config.reuseId, for: indexPath)
        config.update(cell: cell)
        return cell
    }

}

// MARK: - UITableViewDelegate

extension ReviewsViewModel: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        state.items[indexPath.row].height(with: tableView.bounds.size)
    }
    
//    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        guard indexPath.row < state.items.count else { return }
//        
//        let config = state.items[indexPath.row]
//        
//        if let reviewConfig = config as? ReviewCellConfig {
//            if let avatarUrl = reviewConfig.avatarUrl {
//                ImageProvider.shared.cancelFetch(for: avatarUrl)
//            }
//            
//            if let photoUrls = reviewConfig.photoUrls {
//                for url in photoUrls {
//                    ImageProvider.shared.cancelFetch(for: url)
//                }
//            }
//        }
//    }
    
    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось три экрана по высоте.
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if shouldLoadNextPage(scrollView: scrollView) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        screensToLoadNextPage: Double = 3.0
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let currentOffset = scrollView.contentOffset.y
        let remainingDistance = contentHeight - currentOffset - viewHeight
        
        return remainingDistance <= triggerDistance
    }

}
