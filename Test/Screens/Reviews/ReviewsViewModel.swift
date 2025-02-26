import UIKit

/// Класс, описывающий бизнес-логику экрана отзывов.
final class ReviewsViewModel: NSObject {

    /// Замыкание, вызываемое при изменении `state`.
    var onStateChange: ((State) -> Void)?

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

}

// MARK: - Private

private extension ReviewsViewModel {

    /// Метод обработки получения отзывов.
    func gotReviews(_ result: ReviewsProvider.GetReviewsResult) {
        do {
            let data = try result.get()
            let reviews = try decoder.decode(Reviews.self, from: data)
            
            state.items += reviews.items[0..<min(state.limit, reviews.count - state.offset)].map(makeReviewItem)
            state.offset += min(state.limit, reviews.count - state.offset)
            state.shouldLoad = state.items.count < reviews.count
            
            if !state.shouldLoad {
                let totalReviewsConfig = makeTotalReviewsItem(reviews)
                state.items.append(totalReviewsConfig)
            }
        } catch {
            print(error.localizedDescription)
            state.shouldLoad = true
        }
        onStateChange?(state)
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

}

// MARK: - Items

private extension ReviewsViewModel {

    func makeReviewItem(_ review: Review) -> ReviewCellConfig {
        let avatar = UIImage(named: "userpick")!
        let userName = "\(review.firstName) \(review.lastName)".attributed(font: .username)
        let ratingImage = ratingRenderer.ratingImage(review.rating)
        let photos = [UIImage(named: "IMG_0001")!, UIImage(named: "IMG_0002")!, UIImage(named: "IMG_0003")!, UIImage(named: "IMG_0004")!]
        let reviewText = review.text.attributed(font: .text)
        let created = review.created.attributed(font: .created, color: .created)
        let config = ReviewCellConfig(
            avatar: avatar,
            userName: userName,
            ratingImage: ratingImage,
            photos: photos,
            reviewText: reviewText,
            created: created,
            onTapShowMore: showMoreReview
        )
        
        if let avatarUrl = review.avatarUrl {
            PhotoProvider.shared.getPhoto(from: avatarUrl) { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let image):
                    if let index = self.state.items.firstIndex(where: { ($0 as? ReviewCellConfig)?.id == config.id }),
                       var updatedItem = self.state.items[index] as? ReviewCellConfig {
                        updatedItem.updateAvatar(with: image)
                        self.state.items[index] = updatedItem
                        if let onStateChange = self.onStateChange {
                            onStateChange(self.state)
                        }
                    }
                case .failure:
                    break
                }
            }
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

    /// Метод дозапрашивает отзывы, если до конца списка отзывов осталось два с половиной экрана по высоте.
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if shouldLoadNextPage(scrollView: scrollView, targetOffsetY: targetContentOffset.pointee.y) {
            getReviews()
        }
    }

    private func shouldLoadNextPage(
        scrollView: UIScrollView,
        targetOffsetY: CGFloat,
        screensToLoadNextPage: Double = 2.5
    ) -> Bool {
        let viewHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height
        let triggerDistance = viewHeight * screensToLoadNextPage
        let remainingDistance = contentHeight - viewHeight - targetOffsetY
        return remainingDistance <= triggerDistance
    }

}
