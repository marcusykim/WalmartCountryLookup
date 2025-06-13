import UIKit

class CountriesViewController: UIViewController {
    private let viewModel = CountriesViewModel()
    private let tableView = UITableView()
    private let search = UISearchController(searchResultsController: nil)
    private let activity = UIActivityIndicatorView(style: .large)
    private let banner = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.load()
        
    }

    private func setupUI() {
        title = "🌎 Walmart Rollback"
        view.backgroundColor = .systemBackground
        setupBanner()
        setupActivity()
        setupTable()
        setupSearch()
    }

    private func setupBanner() {
        banner.text = "Pull for rollback deal 🎉"
        banner.backgroundColor = .systemYellow.withAlphaComponent(0.2)
        banner.textAlignment = .center
        banner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupActivity() {
        activity.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(activity)
        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupTable() {
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: CountryTableViewCell.reuseID)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: banner.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(didPull), for: .valueChanged)
        tableView.refreshControl = rc
    }

    private func setupSearch() {
        search.searchResultsUpdater = self
        navigationItem.searchController = search
    }

    private func bindViewModel() {
        viewModel.stateChanged = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .loading: self?.activity.startAnimating()
                default: self?.activity.stopAnimating()
                }
            }
        }
        viewModel.dataChanged = { [weak self] in
            self?.tableView.reloadData()
        }
    }

    @objc private func didPull() {
        if let deal = viewModel.showDeal() {
            tableView.reloadData()
            tableView.refreshControl?.endRefreshing()
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Show All", style: .plain,
                target: self, action: #selector(showAll)
            )
            let alert = UIAlertController(title: "Deal of the Day!", message: DealMessages.dealMessages[Int.random(in: 0...DealMessages.dealMessages.count - 1)] + deal.name, preferredStyle: .alert)
            alert.addAction(.init(title: "Nice!", style: .default))
            present(alert, animated: true)
            
        }
        tableView.refreshControl?.endRefreshing()
        let topInset = tableView.adjustedContentInset.top
                tableView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: true)
    }

    @objc private func showAll() {
        viewModel.resetFilter()
        navigationItem.rightBarButtonItem = nil
    }
}

extension CountriesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tv: UITableView, numberOfRowsInSection section: Int) -> Int { viewModel.filtered.count }
    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        guard let cell = tv.dequeueReusableCell(
            withIdentifier: CountryTableViewCell.reuseID, for: ip) as? CountryTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: viewModel.filtered[ip.row])
        return cell
    }
}

extension CountriesViewController: UISearchResultsUpdating {
    func updateSearchResults(for sc: UISearchController) {
        viewModel.searchText = sc.searchBar.text ?? ""
    }
}
