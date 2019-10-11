//
//  Endpoint.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import UIKit

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
}

public typealias HTTPHeaders = [String: String]
public typealias ResultRequestCallback<T> = (Response<T, NetworkStackError>) -> Void
public typealias ResultDecodableCallback<T> = (Result<T, NetworkStackError>) -> Void
public typealias ResultDataCallback = (URLRequest?, URLResponse?, Result<Data, NetworkStackError>) -> Void
public typealias ResultStatusCodeCallBack = (Result<Int, NetworkStackError>) -> Void
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

public struct Response<Success, Failure: Error> {
    public let request: URLRequest?
    public let response: URLResponse?
    public let data: Data?
    public let result: Result<Success, Failure>
    public var value: Success? { return try? result.get() }
    public var error: Failure? {
        guard case let .failure(error) = result else { return nil }
        return error
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
