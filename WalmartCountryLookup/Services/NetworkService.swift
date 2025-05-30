import Foundation

enum NetworkError: Error {
    case badURL, requestFailed(statusCode: Int), noData, decodingError(Error)
}

protocol NetworkServiceProtocol {
    func fetchCountries() async throws -> [Country]
}

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let remoteURL =
      "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/countries.json"

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCountries() async throws -> [Country] {
        guard let url = URL(string: remoteURL) else {
            throw NetworkError.badURL
        }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            throw NetworkError.requestFailed(statusCode: http.statusCode)
        }
        guard !data.isEmpty else {
            throw NetworkError.noData
        }
        do {
            return try JSONDecoder().decode([Country].self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
