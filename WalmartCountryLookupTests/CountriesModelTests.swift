

import XCTest
@testable import WalmartCountryLookup

final class CountriesModelTests: XCTestCase {

    func testCountryInitWithValidValues() {
        let country = Country(name: "Testland", region: "Test Region", code: "TR", capital: "Testville")
        XCTAssertEqual(country.name, "Testland")
        XCTAssertEqual(country.region, "Test Region")
        XCTAssertEqual(country.code, "TR")
        XCTAssertEqual(country.capital, "Testville")
    }

    func testCountryInitWithEmptyAndInvalidValues() {
        // Empty name, region, and capital; invalid code length
        let country = Country(name: "", region: "", code: "XYZ", capital: "")
        XCTAssertEqual(country.name, "Unknown")      // empty → "Unknown"
        XCTAssertEqual(country.region, "Global")      // empty → "Global"
        XCTAssertEqual(country.code, "--")            // invalid length → "--"
        XCTAssertEqual(country.capital, "—")          // empty → "—"
    }

    func testDecodableDefaultsFromJSON() throws {
        let jsonString = """
        [
          {
            "name": "",
            "region": "",
            "cca2": "X",
            "capital": ""
          }
        ]
        """
        let data = Data(jsonString.utf8)
        let decoder = JSONDecoder()
        let list = try decoder.decode([Country].self, from: data)
        XCTAssertEqual(list.count, 1)
        let country = list[0]
        XCTAssertEqual(country.name, "Unknown")
        XCTAssertEqual(country.region, "Global")
        XCTAssertEqual(country.code, "--")
        XCTAssertEqual(country.capital, "—")
    }
}
