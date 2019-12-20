//
//  DiskRequest.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

class DiskRequest: NSObject, Request {
    func withAdapter(_ adapter: RequestAdapter) -> Self {
        adapters.append(adapter)
        return self
    }

    var adapters = [RequestAdapter]()

    var data: Data?
    var error: NetworkError?
    var delay: TimeInterval = 0
    var errorModelPath: URL?

    init(urlRequest: URLRequest?, errorModelPath: URL? = nil, delay: TimeInterval = 0) {
        self.urlRequest = urlRequest
        self.errorModelPath = errorModelPath
        self.delay = delay
    }

    private func getDataFromDisk(getErrorModel: Bool = false) -> Data? {
        if !getErrorModel {
            let url = self.urlRequest?.url ?? URL(string: "asdf")!
            return try? Data(contentsOf: url)
        } else if let url = self.errorModelPath {
            return try? Data(contentsOf: url)
        }

        return nil
    }

    func validate() -> Self {
        // no-op
        return self
    }

    func validate(_ successBlock: @escaping ValidationBlock) -> Self {
        if !successBlock(self.data, self.response, self.error) {
            self.error = NetworkError.validateError
        }
        return self
    }

    func validate(with validator: ResponseValidator) -> Self {
        if !validator.validate(data: self.data, urlResponse: self.response, error: self.error) {
            self.error = NetworkError.validateError
        }

        return self
    }

    func response(_ completion: @escaping ResponseCallback<Data>) -> Self {
        var data: Data?

        DispatchQueue.global(qos: .background).async {
            data = self.getDataFromDisk()

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.delay, execute: {
                if let data = data {
                    completion(Response(.success(data)))
                } else {
                    completion(Response(.failure(.dataMissing)))
                }
            })
        }

        return self
    }

    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self {
        var string: String?

        DispatchQueue.global(qos: .background).async {
            let data = self.getDataFromDisk()
            if let data = data {
                string = String(data: data, encoding: .utf8)
            }

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.delay, execute: {
                if let string = string {
                    completion(Response(.success(string)))
                } else {
                    completion(Response(.failure(.dataMissing)))
                }
            })
        }

        return self
    }

    func responseDecoded<T>(of type: T.Type,
                            parser: DecodableParserProtocol?,
                            completion: @escaping ResponseCallback<T>) -> Self where T: Decodable {
        var parserResult: Result<T, NetworkError>?

        DispatchQueue.global(qos: .background).async {
            let parser = parser ?? DecodableJSONParser()
            let data = self.getDataFromDisk()
            parserResult = parser.parse(data: data)
                .mapError({ NetworkError.parsingError($0)}) as Result<T, NetworkError>

            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.delay, execute: {
                if let parserResult = parserResult {
                    completion(Response(parserResult))
                }
            })
        }

        return self
    }

    func responseDecoded<T, E>(of type: T.Type,
                               errorType: E.Type,
                               parser: DecodableParserProtocol?,
                               completion: @escaping (Response<T>) -> Void) -> Self where T: Decodable, E: Decodable {
        var parserResult: Result<T, NetworkError>?

        DispatchQueue.global(qos: .background).async {
            if self.error == nil {
                let parser = parser ?? DecodableJSONParser()
                let data = self.getDataFromDisk()
                parserResult = parser.parse(data: data)
                    .mapError({ NetworkError.parsingError($0)}) as Result<T, NetworkError>

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.delay, execute: {
                    if let parserResult = parserResult {
                        completion(Response(parserResult))
                    }
                })
            } else if let error = self.error,
                case .validateError = error {
                let parser = parser ?? DecodableJSONParser()
                let data = self.getDataFromDisk()
                parserResult = parser.parse(data: data)
                    .mapError({ NetworkError.parsingError($0)}) as Result<T, NetworkError>

                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + self.delay, execute: {
                    if let parserResult = parserResult {
                        completion(Response(parserResult))
                    }
                })

            }
        }

        return responseDecoded(of: type, parser: parser, completion: completion)
    }

    func cancel() {
        // no-op
    }

    var urlRequest: URLRequest?
    var response: URLResponse?
}
