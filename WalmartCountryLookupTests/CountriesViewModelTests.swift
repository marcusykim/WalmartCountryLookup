import XCTest
@testable import WalmartCountryLookup

private let testCountries: [Country] = [
    Country(name: "Atlantis", region: "Mythical", code: "AT", capital: "Poseidon"),
    Country(name: "", region: "", code: "X", capital: ""),              // triggers defaults
    Country(name: "Narnia", region: "Fantasy", code: "NA", capital: "Cair Paravel"),
    Country(name: "Wakanda", region: "Africa", code: "WK", capital: "Birnin Zana")
]

private final class MockNetworkServiceSuccess: NetworkServiceProtocol {
    let stub: [Country]
    init(stub: [Country]) { self.stub = stub }
    func fetchCountries() async throws -> [Country] { stub }
}

private final class MockNetworkServiceFailure: NetworkServiceProtocol {
    func fetchCountries() async throws -> [Country] {
        throw URLError(.badServerResponse)
    }
}

@MainActor
final class CountriesViewModelTests: XCTestCase {

    func testLoadSuccessPopulatesData() async {
        let mock = MockNetworkServiceSuccess(stub: testCountries)
        let vm = CountriesViewModel(service: mock)
        var didLoad = false
        vm.dataChanged = { didLoad = true }

        vm.load()
        // allow Task to run
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(didLoad)
        XCTAssertEqual(vm.allCountries, testCountries)
        XCTAssertEqual(vm.filtered, testCountries)
    }

    func testFilterUpdatesFilteredList() async {
        let mock = MockNetworkServiceSuccess(stub: testCountries)
        let vm = CountriesViewModel(service: mock)
        // Manually set originalList to avoid waiting for load
        vm.originalList = testCountries
        vm.filtered = testCountries

        vm.searchText = "nar"
        // debounce delay
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(vm.filtered.count, 1)
        XCTAssertEqual(vm.filtered.first?.name, "Narnia")

        vm.searchText = "ca"
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(vm.filtered.count, 2)
        let names = vm.filtered.map { $0.name }
        XCTAssertTrue(names.contains("Atlantis"))
        XCTAssertTrue(names.contains("Narnia"))

        vm.searchText = ""
        try? await Task.sleep(nanoseconds: 400_000_000)
        XCTAssertEqual(vm.filtered.count, testCountries.count)
    }

    func testShowDealFiltersToSingleCountry() async {
        let mock = MockNetworkServiceSuccess(stub: testCountries)
        let vm = CountriesViewModel(service: mock)
        vm.originalList = testCountries
        vm.filtered = testCountries

        let deal = vm.showDeal()
        XCTAssertNotNil(deal)
        XCTAssertEqual(vm.filtered.count, 1)
        XCTAssertEqual(vm.filtered.first, deal)
    }

    func testLoadFailureFallsBackToBundle() async {
        // Write a temporary JSON file into a bundle-like location
        // Use the same test JSON as countries.json
        let bundleURL = Bundle.main.bundleURL.appendingPathComponent("countries.json")
        let jsonString = """
        [
          {
            "name": "Fallbackland",
            "region": "Test",
            "cca2": "FB",
            "capital": "Testville"
          }
        ]
        """
        try? jsonString.data(using: .utf8)?.write(to: bundleURL)

        let mock = MockNetworkServiceFailure()
        let vm = CountriesViewModel(service: mock)
        var didLoad = false
        vm.dataChanged = { didLoad = true }

        vm.load()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(didLoad)
        XCTAssertEqual(vm.filtered.count, 1)
        XCTAssertEqual(vm.filtered.first?.name, "Fallbackland")

        // Clean up
        try? FileManager.default.removeItem(at: bundleURL)
    }
}
