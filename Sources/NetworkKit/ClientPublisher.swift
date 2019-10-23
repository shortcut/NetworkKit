//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/22/19.
//

import Foundation
import Combine

typealias DataResponse = Response<Data, EmptyErrorResponse>

@available(iOS 13.0, *)
extension Client {

    func request(_ urlRequest: URLRequest) -> AnyPublisher<DataResponse, NetworkStackError> {
        return Future<DataResponse, NetworkStackError> { promise in
            self.request(urlRequest) { (response: DataResponse) in
                promise(.failure(.dataMissing))
            }
        }.eraseToAnyPublisher()
    }
}
