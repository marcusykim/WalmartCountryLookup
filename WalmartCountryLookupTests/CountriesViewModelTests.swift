import XCTest
@testable import WalmartCountryLookup

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

/// Subclass that overrides the bundle‐loading fallback,
/// so we can guarantee non‐empty fallback data in tests.
private final class TestableViewModel: CountriesViewModel {
    override func loadFromBundle() -> [Country] {
        [ Country(name: "Fallbackland", region: "FB", code: "FB", capital: "Fallback") ]
    }
}

final class CountriesViewModelTests: XCTestCase {
    @MainActor
    func testLoadSuccessCallsOnUpdate() async {
        let sample = [ Country(name: "X", region: "Y", code: "Z1", capital: "CapX") ]
        let vm = CountriesViewModel(service: MockNetworkServiceSuccess(stub: sample))
        let exp = expectation(description: "onUpdate called")
        vm.onUpdate = { exp.fulfill() }

        
        await vm.load()
    
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(vm.allCountries, sample)
        XCTAssertEqual(vm.filtered, sample)
    }

    @MainActor
    func testFilterByNameAndCapital() {
        let a = Country(name: "Alpha", region: "R", code: "A1", capital: "FirstCity")
        let b = Country(name: "Beta",  region: "R", code: "B2", capital: "SecondCity")
        let vm = CountriesViewModel(service: MockNetworkServiceSuccess(stub: [a, b]))
        vm.allCountries = [a, b]
        vm.filtered     = [a, b]

        vm.searchText = "Alpha"
        XCTAssertEqual(vm.filtered, [a])

        vm.searchText = "Second"
        XCTAssertEqual(vm.filtered, [b])

        vm.searchText = ""
        XCTAssertEqual(vm.filtered.count, 2)
    }

    @MainActor
    func testShowDealReturnsOneAndFilters() {
        let a = Country(name: "A", region: "R", code: "C1", capital: "CapA")
        let b = Country(name: "B", region: "R", code: "C2", capital: "CapB")
        let vm = CountriesViewModel(service: MockNetworkServiceSuccess(stub: [a, b]))
        vm.allCountries = [a, b]
        vm.filtered     = [a, b]

        let deal = vm.showDeal()
        XCTAssertNotNil(deal)
        XCTAssertEqual(vm.filtered.count, 1)
        XCTAssertEqual(vm.filtered.first, deal)
    }

    @MainActor
    func testLoadFailureTriggersErrorAndFallback() async {
        // use the test‐file subclass that stubs in our fallback
        let vm = TestableViewModel(service: MockNetworkServiceFailure())
        var errorCalled = false
        var updateCalled = false
        vm.onError  = { _ in errorCalled = true }
        vm.onUpdate = { updateCalled = true }

        await vm.load()

        XCTAssertTrue(errorCalled)
        XCTAssertTrue(updateCalled)
        XCTAssertFalse(vm.allCountries.isEmpty)
        XCTAssertEqual(vm.allCountries, vm.filtered)
        XCTAssertEqual(vm.allCountries.first?.name, "Fallbackland")
    }


}
