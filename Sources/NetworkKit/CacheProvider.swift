//
//  CacheProvider.swift
//  
//
//  Created by Andre Navarro on 10/29/19.
//

import Foundation

public class CacheItem {
    var data: Data?
    var object: Any?

    public init(data: Data?, object: Any?) {
        self.data = data
        self.object = object
    }
}

public protocol CacheProvider {
    func setCache(for request: URLRequest, data: Data?, object: Any?)
    func getCache(for request: URLRequest) -> CacheItem?
    func removeCache(for request: URLRequest)
    func removeAll()
}

public class NSCacheProvider: CacheProvider {
    private lazy var cache = NSCache<URLRequestKey, CacheItem>()
    private lazy var operationQueue = OperationQueue()

    public init() {}

    public func setCache(for request: URLRequest, data: Data?, object: Any?) {
        if data != nil || object != nil {
            let key = URLRequestKey(request: request)
            var item: CacheItem?
            if let existingItem = getCache(for: key.request) {
                item = existingItem
            } else {
                item = CacheItem(data: data, object: object)
            }

            if let item = item {
                cache.setObject(item, forKey: URLRequestKey(request: request))
            }
        }
    }

    public func getCache(for request: URLRequest) -> CacheItem? {
        cache.object(forKey: URLRequestKey(request: request))
    }

    public func removeCache(for request: URLRequest) {
        cache.removeObject(forKey: URLRequestKey(request: request))
    }

    public func removeAll() {
        cache.removeAllObjects()
    }

    class URLRequestKey: NSObject {
        let request: URLRequest
        init(request: URLRequest) {
            self.request = request
        }

        override func isEqual(_ object: Any?) -> Bool {
            guard let other = object as? URLRequestKey else {
                return false
            }
            return request == other.request
        }

        override var hash: Int {
            return request.hashValue
        }
    }
}
