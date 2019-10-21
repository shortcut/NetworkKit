//
//  RequestMiddleware.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

protocol RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>) -> Void)
}
