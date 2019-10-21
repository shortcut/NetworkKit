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
    static var headerValues: HTTPHeaders? {
        return ["Accept" : "application/json"]
    }
    
    var additionalHeaderValues: HTTPHeaders? {
        nil
    }
    
    static var baseURL: URL {
        URL(string: "https://httpstat.us/")!
    }
    
    var path: String {
        switch self {
        case .twoHundred:
            return "200"
        case .fiveHundred:
            return "500"
        }
    }

    var method: HTTPMethod {
        .get
    }
    
    var bodyType: HTTPBodyType {
        .none
    }
    
    var body: Encodable? {
        nil
    }
    
    var queryParameters: QueryParameters? {
        switch self {
        case .fiveHundred:
            return nil
        case let .twoHundred(delay):
            return ["sleep": "\(delay)"]
        }
    }
    
    var diskFileName: String {
        return "getResponse.json"
    }
}

class LoggerRequestMiddleware: RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>) -> Void) {
        print("REQUEST MIDDLE LOGGING: \(request) ")
        completion(.success(request))
    }
}

class LoggerResponseMiddleware: ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E, NetworkStackError>, completion: @escaping (Response<T, E, NetworkStackError>) -> Void) {
        print("RESPONSE MIDDLE LOGGING")
        completion(response)
    }
}

class FailerRequestMiddleware: RequestMiddleware {
    func massage(_ request: URLRequest, completion: @escaping (Result<URLRequest, NetworkStackError>) -> Void) {
        print("REQUEST MIDDLE LOGGING: \(request) ")
        completion(.failure(.dataMissing))
    }
}

class FailerResponseMiddleware: ResponseMiddleware {
    func massage<T, E>(_ response: Response<T, E, NetworkStackError>, completion: @escaping (Response<T, E, NetworkStackError>) -> Void) {
        print("FAILLLLL MIDDLE LOGGING")
        completion(Response(request: response.request, response: response.response, data: response.data, result: .failure(NetworkStackError.dataMissing), errorResponse: nil))
    }
}



final class ClientTests: XCTestCase {
    
    var client: Client = Client()
    
    override func setUp() {
        client = Client()
//        client.requestMiddleware.append(FailerRequestMiddleware())
    }

    func testSuccessClient() {
        let expectation = XCTestExpectation(description: "make get request")

        self.client.request(HTTPStatusService.twoHundred(delay: 0)) { response in
            
            XCTAssertTrue(Thread.isMainThread)

            response.mapJSON() { (response: Response<TestModel, TestErrorModel, NetworkStackError>) in
                
                XCTAssertTrue(Thread.isMainThread)

                switch response.result {
                case let .success(result):
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
            response.mapJSON() { (response: Response<TestModel, TestErrorModel, NetworkStackError>) in
                
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
    
    func testFailingMiddleware() {
        let expectation = XCTestExpectation(description: "make get request")
        
        client.responseMiddleware.append(FailerResponseMiddleware())

        client.request(HTTPStatusService.twoHundred(delay: 0)) { response in
            response.mapJSON() { (response: Response<TestModel, TestErrorModel, NetworkStackError>) in
                
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

