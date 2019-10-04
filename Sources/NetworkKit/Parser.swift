//
//  Parser.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public protocol ParserProtocol {
    func json<T: Decodable>(data: Data, completion: @escaping ResultDecodableCallback<T>)
}

public class Parser: ParserProtocol {
    let jsonDecoder = JSONDecoder()
    public init() {
        
    }
    
    public func json<T: Decodable>(data: Data, completion: @escaping ResultDecodableCallback<T>) {
        do {
            let result: T = try jsonDecoder.decode(T.self, from: data)
            OperationQueue.main.addOperation {completion(.success(result))}
        }catch {
            OperationQueue.main.addOperation {completion(.failure(.paringError(error)))}
        }
    }
}
