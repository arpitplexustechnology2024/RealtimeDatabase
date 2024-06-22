//
//  ProductListViewController.swift
//  RealtimeDatabase
//
//  Created by Arpit iOS Dev. on 20/06/24.
//

import UIKit
import FirebaseDatabase
import SDWebImage

class ProductListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var products: [Product] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        activityIndicator.style = .large
        activityIndicator.startAnimating()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1 ) {
            self.tableView.isHidden = false
            self.activityIndicator.stopAnimating()
            self.activityIndicator.isHidden = true
            self.fetchProducts()
        }
    }

    func fetchProducts() {
        let productsRef = Database.database().reference().child("products")
        productsRef.observe(.value) { snapshot in
            var fetchedProducts: [Product] = []

            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let productDict = snapshot.value as? [String: Any],
                   let productName = productDict["productName"] as? String,
                   let productDescription = productDict["productDescription"] as? String,
                   let productWeight = productDict["productWeight"] as? String,
                   let productImageUrl = productDict["productImageUrl"] as? String {
                   
                   // Create a Product object
                   let product = Product(name: productName, description: productDescription, weight: productWeight, imageUrl: productImageUrl)
                   fetchedProducts.append(product)
                }
            }
            self.products = fetchedProducts
            self.tableView.reloadData()
        }
    }
}

extension ProductListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProductListTableViewCell", for: indexPath) as! ProductListTableViewCell
        let product = products[indexPath.row]
        cell.nameLabel.text = product.name
        cell.descriptionLabel.text = product.description
        cell.weightLabel.text = product.weight

        if let imageUrl = URL(string: product.imageUrl) {
            cell.productImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder_image"))
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 159
    }
}
