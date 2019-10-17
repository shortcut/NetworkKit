//
//  WebService.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public class Webservice: WebServiceProtocol {
    public var baseURL: URL
    public var headerValues: HTTPHeaders
    public var urlSession: URLSession
    public var networkActivity: NetworkActivityProtocol
    public var parser: ParserProtocol

    public init(baseURL: URL, headerValues: HTTPHeaders = [:],
                urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity(),
                parser: ParserProtocol = JSONParser()) {
        self.baseURL = baseURL
        self.headerValues = headerValues
        self.urlSession = urlSession
        self.networkActivity = networkActivity
        self.parser = parser
    }
}

// MARK: - Utility

public extension Webservice {
    func deleteAllHeaders() {
        headerValues.removeAll()
    }

    func addHeaderValue(key: String, value: String) {
        headerValues[key] = value
    }

    func removeHeaderValue(forKey key: String) {
        headerValues.removeValue(forKey: key)
    }
}

// MARK: - Requests

public extension Webservice {
    @discardableResult
    func request<T: Decodable>(withPath path: String,
                               method: HTTPMethod,
                               bodyType: HTTPBodyType = .none,
                               body: Encodable? = nil,
                               queryParameters query: QueryParameters? = nil,
                               completion: @escaping ResultRequestCallback<T>) -> Request {
        requestData(withPath: path, method: method, bodyType: bodyType,
                    body: body, queryParameters: query) { (request, urlResponse, result: Result<Data, NetworkStackError>) in

            switch result {
            case let .success(data):
                DispatchQueue.global(qos: .background).async {
                    
                    let decodeResult = self.parser.parse(data: data) as Result<T, NetworkStackError>

                    OperationQueue.main.addOperation {
                        completion(Response<T, NetworkStackError>(request: request, response: urlResponse, data: data, result: decodeResult))
                    }
                }
            case let .failure(error):
                OperationQueue.main.addOperation {
                    completion(Response<T, NetworkStackError>(request: request, response: urlResponse, data: nil, result: .failure(error)))
                }
            }
        }
    }

    @discardableResult
    func requestData(withPath path: String,
                     method: HTTPMethod,
                     bodyType: HTTPBodyType = .none,
                     body: Encodable? = nil,
                     queryParameters query: QueryParameters? = nil,
                     completion: @escaping ResultDataCallback) -> Request {
        guard let request = buildRequest(withPath: path, method: method, bodyType: bodyType, body: body, queryParameters: query) else {
            let error = NetworkStackError.invalidURL
            completion(nil, nil, .failure(error))
            return Request(task: nil, error: error, request: nil, response: nil)
        }

        return perfomDataTask(withRequest: request) { data, response, error in

            if let error = error {
                DispatchQueue.main.async {
                    completion(request, response, .failure(.responseError(error)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(request, response, .failure(NetworkStackError.dataMissing))
                }
                return
            }

            DispatchQueue.main.async {
                completion(request, response, .success(data))
            }
        }
    }
}
