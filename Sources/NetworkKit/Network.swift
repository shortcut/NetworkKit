//
//  Network.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

typealias TaskIdentifier = Int

public protocol NetworkType {
    func request(withBaseURL baseURL: URL,
        path: String,
        method: HTTPMethod,
        bodyType: HTTPBodyType,
        headerValues: HTTPHeaders?,
        body: Encodable?,
        queryParameters query: QueryParameters?) -> Request

    func request(_ url: URL, method: HTTPMethod) -> Request
    func request(_ target: TargetType) -> Request

    func request(_ urlRequest: URLRequest?) -> Request
}

extension NetworkType {
    public func request(withBaseURL baseURL: URL,
        path: String,
        method: HTTPMethod,
        bodyType: HTTPBodyType = .none,
        headerValues: HTTPHeaders? = nil,
        body: Encodable? = nil,
        queryParameters query: QueryParameters? = nil) -> Request {

        return request(URLRequest(baseURL: baseURL,
                                  path: path,
                                  httpMethod: method,
                                  headerValues: headerValues,
                                  additionalHeaderValues: nil,
                                  queryParameters: query,
                                  bodyType: bodyType,
                                  body: body))
    }

    public func request(_ target: TargetType) -> Request {
        return request(target.asURLRequest())
    }

    public func request(_ url: URL, method: HTTPMethod = .get) -> Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.value

        return request(urlRequest)
    }
}

public class MockNetwork: NetworkType {
    public func request(_ urlRequest: URLRequest?) -> Request {
        return DiskRequest(urlRequest: urlRequest)
    }
}

public class Network: NSObject, NetworkType {
    var sessionDelegate: NetworkSessionDelegate?
    var urlSession: URLSession?
    var cacheProvider: CacheProvider

    deinit {
        urlSession?.invalidateAndCancel()
        sessionDelegate = nil
        urlSession = nil
    }

    public init(urlSessionConfiguration: URLSessionConfiguration = .default, cacheProvider: CacheProvider = NSCacheProvider()) {
        self.cacheProvider = cacheProvider
        self.sessionDelegate = NetworkSessionDelegate()
        self.urlSession = URLSession(configuration: urlSessionConfiguration, delegate: self.sessionDelegate, delegateQueue: nil)
    }

    public func request(_ urlRequest: URLRequest?) -> Request {
        let ourRequest = URLSessionDataRequest(urlSession: urlSession!,
                                               urlRequest: urlRequest,
                                               cacheProvider: cacheProvider)

        if let taskId = ourRequest.task?.taskIdentifier {
            self.sessionDelegate?.tasks[taskId] = ourRequest
        }
        return ourRequest
    }
}

class NetworkSessionDelegate: NSObject, URLSessionDataDelegate {
    var tasks = [TaskIdentifier: URLSessionDataRequest]()

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let request = tasks[task.taskIdentifier] {
            request.urlSession(session, task: task, didCompleteWithError: error)
            tasks[task.taskIdentifier] = nil
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let request = tasks[dataTask.taskIdentifier] {
            request.urlSession(session, dataTask: dataTask, didReceive: data)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let request = tasks[dataTask.taskIdentifier] {
            request.urlSession(session, dataTask: dataTask, didReceive: response, completionHandler: completionHandler)
            completionHandler(.allow)
        }
    }
}
