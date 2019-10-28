//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

// input a Request
// run request middleware
// make request
// run response middleware
// parse if client wants
// return

public typealias ClientResponse = (Response<Data>) -> Void

public protocol ClientType {
    func perform(_ request: RequestType, completion: @escaping ClientResponse) -> TaskIdentifier?
    func perform(_ urlRequest: URLRequest, completion: @escaping ClientResponse) -> TaskIdentifier?
    var requestMiddleware: [RequestMiddleware] { get }
    var responseMiddleware: [ResponseMiddleware] { get }

    func cancelRequest(with identifier: TaskIdentifier)
}

/// This middleware takes the passed request, makes changes to it (or not) and passes it back into the chain
public protocol RequestMiddleware {
    func prepare(_ request: URLRequest) -> (URLRequest, Response<Data>?)
}

/// This middleware takes the passed response, makes changes to it (or not) and passes it back
public protocol ResponseMiddleware {
    func prepare<T>(_ response: Response<T>) -> Response<T>
}

public class Client: ClientType {
    public static var shared: Client = Client()
    private var dataFetcher: DataFetcher

    public var requestMiddleware: [RequestMiddleware] = []
    public var responseMiddleware: [ResponseMiddleware] = []

    public init(dataFetcher: DataFetcher = URLSessionDataFetcher.shared) {
        self.dataFetcher = dataFetcher
    }

    public func cancelRequest(with identifier: TaskIdentifier) {
        dataFetcher.cancelRequest(with: identifier)
    }

    @discardableResult
    public func perform(_ request: RequestType, completion: @escaping ClientResponse) -> TaskIdentifier? {
        guard let urlRequest = request.asURLRequest()
        else {
            completion(Response(request: nil, response: nil, data: nil, result: .failure(.invalidURL)))
            return nil
        }

        return perform(urlRequest, completion: completion)
    }

    @discardableResult
    public func perform(_ urlRequest: URLRequest, completion: @escaping ClientResponse) -> TaskIdentifier? {
        var modifiedRequest = urlRequest
        var middlewareError: Error?

        // walk along the middleware pipeline and let them modify the request
        for middle in requestMiddleware {
            let middleResponse = middle.prepare(modifiedRequest)
            modifiedRequest = middleResponse.0
            if case let .failure(error) = middleResponse.1?.result {
                middlewareError = error
                break
            }
        }

        // return early if any middleware errored
        if let error = middlewareError {
            let result = Result<Data, NetworkStackError>.failure(.middlewareError(error))
            DispatchQueue.main.async {
                completion(Response(request: urlRequest, response: nil, data: nil, result: result))
            }
            return nil
        }

        // go get the actual data
        return dataFetcher.fetchRequest(modifiedRequest) { (request, response, data, error) in
            let result: Result<Data, NetworkStackError> = (data != nil ? .success(data!) :
                .failure(.responseError(error ?? NetworkStackError.dataMissing)))

            var modifiedResponse = Response<Data>(request: request, response: response, data: data, result: result)
            var middlewareError: Error?

            // walk along the middleware pipeline and let them modify the response
            for middle in self.responseMiddleware {
                modifiedResponse = middle.prepare(modifiedResponse)
                if case let .failure(newError) = modifiedResponse.result {
                    middlewareError = newError
                    break
                }
            }

            // finally complete with the slutty Response touched by everyone
            DispatchQueue.main.async {
                if let newError = middlewareError {
                    let newResponse = Response<Data>(request: modifiedResponse.request,
                                                     response: modifiedResponse.response,
                                                     data: modifiedResponse.data,
                                                     result: .failure(.middlewareError(newError)))
                    completion(newResponse)
                } else {
                    completion(modifiedResponse)
                }
            }
        }
    }
}
