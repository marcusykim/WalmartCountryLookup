import Foundation

@MainActor
class CountriesViewModel {
    private let service: NetworkServiceProtocol

    var allCountries: [Country] = []
    var filtered:     [Country] = []

    var onUpdate: (() -> Void)?
    var onError:  ((ViewModelError) -> Void)?

    var searchText: String = "" {
        didSet { filter() }
    }

    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }

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

    func loadFromBundle() -> [Country] {
        if let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let list = try? JSONDecoder().decode([Country].self, from: data),
           !list.isEmpty {
            return list
        }
        return [Country(name: "Fallbackland", region: "FB", code: "FB", capital: "Fallback")]
    }

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

    @discardableResult
    func showDeal() -> Country? {
        guard let deal = allCountries.randomElement() else { return nil }
        filtered = [deal]
        onUpdate?()
        return deal
    }
}

extension CountriesViewModel {
    class TestableViewModel: CountriesViewModel {
        override func loadFromBundle() -> [Country] {
            [Country(name: "Fallbackland", region: "FB", code: "FB", capital: "Fallback")]
        }
    }
}

enum ViewModelError: LocalizedError {
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .network(let err): return "Network error: \(err.localizedDescription)"
        }
    }
}
