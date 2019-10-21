//
//  Target.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

struct Target: TargetType {
    static var baseURL: URL = URL(string: "test.com")!
    
    static var headerValues: HTTPHeaders?
    
    var path: String
    
    var method: HTTPMethod
    var bodyType: HTTPBodyType
    var body: Encodable?
    var queryParameters: QueryParameters?
    var additionalHeaderValues: HTTPHeaders?
    var diskFileName: String
}

public protocol TargetType {
    static var baseURL: URL { get }
    static var headerValues: HTTPHeaders? { get }
    
    var path: String { get }
    var method: HTTPMethod { get }
    var bodyType: HTTPBodyType { get }
    var body: Encodable? { get }
    var queryParameters: QueryParameters? { get }
    var additionalHeaderValues: HTTPHeaders? { get }
    var diskFileName: String { get }
}

extension TargetType {
    func asURLRequest() -> URLRequest? {
        guard
            var components = URLComponents(string: Self.baseURL.absoluteString + path)
        else { return nil }

        if let queryParameters = queryParameters {
            components.setQueryItems(with: queryParameters)
        }
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.value

        if let headerValues = Self.headerValues {
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
}
