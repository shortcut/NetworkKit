//
//  URLSessionDataRequest.swift
//  
//
//  Created by Andre Navarro on 12/20/19.
//

import Foundation

/// main implementation of a Request that uses URLSession
/// best to be used as part of a Network
public class URLSessionDataRequest: NSObject, Request {
    internal let queue = DispatchQueue(label: "no.shortcut.NetworkKit.Requests",
                                       qos: .background,
                                       attributes: .concurrent)
    internal var afterRequestQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true
        return operationQueue
    }()

    internal let defaultParser: DecodableParserProtocol
    public var urlRequest: URLRequest?
    public let urlSession: URLSession
    public var response: URLResponse?

    internal var task: URLSessionTask?
    internal var taskCreation: ((URLSessionTask) -> Void)?

    private var receivedData: Data? = Data()
    public var data: Data?
    public var error: NetworkError?

    public var adapters = [RequestAdapter]()

    internal var isCancelled = false

    var cacheProvider: CacheProvider
    var cachedItem: CacheItem?

    public init(urlSession: URLSession,
                urlRequest: URLRequest?,
                cacheProvider: CacheProvider,
                defaultParser: DecodableParserProtocol) {
        self.cacheProvider = cacheProvider
        self.urlSession = urlSession
        self.urlRequest = urlRequest
        self.defaultParser = defaultParser
        super.init()
    }

    internal func prepareTask() {
        guard var urlRequest = urlRequest else {
            self.error = NetworkError.invalidURL
            return
        }

        for adapter in adapters {
            urlRequest = adapter.adapt(urlRequest)
        }

        self.urlRequest = urlRequest
    }

    public func withAdapter(_ adapter: RequestAdapter) -> Self {
        adapters.append(adapter)
        return self
    }

    public func cancel() {
        isCancelled = true
        task?.cancel()
    }

    func checkCache() -> CacheItem? {
        // swiftlint:disable:next todo
        // TODO: need to check cachePolicy in a better way, maybe have our own enum
        if let urlRequest = self.urlRequest,
            let cacheItem = self.cacheProvider.getCache(for: urlRequest),
            urlRequest.cachePolicy == .returnCacheDataElseLoad {
            return cacheItem
        }

        return nil
    }

    internal func addParseOperation<Parser: ResponseParser>(parser: Parser,
                                                            block: @escaping ResponseCallback<Parser.ParsedObject>) {

        // check if we have a cache item and return early
        if let cachedItem = self.cachedItem,
            let cachedObject = cachedItem.object as? Parser.ParsedObject {

            let result = Result<Parser.ParsedObject, NetworkError>.success(cachedObject)
            block(self.responseWithResult(result))
            return
        }

        // no cache, so parse whatever network request comes in
        afterRequestQueue.addOperation {
            guard self.urlRequest != nil else {
                self.error = NetworkError.invalidURL
                return
            }

            if let error = self.error {
                let result = Result<Parser.ParsedObject, NetworkError>.failure(error)
                block(self.responseWithResult(result))
                return
            }

            // finally try to parse
            let result = self.parseResponse(data: self.data, parser: parser).mapError { error in
                NetworkError.parsingError(error)
            }
            block(self.responseWithResult(result))

            // save to cache
            self.queue.async {
                if let urlRequest = self.urlRequest,
                    case let .success(object) = result {
                    self.cacheProvider.setCache(for: urlRequest, data: self.data, object: object)
                }
            }
        }
    }

    internal func parseResponse<Parser: ResponseParser>(data: Data?,
                                                        parser: Parser) -> Result<Parser.ParsedObject, ParserError> {
        guard let data = data else {
            return .failure(.dataMissing)
        }

        return parser.parse(data: data, type: Parser.ParsedObject.self)
    }

    internal func startTask() {
        prepareTask()

        // try our cache, return early if we gots it
        if let cacheItem = checkCache() {
            self.cachedItem = cacheItem
            finish()
            return
        }

        guard let urlRequest = urlRequest else {
            self.error = NetworkError.invalidURL
            return
        }

        let task = urlSession.dataTask(with: urlRequest)
        self.task = task
        taskCreation?(task)
        taskCreation = nil

        // swiftlint:disable:next todo
        // TODO: better state management
        if task.state != .running,
            task.state != .canceling,
            task.state != .completed,
            isCancelled == false {

            // resume iz expensive, let's do it in the background
            urlSession.delegateQueue.addOperation {
                task.resume()
            }
        }
    }

    internal func finish() {
        // request or cache lookup is finished, let the dogs out and validate, parse, etc
        afterRequestQueue.isSuspended = false
    }

    internal func responseWithResult<ParsedObject>(
        _ result: Result<ParsedObject, NetworkError>) -> Response<ParsedObject> {
        var response = Response(result)
        response.data = self.data
        response.response = self.response
        response.request = self.urlRequest
        response.responseIsFromCacheProvider = self.cachedItem != nil

        return response
    }
}

public extension URLSessionDataRequest {
    var statusCode: Int? {
        guard let response = self.response as? HTTPURLResponse else { return nil }
        return response.statusCode
    }

    func localizedStringForStatusCode() -> String? {
        guard let statusCode = self.statusCode else { return nil }
        return HTTPURLResponse.localizedString(forStatusCode: statusCode)
    }

    var allHeaderFields: [AnyHashable: Any]? {
        guard let response = self.response as? HTTPURLResponse else { return nil }
        return response.allHeaderFields
    }
}

extension URLSessionDataRequest: URLSessionDataDelegate {
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.receivedData?.append(data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.error = .responseError(error)
        }

        if let receivedData = self.receivedData,
            receivedData.count > 0 {
            self.data = self.receivedData
            self.receivedData = nil
        }
        finish()
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceive response: URLResponse,
                           completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            self.error = .responseError(error)
        }

        finish()
    }
}
