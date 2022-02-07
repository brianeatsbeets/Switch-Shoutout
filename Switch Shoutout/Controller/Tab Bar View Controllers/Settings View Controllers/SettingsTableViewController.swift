//
//  SettingsTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import UIWindowTransitions
import SVProgressHUD
import OneSignal

protocol RedownloadDelegate: class {
    func updateGameList(status: GameListStatus)
}

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var friendcodeLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    var email = ""
    var friend_code = ""
    var nickname = ""
    var firstLoad = true
    weak var delegate: RedownloadDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        let userDefaults = UserDefaults.standard
        if let decodedEmail = userDefaults.object(forKey: "Email") as? Data {
            email = NSKeyedUnarchiver.unarchiveObject(with: decodedEmail) as! String
            emailLabel.text = email
        }
        
        if let decodedFriendCode = userDefaults.object(forKey: "FriendCode") as? Data {
            friend_code = NSKeyedUnarchiver.unarchiveObject(with: decodedFriendCode) as! String
            friendcodeLabel.text = friend_code
        }
        
        if let decodedNickname = userDefaults.object(forKey: "Nickname") as? Data {
            nickname = NSKeyedUnarchiver.unarchiveObject(with: decodedNickname) as! String
            nicknameLabel.text = nickname
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch tableView.cellForRow(at: indexPath)!.contentView.tag {
        case 1000:
            break
        case 2000:
            tableView.deselectRow(at: indexPath, animated: true)
            performSegue(withIdentifier: "goToChangeFriendCode", sender: self)
        case 3000:
            tableView.deselectRow(at: indexPath, animated: true)
            performSegue(withIdentifier: "goToChangeNickname", sender: self)
        case 4000:
            tableView.deselectRow(at: indexPath, animated: true)
            
            UserDefaults.standard.removeObject(forKey:"AllGamesList")
            UserDefaults.standard.set(0, forKey: "currentGameCount")
            delegate?.updateGameList(status: GameListStatus.redownloading)
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
//            let alert = UIAlertController(title: "Redownloading Games", message: "The list of all available games has been cleared and is being redownloaded in the background. Adding games to My Games will not be possible until all games have finished downloading.", preferredStyle: .alert)
//            
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            
//            self.present(alert, animated: true)
        case 5000:
            tableView.deselectRow(at: indexPath, animated: true)
            
            let alert = UIAlertController(title: "Sign out", message: "Are you sure?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in self.signOut() }))
            
            self.present(alert, animated: true)
        default:
            break
        }
    }
    
    func signOut() {
        
        var success = true
        let currentID = Auth.auth().currentUser!.uid
        
        do {
            try Auth.auth().signOut()
        }
        catch let error as NSError{
            print("Error: \(error.localizedDescription)")
            
            success = false
            
            let alert = UIAlertController(title: "Error :(", message: ("There was an issue signing you out."), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        
        if success {
            
            // Set next view controller
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let viewController = mainStoryboard.instantiateViewController(withIdentifier: "welcomeNC") as! UINavigationController
            
            // Disable notifications until sign in
            OneSignal.setSubscription(false)
            
            // Remove current beacon from firebase
            Database.database().reference().child("users").child(currentID).child("beacons").removeValue()
            
            // Remove beacon in friends' beacon lists
            let userDefaults = UserDefaults.standard
            if let decoded = userDefaults.object(forKey: "FriendList") as? Data {
                // Set value in beacons table for notifications
                if let friendArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [User] {
                    for friend in friendArray {
                        Database.database().reference().child("beacons").child(friend.fbuid).child(currentID).removeValue()
                    }
                }
                else {
                    print("No friends in friend array")
                }
            }
            else {
                print("No friend array in user defaults")
            }
            
            // Remove appropriate items from user defaults
            userDefaults.removeObject(forKey: "MyGamesList")
            userDefaults.removeObject(forKey: "FriendList")
            userDefaults.removeObject(forKey: "ConversationsList")
            userDefaults.removeObject(forKey: "Email")
            userDefaults.removeObject(forKey: "FriendCode")
            userDefaults.removeObject(forKey: "Nickname")
            userDefaults.removeObject(forKey: "CurrentBeacon")
            userDefaults.removeObject(forKey: "CurrentBeaconImage")
            //userDefaults.removeObject(forKey: "CompletedRegistration")
            
            // Remove observers from firebase
            Database.database().reference().child("users").child(currentID).child("friend_requests").removeAllObservers()
            Database.database().reference().child("beacons").child(currentID).removeAllObservers()
            
            UIApplication.shared.keyWindow?.setRootViewController(viewController)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}
