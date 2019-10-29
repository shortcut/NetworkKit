//
//  Request.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

public protocol RequestType {
    var baseURL: URL { get }
    var headerValues: HTTPHeaders? { get }

    var path: String { get }
    var method: HTTPMethod { get }
    var bodyType: HTTPBodyType { get }
    var body: Encodable? { get }
    var queryParameters: QueryParameters? { get }
    var additionalHeaderValues: HTTPHeaders? { get }
}

// defaults
extension RequestType {
    var bodyType: HTTPBodyType { .none }
    var body: Encodable? { nil }
    var queryParameters: QueryParameters? { nil }
    var headerValues: HTTPHeaders? { nil }
    var additionalHeaderValues: HTTPHeaders? { nil }
}

extension RequestType {
    func asURLRequest() -> URLRequest? {
        guard let url = asURL() else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.value

        if let headerValues = headerValues {
            headerValues.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }

        if let headerValues = additionalHeaderValues {
            headerValues.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        }

        switch bodyType {
        case .none:
            break
        case let .formEncoded(parameters: parameters):
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            request.encodeParameters(parameters: parameters)
        case .json:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body?.encode()
        }

        return request
    }

    private func asURL() -> URL? {
        guard
            var components = URLComponents(string: baseURL.absoluteString + path)
        else { return nil }

        if let queryParameters = queryParameters {
            components.setQueryItems(with: queryParameters)
        }

        return components.url
    }
}
