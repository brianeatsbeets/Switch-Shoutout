//
//  WelcomeViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Reachability

class WelcomeViewController: UIViewController {
    let reachability = Reachability()!
    var connected = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        runReachability()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    func runReachability() {
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            if !self.connected {
                // Dismiss "No internet connection" screen
                self.dismiss(animated: true, completion: nil)
            }
            
            self.connected = true
            
        }
        reachability.whenUnreachable = { _ in
            print("Not reachable")
            
            self.connected = false
            
            let reachVC = self.storyboard?.instantiateViewController(withIdentifier: "reachabilityVC")
            self.present(reachVC!, animated: true, completion: nil)
        }
        
        do {
            try reachability.startNotifier()
        } catch {
            print("Unable to start notifier")
        }
    }
}

