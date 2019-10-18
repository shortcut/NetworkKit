//
//  DataFetcher.swift
//  
//
//  Created by Andre Navarro on 10/17/19.
//

import Foundation

public protocol DataFetcher {
    func fetch(_ target: TargetType, completion: @escaping DataCallback)
    func cancelAllRequests()
    func cancelRequest(_ target: TargetType)
}

public struct DiskDataFetcher: DataFetcher {
    public func fetch(_ target: TargetType, completion: @escaping DataCallback) {
        if let url = Bundle.main.url(forResource: target.diskFileName, withExtension: nil),
            let data = try? Data(contentsOf: url) {
            completion(nil, nil, data, nil)
        }
        else {
            completion(nil, nil, nil, .dataMissing)
        }
    }
        
    public func cancelAllRequests() {
    }
    
    public func cancelRequest(_ target: TargetType) {
    }
}

public class URLSessionDataFetcher: DataFetcher {
    private var webService: Webservice
    private var requests: Set<URLRequest> = Set<URLRequest>()
    private var middleware: [Middlewarer]
    
    public init(headerValues: HTTPHeaders = [:],
                urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        
        webService = Webservice(baseURL: Target.baseURL,
                                headerValues: headerValues,
                                urlSession: urlSession,
                                networkActivity: networkActivity)
    }

    public func fetch(_ target: TargetType, completion: @escaping DataCallback) {
        let request = webService.requestData(withPath: target.path,
                                         method: target.method,
                                         bodyType: target.bodyType,
                                         body: target.body,
                                         queryParameters: target.queryParameters) { (request, response, data, error) in
                                            
                                            middleware.forEach { middle in
                                                middle.prepare(request, completion())
                                            }
                                            
                                            
                                            completion(request, response, data, error)
        }
        
        if let urlRequest = request.request {
            requests.insert(urlRequest)
        }
        //TODO: save request so it can be cancelled
    }
    
    public func cancelRequest(_ target: TargetType) {
    }
    
    public func cancelAllRequests() {
    }
}
