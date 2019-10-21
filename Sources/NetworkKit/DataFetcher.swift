//
//  DataFetcher.swift
//  
//
//  Created by Andre Navarro on 10/17/19.
//

import Foundation

public protocol DataFetcher {
    func fetch(_ target: TargetType, completion: @escaping DataCallback)
    func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback)
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
        
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
        
    }
    public func cancelAllRequests() {
    }
    
    public func cancelRequest(_ target: TargetType) {
    }
}

public class URLSessionDataFetcher<Target: TargetType>: DataFetcher {
    private var webService: Webservice
    private var requests: Set<URLRequest> = Set<URLRequest>()
    
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
                                         queryParameters: target.queryParameters) { (request, response, result) in
                                            switch result {
                                            case let .success(data):
                                                completion(request, response, data, nil)
                                            case let .failure(error):
                                                completion(request, response, nil, error)
                                            }
        }
        
        if let urlRequest = request.request {
            requests.insert(urlRequest)
        }
        //TODO: save request so it can be cancelled
    }
    
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
        
    }
    
    public func cancelRequest(_ target: TargetType) {
    }
    
    public func cancelAllRequests() {
    }
}

public class URLSession2DataFetcher: DataFetcher {
    public var urlSession: URLSession
    public var networkActivity: NetworkActivityProtocol

    private var requests: Set<URLRequest> = Set<URLRequest>()
    
    public init(urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        self.urlSession = urlSession
        self.networkActivity = networkActivity
    }

    public func fetch(_ target: TargetType, completion: @escaping DataCallback) {
    }
    
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
        let task = urlSession.dataTask(with: request, completionHandler: { data, response, error in
            self.networkActivity.decrement()

            completion(request, response, data, .responseError(error ?? NetworkStackError.dataMissing))
        })

        task.resume()

    }
    
    public func cancelRequest(_ target: TargetType) {
    }
    
    public func cancelAllRequests() {
    }
}
