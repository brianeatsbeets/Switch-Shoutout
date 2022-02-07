//
//  TabBarController.swift
//  Switch Shoutout
//
//  Created by Aguirre, Brian P. on 5/2/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    let delegate2 = ScrollingTabBarControllerDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = delegate2
    }
}
