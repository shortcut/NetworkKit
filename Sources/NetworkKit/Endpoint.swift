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
public typealias ResponseCallback<SuccessType, ErrorType> = (Response<SuccessType, ErrorType, NetworkStackError>) -> Void
public typealias ResultDataCallback = (URLRequest?, URLResponse?, Result<Data, NetworkStackError>) -> Void
public typealias DataCallback = (URLRequest?, URLResponse?, Data?, NetworkStackError?) -> Void
public typealias ResultRequestCallback<T> = (Response<T, EmptyErrorResponse, NetworkStackError>) -> Void

public typealias QueryParameters = [String: String]
public typealias TaskCallback = (Data?, URLResponse?, Error?) -> Void

public enum ResponseType {
    case statusCode
    case data
    case codable
}

public enum HTTPBodyType {
    case json
    case formEncoded(parameters: [String: String])
    case none
}

public protocol ResponseSuccessSelector {
    func isSuccess<SuccessType, ErrorResponseType, NetworkStackError>(_ response: Response<SuccessType, ErrorResponseType, NetworkStackError>) -> Bool
}

public struct DefaultResponseSuccessSelector: ResponseSuccessSelector {
    public init() {}
    public func isSuccess<SuccessType, ErrorResponseType, NetworkStackError>(_ response: Response<SuccessType, ErrorResponseType, NetworkStackError>) -> Bool {
        if let statusCode = response.statusCode, statusCode < 400 {
            return true
        }
        else {
            return false
        }
    }
}

public struct Response<SuccessType, ErrorType, Failure: Error> {
    // hmmm
    public let request: URLRequest?
    public let response: URLResponse?

    public var data: Data?
    public var result: Result<SuccessType, Failure>
    public var value: SuccessType? { return try? result.get() }
    public var error: Failure? {
        guard case let .failure(error) = result else { return nil }
        return error
    }

    public var errorResponse: ErrorType?

    public var statusCode: Int? {
        guard let response = self.response as? HTTPURLResponse else { return nil }
        return response.statusCode
    }
}

public struct Request {
    var task: URLSessionTask?
    var error: Error?
    var request: URLRequest?
    var response: URLResponse?

    func cancel() {
        task?.cancel()
    }
}
