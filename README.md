# NetworkKit

This package provides basic Networking.

## Usage

You manage your own retained WebService instance inside some network manager class and wrap the HTTP calls:

```swift
    private var webService = Webservice(baseURL: URL(string: "https://httpbin.org/")!)
    webService.request(withPath: "get", method: .get) { (response: Response<HTTPBinResult, NetworkStackError>) in
        switch response.result {
        case let .success(httpBinResult):
            print(httpBinResult)
        case let .failure(error):
            print("error: \(error)")
        }

    }
`

or if you need the data directly:

```swift
    webService.requestData(withPath: "get", method: .get) { (_, response, result: Result<Data, NetworkStackError>) in
        switch result {
        case let .success(data):
            print("success \(data)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
`

## Response

The type of object you get back from a response is Response<SomeModel, NetworkStackError>, where SomeModel's type is defined by the completion block's definition of the Success value of Response in your webService.request() call.

The Response object is a wrapper around the Result<SomeModel, NetworkStackError> and holds everything you might need about the response, such as the originating URLRequest, the URLResponse object and raw data.

```swift
public struct Response<Success, Failure: Error> {
    public let request: URLRequest?
    public let response: URLResponse?
    public let data: Data?
    public let result: Result<Success, Failure>
    public var value: Success? { return try? result.get() }
    public var error: Failure? {
        guard case let .failure(error) = result else { return nil }
        return error
    }
}
`

If you wanted to get the status code for example, you'd take it from:

```swift
(response.response as? HTTPURLResponse)?.statusCode
`

## Cancel

To cancel requests, hold on to the returned Request object from webService.request() and call cancel on that.