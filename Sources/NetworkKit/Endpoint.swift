//
//  Endpoint.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import UIKit

public enum HTTPMethod: String {
    case get
    case post
    case put
    case delete
    
    var value: String {
        return self.rawValue.uppercased()
    }
}

public enum NetworkStackError: Error {
    case requestIsMissing
    case paringError(Error)
    case invalidURL
    case responseError(Error)
    case dataMissing
    case responseMissing
}

public typealias HTTPHeaders = [String: String]
public typealias ResultDecodableCallback<T> = (Result<T, NetworkStackError>) -> Void
public typealias ResultDataCallback = (Result<Data, NetworkStackError>) -> Void
public typealias ResultStatusCodeCallBack = (Result<Int, NetworkStackError>) -> Void
public typealias QueryParameters = [String : String]
public typealias TaskCallback = (Data?, URLResponse?, Error?) -> Void

public enum ResponseType {
    
    case statusCode
    case data
    case codable
}

public enum HTTPBodyType{
    case json
    case formEncoded(parameters: [String: String])
    case none
}
