//
//  QueryParameters.swift
//  
//
//  Created by Andre Navarro on 10/22/19.
//

import Foundation

public struct QueryParameters {
    /// Defines how arrays should be formatted within a query string
    public enum ArrayFormat {
        /// param=value1&param=value2&param=value3
        case duplicatedKeys
        /// param[]=value1&param[]=value2&param[]=value3
        case bracketed
        /// param[0]=value1&param[1]=value2&param[3]=value3
        case indexed
        /// param=value1,value2,value3
        case commaSeparated
    }

    /// Defines how dictionaires should be formatted within a query string
    public enum DictionaryFormat {
        /// param.key1=value1&param.key2=value2&param.key3.key4=value3
        case dotNotated
        /// param[key1]=value1&param[key2]=value2&param[key3][key4]=value3
        case subscripted
    }

    // default formats
    public var arrayFormat: ArrayFormat = .commaSeparated
    public var dictionaryFormat: DictionaryFormat = .subscripted

    // input dictionary
    public var queryDictionary: [String: Any]

    public init(_ queryDictionary: [String: Any]) {
        self.queryDictionary = queryDictionary
    }

    public var queryItems: [URLQueryItem] {
        return queryDictionary.flatMap { kvp in
            queryItemsFrom(parameter: (kvp.key, kvp.value))
        }
    }

    private func queryItemsFrom(parameter: (String, Any)) -> [URLQueryItem] {
        let name = parameter.0
        var value: String?
        if let parameterValue = parameter.1 as? [Any] {
            return queryItemsFrom(arrayParameter: (name, parameterValue))
        }
        if let parameterValue = parameter.1 as? [String: Any] {
            return queryItemsFrom(dictionaryParameter: (name, parameterValue))
        }
        if let parameterValue = parameter.1 as? String {
            value = parameterValue
        } else if let parameterValue = parameter.1 as? NSNumber {
            value = parameterValue.stringValue
        } else if parameter.1 is NSNull {
            value = nil
        } else {
            value = "\(parameter.1)"
        }
        return [URLQueryItem(name: name, value: value)]
    }

    private func queryItemsFrom(arrayParameter parameter: (String, [Any])) -> [URLQueryItem] {
        let key = parameter.0
        let value = parameter.1
        switch arrayFormat {
        case .indexed:
            return value.enumerated().flatMap { queryItemsFrom(parameter: ("\(key)[\($0)]", $1)) }
        case .bracketed:
            return value.flatMap { queryItemsFrom(parameter: ("\(key)[]", $0)) }
        case .duplicatedKeys:
            return value.flatMap { queryItemsFrom(parameter: (key, $0)) }
        case .commaSeparated:
            let queryItemValue = value.map { "\($0)" }.joined(separator: ",")
            return [URLQueryItem(name: key, value: queryItemValue)]
        }
    }

    private func queryItemsFrom(dictionaryParameter parameter: (String, [String: Any])) -> [URLQueryItem] {
        let key = parameter.0
        let value = parameter.1
        switch dictionaryFormat {
        case .dotNotated:
            return value.flatMap { queryItemsFrom(parameter: ("\(key).\($0)", $1)) }
        case .subscripted:
            return value.flatMap { queryItemsFrom(parameter: ("\(key)[\($0)]", $1)) }
        }
    }
}
