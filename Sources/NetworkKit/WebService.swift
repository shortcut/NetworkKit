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
    
    public init(baseURL: URL, headerValues: HTTPHeaders = [:],
                urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        self.baseURL = baseURL
        self.headerValues = headerValues
        self.urlSession = urlSession
        self.networkActivity = networkActivity
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

public class WebserviceDecoder: Webservice {
    public var parser: ParserProtocol
    
    public init(baseURL: URL,
        headerValues: HTTPHeaders = [:],
        urlSession: URLSession = URLSession(configuration: .default),
        networkActivity: NetworkActivityProtocol = NetworkActivity(),
        parser: ParserProtocol = JSONParser()) {
        
        self.parser = parser

        super.init(baseURL: baseURL, headerValues: headerValues, urlSession: urlSession, networkActivity: networkActivity)
    }
    
    @discardableResult
    func request<T: Decodable>(withPath path: String,
                               method: HTTPMethod,
                               bodyType: HTTPBodyType = .none,
                               body: Encodable? = nil,
                               queryParameters query: QueryParameters? = nil,
                               completion: @escaping ResponseCallback<T, EmptyErrorResponse>) -> Request {
        requestData(withPath: path, method: method, bodyType: bodyType,
                    body: body, queryParameters: query) { (request, urlResponse, result: Result<Data, NetworkStackError>) in

            switch result {
            case let .success(data):
                DispatchQueue.global(qos: .background).async {
                    
                    let decodeResult = self.parser.parse(data: data) as Result<T, NetworkStackError>

                    OperationQueue.main.addOperation {
                        let response = Response<T, EmptyErrorResponse, NetworkStackError>(request: request, response: urlResponse, data: data, result: decodeResult, errorResponse: nil)
                        completion(response)
                    }
                }
            case let .failure(error):
                OperationQueue.main.addOperation {
                    completion(Response<T, EmptyErrorResponse, NetworkStackError>(request: request, response: urlResponse, data: nil, result: .failure(error), errorResponse: nil))
                }
            }
        }
    }
        
    @discardableResult
    func request<Selector: ResponseTypeSelector>(withPath path: String,
                                                 method: HTTPMethod,
                                                 bodyType: HTTPBodyType = .none,
                                                 body: Encodable? = nil,
                                                 queryParameters query: QueryParameters? = nil,
                                                 typeSelector: Selector,
                                                 completion: @escaping ResponseCallback<Selector.SuccessType, Selector.ErrorType>) -> Request {

        return requestData(withPath: path,
                           method: method,
                           bodyType: bodyType,
                           body: body,
                           queryParameters: query) { (request, response, data, error) in
            // have no data, have error
            guard let data = data else {
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: nil,
                                                                                                     result: .failure(NetworkStackError.dataMissing),
                                                                                                     errorResponse: nil)
                completion(response)
                return
            }
            
            // maybe have data, have undeniable error
            if let error = error {
                let errorResponse = self.parser.parse(data: data) as Result<Selector.ErrorType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: .failure(NetworkStackError.responseError(error)),
                                                                                                     errorResponse: try? errorResponse.get())
                completion(response)
                return
            }
            
            // let the type selector decide if there is an error
            // TODO: response wrapper hmmm
            let responseType = typeSelector.type(for: (response as? HTTPURLResponse)!.statusCode)
            
            switch responseType {
                // we want to parse the successful response and return the model object
            case is Selector.SuccessType.Type:
                let parseResult = self.parser.parse(data: data) as Result<Selector.SuccessType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: parseResult,
                                                                                                     errorResponse: nil)
                completion(response)
            case is Selector.ErrorType.Type:
                //we want to parse the response as an error model and return that
                let errorResponse = self.parser.parse(data: data) as Result<Selector.ErrorType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: .failure(.errorResponse),
                                                                                                     errorResponse: try? errorResponse.get())
                completion(response)
            default:
                
                // lol wat, never supposed to get here but ok
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: nil,
                                                                                                     result: .failure(NetworkStackError.dataMissing),
                                                                                                     errorResponse: nil)
                completion(response)
            }
        }
    }
}

public extension Webservice {
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
    
    @discardableResult
    func requestData(withPath path: String,
                     method: HTTPMethod,
                     bodyType: HTTPBodyType = .none,
                     body: Encodable? = nil,
                     queryParameters query: QueryParameters? = nil,
                     completion: @escaping DataCallback) -> Request {
        guard let request = buildRequest(withPath: path, method: method, bodyType: bodyType, body: body, queryParameters: query) else {
            let error = NetworkStackError.invalidURL
            completion(nil, nil, nil, error)
            return Request(task: nil, error: error, request: nil, response: nil)
        }

        return perfomDataTask(withRequest: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(request, response, data, .responseError(error))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(request, response, nil, .dataMissing)
                }
                return
            }

            DispatchQueue.main.async {
                completion(request, response, data, nil)
            }
        }
    }
}
