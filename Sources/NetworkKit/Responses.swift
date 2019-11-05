//
//  Responses.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

public protocol RequestResponses {
    @discardableResult
    func response(_ completion: @escaping ResponseCallback<Data>) -> Self

    @discardableResult
    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self

    @discardableResult
    func responseJSON(options: JSONSerialization.ReadingOptions,
                      completion: @escaping ResponseCallback<Any>) -> Self

    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type,
                                       parser: DecodableParserProtocol?,
                                       completion: @escaping ResponseCallback<T>) -> Self
}

public extension RequestResponses {
    // to provide defaults
    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type = T.self,
                                       parser: DecodableParserProtocol? = nil,
                                       completion: @escaping ResponseCallback<T>) -> Self {
        self.responseDecoded(of: type, parser: parser, completion: completion)
        return self
    }

    @discardableResult
    func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments,
                      completion: @escaping ResponseCallback<Any>) -> Self {
        self.responseJSON(options: options, completion: completion)
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
                                              parser: DecodableParserProtocol? = nil,
                                              completion: @escaping ResponseCallback<T>) -> Self {
        let parser = parser ?? self.defaultParser

        self.addParseOperation(parser: DecodableParser<T>(parser: parser)) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }

    @discardableResult
    public func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments,
                             completion: @escaping ResponseCallback<Any>) -> Self {
        self.addParseOperation(parser: JSONParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }
}
