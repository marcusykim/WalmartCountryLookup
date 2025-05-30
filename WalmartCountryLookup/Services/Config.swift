import Foundation

enum Config {
    static let countriesURL = URL(string: "https://gist.githubusercontent.com/peymano-wmt/32dcb892b06648910ddd40406e37fdab/raw/db25946fd77c5873b0303b858e861ce724e0dcd0/countries.json")!
    static let requestTimeout: TimeInterval = 10 // seconds
    static let retryCount = 2
    static let retryDelay: TimeInterval = 1 // seconds
}
