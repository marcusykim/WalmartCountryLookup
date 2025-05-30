
import Foundation

struct Country: Codable, Equatable {
    let name: String
    let region: String
    let code: String
    let capital: String

    enum CodingKeys: String, CodingKey {
        case name, region, code = "cca2", capital
    }

    init(name: String, region: String, code: String, capital: String) {
        self.name = name.isEmpty ? "Unknown" : name
        self.region = region.isEmpty ? "Global" : region
        self.code = code.count == 2 ? code : "--"
        self.capital = capital.isEmpty ? "—" : capital
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawName = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        let rawRegion = try container.decodeIfPresent(String.self, forKey: .region) ?? "Global"
        let rawCode = try container.decodeIfPresent(String.self, forKey: .code) ?? "--"
        let rawCapital = try container.decodeIfPresent(String.self, forKey: .capital) ?? "—"
        self.init(name: rawName, region: rawRegion, code: rawCode, capital: rawCapital)
    }
}
