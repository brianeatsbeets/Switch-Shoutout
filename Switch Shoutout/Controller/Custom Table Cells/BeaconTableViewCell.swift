//
//  BeaconTableViewCell.swift
//  Switch Shoutout
//
//  Created by Aguirre, Brian P. on 5/3/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class BeaconTableViewCell: UITableViewCell {
    
    @IBOutlet weak var gameImage: UIImageView!
    @IBOutlet weak var gameLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
