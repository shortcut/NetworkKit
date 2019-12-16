//
//  URLRequest.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public extension URLRequest {
    private func percentEscapeString(_ string: String) -> String {
        var characterSet = CharacterSet.alphanumerics
        characterSet.insert(charactersIn: "-._*")

        return string
            .addingPercentEncoding(withAllowedCharacters: characterSet)!
            .replacingOccurrences(of: " ", with: "+")
            .replacingOccurrences(of: " ", with: "+", options: [], range: nil)
    }

    mutating func encodeParameters(parameters: [String: String]) {
        let parameterArray = parameters.map { (arg) -> String in
            let (key, value) = arg
            return "\(key)=\(self.percentEscapeString(value))"
        }
        guard let data = parameterArray.joined(separator: "&").data(using: .utf8) else { return }
        httpBody = data
    }

    init?(baseURL: URL,
          path: String,
          httpMethod: HTTPMethod,
          headerValues: HTTPHeaders? = nil,
          queryParameters: QueryParameters? = nil,
          bodyType: HTTPBodyType,
          body: Encodable? = nil,
          cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy) {

        guard let url = URL(baseURL: baseURL, path: path, queryParameters: queryParameters) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.value

        if let headerValues = headerValues {
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

        request.cachePolicy = cachePolicy

        self = request
    }
}

public extension URL {
    init?(baseURL: URL, path: String, queryParameters: QueryParameters?) {
        guard
            var components = URLComponents(string: baseURL.absoluteString + path)
        else { return nil }

        if let queryParameters = queryParameters {
            components.setQueryItems(with: queryParameters)
        }

        guard let url = components.url else { return nil }

        self = url
    }
}
