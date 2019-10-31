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
    private var operationQueue = OperationQueue()
    private var defaultParser: ParserProtocol = JSONParser()

    public let urlRequest: URLRequest?
    public let urlSession: URLSession

    var task: URLSessionTask?
    public var data: Data?
    public var error: Error?

    public var response: URLResponse?
    public var isSuccess: Bool = true
    private var shouldValidate: Bool = false

    var cacheProvider: CacheProvider

    public init(urlSession: URLSession, urlRequest: URLRequest?, cacheProvider: CacheProvider) {
        self.cacheProvider = cacheProvider
        self.urlSession = urlSession
        self.urlRequest = urlRequest
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
        task?.cancel()
    }

    func addParseOperation<Parser: ResponseParser>(parser: Parser,
                                                   block: @escaping ResponseCallback<Parser.ParsedObject>) {
        guard let urlRequest = urlRequest else {
            block(responseWithResult(.failure(.invalidURL)))
            return
        }

        startTask()

        operationQueue.addOperation {
            var result: Result<Parser.ParsedObject, NetworkError>

            if let error = self.error {
                result = .failure(.responseError(error))
            } else {
                if self.shouldValidate && !self.isSuccess {
                    result = .failure(NetworkError.validateError)
                } else {
                    result = self.parseResponse(urlRequest: urlRequest, data: self.data, parser: parser).mapError { error in
                        NetworkError.parsingError(error)
                    }
                }
            }

            block(self.responseWithResult(result))
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
        // TODO: better state management
        if let state = task?.state,
            state != .running,
            state != .canceling,
            state != .completed,
            let task = task {
            task.resume()
        }
    }

    private func finish() {
        // TODO: custom validation
        if let statusCode = statusCode {
            isSuccess = (statusCode < 400)
        }

        operationQueue.isSuspended = false

        task = nil
    }

    private func responseWithResult<ParsedObject>(_ result: Result<ParsedObject, NetworkError>) -> Response<ParsedObject> {
        var response = Response(result)
        response.data = self.data
        response.response = self.response
        response.request = self.urlRequest

        return response
    }
}

public protocol RequestResponses {
    @discardableResult
    func response(_ completion: @escaping ResponseCallback<Data>) -> Self

    @discardableResult
    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self

    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type,
                                       parser: ParserProtocol?,
                                       completion: @escaping ResponseCallback<T>) -> Self
}

public extension RequestResponses {
    // to provide defaults
    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type = T.self,
                                       parser: ParserProtocol? = nil,
                                       completion: @escaping ResponseCallback<T>) -> Self {
        self.responseDecoded(of: type, parser: parser, completion: completion)
        return self
    }
}

extension URLSessionDataRequest: RequestResponses {
    @discardableResult
    public func response(_ completion: @escaping ResponseCallback<Data>) -> Self {
        addParseOperation(parser: DataParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }

    @discardableResult
    public func responseString(_ completion: @escaping ResponseCallback<String>) -> Self {
        addParseOperation(parser: StringParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }

    @discardableResult
    public func responseDecoded<T: Decodable>(of type: T.Type = T.self,
                                       parser: ParserProtocol? = nil,
                                       completion: @escaping ResponseCallback<T>) -> Self {
        let parser = parser ?? self.defaultParser

        // check cache and return early
        // TODO: need to check cachePolicy
        if let urlRequest = urlRequest,
            let cacheItem = cacheProvider.getCache(for: urlRequest),
            urlRequest.cachePolicy == .returnCacheDataDontLoad,
            let cacheObject = cacheItem.object as? T {
            let result = .success(cacheObject) as Result<T, NetworkError>

            OperationQueue.main.addOperation {
                completion(self.responseWithResult(result))
            }
            return self
        }

        addParseOperation(parser: DecodableParser<T>(parser: parser)) { response in

            if let urlRequest = self.urlRequest,
                case let .success(object) = response.result {
                self.cacheProvider.setCache(for: urlRequest, data: self.data, object: object)
            }

            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
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
        self.data = data
    }
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        self.error = error
        finish()
    }
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.response = response as? HTTPURLResponse
    }
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        self.error = error
        finish()
    }
}
