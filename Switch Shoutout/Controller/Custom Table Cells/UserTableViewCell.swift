//
//  UserTableViewCell.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/5/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var friendcodeLabel: UILabel!
    @IBOutlet weak var userButton: UIButton!
    @IBOutlet weak var checkCircle: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
