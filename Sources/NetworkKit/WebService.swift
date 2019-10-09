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
                parser: ParserProtocol = Parser()) {
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
    func request<T: Decodable>(withPath path: String,
                               method: HTTPMethod,
                               bodyType: HTTPBodyType = .none,
                               body: Encodable? = nil,
                               queryParameters query: QueryParameters? = nil,
                               completion: @escaping ResultRequestCallback<T>) {
        requestData(withPath: path, method: method, bodyType: bodyType,
                    body: body, queryParameters: query) { (request, urlResponse, result: Result<Data, NetworkStackError>) in
                        
                        let data = try? result.get()
                        
                        DispatchQueue.global(qos: .background).async {
                            let decodeResult = self.parser.json(data: data) as Result<T, NetworkStackError>
                        
                            OperationQueue.main.addOperation {
                                completion(Response<T, NetworkStackError>(request: request, response: urlResponse, data: data, result: decodeResult))
                            }
                        }
        }
    }

    func requestData(withPath path: String,
                     method: HTTPMethod,
                     bodyType: HTTPBodyType = .none,
                     body: Encodable? = nil,
                     queryParameters query: QueryParameters? = nil,
                     completion: @escaping ResultDataCallback) {
        guard let request = buildRequest(withPath: path, method: method, bodyType: bodyType, body: body, queryParameters: query) else {
            completion(nil, nil, .failure(.invalidURL))
            return
        }

        perfomDataTask(withRequest: request) { (data, response, error) in

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
