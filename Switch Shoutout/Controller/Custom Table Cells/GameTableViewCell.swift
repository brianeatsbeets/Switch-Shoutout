//
//  GameTableViewCell.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/16/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class GameTableViewCell: UITableViewCell {
    
    @IBOutlet weak var cellLabel: UILabel!
    @IBOutlet weak var cellImage: UIImageView!
    @IBOutlet weak var cellBackground: UIImageView!
    @IBOutlet weak var checkCircle: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
