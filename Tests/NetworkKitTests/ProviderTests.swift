//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/14/19.
//

@testable import NetworkKit
import XCTest

enum HTTPBinService {
    case get
    case getDelay(seconds: UInt)
    case post(name: String, age: String)
}

extension HTTPBinService: TargetType {
    typealias ResponseType = HTTPBinResult

    static var baseURL: URL {
        URL(string: "https://httpbin.org/")!
    }
    
    var path: String {
        switch self {
        case .get:
            return "get"
        case let .getDelay(seconds):
            return "delay/\(seconds)"
        case .post:
            return "post"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .get:
            return HTTPMethod.get
        case .getDelay:
            return HTTPMethod.get
        case .post:
            return HTTPMethod.post
        }
    }
    
    var bodyType: HTTPBodyType {
        switch self {
        case .get:
            return .none
        case .getDelay:
            return .none
        case let .post(name, age):
            return .formEncoded(parameters: ["name": name, "age": age])
        }
    }
    
    var body: Encodable? {
        nil
    }
    
    var queryParameters: QueryParameters? {
        nil
    }
}


final class ProviderTests: XCTestCase {

    func testProviderGet() {
        let expectation = XCTestExpectation(description: "make get request")

        let provider = Provider<HTTPBinService>()
        provider.request(.get) { response in
            switch response.result {
            case let .success(httpBinResult):
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertEqual(httpBinResult.url, "https://httpbin.org/get")
            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testProviderPost() {
        let expectation = XCTestExpectation(description: "make post request")

        let provider = Provider<HTTPBinService>()
        provider.request(.post(name: "Andre", age: "35")) { response in
            switch response.result {
            case let .success(httpBinResult):
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertEqual(httpBinResult.url, "https://httpbin.org/post")
                XCTAssertEqual(httpBinResult.form, ["name": "Andre", "age": "35"])

            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3)
    }
    
    func testProviderCancel() {
        let expectation = XCTestExpectation(description: "cancel a request")

        let provider = Provider<HTTPBinService>()
        let request = provider.request(.getDelay(seconds: 3)) { response in
            switch response.result {
            case .success:
                XCTFail("the request should fail")
            case let .failure(error):
                XCTAssertNil(response.data)

                guard case let .responseError(responseError) = error else {
                    XCTFail("there should be an error")
                    return
                }

                XCTAssertEqual((responseError as NSError).code, NSURLErrorCancelled)
            }

            expectation.fulfill()
        }
        
        request.cancel()

        wait(for: [expectation], timeout: 5)
    }
}
