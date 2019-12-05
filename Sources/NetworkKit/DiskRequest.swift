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

    var isSuccess: Bool = true
    var data: Data?
    var error: Error?
    var delay: TimeInterval = 0

    func validate() -> Self {
        return self
    }

    func getDataFromDisk() -> Data? {
        let url = self.urlRequest?.url ?? URL(string: "asdf")!
        return try? Data(contentsOf: url)
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

    func cancel() {
        // no-op
    }

    var urlRequest: URLRequest?
    var response: URLResponse?

    init(urlRequest: URLRequest?, delay: TimeInterval = 0) {
        self.delay = delay
        self.urlRequest = urlRequest
    }
}
