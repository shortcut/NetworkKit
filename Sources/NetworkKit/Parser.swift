//
//  Parser.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public enum ParserError: Error {
    case dataMissing
    case internalParserError(Error)
}

protocol ResponseParser {
    associatedtype ParsedObject
    func parse(data: Data, type: ParsedObject.Type) -> Result<ParsedObject, ParserError>
}

struct StringParser: ResponseParser {
    typealias ParsedObject = String
    func parse(data: Data, type: ParsedObject.Type) -> Result<ParsedObject, ParserError> {
        guard let string = String(data: data, encoding: .utf8) else {
            return .failure(.dataMissing)
        }

        return .success(string)
    }
}

struct DataParser: ResponseParser {
    typealias ParsedObject = Data
    func parse(data: Data, type: ParsedObject.Type) -> Result<ParsedObject, ParserError> {
        return .success(data)
    }
}

struct DecodableParser<T: Decodable>: ResponseParser {
    typealias ParsedObject = T
    let parser: ParserProtocol

    init(parser: ParserProtocol) {
        self.parser = parser
    }

    func parse(data: Data, type: ParsedObject.Type) -> Result<ParsedObject, ParserError> {
        let result = self.parser.parse(data: data) as Result<T, ParserError>
        return result.mapError { error in
            ParserError.internalParserError(error)
        }
    }
}

public protocol ParserProtocol {
    func parse<T: Decodable>(data: Data?) -> Result<T, ParserError>
}

public class JSONParser: ParserProtocol {
    let jsonDecoder = JSONDecoder()
    public init(decoder: JSONDecoder = JSONDecoder()) {}

    public func parse<T>(data: Data?) -> Result<T, ParserError> where T: Decodable {
        guard let data = data else {
            return .failure(ParserError.dataMissing)
        }

        return Result { try jsonDecoder.decode(T.self, from: data) }.mapError { error in
            ParserError.internalParserError(error)
        }
    }
}
