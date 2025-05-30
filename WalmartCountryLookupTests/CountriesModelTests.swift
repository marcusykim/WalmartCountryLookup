import XCTest
@testable import WalmartCountryLookup

final class CountriesModelTests: XCTestCase {
    func testDecodeBundledJSON() throws {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: "countries", withExtension: "json") else {
            XCTFail("Missing countries.json in test bundle")
            return
        }

        let data = try Data(contentsOf: url)
        let countries = try JSONDecoder().decode([Country].self, from: data)
        XCTAssertFalse(countries.isEmpty, "Decoded array should not be empty")

        let first = countries[0]
        XCTAssertFalse(first.name.isEmpty)
        XCTAssertEqual(first.code.count, 2, "Country code should be 2 letters")
        XCTAssertFalse(first.capital.isEmpty)
    }
}
