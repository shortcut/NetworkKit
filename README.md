# NetworkKit

This package provides basic Networking.

## Usage

Create an object that conforms to TargetType to define the HTTP details of your API's endpoints 

```swift
enum TrumfNFCTarget {
    case newNFCSession(ecrId: String, payload: TrumfNFCNewSessionRequest)
    case getNFCSessionStatus(channelId: String)
}

extension TrumfNFCTarget: TargetType {
    var baseURL: URL { URL(string: "https://ngdapidev.azure-api.net/sylinder/trumfpay/v1/pos")! }
    
    var headerValues: HTTPHeaders? {
        ["api-subscription-key": "a9f9ee896e3448c386b377550c713abe",
         "Accept": "application/json"]
    }
    
    var path: String {
        switch self {
        case .newNFCSession(let ecrId, _):
            return "/\(ecrId)/session/nfc"
        case .getNFCSessionStatus(let channelId):
            return "/session/nfc/\(channelId)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .newNFCSession:
            return .post
        case .getNFCSessionStatus:
            return .get
        }
    }
    
    var bodyType: HTTPBodyType {
        switch self {
        case .newNFCSession:
            return .json
        case .getNFCSessionStatus:
            return .none
        }
    }
    
    var body: Encodable? {
        switch self {
        case .newNFCSession(_, let payload):
            return payload
        case .getNFCSessionStatus:
            return nil
        }
    }
}

```

## Request

You can make requests on the shared `Network` object at `NK` or create your own `Network`. For example if you wanted to request a decoded `User` object, you could do:

```swift
NK.request(UsersAPI.getUser(id: 123)).responseDecoded(of: User.self) { response in
    switch response.result {
    case let .success(data):
        print("success \(data)")
    case let .failure(error):
        print("error: \(error)")
    }
}
```
You can request a urlString, URL, URLRequest or a TargetType:

```swift
NK.request("http://google")
NK.request(URL(string: "http://google"))
NK.request(URLRequest(url: URL(string:"http://google")))
NK.request(target)
```

You can also do `.response` if you just want the data, or `.responseString` if you want a string

## Response

The type of object you get back from a response is Response<SomeModel>, which is a wrapper around the Result<SomeModel, NetworkError> and holds everything you might need about the response, such as the originating URLRequest, the URLResponse object and raw data.

```swift
public struct Response<Success, Failure: Error> {
    public var request: URLRequest?
    public var response: URLResponse?

    public var data: Data?
    public let result: Result<SuccessType, NetworkError>
}

extension Response {
    public var statusCode: Int?
    public func localizedStringForStatusCode() -> String? 
    public var allHeaderFields: [AnyHashable: Any]? 
}

To cancel a request, hold on to the `Request` object and cancel it whenever.

```swift
let request = NK.request(UsersAPI.getUsers)
request.response { response in 
// blabla
}

request.cancel()
```