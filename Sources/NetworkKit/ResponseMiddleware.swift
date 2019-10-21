//
//  ResponseMiddleware.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

protocol ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E, NetworkStackError>, completion: @escaping (Response<T, E, NetworkStackError>) -> Void)
}
