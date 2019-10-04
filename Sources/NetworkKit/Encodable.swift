//
//  Encodable.swift
//  Network-Testing
//
//  Created by Vikram on 08/09/2019.
//  Copyright © 2019 Vikram. All rights reserved.
//

import Foundation

public extension Encodable {
    func encode() -> Data? {
        return try? JSONEncoder().encode(self)
    }
}
