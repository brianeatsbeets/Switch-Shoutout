//
//  User.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/1/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class User: NSObject, NSCoding {
    var friendcode: String
    var nickname: String
    var fbuid: String
    var player_id: String
    
    init(_friendcode: String, _nickname: String, _fbuid: String, _player_id: String) {
        friendcode = _friendcode
        nickname = _nickname
        fbuid = _fbuid
        player_id = _player_id
    }
    
    required convenience init(coder aDecoder: NSCoder) {
        let friendcode = aDecoder.decodeObject(forKey: "friendcode") as! String
        let nickname = aDecoder.decodeObject(forKey: "nickname") as! String
        let fbuid = aDecoder.decodeObject(forKey: "fbuid") as! String
        let player_id = aDecoder.decodeObject(forKey: "player_id") as! String
        self.init(_friendcode: friendcode, _nickname: nickname, _fbuid: fbuid, _player_id: player_id)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(friendcode, forKey: "friendcode")
        aCoder.encode(nickname, forKey: "nickname")
        aCoder.encode(fbuid, forKey: "fbuid")
        aCoder.encode(player_id, forKey: "player_id")
    }
}
