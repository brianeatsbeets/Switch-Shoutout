//
//  Message.swift
//  Switch Shoutout
//
//  Created by Aguirre, Brian P. on 7/12/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class Message {
    var senderID: String
    var text: String
    var avatar: String
    
    init(_senderID: String, _text: String, _avatar: String) {
        senderID = _senderID
        text = _text
        avatar = _avatar
    }
}
