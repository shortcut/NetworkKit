//
//  RemoteImage.swift
//
//
//  Created by Andre Navarro on 10/16/19.
//

import Foundation
import UIKit

public extension UIImageView {
    func loadImage(from urlString: String, placeHolder: UIImage? = nil) {
        if let placeHolder = placeHolder {
            self.image = placeHolder
        }

        guard let url = URL(string: urlString) else {
            return
        }

        self.cancelImageLoad()

        let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        if let request = NK.request(urlRequest) as? URLSessionDataRequest {
            request.responseImage { response in
                guard request.urlRequest == self.currentRequest?.urlRequest else {
                    return
                }

                if case let .success(image) = response.result {
                    self.image = image
                }

                self.currentRequest = nil
            }
            self.currentRequest = request
        }
    }

    func cancelImageLoad() {
        self.currentRequest?.cancel()
        self.currentRequest = nil
    }

    private var currentRequest: Request? {
        get {
            return objc_getAssociatedObject(self, &AssociateKey.currentRequest) as? Request
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociateKey.currentRequest,
                newValue,
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
}

private struct AssociateKey {
    static var currentRequest = 0
}

public struct ImageParser: ResponseParser {
    typealias ParsedObject = UIImage

    func parse(data: Data, type: UIImage.Type) -> Result<UIImage, ParserError> {
        guard let image = UIImage(data: data) else {
            return .failure(.dataMissing)
        }

        return .success(image)
    }
}

public extension URLSessionDataRequest {
    @discardableResult
    func responseImage(completion: @escaping ResponseCallback<UIImage>) -> Self {

        startTask()

        self.addParseOperation(parser: ImageParser()) { response in
            OperationQueue.main.addOperation {
                completion(response)
            }
        }

        return self
    }
}
