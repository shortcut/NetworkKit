//
//  Target.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

public protocol TargetType {
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
extension TargetType {
    var bodyType: HTTPBodyType {
        get {.none}
    }
    var body: Encodable? {
        get {nil}
    }
    var queryParameters: QueryParameters? {
        get {nil}
    }
    var additionalHeaderValues: HTTPHeaders? {
        get {nil}
    }
}

extension TargetType {
    func asURLRequest() -> URLRequest? {
        guard let url = self.asURL() else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = method.value

        if let headerValues = self.headerValues {
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
