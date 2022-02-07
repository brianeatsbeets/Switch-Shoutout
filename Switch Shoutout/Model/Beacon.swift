//
//  Beacon.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/18/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class Beacon: NSObject, NSCoding{
    var gameTitle: String
    var owner: String
    var id: Int

    init(_gameTitle: String, _owner: String, _id: Int = Int.random(in: 0 ... 2147483647)) {
        gameTitle = _gameTitle
        owner = _owner
        id = _id
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let gameTitle = aDecoder.decodeObject(forKey: "gameTitle") as! String
        let owner = aDecoder.decodeObject(forKey: "owner") as! String
        let id = aDecoder.decodeInteger(forKey: "id")
        
        self.init(_gameTitle: gameTitle, _owner: owner, _id: id)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(gameTitle, forKey: "gameTitle")
        aCoder.encode(owner, forKey: "owner")
        aCoder.encode(id, forKey: "id")
    }
}
