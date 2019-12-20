//
//  Validation.swift
//  
//
//  Created by Andre Navarro on 12/19/19.
//

import Foundation

public typealias ValidationBlock = (Data?, URLResponse?, Error?) -> Bool

public protocol ResponseValidator {
    func validate(data: Data?, urlResponse: URLResponse?, error: Error?) -> Bool
}

/// for use with mocks or tests that want to fail validation
struct FailValidator: ResponseValidator {
    func validate(data: Data?, urlResponse: URLResponse?, error: Error?) -> Bool {
        false
    }
}

/// most common validation, checking status code between 200 and 299
struct DefaultResponseValidator: ResponseValidator {
    fileprivate var acceptableStatusCodes: Range<Int> { return 200..<300 }

    func validate(data: Data?, urlResponse: URLResponse?, error: Error?) -> Bool {
        if let response = urlResponse as? HTTPURLResponse {
            return acceptableStatusCodes.contains(response.statusCode)
        }

        return true
    }
}

extension URLSessionDataRequest {
    public func validate(with validator: ResponseValidator) -> Self {
        afterRequestQueue.addOperation {
            if !validator.validate(data: self.data, urlResponse: self.response, error: self.error) {
                self.error = NetworkError.validateError
            }
        }

        return self
    }

    public func validate(_ successBlock: @escaping ValidationBlock) -> Self {
        afterRequestQueue.addOperation {
            if !successBlock(self.data, self.response, self.error) {
                self.error = NetworkError.validateError
            }
        }

        return self
    }

    public func validate() -> Self {
        afterRequestQueue.addOperation {
            if !DefaultResponseValidator().validate(data: self.data, urlResponse: self.response, error: self.error) {
                self.error = NetworkError.validateError
            }
        }

        return self
    }
}
