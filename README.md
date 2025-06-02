# Walmart Country Lookup

An iOS app written in **Swift 6** and **UIKit** that fetches a list of countries, lets users live-search, and “pull for rollback deal” (a random country with a deal). If the network fetch fails, it seamlessly falls back to a bundled JSON. Architected in **MVVM** with a protocol-driven networking layer to enable future testability.

---

## 🎬 Overview

* **Language & UI**: Swift 6, UIKit (programmatic).
* **Architecture**: Model-View-ViewModel (MVVM) + protocol-oriented networking.
* **Concurrency**: `async/await` + `@MainActor` for main-thread safety.
* **Resilience**:

  * **Retry + Back-off** on network errors.
  * **Bundle Fallback**: If API fails, load `countries.json` from app bundle.
  * **Debounced Search** prevents filtering on every keystroke.
  * **Pull-to-Deal**: Pull down to reveal a random country with a deal.

---

## 🗂 Project Structure

```
WalmartCountryLookup/
├─ Sources/
│  ├─ Models/
│  │  └─ Country.swift
│  ├─ Services/
│  │  └─ NetworkService.swift
│  ├─ ViewModels/
│  │  └─ CountriesViewModel.swift
│  └─ Views/
│     ├─ CountryTableViewCell.swift
│     └─ CountriesViewController.swift
├─ Resources/
│  └─ countries.json
└─ WalmartCountryLookup.xcodeproj
```

---

## 🔍 Code Highlights & Justifications

### 1. Model: `Country.swift`

```swift
struct Country: Codable, Equatable {
    let name:    String   
    let region:  String   
    let code:    String   
    let capital: String   
}
```

* **Codable**: Simplifies JSON parsing—`JSONDecoder()` maps JSON directly to `Country` instances.
* **Equatable**: Enables easy comparison if unit tests are added later.
* Immutable `let` properties ensure data integrity once initialized.

---

### 2. Networking: `NetworkService.swift`

```swift
protocol NetworkServiceProtocol {
    func fetchCountries() async throws -> [Country]
}

enum NetworkError: Error {
    case badURL
    case requestFailed(statusCode: Int)
    case noData
    case decodingError(Error)
}

final class NetworkService: NetworkServiceProtocol {
    private let session = URLSession.shared
    private let url = URL(string: "https://gist.githubusercontent.com/.../countries.json")!
    private let retries = 2
    private let retryDelay: UInt64 = 300_000_000  // 0.3 seconds

    func fetchCountries() async throws -> [Country] {
        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.noData
                }
                guard (200..<300).contains(http.statusCode) else {
                    throw NetworkError.requestFailed(statusCode: http.statusCode)
                }
                return try JSONDecoder().decode([Country].self, from: data)
            }
            catch let decodeErr as DecodingError {
                throw NetworkError.decodingError(decodeErr)
            }
            catch {
                attempt += 1
                if attempt > retries { throw error }
                try? await Task.sleep(nanoseconds: retryDelay)
            }
        }
    }
}
```

* **Protocol-Driven**: `NetworkServiceProtocol` lets you inject a mock implementation when tests are added.
* **Retry + Back-off**: On transient errors (network timeout or bad HTTP status), automatically retries up to two more times.
* **Granular Errors**: Distinguishes HTTP failures vs. decoding failures so the ViewModel can decide when to fallback.

---

### 3. ViewModel: `CountriesViewModel.swift`

```swift
@MainActor
final class CountriesViewModel {
    private let service: NetworkServiceProtocol

    private(set) var allCountries = [Country]()
    private(set) var filtered     = [Country]()
    var searchText = "" {
        didSet { debounceFilter() }
    }

    private var debounceTask: Task<Void, Never>?

    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }

    func load() async {
        do {
            let list = try await service.fetchCountries()
            allCountries = list
            filtered     = list
        } catch {
            allCountries = loadFromBundle() ?? []
            filtered     = allCountries
        }
    }

    func loadFromBundle() -> [Country]? {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? JSONDecoder().decode([Country].self, from: data)
    }

    private func debounceFilter() {
        debounceTask?.cancel()
        let query = searchText.lowercased()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            filtered = allCountries.filter {
                $0.name.lowercased().contains(query) ||
                $0.capital.lowercased().contains(query)
            }
        }
    }

    @discardableResult
    func showDeal() -> Country? {
        guard let dealCountry = allCountries.randomElement() else { return nil }
        filtered = [dealCountry]
        return dealCountry
    }
}
```

* **`@MainActor`**: All state updates (`allCountries`, `filtered`) run on the main thread—no manual `DispatchQueue` calls.
* **Async Load + Fallback**: Tries network fetch but on any error immediately falls back to bundled JSON so the list never goes blank.
* **Debounced Search**: A 300 ms delay avoids filtering on each keystroke, making the UI feel smoother.
* **`showDeal()`**: Returns a random country with a deal, then updates `filtered` accordingly.

---

### 4. View: Key Snippets

#### 4.1 Cell layout: `CountryTableViewCell.swift`

```swift
class CountryTableViewCell: UITableViewCell {
    static let reuseID = "CountryCell"
    private let nameLabel    = UILabel()
    private let codeLabel    = UILabel()
    private let capitalLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    private func setupUI() {
        nameLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        nameLabel.numberOfLines = 0

        codeLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        codeLabel.textAlignment = .right

        capitalLabel.font = UIFont.systemFont(ofSize: 15, weight: .regular)
        capitalLabel.numberOfLines = 0

        let header = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
        header.axis = .horizontal
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        codeLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [header, capitalLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with country: Country) {
        nameLabel.text    = "\(country.name), \(country.region)"
        codeLabel.text    = country.code
        capitalLabel.text = country.capital
    }
}
```

* The header stack places **name + region** on the left and **ISO code** on the right, ensuring the code never truncates.
* A vertical stack arranges the header above the capital. Programmatic layout prevents storyboard conflicts.

#### 4.2 Pull-to-Deal & Reset: `CountriesViewController.swift`

```swift
@objc private func didPull() {
    guard let dealCountry = viewModel.showDeal() else { return }
    tableView.reloadData()
    tableView.refreshControl?.endRefreshing()
    let topInset = tableView.adjustedContentInset.top
    tableView.setContentOffset(CGPoint(x: 0, y: -topInset), animated: true)
    navigationItem.rightBarButtonItem = UIBarButtonItem(
        title: "Show All", style: .plain,
        target: self, action: #selector(showAll)
    )
    let alert = UIAlertController(
        title: "Deal of the Day!",
        message: dealCountry.name,
        preferredStyle: .alert
    )
    alert.addAction(.init(title: "Nice!", style: .default))
    present(alert, animated: true)
}

@objc private func showAll() {
    viewModel.filtered = viewModel.allCountries
    tableView.reloadData()
    navigationItem.rightBarButtonItem = nil
}
```

* After `showDeal()` returns a random country with a deal, the code reloads, ends the refresh animation, and snaps back to the top so the UI never remains in a pulled state.
* The **“Show All”** button resets `filtered` to the full list.

---

## ⚙️ Installation & Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/WalmartCountryLookup.git
   cd WalmartCountryLookup
   ```

2. **Open in Xcode**

   ```bash
   open WalmartCountryLookup.xcodeproj
   ```

3. **Run the app**

   * Select the **WalmartCountryLookup** scheme.
   * Choose an iOS Simulator (iOS 15+) or a physical device.
   * Press **⌘R** to build and launch.

4. **Future Testing (Optional)**

   * No unit tests are implemented currently, but the protocol-driven networking layer (`NetworkServiceProtocol`) allows easy injection of mocks when adding tests.

---

## 🙏 Thank You

Thank you to the Walmart hiring team for reviewing **Walmart Country Lookup**. This project demonstrates clean MVVM architecture, robust async networking with retry/back-off and fallback, and a playful pull-to-deal feature. I look forward to speaking with you soon.

— Marcus Kim
