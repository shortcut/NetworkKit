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
    case invalidURL
    case parsingError(Error)
    case responseError(Error)
    case dataMissing
    case responseMissing
    case errorResponse(Decodable?)
    case middlewareError(Error)
}

public class EmptyErrorResponse: Decodable {
}

public typealias HTTPHeaders = [String: String]
public typealias ResponseCallback<SuccessType> = (Response<SuccessType>) -> Void
public typealias ResultDataCallback = (URLRequest?, URLResponse?, Result<Data, NetworkStackError>) -> Void
public typealias DataCallback = (URLRequest?, URLResponse?, Data?, Error?) -> Void
public typealias ResultRequestCallback<T> = (Response<T>) -> Void

public typealias TaskCallback = (Data?, URLResponse?, Error?) -> Void

public enum HTTPBodyType {
    case json
    case formEncoded(parameters: [String: String])
    case none
}

public protocol ResponseSuccessSelector {
    func isSuccess<SuccessType>(_ response: Response<SuccessType>) -> Bool
}

public struct DefaultResponseSuccessSelector: ResponseSuccessSelector {
    public init() {}
    public func isSuccess<SuccessType>(_ response: Response<SuccessType>) -> Bool {
        if case .failure = response.result {
            return false
        }

        if let statusCode = response.statusCode, statusCode < 400 {
            return true
        } else {
            return false
        }
    }
}

public struct Response<SuccessType> {
    public let request: URLRequest?
    public let response: URLResponse?

    public var data: Data?
    public var result: Result<SuccessType, NetworkStackError>

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

extension Response {
    public func mapDecodable<SuccessType: Decodable>(
        parser: ParserProtocol = JSONParser(),
        successSelector: ResponseSuccessSelector = DefaultResponseSuccessSelector(),
        completion: @escaping (Response<SuccessType>) -> Void) {

        DispatchQueue.global(qos: .background).async {
            var newResponse: Response<SuccessType>

            if successSelector.isSuccess(self) {
                let result = parser.parse(data: self.data) as Result<SuccessType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: result)
            } else {
                var error: NetworkStackError = .errorResponse(nil)
                if case let .failure(originalError) = self.result {
                    error = originalError
                }
                newResponse = .init(request: self.request,
                                    response: self.response,
                                    data: self.data,
                                    result: .failure(error))
            }

            DispatchQueue.main.async {
                completion(newResponse)
            }
        }

    }

    public func mapDecodableWithError<SuccessType: Decodable, ErrorResponseType: Decodable>(
        parser: ParserProtocol = JSONParser(),
        successSelector: ResponseSuccessSelector = DefaultResponseSuccessSelector(),
        errorResponseType: ErrorResponseType.Type,
        completion: @escaping (Response<SuccessType>) -> Void) {

        DispatchQueue.global(qos: .background).async {
            var newResponse: Response<SuccessType>

            if successSelector.isSuccess(self) {
                let result = parser.parse(data: self.data) as Result<SuccessType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: result)
            } else {
                let errorResult = parser.parse(data: self.data) as Result<ErrorResponseType, NetworkStackError>
                newResponse = .init(request: self.request,
                                    response: self.response,
                                    data: self.data,
                                    result: .failure(.errorResponse(try? errorResult.get())))
            }

            DispatchQueue.main.async {
                completion(newResponse)
            }
        }
    }

    public func mapString(successSelector: ResponseSuccessSelector = DefaultResponseSuccessSelector(),
                          completion: @escaping (Response<String>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            guard let data = self.data,
                let string = String(data: data, encoding: .utf8) else {

                return
            }

            let newResponse = Response<String>(request: self.request,
                                               response: self.response,
                                               data: self.data,
                                               result: .success(string))

            DispatchQueue.main.async {
                completion(newResponse)
            }
        }
    }
}
