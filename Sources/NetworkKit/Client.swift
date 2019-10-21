//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

import Foundation

// input a Target
// run request middleware
// make request
// run response middleware
// parse
// return

typealias ClientResponse = (Response<Data, EmptyErrorResponse, NetworkStackError>) -> Void

protocol ClientType {
    func request(_ target: TargetType, completion: @escaping ClientResponse)
    func request(_ urlRequest: URLRequest, completion: @escaping ClientResponse)
    var requestMiddleware: [RequestMiddleware] { get }
    var responseMiddleware: [ResponseMiddleware] { get }
}

extension Response {
    public func mapJSON<SuccessType: Decodable, ErrorType: Decodable>(parser: ParserProtocol = JSONParser(),
                                                                      successSelector: ResponseSuccessSelector = DefaultResponseSuccessSelector(),
                                                                      completion: @escaping (Response<SuccessType, ErrorType, NetworkStackError>) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            var newResponse: Response<SuccessType, ErrorType, NetworkStackError>
            
            if successSelector.isSuccess(self),
            self.error == nil {
                let result = parser.parse(data: self.data) as Result<SuccessType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: result, errorResponse: nil)
            }
            else {
                let errorResult = parser.parse(data: self.data) as Result<ErrorType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: .failure(.errorResponse), errorResponse: try? errorResult.get())
            }
            
            DispatchQueue.main.async {
                completion(newResponse)
            }
        }
    
    }
}

class Client: ClientType {    
    private static var dataFetcher: DataFetcher = URLSession2DataFetcher()

    public var requestMiddleware: [RequestMiddleware] = []
    public var responseMiddleware: [ResponseMiddleware] = []
    
    init() {}
    
    init(dataFetcher: DataFetcher = URLSession2DataFetcher()) {
        Self.dataFetcher = dataFetcher
    }
    
    func request(_ target: TargetType, completion: @escaping ClientResponse) {
        guard let urlRequest = target.asURLRequest()
        else {
            completion(Response(request: nil, response: nil, data: nil, result: .failure(.dataMissing), errorResponse: nil))
            return
        }
        
        request(urlRequest, completion: completion)
    }
        
    func request(_ urlRequest: URLRequest, completion: @escaping ClientResponse) {
        var modifiedRequest = urlRequest
        var middlewareError: Error?

        // walk along the middleware pipeline and let them modify the request
        for middle in requestMiddleware {
            middle.massage(modifiedRequest) { result in
                switch result {
                case let .success(request):
                    modifiedRequest = request
                case let .failure(error):
                    middlewareError = error
                }
            }
        }

        // return early if any middleware errored
        if let error = middlewareError {
            let result = Result<Data, NetworkStackError>.failure(.middlewareError(error))
            DispatchQueue.main.async {
                completion(Response(request: urlRequest, response: nil, data: nil, result: result, errorResponse: nil))
            }
            return
        }
        
        // go get the actual data
        Self.dataFetcher.fetchRequest(modifiedRequest) { (request, response, data, error) in
            let result: Result<Data, NetworkStackError> = (data != nil ? .success(data!) : .failure(.dataMissing))
            let originalResponse = Response<Data, EmptyErrorResponse, NetworkStackError>(request: request, response: response, data: data, result: result, errorResponse: nil)
            
            var modifiedResponse = originalResponse
            var middlewareError: Error?
            
            // walk along the middleware pipeline and let them modify the response
            for middle in self.responseMiddleware {
                middle.massage(modifiedResponse) { (newResponse: Response<Data, EmptyErrorResponse, NetworkStackError>) in
                    modifiedResponse = newResponse
                    if let newError = modifiedResponse.error {
                        middlewareError = newError
                    }
                }
            }
            
            DispatchQueue.main.async {
                if let newError = middlewareError {
                    let newResponse = Response<Data, EmptyErrorResponse, NetworkStackError>(request: modifiedResponse.request, response: modifiedResponse.response, data: modifiedResponse.data, result: .failure(.middlewareError(newError)), errorResponse: nil)
                    completion(newResponse)
                }
                else {
                    completion(modifiedResponse)
                }
            }
        }
    }
    
    private func processRequestMiddleware() {
        //TODO: Refactor into here
        
    }
    
    private func processResponseMiddleware() {
        //TODO: Refactor into here
    }
}
