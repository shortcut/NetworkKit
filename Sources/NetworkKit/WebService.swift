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

//MARK: - Utility
public extension Webservice {
    func deleteAllHeaders() {
        self.headerValues.removeAll()
    }
    
    func addHeaderValue(key: String, value: String) {
        self.headerValues[key] = value
    }
    
    func removeHeaderValue(forKey key: String) {
        self.headerValues.removeValue(forKey: key)
    }
}

//MARK: - Requests
public extension Webservice {
    func request<T: Decodable>(withPath path: String,
                               method: HTTPMethod,
                               bodyType: HTTPBodyType = .none,
                               body: Encodable? = nil,
                               queryParameters query: QueryParameters? = nil,
                               completion: @escaping ResultDecodableCallback<T>) {
        
        requestData(forPath: path,method: method, bodyType: bodyType,
                    body: body, queryParameters: query) { (result: Result <Data, NetworkStackError>) in
                        
                        switch result {
                        case .failure(let error):
                            OperationQueue.main.addOperation {completion(.failure(error))}
                        case .success(let data):
                            self.parser.json(data: data, completion: completion)
                        }
        }
    }
    
    
    func requestStatusCode(forPath path: String,
                           method: HTTPMethod,
                           bodyType: HTTPBodyType = .none,
                           body: Encodable? = nil,
                           queryParameters query: QueryParameters? = nil ,
                           completion: @escaping ResultStatusCodeCallBack) {
        
        guard
            let request = buildRequest(withPath: path, method: method, bodyType: bodyType, body: body)
            else {
                OperationQueue.main.addOperation {
                    completion(.failure(.invalidURL))
                }
                return
        }
        
        perfomDataTask(withRequest: request) { (data, response, error) in
            if let error = error {
                OperationQueue.main.addOperation({ completion(.failure(.responseError(error)))})
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                OperationQueue.main.addOperation {completion(.failure(.responseMissing))}
                return
            }
            OperationQueue.main.addOperation {
                completion(.success(httpResponse.statusCode))
            }
        }
    }
    
    func requestData(forPath path: String,
                     method: HTTPMethod,
                     bodyType: HTTPBodyType = .none,
                     body: Encodable? = nil,
                     queryParameters query: QueryParameters? = nil ,
                     completion: @escaping ResultDataCallback) {
        
        guard
            let request = buildRequest(withPath: path, method: method, bodyType: bodyType, body: body, queryParameters: query)
            else {
                OperationQueue.main.addOperation {
                    completion(.failure(.invalidURL))
                }
                return
        }
        
        perfomDataTask(withRequest: request) { (data, response, error) in
            if let error = error {
                OperationQueue.main.addOperation({ completion(.failure(.responseError(error)))})
                return
            }
            
            guard let data = data else {
                OperationQueue.main.addOperation({ completion(.failure(NetworkStackError.dataMissing)) })
                return
            }
            
            OperationQueue.main.addOperation {
                completion(.success(data))
            }
        }
    }
}
