//
//  DiskRequest.swift
//  
//
//  Created by Andre Navarro on 10/31/19.
//

import Foundation

class DiskRequest: NSObject, Request {

    var isSuccess: Bool = true
    var data: Data?
    var error: Error?

    func validate() -> Self {
        return self
    }

    func getDataFromDisk() -> Data? {
        let url = self.urlRequest?.url ?? URL(string: "")!
        return try? Data(contentsOf: url)
    }

    func response(_ completion: @escaping ResponseCallback<Data>) -> Self {
        if let data = getDataFromDisk() {
            completion(Response(.success(data)))
        } else {
            completion(Response(.failure(.dataMissing)))
        }

        return self
    }

    func responseString(_ completion: @escaping ResponseCallback<String>) -> Self {
        if let data = self.getDataFromDisk(),
            let string = String(data: data, encoding: .utf8) {
            completion(Response(.success(string)))
        } else {
            completion(Response(.failure(.dataMissing)))
        }

        return self
    }

    func responseDecoded<T>(of type: T.Type,
                            parser: DecodableParserProtocol?,
                            completion: @escaping ResponseCallback<T>) -> Self where T: Decodable {
        let parser = parser ?? DecodableJSONParser()
        let data = self.getDataFromDisk()
        let parserResult = parser.parse(data: data)
            .mapError({ NetworkError.parsingError($0)}) as Result<T, NetworkError>

        completion(Response(parserResult))

        return self
    }

    func cancel() {
    }

    var urlRequest: URLRequest?
    var response: URLResponse?

    init(urlRequest: URLRequest?) {
        self.urlRequest = urlRequest
    }
}
