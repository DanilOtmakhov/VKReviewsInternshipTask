import UIKit

final class ReviewsViewController: UIViewController {

    private lazy var reviewsView = makeReviewsView()
    private let viewModel: ReviewsViewModel
    private let activityIndicator = CustomActivityIndicator()

    init(viewModel: ReviewsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        viewModel.onStateChange = nil
        viewModel.onRefreshComplete = nil
    }

    override func loadView() {
        view = reviewsView
        title = "Отзывы"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupActivityIndicator()
        viewModel.getReviews()
        activityIndicator.startAnimating()
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
    
    func setupActivityIndicator() {
        view.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func setupViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.activityIndicator.stopAnimating()
            
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
        
        viewModel.onPhotoTapped = { [weak self] photos, index in
            self?.openPhotosViewer(photos: photos, startIndex: index)
        }
    }
    
    @objc func refreshReviews() {
        reviewsView.tableView.refreshControl?.beginRefreshing()
        viewModel.refreshReviews()
    }
    
    func openPhotosViewer(photos: [UIImage], startIndex: Int) {
        let viewController = PhotosViewerViewController(photos: photos, startIndex: startIndex)
        present(viewController, animated: true)
    }

}
