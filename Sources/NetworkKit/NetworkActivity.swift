//
//  NetworkActivity.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import UIKit

public protocol NetworkActivityProtocol {
    func increment()
    func decrement()
}

public class NetworkActivity: NetworkActivityProtocol {
    public init() {
        
    }
    private var acitivityCount = 0 {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = (acitivityCount > 0)
        }
    }
    
    public func increment() {
        OperationQueue.main.addOperation { self.acitivityCount += 1 }
    }
    
    public func decrement() {
        OperationQueue.main.addOperation { self.acitivityCount -= 1 }
    }
}

