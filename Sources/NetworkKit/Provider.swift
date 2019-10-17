//
//  File 2.swift
//  
//
//  Created by Andre Navarro on 10/14/19.
//

import Foundation

public protocol TargetType {
    static var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var bodyType: HTTPBodyType { get }
    var body: Encodable? { get }
    var queryParameters: QueryParameters? { get }
    
}

public class Provider<Target: TargetType> {
    private var webService: Webservice
    
    public init(headerValues: HTTPHeaders = [:],
                urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity(),
                parser: ParserProtocol = JSONParser()) {
        
        webService = Webservice(baseURL: Target.baseURL,
                                headerValues: headerValues,
                                urlSession: urlSession,
                                networkActivity: networkActivity,
                                parser: parser)
    }
    
    @discardableResult
    public func request<T: Decodable>(_ target: Target,
                                      completion: @escaping ResultRequestCallback<T>) -> Request {
        
        return webService.request(withPath: target.path,
                                  method: target.method,
                                  bodyType: target.bodyType,
                                  body: target.body,
                                  queryParameters: target.queryParameters,
                                  completion: completion)
    }
}
