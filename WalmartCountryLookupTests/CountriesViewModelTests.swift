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

        await fulfillment(of: [exp], timeout: 1.0)

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
        let vm = TestableViewModel(service: MockNetworkServiceFailure())

        let expError  = expectation(description: "onError called")
        let expUpdate = expectation(description: "fallback update")
        vm.onError  = { _ in expError.fulfill() }
        vm.onUpdate = { expUpdate.fulfill() }

        await vm.load()

        await fulfillment(of: [expError, expUpdate], timeout: 1.0)

        XCTAssertFalse(vm.allCountries.isEmpty)
        XCTAssertEqual(vm.allCountries, vm.filtered)
        XCTAssertEqual(vm.allCountries.first?.name, "Fallbackland")
    }



}
