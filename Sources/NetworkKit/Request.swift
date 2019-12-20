//
//  Request.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

public typealias ResponseCallback<SuccessType> = (Response<SuccessType>) -> Void

public protocol RequestAdapter {
    func adapt(_ urlRequest: URLRequest) -> URLRequest
}

public protocol Request: RequestResponses {
    /// the URLRequest that was sent out
    var urlRequest: URLRequest? { get }

    /// the URLResponse returned. could be a HTTPURLResponse if using URLSessionDataRequest
    var response: URLResponse? { get }

    /// the final collection of data returned
    var data: Data? { get }

    /// if an error was encountered, this will have the error
    var error: NetworkError? { get }

    /// allows the URLRequest to be adapted before transport
    var adapters: [RequestAdapter] { get }
    func withAdapter(_ adapter: RequestAdapter) -> Self

    /// validates using the default response validator (checking if status code is 200...299
    func validate() -> Self

    /// validates with the given ResponseValidator
    func validate(with validator: ResponseValidator) -> Self

    /// validates with the given block
    func validate(_ successBlock: @escaping ValidationBlock) -> Self

    /// cancels the request
    func cancel()
}
