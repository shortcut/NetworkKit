//
//  ViewController.swift
//  NetworkKitDemo
//
//  Created by Andre Navarro on 11/4/19.
//  Copyright © 2019 Shortcut AS. All rights reserved.
//

import UIKit
import NetworkKit

class Cell: UICollectionViewCell {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = self.contentView.bounds
    }
    override func prepareForReuse() {
        super.prepareForReuse()
        self.imageView.image = nil
        self.imageView.cancelImageLoad()
    }
}

struct HTTPBinResult: Decodable {
    let url: String
    let form: [String: String]?
    let args: [String: String]?
    let json: [String: String]?
}

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var network: Network = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = ["Accept": "application/json"]
        let network = Network(urlSessionConfiguration: configuration)

        return network
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView.delegate = self
        self.collectionView.register(Cell.self, forCellWithReuseIdentifier: "Cell")

        let request = network.request("https://httpbin.org/anything")

        request.responseDecoded(of: HTTPBinResult.self) { response in
            switch response.result {
            case let .success(bin):
                print(bin.url)
            case let .failure(error):
                print(error)
            }
        }
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1000
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as? Cell else {
                return UICollectionViewCell()
        }

        cell.backgroundColor = .black

        let urlString = "https://robohash.org/\(indexPath.row)?size=400x400"

        cell.imageView.loadImage(from: urlString, placeHolder: UIImage(named: "0"))
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.reloadData()
    }
}
