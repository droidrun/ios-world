import Foundation

struct APIConfig {
    let baseURL: URL
    let apiKey: String?
    let enableLiveAPI: Bool
    let requestTimeout: TimeInterval

    static let shared = APIConfig.loadFromBundle()

    static func loadFromBundle(bundle: Bundle = .main) -> APIConfig {
        let defaultBaseURL = URL(string: "https://site.api.espn.com/apis/site/v2/sports")!
        let plistURL = bundle.url(forResource: "APIConfig", withExtension: "plist")

        guard
            let plistURL,
            let data = try? Data(contentsOf: plistURL),
            let object = try? PropertyListSerialization.propertyList(from: data, format: nil),
            let dictionary = object as? [String: Any]
        else {
            return APIConfig(baseURL: defaultBaseURL, apiKey: nil, enableLiveAPI: true, requestTimeout: 10)
        }

        let apiKey = (dictionary["API_KEY"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let enableLiveAPI = (dictionary["ENABLE_LIVE_API"] as? Bool) ?? true
        let baseURLString = dictionary["BASE_URL"] as? String
        let resolvedBaseURL = baseURLString.flatMap { URL(string: $0) } ?? defaultBaseURL
        let timeout = (dictionary["REQUEST_TIMEOUT"] as? TimeInterval) ?? 10

        return APIConfig(
            baseURL: resolvedBaseURL,
            apiKey: (apiKey?.isEmpty == false) ? apiKey : nil,
            enableLiveAPI: enableLiveAPI,
            requestTimeout: timeout
        )
    }
}
