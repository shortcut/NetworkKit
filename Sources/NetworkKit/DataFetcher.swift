//
//  DataFetcher.swift
//  
//
//  Created by Andre Navarro on 10/17/19.
//

import Foundation

public protocol DataFetcher {
    func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) -> TaskIdentifier?
    func cancelRequest(with identifier: TaskIdentifier)
    func cancelAllRequests()
}

public struct DiskDataFetcher: DataFetcher {
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) -> TaskIdentifier? {
        return nil
    }
    public func cancelRequest(with identifier: TaskIdentifier) {
    }
    public func cancelAllRequests() {
    }
}

public class URLSessionDataFetcher: DataFetcher {
    public static var shared: URLSessionDataFetcher = URLSessionDataFetcher()

    public var urlSession: URLSession
    public var networkActivity: NetworkActivityProtocol

    public init(urlSession: URLSession = URLSession(configuration: .default),
                networkActivity: NetworkActivityProtocol = NetworkActivity()) {
        self.urlSession = urlSession
        self.networkActivity = networkActivity
    }

    deinit {
      urlSession.invalidateAndCancel()
    }

    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) -> TaskIdentifier? {
        let task = urlSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in
            self?.networkActivity.decrement()

            var possibleError: NetworkStackError?
            if let error = error {
                possibleError = .responseError(error)
            }

            completion(request, response, data, possibleError)
        })

        task.resume()

        return task.taskIdentifier
    }

    public func cancelRequest(with identifier: TaskIdentifier) {
        self.urlSession.getAllTasks { $0.filter { $0.taskIdentifier == identifier }.forEach { $0.cancel() }
        }
    }

    public func cancelAllRequests() {
        self.urlSession.getAllTasks { $0.forEach { $0.cancel() } }
    }
}
