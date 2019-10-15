//
//  File 2.swift
//  
//
//  Created by Andre Navarro on 10/14/19.
//

import Foundation

public protocol TargetType {
    associatedtype ResponseType: Decodable
    
    static var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var bodyType: HTTPBodyType { get }
    var body: Encodable? { get }
    var queryParameters: QueryParameters? { get }
}

public protocol ProviderType {
    associatedtype Target
}

public class Provider<Target: TargetType> {
    private var webService: Webservice
    
    public init(headerValues: HTTPHeaders = [:],
                urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity(),
                parser: ParserProtocol = Parser()) {
        
        webService = Webservice(baseURL: Target.baseURL,
                                headerValues: headerValues,
                                urlSession: urlSession,
                                networkActivity: networkActivity,
                                parser: parser)
    }
    
    @discardableResult
    func request(_ target: Target,
                 completion: @escaping ResultRequestCallback<Target.ResponseType>) -> Request{
        return webService.request(withPath: target.path,
                                  method: target.method,
                                  bodyType: target.bodyType,
                                  body: target.body,
                                  queryParameters: target.queryParameters,
                                  completion: completion)
    }
}
