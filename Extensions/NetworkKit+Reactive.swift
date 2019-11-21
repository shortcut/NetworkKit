//
//  NetworkKit+Reactive.swift
//  Services
//
//  Created by Andre Navarro on 11/21/19.
//  Copyright © 2019 Shortcut AS. All rights reserved.
//

import Foundation
import NetworkKit
import ReactiveKit

extension Request {
    @discardableResult
    public func response() -> Signal<Data, NetworkError> {
        Signal<Data, NetworkError> { observer in
            let request = self.response { response in
                switch response.result {
                case let .success(data):
                    observer.receive(lastElement: data)
                case let .failure(error):
                    observer.receive(completion: .failure(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }

    @discardableResult
    public func responseString() -> Signal<String, NetworkError> {
        Signal<String, NetworkError> { observer in
            let request = self.responseString { response in
                switch response.result {
                case let .success(string):
                    observer.receive(lastElement: string)
                case let .failure(error):
                    observer.receive(completion: .failure(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }

    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type) -> Signal<T, NetworkError> {
        Signal<T, NetworkError> { observer in
            let request = self.responseDecoded(of: T.self, parser: DecodableJSONParser()) { response in
                switch response.result {
                case let .success(decodedObject):
                    observer.receive(lastElement: decodedObject)
                case let .failure(error):
                    observer.receive(completion: .failure(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }
}
