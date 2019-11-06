import Foundation

/// Convenience access to the global Network session
// swiftlint:disable:next type_name
public enum NK {
    public static var sharedNetwork = Network()
    public static func request(withBaseURL baseURL: URL,
                               path: String,
                               method: HTTPMethod,
                               bodyType: HTTPBodyType = .none,
                               headerValues: HTTPHeaders? = nil,
                               body: Encodable? = nil,
                               queryParameters query: QueryParameters? = nil) -> Request {

        return NK.sharedNetwork.request(URLRequest(baseURL: baseURL,
                                                path: path,
                                                httpMethod: method,
                                                headerValues: headerValues,
                                                additionalHeaderValues: nil,
                                                queryParameters: query,
                                                bodyType: bodyType,
                                                body: body))
    }

    public static func request(_ target: TargetType) -> Request {
        return NK.sharedNetwork.request(target)
    }

    public static func request(_ url: URL, method: HTTPMethod = .get) -> Request {
        return NK.sharedNetwork.request(url, method: method)
    }

    public static func request(_ urlString: String, method: HTTPMethod = .get) -> Request {
        return NK.sharedNetwork.request(urlString, method: method)
    }

    public static func request(_ urlRequest: URLRequest) -> Request {
        return NK.sharedNetwork.request(urlRequest)
    }
}
