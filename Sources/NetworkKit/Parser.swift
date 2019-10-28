//
//  Parser.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public protocol ParserProtocol {
    func parse<T: Decodable>(data: Data?) -> Result<T, NetworkStackError>
}

public class JSONParser: ParserProtocol {
    let jsonDecoder = JSONDecoder()
    public init(decoder: JSONDecoder = JSONDecoder()) {}

    public func parse<T>(data: Data?) -> Result<T, NetworkStackError> where T: Decodable {
        guard let data = data else {
            return .failure(NetworkStackError.dataMissing)
        }

        return Result { try jsonDecoder.decode(T.self, from: data) }.mapError { error in
            NetworkStackError.parsingError(error)
        }
    }
}
