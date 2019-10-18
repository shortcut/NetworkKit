// https://justsitandgrin.net/swift-package-manager/ios/2019/01/20/swift_package_manager_vs_ios.html

@testable import NetworkKit
import XCTest

struct HTTPBinResult: Decodable {
    let url: String
    let form: [String: String]?
    let args: [String: String]?
    let json: [String: String]?
}

struct HTTPStatus: Decodable {
    let code: String
    let description: String
}

struct HTTPStatusErrorResponse: Decodable {
    let code: String
    let description: String
}

struct HTTPStatusTypeSelector: ResponseTypeSelector {
    typealias SuccessType = HTTPStatus
    typealias ErrorType = HTTPStatusErrorResponse
}

struct HTTPBinTypeSelector: ResponseTypeSelector {
    typealias SuccessType = HTTPBinResult
    typealias ErrorType = EmptyErrorResponse
}

final class NetworkKitTests: XCTestCase {
    private var webService = Webservice(baseURL: URL(string: "https://httpbin.org/")!)
    private var webServiceDecoder = WebserviceDecoder(baseURL: URL(string: "https://httpbin.org/")!)

    private var httpStatusService = WebserviceDecoder(baseURL: URL(string: "https://httpstat.us/")!, headerValues: ["Accept": "application/json"])
    
    
    func testGetRequestResponse() {
        let expectation = XCTestExpectation(description: "make get request")

        webServiceDecoder.request(withPath: "get", method: .get, typeSelector: HTTPBinTypeSelector()) { response in
            
            XCTAssertTrue(Thread.isMainThread)

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

    func testGetDataRequestResponse() {
        let expectation = XCTestExpectation(description: "make get request")

        webService.requestData(withPath: "get", method: .get) { (_, response, result: Result<Data, NetworkStackError>) in
            
            XCTAssertTrue(Thread.isMainThread)

            switch result {
            case let .success(data):
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertNotNil(data)
            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testPostRequest() {
        let expectation = XCTestExpectation(description: "make post request")

        let parameters = ["test": "Hello world",
                          "message": "øåæ",
                          "face": "🤓"]

        webServiceDecoder.request(withPath: "post", method: .post, bodyType: .formEncoded(parameters: parameters), typeSelector: HTTPBinTypeSelector()) { response in

            XCTAssertTrue(Thread.isMainThread)

            switch response.result {
            case let .success(httpBinResult):
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertEqual(httpBinResult.url, "https://httpbin.org/post")
                XCTAssertEqual(httpBinResult.form, parameters)
            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testPostJSONRequest() {
        let expectation = XCTestExpectation(description: "make post request")

        let parameters = ["test": "Hello world",
                          "message": "øåæ",
                          "face": "🤓"]

        webServiceDecoder.request(withPath: "post", method: .post, bodyType: .json, body: parameters, typeSelector: HTTPBinTypeSelector()) { response in

            XCTAssertTrue(Thread.isMainThread)

            switch response.result {
            case let .success(httpBinResult):
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertEqual(httpBinResult.url, "https://httpbin.org/post")
                XCTAssertEqual(httpBinResult.json, parameters)
            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testGetRequestQueryParamsResponse() {
        let expectation = XCTestExpectation(description: "make get request with query parameters")

        let parameters = ["test": "Hello world",
                          "message": "cool",
                          "number": "23"]

        webServiceDecoder.request(withPath: "get", method: .get, queryParameters: parameters, typeSelector: HTTPBinTypeSelector()) { response in
            
            XCTAssertTrue(Thread.isMainThread)

            switch response.result {
            case let .success(httpBinResult):
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 200)
                XCTAssertEqual(httpBinResult.args, parameters)

            case let .failure(error):
                XCTFail()
                print("error: \(error)")
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testGet404Response() {
        let expectation = XCTestExpectation(description: "get a 404 status code")

        webServiceDecoder.request(withPath: "status/404", method: .get, typeSelector: HTTPBinTypeSelector()) { response in
            
            XCTAssertTrue(Thread.isMainThread)

            switch response.result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertNotNil(response.data)
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 404)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }

    func testGetErrorModel() {
        let expectation = XCTestExpectation(description: "get a 500 status code with json backpo")

        webServiceDecoder.request(withPath: "500", method: .get, typeSelector: HTTPStatusTypeSelector()) { response in
            
            XCTAssertTrue(Thread.isMainThread)

            switch response.result {
            case .success:
                XCTFail()
            case .failure:
                XCTAssertEqual(response.errorResponse?.code, "500", "should have error response")
                XCTAssertEqual(response.errorResponse?.description, "Internal Server Error", "should have error response")
                XCTAssertNotNil(response.data)
                XCTAssertEqual((response.response as? HTTPURLResponse)?.statusCode, 500)
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3)
    }
    func testCancelRequest() {
        let expectation = XCTestExpectation(description: "cancel a request")

        let request = webServiceDecoder.request(withPath: "delay/5", method: .get, typeSelector: HTTPBinTypeSelector()) { response in
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
