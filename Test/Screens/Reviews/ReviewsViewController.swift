import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        viewModel.getReviews()
    }

}

// MARK: - Private

private extension ReviewsViewController {

    func makeReviewsView() -> ReviewsView {
        let reviewsView = ReviewsView()
        reviewsView.tableView.delegate = viewModel
        reviewsView.tableView.dataSource = viewModel
        reviewsView.tableView.refreshControl?.addTarget(self, action: #selector(refreshReviews), for: .valueChanged)
        return reviewsView
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let tableView = self?.reviewsView.tableView else { return }
            
            let oldCount = tableView.numberOfRows(inSection: 0)
            let newCount = state.items.count
            
            if newCount > oldCount {
                tableView.performBatchUpdates {
                    let indexPathsToInsert = (oldCount..<newCount).map {
                        IndexPath(row: $0, section: 0)
                    }
                    tableView.insertRows(at: indexPathsToInsert, with: .automatic)
                }
            } else {
                tableView.reloadData()
            }
        }
        
        viewModel.onRefreshComplete = { [weak self] in
            guard let tableView = self?.reviewsView.tableView else { return }
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    @objc func refreshReviews() {
        reviewsView.tableView.refreshControl?.beginRefreshing()
        viewModel.startPullToRefresh()
    }

}
