//
//  RemoteImage.swift
//  
//
//  Created by Andre Navarro on 10/16/19.
//

import Foundation
import UIKit

extension Webservice {

    @discardableResult
    public func requestImage(withPath path: String,
                             method: HTTPMethod,
                             bodyType: HTTPBodyType = .none,
                             body: Encodable? = nil,
                             queryParameters query: QueryParameters? = nil,
                             completion: @escaping ResultRequestCallback<UIImage>) -> Request {

        return requestData(withPath: path,
                           method: method,
                           bodyType: bodyType,
                           body: body,
                           queryParameters: query) { (request, urlResponse, result: Result<Data, NetworkStackError>) in
                        
            switch result {
            case let .success(data):
                DispatchQueue.global(qos: .background).async {
                    guard let image = UIImage.init(data: data) else {
                        OperationQueue.main.addOperation {
                            completion(Response<UIImage, NetworkStackError>(request: request,
                                                                            response: urlResponse,
                                                                            data: data,
                                                                            result: .failure(NetworkStackError.dataMissing)))
                        }
                        return
                    }
                    
                    OperationQueue.main.addOperation {
                        completion(Response<UIImage, NetworkStackError>(request: request,
                                                                        response: urlResponse,
                                                                        data: data,
                                                                        result: .success(image)))
                    }
                }
            case let .failure(error):
                OperationQueue.main.addOperation {
                    completion(Response<UIImage, NetworkStackError>(request: request,
                                                                    response: urlResponse,
                                                                    data: nil,
                                                                    result: .failure(error)))
                }
            }
        }
    }
    
}
