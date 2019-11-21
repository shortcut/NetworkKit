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
    public func response() -> LoadingSignal<Data, NetworkError> {
        LoadingSignal<Data, NetworkError> { observer in
            observer.receive(.loading)
            let request = self.response { response in
                switch response.result {
                case let .success(data):
                    observer.receive(lastElement: .loaded(data))
                case let .failure(error):
                    observer.receive(.failed(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }

    @discardableResult
    public func responseString() -> LoadingSignal<String, NetworkError> {
        LoadingSignal<String, NetworkError> { observer in
            observer.receive(.loading)
            let request = self.responseString { response in
                switch response.result {
                case let .success(string):
                    observer.receive(lastElement: .loaded(string))
                case let .failure(error):
                    observer.receive(.failed(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }

    @discardableResult
    func responseDecoded<T: Decodable>(of type: T.Type) -> LoadingSignal<T, NetworkError> {
        LoadingSignal<T, NetworkError> { observer in
            observer.receive(.loading)
            let request = self.responseDecoded(of: T.self, parser: DecodableJSONParser()) { response in
                switch response.result {
                case let .success(orderResponse):
                    observer.receive(lastElement: .loaded(orderResponse))
                case let .failure(error):
                    observer.receive(.failed(error))
                }
            }

            return BlockDisposable {
                request.cancel()
            }
        }
    }
}
