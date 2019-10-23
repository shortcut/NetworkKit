//
//  DataFetcher.swift
//  
//
//  Created by Andre Navarro on 10/17/19.
//

import Foundation

public protocol DataFetcher {
    func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback)
    func cancelAllRequests()
    func cancelRequest(_ request: URLRequest)
}

public struct DiskDataFetcher: DataFetcher {
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
    }
    public func cancelAllRequests() {
    }
    
    public func cancelRequest(_ request: URLRequest) {
    }
}

public class URLSessionDataFetcher: DataFetcher {
    public static var shared: URLSessionDataFetcher = URLSessionDataFetcher()
    
    public var urlSession: URLSession
    public var networkActivity: NetworkActivityProtocol

    private var requests: Set<URLRequest> = Set<URLRequest>()
    private var tasks: [URLRequest: URLSessionTask] = [URLRequest: URLSessionTask]()
    
    private var tasksDispatchQueue: DispatchQueue = .global(qos: .background)
  
    public init(urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        self.urlSession = urlSession
        self.networkActivity = networkActivity
    }

    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
        let task = urlSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            self?.networkActivity.decrement()

            completion(request, response, data, .responseError(error ?? NetworkStackError.dataMissing))
        })

        task.resume()
    }
    
    public func cancelRequest(_ request: URLRequest) {
        // TODO:
    }
    
    public func cancelAllRequests() {
        // TODO:
    }
}
