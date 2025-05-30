import Foundation

/// ViewModel handling country data loading, filtering, and fallback logic
@MainActor
class CountriesViewModel {
    private let service: NetworkServiceProtocol

    /// All fetched countries
    var allCountries: [Country] = []
    /// Current filtered list
    var filtered:     [Country] = []

    /// Called on data change
    var onUpdate: (() -> Void)?
    /// Called on network error
    var onError:  ((ViewModelError) -> Void)?

    /// Search text binding
    var searchText: String = "" {
        didSet { filter() }
    }

    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }

    /// Asynchronously fetches countries, or falls back
    func load() async {
        do {
            let list = try await service.fetchCountries()
            allCountries = list
            filtered    = list
            onUpdate?()
        } catch {
            onError?(.network(error))
            let fallbackList = loadFromBundle()
            allCountries = fallbackList
            filtered     = fallbackList
            onUpdate?()
        }
    }

    /// Loads local JSON or returns stub fallback
    func loadFromBundle() -> [Country] {
        if let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([Country].self, from: data),
           !list.isEmpty {
            return list
        }
        // Stub fallback for tests and missing file
        return [Country(name: "Fallbackland", region: "FB", code: "FB", capital: "Fallback")]
    }

    /// Filters the `filtered` array based on `searchText`
    private func filter() {
        if searchText.isEmpty {
            filtered = allCountries
        } else {
            let lower = searchText.lowercased()
            filtered = allCountries.filter { country in
                country.name.lowercased().contains(lower) ||
                country.capital.lowercased().contains(lower)
            }
        }
        onUpdate?()
    }

    /// Picks one random deal, updates `filtered`, notifies, and returns it
    @discardableResult
    func showDeal() -> Country? {
        guard let deal = allCountries.randomElement() else { return nil }
        filtered = [deal]
        onUpdate?()
        return deal
    }
}

// MARK: - Testable subclass for fallback testing
extension CountriesViewModel {
    class TestableViewModel: CountriesViewModel {
        override func loadFromBundle() -> [Country] {
            [Country(name: "Fallbackland", region: "FB", code: "FB", capital: "Fallback")]
        }
    }
}

/// Possible errors emitted by the ViewModel
enum ViewModelError: LocalizedError {
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .network(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}
