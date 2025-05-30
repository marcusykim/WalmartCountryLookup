import Foundation

@MainActor
class CountriesViewModel {
    private let service: NetworkServiceProtocol
    private var loadTask: Task<Void, Never>? = nil

    private(set) var allCountries = [Country]()
    private(set) var filtered    = [Country]()
    private var originalList = [Country]()

    enum State { case idle, loading, loaded, error(String) }
    var stateChanged: ((State) -> Void)?
    var dataChanged: (() -> Void)?

    private var searchDebounce: Task<Void, Never>?
    var searchText = "" {
        didSet { debounceFilter() }
    }

    init(service: NetworkServiceProtocol = NetworkService()) {
        self.service = service
    }

    func load() {
        loadTask?.cancel()
        stateChanged?(.loading)
        loadTask = Task {
            do {
                let list = try await service.fetchCountries()
                self.completeLoad(with: list)
            } catch {
                stateChanged?(.error(error.localizedDescription))
                if let fallback = loadFromBundle() {
                    self.completeLoad(with: fallback)
                }
            }
        }
    }

    private func completeLoad(with list: [Country]) {
        originalList = list
        allCountries = list
        filtered = list
        stateChanged?(.loaded)
        dataChanged?()
    }

    func resetFilter() {
        filtered = originalList
        dataChanged?()
    }

    func showDeal() -> Country? {
        guard let deal = originalList.randomElement() else { return nil }
        filtered = [deal]
        dataChanged?()
        return deal
    }

    func loadFromBundle() -> [Country]? {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([Country].self, from: data)
        else { return nil }
        return list
    }

    private func debounceFilter() {
        searchDebounce?.cancel()
        let text = searchText

        searchDebounce = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 300_000_000)
            filter(text: text)
        }
    }

    private func filter(text: String) {
        if text.isEmpty { resetFilter(); return }
        let lower = text.lowercased()
        filtered = originalList.filter { $0.name.lowercased().contains(lower) || $0.capital.lowercased().contains(lower) }
        dataChanged?()
    }
}
