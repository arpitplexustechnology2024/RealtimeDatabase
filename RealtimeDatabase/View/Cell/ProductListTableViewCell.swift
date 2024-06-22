//
//  ProductListTableViewCell.swift
//  RealtimeDatabase
//
//  Created by Arpit iOS Dev. on 20/06/24.
//

import UIKit

class ProductListTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
        @IBOutlet weak var descriptionLabel: UILabel!
        @IBOutlet weak var weightLabel: UILabel!
        @IBOutlet weak var productImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
