//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/22/19.
//

import Foundation
import NetworkKit

public struct MockDataFetcher: DataFetcher {
    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) {
        if let data = Resource(name: "getResponse", type: "json").data {
            completion(nil, nil, data, nil)
        }
        else {
            completion(nil, nil, nil, .dataMissing)
        }
    }
    public func cancelAllRequests() {
    }
    
    public func cancelRequest(_ request: URLRequest) {
    }
}
