//
//  Request.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

public typealias ResponseCallback<SuccessType> = (Response<SuccessType>) -> Void

public protocol Request: RequestResponses {
    var urlRequest: URLRequest? { get }
    var response: URLResponse? { get }
    var data: Data? { get }
    var error: Error? { get }
    var isSuccess: Bool { get }

    func validate() -> Self
    func cancel()
}

public class URLSessionDataRequest: NSObject, Request {
    let queue = DispatchQueue(label: "no.shortcut.NetworkKit.Requests", qos: .background, attributes: .concurrent)
    private var operationQueue = OperationQueue()

    private var workItems = [DispatchWorkItem]()

    let defaultParser: DecodableParserProtocol
    public let urlRequest: URLRequest?
    public let urlSession: URLSession

    var task: URLSessionTask?
    private var receivedData: Data? = Data()
    public var data: Data?
    public var error: Error?

    public var response: URLResponse?
    public var isSuccess: Bool = true
    private var shouldValidate: Bool = false

    private var isCancelled = false

    var cacheProvider: CacheProvider

    deinit {
    }

    public init(urlSession: URLSession,
                urlRequest: URLRequest?,
                cacheProvider: CacheProvider,
                defaultParser: DecodableParserProtocol) {
        self.cacheProvider = cacheProvider
        self.urlSession = urlSession
        self.urlRequest = urlRequest
        self.defaultParser = defaultParser
        super.init()

        self.prepareTask()
    }

    private func prepareTask() {
        operationQueue.isSuspended = true

        guard let urlRequest = urlRequest else {
            return
        }

        task = urlSession.dataTask(with: urlRequest)
    }

    public func cancel() {
        isCancelled = true
        task?.cancel()
    }

    func completeWithCache<Parser: ResponseParser>(parser: Parser,
                                                   block: @escaping ResponseCallback<Parser.ParsedObject>) -> Bool {
        // check cache and return early
        // swiftlint:disable:next todo
        // TODO: need to check cachePolicy better
        if let urlRequest = self.urlRequest,
            let cacheItem = self.cacheProvider.getCache(for: urlRequest),
            urlRequest.cachePolicy == .returnCacheDataElseLoad,
            let cacheObject = cacheItem.object as? Parser.ParsedObject {
            let result = .success(cacheObject) as Result<Parser.ParsedObject, NetworkError>

            OperationQueue.main.addOperation {
                block(self.responseWithResult(result))
            }
            return true
        }

        return false
    }

    func addParseOperation<Parser: ResponseParser>(parser: Parser,
                                                   block: @escaping ResponseCallback<Parser.ParsedObject>) {

        guard let urlRequest = urlRequest else {
            block(responseWithResult(.failure(.invalidURL)))
            return
        }

        // try our cache, return early if we gots it
        queue.sync {
            if completeWithCache(parser: parser, block: block) {
                return
            }
        }

        // no cache, so start network requests if not already started
        startTask()

        operationQueue.addOperation {

            // check if cancelled (not sure this ever does anything actually)
            if self.error == nil,
                self.isCancelled == true ||
                    self.task?.state == .canceling {
                block(self.responseWithResult(.failure(.cancelled)))
                print("cancelled \(self.debugDescription)")
                return
            }

            // URLSession network error? always fail
            if let error = self.error {
                print("error \(error)")
                block(self.responseWithResult(.failure(.responseError(error))))
                return
            }

            // validation error? fail.
            if self.shouldValidate && !self.isSuccess {
                block(self.responseWithResult(.failure(NetworkError.validateError)))
                return
            }

            // finally try to parse
            let result = self.parseResponse(urlRequest: urlRequest, data: self.data, parser: parser).mapError { error in
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

    public func validate() -> Self {
        shouldValidate = true
        return self
    }

    private func parseResponse<Parser: ResponseParser>(urlRequest: URLRequest,
                                                       data: Data?,
                                                       parser: Parser) -> Result<Parser.ParsedObject, ParserError> {
        guard let data = data else {
            return .failure(.dataMissing)
        }

        return parser.parse(data: data, type: Parser.ParsedObject.self)
    }

    private func startTask() {
        // swiftlint:disable:next todo
        // TODO: better state management
        if let task = task,
            task.state != .running,
            task.state != .canceling,
            task.state != .completed,
            isCancelled == false {

            task.resume()
        }
    }

    private func finish() {
        // swiftlint:disable:next todo
        // TODO: custom validation
        if let statusCode = statusCode {
            isSuccess = (statusCode < 400)
        }

        operationQueue.isSuspended = false
    }

    private func responseWithResult<ParsedObject>(
        _ result: Result<ParsedObject, NetworkError>) -> Response<ParsedObject> {
        var response = Response(result)
        response.data = self.data
        response.response = self.response
        response.request = self.urlRequest

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
        self.error = error
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
        self.error = error
        finish()
    }
}
