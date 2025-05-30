## Walmart Rollback: Country Lookup

A lightweight UIKit app that fetches a list of countries, lets you search and “pull for rollback deal,” and survives network failures with a bundled-JSON fallback—all wired up in MVVM + Swift Concurrency and covered by async unit tests.

---

## Overview

* **Language & UI**: Swift 5, UIKit (no storyboards → zero merge conflicts).
* **Architecture**: MVVM + Protocol-oriented Networking.
* **Concurrency**: `async/await` + `@MainActor` for main-thread safety.
* **Testing**: Full unit-test suite for model, networking, ViewModel logic.

---

## Key Features

* **Retry + Back-off** on network failure
* **Bundle Fallback**: If the API fails, load a local `countries.json`
* **Live Search**: Filter by country *name* or *capital* as you type
* **Pull-to-Deal**: Pull down to reveal a random “rollback deal” country
* **Robust Error Handling** with granular `NetworkError` types
* **Dynamic Type** support for accessibility
* **iPhone & iPad** | Portrait & Landscape
* **Async Unit Tests** covering success, failure, filtering, and deal logic

---

## Installation

```bash
git clone https://github.com/yourusername/WalmartCountryLookup.git
cd WalmartCountryLookup
open WalmartCountryLookup.xcodeproj
```

1. Select the **WalmartCountryLookup** scheme.
2. Hit **⌘R** to run on simulator or device.
3. **⌘U** to run all tests.

---

## 🏗 Project Structure

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
│  ├─ LaunchScreen.storyboard
│  └─ countries.json      ← bundled fallback
└─ Tests/
   └─ CountriesViewModelTests.swift
```

---

## Model

**`Country.swift`**

```swift
struct Country: Codable, Equatable {
  let name:    String   // Official country name
  let region:  String   // Region grouping (e.g., “Europe”)
  let code:    String   // 2-letter ISO code (e.g., “US”)
  let capital: String   // Capital city name
}
```

* **Why?** Direct JSON mapping with `Codable`.
* **Equatable**: lets us compare values in tests.

---

## Networking

**`NetworkService.swift`**

```swift
final class NetworkService: NetworkServiceProtocol {
  private let session = URLSession.shared
  private let retries = 2
  private let retryDelay: UInt64 = 300_000_000 // 0.3s

  func fetchCountries() async throws -> [Country] {
    var attempt = 0
    while true {
      do {
        let (data, resp) = try await session.data(from: url)
        guard let http = resp as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
          throw NetworkError.requestFailed(statusCode: (resp as? HTTPURLResponse)?.statusCode ?? -1)
        }
        return try JSONDecoder().decode([Country].self, from: data)
      }
      catch let decodeErr as DecodingError {
        throw NetworkError.decodingError(decodeErr)  // precise error
      }
      catch {
        if attempt >= retries { throw error }
        attempt += 1
        try? await Task.sleep(nanoseconds: retryDelay)
      }
    }
  }
}
```

* **Retry + Back-off**: improves resilience on flaky networks.
* **Granular errors**: distinguishes bad status, missing data, decoding issues.

---

## ViewModel

**`CountriesViewModel.swift`**

```swift
@MainActor
final class CountriesViewModel {
  private let service: NetworkServiceProtocol
  private(set) var allCountries = [Country]()
  private(set) var filtered     = [Country]()
  var searchText = "" {
    didSet { debounceFilter() }
  }

  /// Primary loader: tries network → fallbacks to bundle
  func load() async {
    do {
      let list = try await service.fetchCountries()
      allCountries = list; filtered = list
    } catch {
      allCountries = loadFromBundle() ?? []
      filtered     = allCountries
    }
  }

  /// Returns optional fallback from bundled JSON
  func loadFromBundle() -> [Country]? {
    guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
          let data = try? Data(contentsOf: url)
    else { return nil }
    return try? JSONDecoder().decode([Country].self, from: data)
  }

  /// Live text search with 300ms debounce
  private var debounceTask: Task<Void, Never>?
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

  /// Pick random “deal” country and filter to it
  @discardableResult
  func showDeal() -> Country? {
    guard let deal = allCountries.randomElement() else { return nil }
    filtered = [deal]
    return deal
  }
}
```

* **`@MainActor`**: all state mutations happen on main thread—no GCD boilerplate.
* **Debounce**: avoids over-filtering on rapid typing.
* **Bundled fallback**: makes app work offline or on failure.

---

## Views & Controller

**`CountryTableViewCell.swift`**

```swift
class CountryTableViewCell: UITableViewCell {
  static let reuseID = "CountryCell"
  private let nameLabel    = UILabel()
  private let codeLabel    = UILabel()
  private let capitalLabel = UILabel()

  private func setupUI() {
    // Header: name + code
    let header = UIStackView(arrangedSubviews: [nameLabel, codeLabel])
    header.axis = .horizontal; header.spacing = 8
    nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    codeLabel.setContentHuggingPriority(.required,    for: .horizontal)

    // Main stack
    let stack = UIStackView(arrangedSubviews: [header, capitalLabel])
    stack.axis = .vertical; stack.spacing = 4
    contentView.addSubview(stack)
    stack.pinToEdges(of: contentView, insets: .init(all: 8))
  }

  func configure(with country: Country) {
    nameLabel.text    = "\(country.name), \(country.region)"
    codeLabel.text    = country.code
    capitalLabel.text = country.capital
  }
}
```

* **Content Hugging**: ensures code label never truncates.
* **Programmatic layout**: no Interface Builder needed.

---

**`CountriesViewController.swift`**

```swift
override func viewDidLoad() {
  super.viewDidLoad()
  setupTable(); setupSearch(); setupBanner(); setupRefresh()
  Task { await viewModel.load() }  // async start
}

@objc private func didPull() {
  guard let deal = viewModel.showDeal() else { return }
  tableView.reloadData()
  tableView.refreshControl?.endRefreshing()
  let top = tableView.adjustedContentInset.top
  tableView.setContentOffset(.init(x:0,y:-top), animated: true)
  showDealAlert(deal)
  navigationItem.rightBarButtonItem = UIBarButtonItem(
    title: "Show All", style: .plain, target: self, action: #selector(showAll)
  )
}
```

* **Pull-to-Deal**: leverages built-in spinner only when you want it.
* **Auto-reset**: snaps table back to top so UI never hangs mid-pull.

---

## Testing

All ViewModel logic is covered by async XCTest:

```swift
@MainActor
func testLoadSuccessPopulatesLists() async {
  let vm = CountriesViewModel(service: MockSuccess(stub: sample))
  await vm.load()
  XCTAssertEqual(vm.filtered, sample)
}

@MainActor
func testLoadFailureFallsBack() async {
  let vm = TestableViewModel(service: MockFailure())
  await vm.load()
  XCTAssertEqual(vm.allCountries.first?.name, "Fallbackland")
}
```

* **No race conditions**: `@MainActor` + `await` = deterministic tests.
* **Protocol mocks** drive both success and failure paths.

---

## Robustness

* **Protocol-Oriented Networking**: swap in new endpoints or mocks without touching business logic.
* **Error Granularity**: `NetworkError` covers bad URL, HTTP codes, no data, decoding failures.
* **Bundled Fallback**: app remains functional offline or on API downtimes.
* **Debounced Search**: prevents UI churn with thousands of countries.
* **Dynamic Type** & **Safe Threading**: all UI updates on main actor; no GCD mistakes.
* **Test Coverage**: every branch in ViewModel validated, UI logic of “deal” tested via state changes.

