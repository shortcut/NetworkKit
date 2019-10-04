//
//  WebServiceProtocol.swift
//  Network-Testing
//
//  Created by Vikram on 08/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public protocol WebServiceProtocol {
    
    var baseURL: URL { get set }
    var headerValues: HTTPHeaders { get set }
    var urlSession: URLSession { get }
    var networkActivity: NetworkActivityProtocol { get }
    var parser: ParserProtocol { get }
}


//MARK: Requet Utility
public extension WebServiceProtocol {
    
    func buildRequest(withPath path: String,
                      method: HTTPMethod,
                      bodyType: HTTPBodyType = .none,
                      body: Encodable?,
                      queryParameters query: QueryParameters? = nil) -> URLRequest? {
        guard
            var components = URLComponents(string: baseURL.absoluteString + path)
            else { return nil }
        
        if let queryParameters = query {
            components.setQueryItems(with: queryParameters)
        }
        guard let url = components.url else { return nil }
        return buildRequest(withUrl: url, method: method, bodyType: bodyType, body: body)
    }
    
    private func buildRequest(withUrl url: URL,
                              method: HTTPMethod,
                              bodyType: HTTPBodyType = .none,
                              body: Encodable? = nil) -> URLRequest? {
        
        var request = URLRequest(url: url)
        request.httpMethod = method.value
        
        if !headerValues.isEmpty {
            headerValues.forEach{request.setValue($0.value, forHTTPHeaderField: $0.key)}
        }
        
        switch bodyType {
        case .none:
            break
        case .formEncoded(parameters: let parameters):
            request.encodeParameters(parameters: parameters)
        case .json:
            request.httpBody = body?.encode()
        }
        
        return request
    }
}

//MARK: URLSession Utility
public extension WebServiceProtocol {
    
    func perfomDataTask(withRequest request: URLRequest, completion: @escaping TaskCallback) {
        networkActivity.increment()
        urlSession.dataTask(with: request, completionHandler: { (data, response, error) in
            self.networkActivity.decrement()
            completion(data, response, error)
        }).resume()
    }
}
