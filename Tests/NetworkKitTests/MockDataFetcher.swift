//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/22/19.
//

import Foundation
import NetworkKit

//public struct MockDataFetcher: DataFetcher {
//    public func fetchRequest(_ request: URLRequest, completion: @escaping DataCallback) -> TaskIdentifier? {
//        if let data = Resource(name: "getResponse", type: "json").data {
//            completion(nil, nil, data, nil)
//        } else {
//            completion(nil, nil, nil, NetworkError.dataMissing)
//        }
//        
//        return nil
//    }
//    
//    public func cancelRequest(with identifier: TaskIdentifier) {
//    }
//    
//    public func cancelAllRequests() {
//    }
//}
