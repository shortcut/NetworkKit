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

public enum NetworkStackError: Error {
    case requestIsMissing
    case paringError(Error)
    case invalidURL
    case responseError(Error)
    case dataMissing
    case responseMissing
    case errorResponse
    case middlewareError(Error)
}

public struct EmptyErrorResponse: Decodable {
}

public typealias HTTPHeaders = [String: String]
public typealias ResponseCallback<SuccessType, ErrorType> = (Response<SuccessType, ErrorType>) -> Void
public typealias ResultDataCallback = (URLRequest?, URLResponse?, Result<Data, NetworkStackError>) -> Void
public typealias DataCallback = (URLRequest?, URLResponse?, Data?, NetworkStackError?) -> Void
public typealias ResultRequestCallback<T> = (Response<T, EmptyErrorResponse>) -> Void

public typealias QueryParameters = [String: String]
public typealias TaskCallback = (Data?, URLResponse?, Error?) -> Void

public enum HTTPBodyType {
    case json
    case formEncoded(parameters: [String: String])
    case none
}

public protocol ResponseSuccessSelector {
    func isSuccess<SuccessType, ErrorResponseType>(_ response: Response<SuccessType, ErrorResponseType>) -> Bool
}

public struct DefaultResponseSuccessSelector: ResponseSuccessSelector {
    public init() {}
    public func isSuccess<SuccessType, ErrorResponseType>(_ response: Response<SuccessType, ErrorResponseType>) -> Bool {
        if case .failure = response.result {
            return false
        }
        
        if let statusCode = response.statusCode, statusCode < 400 {
            return true
        }
        else {
            return false
        }
    }
}

public struct Response<SuccessType, ErrorResponseType> {
    public let request: URLRequest?
    public let response: URLResponse?

    public var data: Data?
    public var result: Result<SuccessType, NetworkStackError>

    public var errorResponse: ErrorResponseType?

    public var statusCode: Int? {
        guard let response = self.response as? HTTPURLResponse else { return nil }
        return response.statusCode
    }
    
    public func localizedStringForStatusCode() -> String? {
        guard let statusCode = self.statusCode else { return nil }
        return HTTPURLResponse.localizedString(forStatusCode: statusCode)
    }

    public var allHeaderFields: [AnyHashable : Any]? {
        guard let response = self.response as? HTTPURLResponse else { return nil }
        return response.allHeaderFields
    }
}

public struct Request {
    var task: URLSessionTask?
    var error: Error?
    var request: URLRequest?
    var response: URLResponse?

    public func cancel() {
        task?.cancel()
    }
    
    public init() {}
}
