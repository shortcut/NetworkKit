//
//  Endpoint.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete

    var value: String {
        return rawValue.uppercased()
    }
}

public enum NetworkError: Error {
    case invalidURL
    case parsingError(Error)
    case responseError(Error)
    case dataMissing
    case responseMissing
    case errorResponse(Decodable)
    case middlewareError(Error)
    case validateError
    case cancelled
}

public typealias HTTPHeaders = [String: String]
public typealias ResultRequestCallback<T> = (Response<T>) -> Void

public enum HTTPBodyType {
    case json
    case formEncoded(parameters: [String: String])
    case none
}

public struct Response<SuccessType> {
    public var request: URLRequest?
    public var response: URLResponse?

    public var data: Data?
    public var result: Result<SuccessType, NetworkError>
    public var responseIsFromCacheProvider: Bool = false

    init(_ result: Result<SuccessType, NetworkError>) {
        self.result = result
    }
}

extension Response {
    public var statusCode: Int? {
         guard let response = self.response as? HTTPURLResponse else { return nil }
         return response.statusCode
     }

     public func localizedStringForStatusCode() -> String? {
         guard let statusCode = self.statusCode else { return nil }
         return HTTPURLResponse.localizedString(forStatusCode: statusCode)
     }

     public var allHeaderFields: [AnyHashable: Any]? {
         guard let response = self.response as? HTTPURLResponse else { return nil }
         return response.allHeaderFields
     }
}
