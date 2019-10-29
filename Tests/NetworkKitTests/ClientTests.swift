//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

@testable import NetworkKit
import XCTest


final class ClientTests: XCTestCase {

    var client: Client = {
        let client = Client()
        client.requestMiddleware.append(LoggerRequestMiddleware())
        client.responseMiddleware.append(LoggerResponseMiddleware())
        return client
    }()
    var diskClient: Client = { Client(dataFetcher: MockDataFetcher()) }()

    override func setUp() {
        super.setUp()
        client.requestMiddleware = []
        client.responseMiddleware = []
    }
    
    func testSuccessClient() {
        let expectation = XCTestExpectation(description: "should make a sucessful get request and decode the response")

        self.client.perform(HTTPStatusService.twoHundred(delay: 0)) { response in
            XCTAssertTrue(Thread.isMainThread)

            response.mapDecodable { (response: Response<TestModel>) in
                XCTAssertTrue(Thread.isMainThread)

                switch response.result {
                case let .success(result):
                    XCTAssertEqual(response.statusCode, 200)
                    XCTAssertEqual(result.code, 200)
                    expectation.fulfill()
                case let .failure(error):
                    print(error)
                    XCTFail()
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testErrorClient() {
        let expectation = XCTestExpectation(description: "should fail after a request that returns code 500")

        client.perform(HTTPStatusService.fiveHundred) { response in
            response.mapDecodable { (response: Response<TestModel>) in

                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    print(error)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testErrorResponseClient() {
        let expectation = XCTestExpectation(description: "should fail and return a decoded error response")

        client.perform(HTTPStatusService.fiveHundred) { response in
            response.mapDecodableWithError(errorResponseType: TestErrorModel.self) { (response: Response<TestModel>) in

                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    if case let .errorResponse(model) = error {
                        if let errorModel = model as? TestErrorModel {
                            XCTAssertEqual(errorModel.code, 500)
                            expectation.fulfill()
                        }
                    }
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }
    
    func testFailingRequestMiddleware() {
        let expectation = XCTestExpectation(description: "should fail a successful request")

        client.requestMiddleware.append(FailerRequestMiddleware())
        
        client.perform(HTTPStatusService.twoHundred(delay: 0)) { response in
            response.mapDecodable { (response: Response<TestModel>) in

                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    print(error)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testFailingResponseMiddleware() {
        let expectation = XCTestExpectation(description: "should fail a successful request")

        client.responseMiddleware.append(FailerResponseMiddleware())
        client.perform(HTTPStatusService.twoHundred(delay: 0)) { response in
            response.mapDecodable { (response: Response<TestModel>) in

                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    print(error)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }
    
    func testInvalidURL() {
        let expectation = XCTestExpectation(description: "should fail because invalid url")

        client.perform(URLRequest(url: URL(string: "lolwat")!)) { response in
            response.mapDecodable { (response: Response<TestModel>) in

                switch response.result {
                case .success:
                    XCTFail()
                case let .failure(error):
                    print(error)
                    expectation.fulfill()
                }
            }
        }

        wait(for: [expectation], timeout: 5)
    }
    
    func testCancelRequest() {
        let expectation = XCTestExpectation(description: "should cancel a request")

        let taskId = self.client.perform(HTTPStatusService.twoHundred(delay: 5)) { response in
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

        self.client.cancelRequest(with: taskId!)
        
        wait(for: [expectation], timeout: 5)
    }
}

struct TestModel: Decodable {
    let code: Int
    let description: String
}

struct TestErrorModel: Decodable {
    let code: Int
    let description: String
}

enum HTTPStatusService {
    case twoHundred(delay: UInt)
    case fiveHundred
}

extension HTTPStatusService: RequestType {
    var headerValues: HTTPHeaders? { ["Accept": "application/json"] }

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
            return QueryParameters(["sleep": "\(delay)"])
        }
    }
}

class LoggerRequestMiddleware: RequestMiddleware {
    func prepare(_ request: URLRequest) -> (URLRequest, Response<Data>?) {
        print("REQUEST MIDDLE LOGGING: \(request)")
        return (request, nil)
    }
}

class LoggerResponseMiddleware: ResponseMiddleware {
    func prepare<T>(_ response: Response<T>) -> Response<T> {
        switch response.result {
        case .success:
            print("RESPONSE MIDDLE LOGGING \(String(data: response.data!, encoding: .utf8)!)")
        case let .failure(error):
            print("RESPONSE MIDDLE LOGGING ERROR: \(error)")
        }
        return response
    }
}

class FailerRequestMiddleware: RequestMiddleware {
    func prepare(_ request: URLRequest) -> (URLRequest, Response<Data>?) {
        print("REQUEST FAIL MIDDLE")
        return (request, .init(request: request, response: nil, data: nil, result: .failure(.dataMissing)))
    }
}

class FailerResponseMiddleware: ResponseMiddleware {
    func prepare<T>(_ response: Response<T>) -> Response<T> {
        return Response(request: response.request, response: response.response, data: response.data, result: .failure(NetworkStackError.dataMissing))
    }
}

class CachedRequestMiddleware: RequestMiddleware {
    public func prepare(_ request: URLRequest) -> (URLRequest, Response<Data>?) {
        var possibleResponse: Response<Data>?

        if let data = URLCache.shared.cachedResponse(for: request)?.data {
            possibleResponse = .init(request: request, response: nil, data: data, result: .success(data))
        }

        return (request, possibleResponse)
    }
}
