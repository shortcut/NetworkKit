//
//  RemoteImage.swift
//
//
//  Created by Andre Navarro on 10/16/19.
//

import Foundation
import UIKit

extension UIImageView {
    public func loadImage(from URLString: String) {
//        guard let url = URL(string: URLString) else { return }
//        let urlRequest = URLRequest(url: url)
//
//        downloadOperation?.cancel()
//
//        self.currentTaskId = Client.shared.perform(urlRequest) { response in
//            self.downloadOperation = BlockOperation(block: {
//                response.mapImage(cache: Client.shared.cache) { (response: Response<UIImage>) in
//                    if urlRequest == response.request {
//                        switch response.result {
//                        case let .success(image):
//                            if self.downloadOperation?.isCancelled == false {
//                                self.image = image
//                            }
//                            else {
//                                print("nawwww")
//                            }
//                        case let .failure(error):
//                            print(" \(error)")
//                        }
//                    }
//
//                    self.currentTaskId = nil
//                }
//            })
//
//            self.downloadOperation?.start()
//        }
    }

    public func cancelImageLoad() {
//        downloadOperation?.cancel()
//        if let taskId = self.currentTaskId {
//            Client.shared.cancelRequest(with: taskId)
//        }
//        self.currentTaskId = nil
    }

    private var currentTaskId: TaskIdentifier? {
        get {
            return objc_getAssociatedObject(self, &AssociateKey.currentTaskId) as? TaskIdentifier
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociateKey.currentTaskId,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    private var downloadOperation: Operation? {
        get {
            return objc_getAssociatedObject(self, &AssociateKey.downloadOperation) as? Operation
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociateKey.downloadOperation,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

private struct AssociateKey {
    static var currentTaskId = 0
    static var downloadOperation = 1
}

struct ImageParser: ResponseParser {
    typealias ParsedObject = UIImage

    func parse(data: Data, type: UIImage.Type) -> Result<UIImage, ParserError> {
        guard let image = UIImage(data: data) else {
            return .failure(.dataMissing)
        }

        return .success(image)
    }
}

extension URLSessionDataRequest {
    func responseImage(completion: @escaping ResponseCallback<UIImage>) -> Self {

        // check cache and return early
        if let urlRequest = urlRequest,
            let cacheItem = cacheProvider.getCache(for: urlRequest),
            let cacheObject = cacheItem.object as? UIImage {
            let result = .success(cacheObject) as Result<UIImage, NetworkError>
            completion(Response(result))
            return self
        }

        addParseOperation(parser: ImageParser()) { response in
            if let urlRequest = self.urlRequest {
                self.cacheProvider.setCache(for: urlRequest, data: nil, object: try? response.result.get())
            }
            completion(response)
        }

        return self
    }
}
