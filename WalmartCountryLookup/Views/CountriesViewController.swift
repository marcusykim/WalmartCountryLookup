import UIKit

class CountriesViewController: UIViewController {
    // MARK: - Properties
    private let viewModel = CountriesViewModel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let search    = UISearchController(searchResultsController: nil)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title               = "🌎 Walmart Rollback: Countries"
        view.backgroundColor = .systemBackground

        setupTable()
        setupBanner()
        setupSearch()
        setupRefresh()
        bindViewModel()

        // Load data asynchronously without marking viewDidLoad async
        Task {
            await viewModel.load()
        }
    }

    // MARK: - Setup Methods

    private func setupTable() {
        tableView.register(
            CountryTableViewCell.self,
            forCellReuseIdentifier: CountryTableViewCell.reuseID
        )
        tableView.dataSource = self
        tableView.delegate   = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupBanner() {
        let banner = UILabel()
        banner.text             = "Pull for rollback deal 🎉"
        banner.font             = UIFont.preferredFont(forTextStyle: .subheadline)
        banner.textAlignment    = .center
        banner.numberOfLines    = 0
        banner.backgroundColor  = .systemYellow.withAlphaComponent(0.2)
        banner.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView(frame: CGRect(x: 0,
                                             y: 0,
                                             width: view.bounds.width,
                                             height: 44))
        container.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            banner.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            banner.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            banner.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4),
        ])

        tableView.tableHeaderView = container
    }

    private func setupSearch() {
        search.searchResultsUpdater                   = self
        search.obscuresBackgroundDuringPresentation   = false
        navigationItem.searchController               = search
        navigationItem.hidesSearchBarWhenScrolling    = false
    }

    private func setupRefresh() {
        let rc = UIRefreshControl()
        rc.attributedTitle = NSAttributedString(string: "")
        rc.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
        tableView.refreshControl = rc
    }

    private func bindViewModel() {
        viewModel.onUpdate = { [weak self] in
            self?.tableView.reloadData()
        }
        viewModel.onError = { [weak self] error in
            let msg = error.localizedDescription + " — bringing you rollback support!"
            let alert = UIAlertController(title: "Oops!", message: msg, preferredStyle: .alert)
            alert.addAction(.init(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    // MARK: - Actions

    @objc private func didPullToRefresh() {
        guard let deal = viewModel.showDeal() else {
            tableView.refreshControl?.endRefreshing()
            return
        }
        tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
        let topInset = tableView.adjustedContentInset.top
        tableView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: true)

        let alert = UIAlertController(
            title: "Deal of the Day!",
            message: "Free shipping to \(deal.name)! 🛒",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "Score!", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension CountriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.filtered.count
    }

    func tableView(_ tv: UITableView,
                   cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(
            withIdentifier: CountryTableViewCell.reuseID,
            for: ip
        ) as! CountryTableViewCell
        cell.configure(with: viewModel.filtered[ip.row])
        return cell
    }
}

// MARK: - UISearchResultsUpdating

extension CountriesViewController: UISearchResultsUpdating {
    func updateSearchResults(for sc: UISearchController) {
        viewModel.searchText = sc.searchBar.text ?? ""
    }
}
