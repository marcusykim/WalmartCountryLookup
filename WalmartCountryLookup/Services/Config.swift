import Foundation

enum Config {
    private static var info: [String: Any] {
        Bundle.main.infoDictionary ?? [:]
    }

    static let countriesURL: URL = {
        guard
            let string = info["CountriesURL"] as? String,
            let url = URL(string: string)
        else {
            fatalError("Missing CountriesURL in Info.plist")
        }
        return url
    }()

    static let requestTimeout: TimeInterval = {
        (info["RequestTimeout"] as? NSNumber)?.doubleValue ?? 10
    }()

    static let retryCount: Int = {
        (info["RetryCount"] as? NSNumber)?.intValue ?? 2
    }()

    static let retryDelay: TimeInterval = {
        (info["RetryDelay"] as? NSNumber)?.doubleValue ?? 1
    }()
}
