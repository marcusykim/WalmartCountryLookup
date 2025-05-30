# Walmart Country Lookup

## Overview

`WalmartCountryLookup` is a UIKit-based iOS app that:

* Fetches a list of countries from a remote JSON source.
* Displays the countries in a searchable table.
* Includes a playful “Rollback Deal” pull‑to‑refresh feature.

It follows the **Model–View–ViewModel (MVVM)** pattern for clear separation of concerns, uses **Swift Concurrency (`async/await`)** for networking, and is coded entirely in Swift (no complex storyboards beyond the launch screen) to simplify maintenance.

## Key Features

* **Remote Data Fetch**: Retrieves country list via a Gist URL.
* **Searchable UI**: Real‑time filtering by country name or capital.
* **Rollback Deal**: Pull down to filter the list to a single “deal” country, with a celebratory alert.
* **Offline Fallback**: On network failure, loads bundled `countries.json`.
* **Accessibility**: Dynamic Type support via `UIFont.preferredFont` and Auto Layout.
* **Universal App**: Works on both iPhone and iPad in portrait and landscape.
* **Unit Tests**: Coverage for model decoding, ViewModel operations, and fallback logic.

## Project Structure

```
WalmartCountryLookup/
├── AppDelegate.swift
├── SceneDelegate.swift
├── Models/
│   └── Country.swift
├── Services/
│   └── NetworkService.swift
├── ViewModels/
│   └── CountriesViewModel.swift
├── Views/
│   ├── CountryTableViewCell.swift
│   └── CountriesViewController.swift
├── Resources/
│   ├── countries.json
│   └── Base.lproj/LaunchScreen.storyboard
└── Tests/WalmartCountryLookupTests/
    ├── CountriesModelTests.swift
    └── CountriesViewModelTests.swift
```

---

## Code Snippets with Explanations

### 1. **Country Model** (`Models/Country.swift`)

```swift
// Represents a country with minimal fields for display
struct Country: Codable, Equatable {
    let name: String       // Full country name
    let region: String     // Geographical region (e.g., "Asia")
    let code: String       // ISO 2-letter code (e.g., "US")
    let capital: String    // Capital city name
}
```

* **Codable**: Enables JSON encoding/decoding.
* **Equatable**: Allows direct comparison in unit tests.

---

### 2. **Networking Service** (`Services/NetworkService.swift`)

```swift
protocol NetworkServiceProtocol {
    func fetchCountries() async throws -> [Country]
}

// Concrete implementation using Swift Concurrency
final class NetworkService: NetworkServiceProtocol {
    private let session = URLSession.shared
    private let remoteURL =
      "https://gist.githubusercontent.com/.../countries.json"

    func fetchCountries() async throws -> [Country] {
        // 1. Build URL
        guard let url = URL(string: remoteURL) else {
            throw NetworkError.badURL  // Invalid URL error
        }
        // 2. Perform network request
        let (data, response) = try await session.data(from: url)
        // 3. Check HTTP status code
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw NetworkError.requestFailed(statusCode: http.statusCode)
        }
        // 4. Decode JSON into [Country]
        return try JSONDecoder().decode([Country].self, from: data)
    }
}
```

* **Error Handling**: Throws clear errors for invalid URL, HTTP failure, or decoding issues.
* **Protocol‑Oriented**: Allows swapping in mock implementations in tests.

---

### 3. **ViewModel Logic** (`ViewModels/CountriesViewModel.swift`)

```swift
@MainActor
class CountriesViewModel {
    private let service: NetworkServiceProtocol

    private(set) var allCountries = [Country]()  // Full data set
    private(set) var filtered    = [Country]()  // Current table data

    var onUpdate: (() -> Void)?    // Called after data changes
    var onError:  ((ViewModelError) -> Void)?  // Called on network error
    var searchText = "" {           // Binding for search text
        didSet { filter() }           // Automatically refilter when text changes
    }

    // Initiate with real or mock network service
    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }

    // Fetch or fallback to local JSON
    func load() async {
        do {
            let list = try await service.fetchCountries()
            allCountries = list
            filtered    = list
            onUpdate?()
        } catch {
            onError?(.network(error))
            if let fallback = loadFromBundle() {
                allCountries = fallback
                filtered     = fallback
                onUpdate?()
            }
        }
    }

    // Load bundled JSON if available
    func loadFromBundle() -> [Country]? {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Country].self, from: data)
        else { return nil }
        return list
    }

    // Filter logic for search
    private func filter() {
        guard !searchText.isEmpty else {
            filtered = allCountries
            onUpdate?()
            return
        }
        let lower = searchText.lowercased()
        filtered = allCountries.filter {
            $0.name.lowercased().contains(lower) ||
            $0.capital.lowercased().contains(lower)
        }
        onUpdate?()
    }

    // Return a random "deal" and update filtered list
    @discardableResult
    func showDeal() -> Country? {
        guard let deal = allCountries.randomElement() else { return nil }
        filtered = [deal]
        onUpdate?()
        return deal
    }
}
```

* **`@MainActor`**: Guarantees UI‑safe updates from async tasks.
* **`onUpdate` & `onError` closures**: Decouple ViewModel from ViewController.

---

### 4. **UIView & Controller** (`Views/CountriesViewController.swift`)

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    // Setup UI components
    setupTable(); setupBanner(); setupSearch(); setupRefresh()
    bindViewModel()

    // 5. Trigger async load without making viewDidLoad async
    Task { await viewModel.load() }
}

@objc private func didPullToRefresh() {
    // 6. Show "deal" country when user pulls
    if let deal = viewModel.showDeal() {
        tableView.reloadData()                  // Refresh table
        tableView.refreshControl?.endRefreshing() // Hide spinner
        presentAlert(title: "Deal of the Day!", message: deal.name)
    }
}
```

* **Programmatic UI**: No IBOutlets needed, reducing merge conflicts.
* **`Task { await ... }`**: Keeps lifecycle methods synchronous.

---

## Running the App

1. Clone & open `WalmartCountryLookup.xcodeproj` in Xcode 16.
2. Ensure your scheme is **WalmartCountryLookup**.
3. Build (⌘B) and Run (⌘R) on iOS 15+ simulator or device.

## Running Tests

1. Select the **WalmartCountryLookupTests** scheme.
2. Run **Product → Test** or press **⌘U**.
3. All tests, including fallback scenarios, should pass.
