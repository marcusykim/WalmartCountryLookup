
import Foundation

struct Country: Codable, Equatable {
    let name: String
    let region: String
    let code: String
    let capital: String

    enum CodingKeys: String, CodingKey {
        case name, region, code, capital
    }

    init(name: String, region: String, code: String, capital: String) {
        self.name = name.isEmpty ? "N/A" : name
        self.region = region.isEmpty ? "N/A" : region
        self.code = (2...3).contains(code.count) ? code : "N/A"
        self.capital = capital.isEmpty ? "N/A" : capital
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawName = try container.decodeIfPresent(String.self, forKey: .name) ?? "N/A"
        let rawRegion = try container.decodeIfPresent(String.self, forKey: .region) ?? "N/A"
        let rawCode    = try container.decodeIfPresent(String.self, forKey: .code)   ?? "N/A"
        let rawCapital = try container.decodeIfPresent(String.self, forKey: .capital) ?? "N/A"
        self.init(name: rawName, region: rawRegion, code: rawCode, capital: rawCapital)
    }
}
