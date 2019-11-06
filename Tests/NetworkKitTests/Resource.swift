//
//  Resource.swift
//  
//
//  Created by Andre Navarro on 10/22/19.
//

import Foundation

class Resource {
    static var resourcePath = "./Tests/NetworkKitTests/Resources"

    let name: String
    let type: String

    init(name: String, type: String) {
        self.name = name
        self.type = type
    }

    var path: String {
        guard let path: String = Bundle(for: Swift.type(of: self)).path(forResource: name, ofType: type) else {
            let filename: String = type.isEmpty ? name : "\(name).\(type)"
            return "\(Resource.resourcePath)/\(filename)"
        }
        return path
    }
}

extension Resource {
    var data: Data? {
        guard let url = URL(string: path) else { return nil }

        return try? Data(contentsOf: url)
    }

    var content: String? {
        return try? String(contentsOfFile: path).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    var base64EncodedData: Data? {
        guard let string = content, let data = Data(base64Encoded: string) else {
            return nil
        }
        return data
    }
}
