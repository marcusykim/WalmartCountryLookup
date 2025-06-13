import Foundation
struct DealMessages {
    static let dealMessages: [String] = {
        guard
            let url = Bundle.main.url(forResource: "dealMessages", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let messages = try? JSONDecoder().decode([String].self, from: data)
        else {
            return ["The best deals are in "]
        }
        return messages
    }()
}
