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
    func cancelRequest(_ target: TargetType)
}

public struct DiskDataFetcher: DataFetcher {
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
//        if let url = Bundle.main.url(forResource: target.diskFileName, withExtension: nil),
//            let data = try? Data(contentsOf: url) {
//            completion(nil, nil, data, nil)
//        }
//        else {
//            completion(nil, nil, nil, .dataMissing)
//        }
    }
    public func cancelAllRequests() {
    }
    
    public func cancelRequest(_ target: TargetType) {
    }
}

public class URLSessionDataFetcher: DataFetcher {
    public var urlSession: URLSession
    public var networkActivity: NetworkActivityProtocol

    private var requests: Set<URLRequest> = Set<URLRequest>()
    
    public init(urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        self.urlSession = urlSession
        self.networkActivity = networkActivity
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
