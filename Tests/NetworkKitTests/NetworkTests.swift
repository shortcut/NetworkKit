//
//  File.swift
//  
//
//  Created by Andre Navarro on 10/21/19.
//

@testable import NetworkKit
import XCTest

final class NetworkTests: XCTestCase {
    var network: Network?

    override func setUp() {
        super.setUp()
        network = Network()
    }

    override func tearDown() {
        super.tearDown()
        network = nil
    }

    func testNetwork() {
        let expectation = XCTestExpectation(description: "string")
        let expectation2 = XCTestExpectation(description: "decode")
        let expectation3 = XCTestExpectation(description: "decode")

            let request = network?.request(HTTPStatusService.twoHundred(delay: 0))
        request?.responseString({ response in

            expectation.fulfill()

            switch response.result {
            case let .success(string):
                print("yay! \(string)")
            case let .failure(error):
                print("error: \(error)")
            }

            })

        request?.responseDecoded(of: TestModel.self) { response in

            expectation2.fulfill()

            switch response.result {
            case let .success(string):
                print("yay! \(string)")
            case let .failure(error):
                print("error: \(error)")
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

                self.network?.request(HTTPStatusService.twoHundred(delay: 0)).responseDecoded(of: TestModel.self) { response in
                    switch response.result {
                    case let .success(string):
                        print("yay! \(string)")
                    case let .failure(error):
                        print("error: \(error)")
                    }

                    expectation3.fulfill()

                }
            }

        }
        wait(for: [expectation, expectation2, expectation3], timeout: 5)

    }

    func testSuccessClient() {
        let expectation = XCTestExpectation(description: "should make a sucessful get request and decode the response")

        network?.request(HTTPStatusService.twoHundred(delay: 0)).responseDecoded(of: TestModel.self) { response in
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

        wait(for: [expectation], timeout: 5)
    }

    func testErrorClient() {
        let expectation = XCTestExpectation(description: "should fail after a request that returns code 500")

        network?.request(HTTPStatusService.fiveHundred).validate().responseDecoded(of: TestModel.self) { response in
            switch response.result {
            case .success:
                XCTFail()
            case let .failure(error):
                print(error)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
    }

    func testInvalidURL() {
        let expectation = XCTestExpectation(description: "should fail because invalid url")

        network?.request(URLRequest(url: URL(string: "lolwat")!)).response { response in
            switch response.result {
            case .success:
                XCTFail()
            case let .failure(error):
                print(error)
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 5)
    }

    func testCancelRequest() {
        let expectation = XCTestExpectation(description: "should cancel a request")

        let request = network?.request(HTTPStatusService.twoHundred(delay: 5))

        request?.responseDecoded(of: TestModel.self) { response in
            switch response.result {
            case .success:
                XCTFail("the request should fail")
            case let .failure(error):
                XCTAssertNil(response.data)

                guard case let .responseError(responseError) = error else {
                    return
                }

                XCTAssertEqual((responseError as NSError).code, NSURLErrorCancelled)
            }

            expectation.fulfill()
        }

        request?.cancel()

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

extension HTTPStatusService: TargetType {
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