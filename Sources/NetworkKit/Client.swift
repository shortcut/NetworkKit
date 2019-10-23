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
// parse if client wants
// return

public typealias ClientResponse = (Response<Data, EmptyErrorResponse>) -> Void

protocol ClientType {
    func request(_ target: TargetType, completion: @escaping ClientResponse)
    func request(_ urlRequest: URLRequest, completion: @escaping ClientResponse)
    var requestMiddleware: [RequestMiddleware] { get }
    var responseMiddleware: [ResponseMiddleware] { get }
    
    // TODO: cancel
}

extension Response {
    public func mapDecodable<SuccessType: Decodable, ErrorResponseType: Decodable>(parser: ParserProtocol = JSONParser(),
                                                                      successSelector: ResponseSuccessSelector = DefaultResponseSuccessSelector(),
                                                                      completion: @escaping (Response<SuccessType, ErrorResponseType>) -> Void) {
        
        DispatchQueue.global(qos: .background).async {
            var newResponse: Response<SuccessType, ErrorResponseType>
            
            if successSelector.isSuccess(self) {
                let result = parser.parse(data: self.data) as Result<SuccessType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: result, errorResponse: nil)
            }
            else {
                let errorResult = parser.parse(data: self.data) as Result<ErrorResponseType, NetworkStackError>
                newResponse = .init(request: self.request, response: self.response, data: self.data, result: .failure(.errorResponse), errorResponse: try? errorResult.get())
            }
            
            DispatchQueue.main.async {
                completion(newResponse)
            }
        }
    
    }
}

public protocol RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>, Response<Data, EmptyErrorResponse>?) -> Void)
}

public protocol ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E>, completion: @escaping (Response<T, E>) -> Void)
}

public class Client: ClientType {
    public static var shared: Client = Client()
    private var dataFetcher: DataFetcher

    public var requestMiddleware: [RequestMiddleware] = []
    public var responseMiddleware: [ResponseMiddleware] = []
        
    public init(dataFetcher: DataFetcher = URLSessionDataFetcher.shared) {
        self.dataFetcher = dataFetcher
    }
    
    public func request(_ target: TargetType, completion: @escaping ClientResponse) {
        guard let urlRequest = target.asURLRequest()
        else {
            completion(Response(request: nil, response: nil, data: nil, result: .failure(.invalidURL), errorResponse: nil))
            return
        }
        
        request(urlRequest, completion: completion)
    }
        
    public func cancel(_ request: URLRequest) {
        dataFetcher.cancelRequest(request)
    }
    
    public func request(_ urlRequest: URLRequest, completion: @escaping ClientResponse) {
        var modifiedRequest = urlRequest
        var middlewareError: Error?
      
        // walk along the middleware pipeline and let them modify the request
        for middle in requestMiddleware {
            middle.massage(modifiedRequest) { result, response in
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
        dataFetcher.fetchRequest(modifiedRequest) { (request, response, data, error) in
            let result: Result<Data, NetworkStackError> = (data != nil ? .success(data!) : .failure(.dataMissing))
            let originalResponse = Response<Data, EmptyErrorResponse>(request: request, response: response, data: data, result: result, errorResponse: nil)
            
            var modifiedResponse = originalResponse
            var middlewareError: Error?
            
            // walk along the middleware pipeline and let them modify the response
            for middle in self.responseMiddleware {
                middle.massage(modifiedResponse) { (newResponse: Response<Data, EmptyErrorResponse>) in
                    modifiedResponse = newResponse
                    if case let .failure(newError) = modifiedResponse.result {
                        middlewareError = newError
                    }
                }
            }
            
            // finally complete with the slutty Response touched by everyone
            DispatchQueue.main.async {
                if let newError = middlewareError {
                    let newResponse = Response<Data, EmptyErrorResponse>(request: modifiedResponse.request, response: modifiedResponse.response, data: modifiedResponse.data, result: .failure(.middlewareError(newError)), errorResponse: nil)
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


public class CachedRequestMiddleware: RequestMiddleware {
  public func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>, Response<Data, EmptyErrorResponse>?) -> Void) {


        var possibleResponse: Response<Data, EmptyErrorResponse>?
        

        if let data = URLCache.shared.cachedResponse(for: request)?.data {
            possibleResponse = .init(request: request, response: nil, data: data, result: .success(data), errorResponse: nil)
        }

        
        completion(.success(request), possibleResponse)
    }
}
