//
//  URLComponent.swift
//  Network-Testing
//
//  Created by Vikram on 05/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public extension URLComponents {
    mutating func setQueryItems(with parameters: QueryParameters) {
        queryItems = parameters.map { URLQueryItem(name: $0.key,
                                                   value: $0.value) }
    }
}
