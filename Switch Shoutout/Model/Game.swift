//
//  Game.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class Game: NSObject, NSCoding {
    
    var title : String
    var image : UIImage
    
    init(_title: String, _image: UIImage) {
        title = _title
        image = _image
    }
    
    convenience override init() {
        self.init(_title: "", _image: UIImage())
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let title = aDecoder.decodeObject(forKey: "title") as! String
        let image = aDecoder.decodeObject(forKey: "image") as! UIImage
        self.init(_title: title, _image: image)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(title, forKey: "title")
        aCoder.encode(image, forKey: "image")
    }
}
