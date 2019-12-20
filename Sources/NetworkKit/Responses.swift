//
//  Responses.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

public protocol RequestResponses {
    /// returns the raw data from the request
    @discardableResult
    func response(_ completion: @escaping ResponseCallback<Data>) -> Self

    /// returns the response back as a string
    @discardableResult
    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self

    /// returns the JSON dictionary from the response
    @discardableResult
    func responseJSON(options: JSONSerialization.ReadingOptions,
                      completion: @escaping ResponseCallback<Any>) -> Self

    /// returns a decoded object of the specified type with the given parser
    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type,
                                       parser: DecodableParserProtocol?,
                                       completion: @escaping ResponseCallback<T>) -> Self

    /// returns a decoded object of the specified type with the given parser
    /// or... a decoded error object in the network error if the response failed validation
    ///
    /// for example... if the server returns a json error that you want to parse, you'll find the passed errorType in
    /// NetworkError.responseError(Decodable?)
    @discardableResult
    func responseDecoded<T: Decodable, E: Decodable>(of type: T.Type,
                                                     errorType: E.Type,
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
    func responseDecoded<T: Decodable, E: Decodable>(of type: T.Type = T.self,
                                                     errorType: E.Type = E.self,
                                                     parser: DecodableParserProtocol? = nil,
                                                     completion: @escaping ResponseCallback<T>) -> Self {
        self.responseDecoded(of: type, errorType: errorType, parser: parser, completion: completion)
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
        startTask()

        addParseOperation(parser: DataParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }

    @discardableResult
    public func responseString(_ completion: @escaping ResponseCallback<String>) -> Self {
        startTask()

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
        startTask()

        let parser = parser ?? self.defaultParser

        self.addParseOperation(parser: DecodableParser<T>(parser: parser)) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }

    @discardableResult
    public func responseDecoded<T: Decodable, E: Decodable>(of type: T.Type = T.self,
                                                            errorType: E.Type = E.self,
                                                            parser: DecodableParserProtocol? = nil,
                                                            completion: @escaping ResponseCallback<T>) -> Self {
        startTask()

        let parser = parser ?? self.defaultParser

        afterRequestQueue.addOperation {
            if self.error == nil {
                self.addParseOperation(parser: DecodableParser<T>(parser: parser)) { response in
                    OperationQueue.main.addOperation {
                        completion(response)
                    }
                }
            } else if let error = self.error,
                case .validateError = error {
                self.afterRequestQueue.addOperation {
                    let result: Result<E, ParserError> = parser.parse(data: self.data)
                    var networkResult: Result<T, NetworkError>
                    if let errorObject = try? result.get() {
                        networkResult = .failure(.errorResponse(errorObject))
                    } else {
                        networkResult = .failure(error)
                    }

                    OperationQueue.main.addOperation {
                        completion(self.responseWithResult(networkResult))
                    }
                }
            }
        }

        return self
    }

    @discardableResult
    public func responseJSON(options: JSONSerialization.ReadingOptions = .allowFragments,
                             completion: @escaping ResponseCallback<Any>) -> Self {
        startTask()

        self.addParseOperation(parser: JSONParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }
}
