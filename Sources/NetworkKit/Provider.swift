//
//  File 2.swift
//  
//
//  Created by Andre Navarro on 10/14/19.
//

import Foundation

public protocol TargetType {
    static var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var bodyType: HTTPBodyType { get }
    var body: Encodable? { get }
    var queryParameters: QueryParameters? { get }
    var diskFileName: String { get }
}

public class Provider<Target: TargetType> {
    private var dataFetcher: DataFetcher
    
    init(dataFetcher: DataFetcher = URLSessionDataFetcher<Target>()) {
        self.dataFetcher = dataFetcher
    }
    
    public func request<Selector: ResponseTypeSelector>(_ target: Target,
                                                        typeSelector: Selector,
                                                        parser: ParserProtocol = JSONParser(),
                                                        completion: @escaping ResponseCallback<Selector.SuccessType, Selector.ErrorType>) {

        dataFetcher.fetch(target) { (request, response, data, error) in
            // have no data, have error
            guard let data = data else {
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: nil,
                                                                                                     result: .failure(NetworkStackError.dataMissing),
                                                                                                     errorResponse: nil)
                completion(response)
                return
            }
            
            // maybe have data, have undeniable error
            if let error = error {
                let errorResponse = parser.parse(data: data) as Result<Selector.ErrorType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: .failure(NetworkStackError.responseError(error)),
                                                                                                     errorResponse: try? errorResponse.get())
                completion(response)
                return
            }
            
            // let the type selector decide if there is an error
            // TODO:  hmmm this is assuming the fetcher is urlsession
            let responseType = typeSelector.type(for: (response as? HTTPURLResponse)!.statusCode)
            
            switch responseType {
            case is Selector.SuccessType.Type:
                let parseResult = parser.parse(data: data) as Result<Selector.SuccessType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: parseResult,
                                                                                                     errorResponse: nil)
                completion(response)
            case is Selector.ErrorType.Type:
                let errorResponse = parser.parse(data: data) as Result<Selector.ErrorType, NetworkStackError>
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: data,
                                                                                                     result: .failure(.errorResponse),
                                                                                                     errorResponse: try? errorResponse.get())
                completion(response)
            default:
                
                // lol wat, never supposed to get here but ok
                let response = Response<Selector.SuccessType, Selector.ErrorType, NetworkStackError>(request: request,
                                                                                                     response: response,
                                                                                                     data: nil,
                                                                                                     result: .failure(NetworkStackError.dataMissing),
                                                                                                     errorResponse: nil)
                completion(response)
            }
        }
    }
}

public protocol ResponseTypeSelector {
    associatedtype SuccessType: Decodable
    associatedtype ErrorType: Decodable
    
    func type(for statusCode: Int) -> Decodable.Type
}

extension ResponseTypeSelector {
    func type(for statusCode: Int) -> Decodable.Type {
        if statusCode < 400 {
            return SuccessType.self
        }
        else {
            return ErrorType.self
        }
    }
}
