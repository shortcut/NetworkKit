[![CircleCI](https://circleci.com/gh/shortcut/NetworkKit.svg?style=svg)](https://circleci.com/gh/shortcut/NetworkKit)

# NetworkKit

This package provides basic Networking.

### Usage

#### Request

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

### Response

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
```

To cancel a request, hold on to the `Request` object and cancel it whenever.

```swift
let request = NK.request(UsersAPI.getUsers)
request.response { response in 
// blabla
}

request.cancel()
```

### TargetType

Create an object that conforms to TargetType to define the HTTP details of your API's endpoints 

```swift
enum UsersAPI {
    case createUser(id: String)
    case getUsers(name: String)
}

extension UsersAPI: TargetType {
    var baseURL: URL { URL(string: "http://example.com/")! }
    
    var headerValues: HTTPHeaders? {
        ["api-subscription-key": "asdkfhaskjdfh",
         "Accept": "application/json"]
    }
    
    var path: String {
        switch self {
        case .createUser(let id, _):
            return "/\(id)"
        case .getUsers(let name):
            return "/session/nfc/\(name)"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .createUser:
            return .post
        case .getUsers:
            return .get
        }
    }
    
    var bodyType: HTTPBodyType {
        switch self {
        case .createUser:
            return .json
        case .getUsers:
            return .none
        }
    }
    
    var body: Encodable? {
        switch self {
        case .createUser(_, let payload):
            return payload
        case .getUsers:
            return nil
        }
    }
}

```

### Validation

You can validate requests after the response if you need to define what counts as an error, for example if the HTTP status code is not 200. You can chain multiple validations, custom or not 


```swift
NK.request(UserAPI.getUser("bob").validate().responseDecoded(of: TestModel.self) { response in
    
}

```

### Custom error parsing

If your server returns different schemas on errors that you'd like to parse, you can supply a type that will be used to parse that, in the cases when validation fails.

So for example if you are calling an authorization server that returns status code 401 and some json describing the error, you can parse that and get it in the NetworkError

```swift

network?.request(AuthAPI.authenticate(with: credentials))
    .validate()
    .responseDecoded(of: AuthState.self,
                     errorType: AuthError.self) { response in

        switch response.result {
        case .success:
            // do fun stuff
        case let .failure(error):
            // get the AuthError object
            if case let .errorResponse(errorObject) = error {
                // do fun stuff with your AuthError object
            }
        }
}

```

### Request Adaptors

If you'd like to adapt the URLRequest before transport, you can pass in a RequestAdaptor to your request, for example if you'd like to add runtime authentication headers:

```swift
public struct AuthenticationAdapter: RequestAdapter {
    let accessToken: AccessToken

    public func adapt(_ urlRequest: URLRequest) -> URLRequest {
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return urlRequest
    }
}

self.network.request(target)
    .withAdapter(AuthenticationAdapter(accessToken: accessToken))
    .responseDecoded(of: T.self) { response in
        switch response.result {
        case let .success(products):
            completion(.success(products))
        case let .failure(error):
            completion(.failure(ApplicationError.networkError(error)))
        }
}
```
