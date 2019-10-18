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

enum HTTPBinUserService {
    case getUsers
    case getDelay(seconds: UInt)
    case post(name: String, age: String)
}

enum HTTPBinUserImagesService {
    case getUserImages
    case getDelay(seconds: UInt)
    case post(name: String, age: String)
}

extension HTTPBinService: TargetType {
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
    
    var diskFileName: String {
        return "getResponse.json"
    }
}


final class ProviderTests: XCTestCase, URLSessionDataDelegate {

    let provider = Provider<HTTPBinService>()
    let diskProvider = Provider<HTTPBinService>(dataFetcher: DiskDataFetcher())

    var dataFetcher: URLSessionDataFetcher<HTTPBinService>?
    var delegatedProvider: Provider<HTTPBinService>?
    var sessionDelegate: SessionDelegate?
    
    func testProviderGet() {
        let expectation = XCTestExpectation(description: "make get request")

        provider.request(.getUsers, typeSelector: HTTPBinTypeSelector()) { response in
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

        provider.request(.post(name: "Andre", age: "35"), typeSelector: HTTPBinTypeSelector()) { response in
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

        provider.request(.getDelay(seconds: 2), typeSelector: HTTPBinTypeSelector()) { response in
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
  
        //provider.cancel(.get)
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testOneFlightForMultipleEqualRequests() {
        sessionDelegate = SessionDelegate()
        
        dataFetcher = URLSessionDataFetcher<HTTPBinService>(urlSession: URLSession(configuration: .default, delegate: self, delegateQueue: nil), headers: [adf:aasdf])


        dataFetcher.middle { request in
            
        }
        
        delegatedProvider = Provider<HTTPBinService>(dataFetcher: dataFetcher!)

        
        
        delegatedProvider!.request(.getDelay(seconds: 3), typeSelector: HTTPBinTypeSelector()) { response in
            print(response)
        }
        
        delegatedProvider!.request(.getDelay(seconds: 3), typeSelector: HTTPBinTypeSelector()) { response in
        }
        
        delegatedProvider!.request(.getDelay(seconds: 3), typeSelector: HTTPBinTypeSelector()) { response in
        }
        
        delegatedProvider!.request(.getDelay(seconds: 3), typeSelector: HTTPBinTypeSelector()) { response in
        }
        
        delegatedProvider!.request(.getDelay(seconds: 3), typeSelector: HTTPBinTypeSelector()) { response in
        }
        
    }
//
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        print("asdf")
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("asdf")
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
            print("asdf")
    }

    @available(iOS 10.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        for metric in metrics.transactionMetrics {
            print(metric)
        }
    }
}

class SessionDelegate: NSObject, URLSessionDataDelegate {
    @available(iOS 10.0, *)
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        for metric in metrics.transactionMetrics {
            print(metric)
        }
    }
}
