//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

@testable import NetworkKit
import XCTest

enum HTTPStatusService {
    case twoHundred(delay: UInt)
    case fiveHundred
}

extension HTTPStatusService: TargetType {
    var headerValues: HTTPHeaders? {
        return ["Accept" : "application/json"]
    }
    
    var baseURL: URL { URL(string: "https://httpstat.us/")! }
    
    var path: String {
        switch self {
        case .twoHundred:
            return "200"
        case .fiveHundred:
            return "500"
        }
    }

    var method: HTTPMethod { .get }

    var queryParameters: QueryParameters? {
        switch self {
        case .fiveHundred:
            return nil
        case let .twoHundred(delay):
            return ["sleep": "\(delay)"]
        }
    }
}


class LoggerRequestMiddleware: RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>, Response<Data, EmptyErrorResponse>?) -> Void) {
        print("REQUEST MIDDLE LOGGING: \(request) ")
        completion(.success(request), nil)
    }
}

class LoggerResponseMiddleware: ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E>, completion: @escaping (Response<T, E>) -> Void) {
        print("RESPONSE MIDDLE LOGGING")
        completion(response)
    }
}

class FailerRequestMiddleware: RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>, Response<Data, EmptyErrorResponse>?) -> Void) {
        print("REQUEST FAIL MIDDLE")
        completion(.failure(.dataMissing), nil)
    }
}

class FailerResponseMiddleware: ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E>, completion: @escaping (Response<T, E>) -> Void) {
        print("RESPONSE FAIL MIDDLE")
        completion(Response(request: response.request, response: response.response, data: response.data, result: .failure(NetworkStackError.dataMissing), errorResponse: nil))
    }
}



final class ClientTests: XCTestCase {
    
    var client: Client = { Client() }()
    var diskClient: Client = { Client(dataFetcher: MockDataFetcher()) }()
    
    func testSuccessClient() {
        let expectation = XCTestExpectation(description: "make get request")

        let request = HTTPStatusService.twoHundred(delay: 0).asURLRequest()!
        self.client.request(request) { response in
            XCTAssertTrue(Thread.isMainThread)

            response.mapDecodable() { (response: Response<TestModel, TestErrorModel>) in
                XCTAssertTrue(Thread.isMainThread)

                switch response.result {
                case let .success(result):
                    XCTAssertNotNil(URLCache.shared.cachedResponse(for: request))
                    XCTAssertEqual(response.statusCode, 200)
                    XCTAssertEqual(result.code, 200)
                case let .failure(error):
                    print(error)
                    XCTFail()
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testErrorClient() {
        let expectation = XCTestExpectation(description: "make get request")

        client.request(HTTPStatusService.fiveHundred) { response in
            response.mapDecodable() { (response: Response<TestModel, TestErrorModel>) in
                
                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    XCTAssertEqual(response.errorResponse?.code, 500)
                    print(error)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testFailingRequestMiddleware() {
        let expectation = XCTestExpectation(description: "make get request")
        
        client.requestMiddleware.append(FailerRequestMiddleware())
        client.request(HTTPStatusService.twoHundred(delay: 0)) { response in
            response.mapDecodable() { (response: Response<TestModel, TestErrorModel>) in
                
                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    print(error)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }

    func testFailingResponseMiddleware() {
        let expectation = XCTestExpectation(description: "make get request")
        
        client.responseMiddleware.append(FailerResponseMiddleware())
        client.request(HTTPStatusService.twoHundred(delay: 0)) { response in
            response.mapDecodable() { (response: Response<TestModel, TestErrorModel>) in
                
                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    
                    XCTAssertEqual(response.errorResponse?.code, 200)
                    print(error)
                }
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5)
    }
}

