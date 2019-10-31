//
//  DiskRequest.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

class DiskRequest: NSObject, Request {

    var isSuccess: Bool = true
    var data: Data?
    var error: Error?

    func validate() -> Self {
        return self
    }

    func response(_ completion: @escaping ResponseCallback<Data>) -> Self {
        completion(Response(.failure(.dataMissing)))
        return self
    }

    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self {
        completion(Response(.failure(.dataMissing)))
        return self
    }

    func responseDecoded<T>(of type: T.Type, parser: ParserProtocol?, completion: @escaping ResponseCallback<T>) -> Self where T : Decodable {
        completion(Response(.failure(.dataMissing)))
        return self
    }

    func cancel() {
    }

    var urlRequest: URLRequest?
    var response: URLResponse?

    init(urlRequest: URLRequest?) {
        self.urlRequest = urlRequest
    }
}
