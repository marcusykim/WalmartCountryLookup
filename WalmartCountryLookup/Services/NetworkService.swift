import Foundation

enum NetworkError: Error {
    case requestFailed(statusCode: Int)
    case noData
    case decodingError(Error)
}

protocol NetworkServiceProtocol {
    func fetchCountries() async throws -> [Country]
}

final class NetworkService: NetworkServiceProtocol {
    private let session: URLSession
    private let url: URL
    private let retries: Int

    init(session: URLSession = URLSession(configuration: .default),
         url: URL = Config.countriesURL,
         retries: Int = Config.retryCount) {
        let config = session.configuration
        config.timeoutIntervalForRequest = Config.requestTimeout
        self.session = URLSession(configuration: config)
        self.url = url
        self.retries = retries
    }

    func fetchCountries() async throws -> [Country] {
        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(from: url)
                guard let http = response as? HTTPURLResponse else {
                    throw NetworkError.noData
                }
                guard (200...299).contains(http.statusCode) else {
                    throw NetworkError.requestFailed(statusCode: http.statusCode)
                }
                return try JSONDecoder().decode([Country].self, from: data)
            }
            catch let decodingError as DecodingError {
                throw NetworkError.decodingError(decodingError)
            }
            catch {
                attempt += 1
                if attempt > retries { throw error }
                try? await Task.sleep(nanoseconds: UInt64(Config.retryDelay * 1_000_000_000))
            }
        }
    }

}
