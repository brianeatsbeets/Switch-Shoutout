//
//  FriendsTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import DZNEmptyDataSet
import OneSignal

class FriendsTableViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var friendArray = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Pull to refresh initiation
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:  #selector(fetchFriendList), for: UIControl.Event.valueChanged)
        self.refreshControl = refreshControl
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing Friends List...", attributes: nil)
        
        //SVProgressHUD.show()
        
        self.tableView.register(UINib (nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
        
        self.tableView.tableFooterView = UIView()
        
        // Check if the user opened the app by touching a friend request notification
        if UserDefaults.standard.bool(forKey: "DidLaunchFromFriendRequest") {
            self.performSegue(withIdentifier: "goToFriendRequests", sender: self)
            UserDefaults.standard.set(false, forKey: "DidLaunchFromFriendRequest")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        let userDefaults = UserDefaults.standard
        if let decodedFriendList = userDefaults.object(forKey: "FriendList") as? Data {
            friendArray = NSKeyedUnarchiver.unarchiveObject(with: decodedFriendList) as! [User]
        }
        
        self.tableView.reloadData()
        
        // If there is an unread friend request, set the Request bar button item text to bold; else, not bold
//        if UserDefaults.standard.bool(forKey: "newFriendRequest") {
//            navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "Avenir-Heavy", size: 19)!], for: .normal)
//            navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "Avenir-Heavy", size: 19)!], for: .highlighted)
//            print("bold")
//        }
//        else {
//            navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "Avenir-Roman", size: 19)!], for: .normal)
//            navigationItem.leftBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.font : UIFont(name: "Avenir-Roman", size: 19)!], for: .highlighted)
//            print("not bold")
//        }
        
    }
    
    @objc func fetchFriendList() {
        
        print("fetching updated friends list from firebase...")
        
        var tempFriendArray = [User]()
        let currentID = Auth.auth().currentUser!.uid
        let database = Database.database().reference()
        
        database.child("users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            var i = 0
            
            // Fill array of current friends
            if let friends = snapshot.value as? NSDictionary {
                for friend in friends {
                    
                    // Get friend details
                    database.child("users").child(friend.key as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                        if let details = snapshot.value as? Dictionary<String, Any> {
                            tempFriendArray.append(User(_friendcode: details["friend_code"]! as! String, _nickname: details["nickname"]! as! String, _fbuid: friend.key as! String, _player_id: details["player_id"] as? String ?? "none"))
                        }
                        
                        if i == friends.count - 1 {
                            self.friendArray = tempFriendArray
                            
                            let userDefaults = UserDefaults.standard
                            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.friendArray)
                            userDefaults.set(encodedData, forKey: "FriendList")
                            
                            self.tableView.reloadData()
                            
                            self.refreshControl?.endRefreshing()
                            
                            print("fetching complete.")
                        }
                        
                        i += 1
                    })
                }
            }
            else {
                self.friendArray.removeAll()
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
                print("fetching complete. No friends.")
            }
        }) { (error) in
            print(error.localizedDescription)
            SVProgressHUD.dismiss()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        
        cell.friendcodeLabel.text = friendArray[indexPath.row].friendcode
        cell.nicknameLabel.text = friendArray[indexPath.row].nickname
        cell.userButton.isHidden = true
        
        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Delete the row from friendArray
            let deletedFriend = friendArray[indexPath.row]
            friendArray = friendArray.filter {$0.fbuid != deletedFriend.fbuid}
            
            let database = Database.database().reference()
            let userID = Auth.auth().currentUser!.uid
            
            // Delete friend from the user's friends in Firebase
            database.child("users").child(userID).child("friends").child(deletedFriend.fbuid).removeValue()
            
            // Delete user from the friend's friends in Firebase
            database.child("users").child(deletedFriend.fbuid).child("friends").child(userID).removeValue()
            
            // Delete beacon fron friend's beacon list
            database.child("beacons").child(deletedFriend.fbuid).child(userID).removeValue()
            
            // Delete friend's beacon from beacon list
            database.child("beacons").child(userID).child(deletedFriend.fbuid).removeValue()
            
            // Delete friend from user defaults
            let userDefaults = UserDefaults.standard
            let encodedData = NSKeyedArchiver.archivedData(withRootObject: friendArray)
            userDefaults.set(encodedData, forKey: "FriendList")
            
            // Remove beacon in friend's beacon list
            if let decodedBeacon = userDefaults.object(forKey: "CurrentBeacon") as? Data {
                var friend_player_ids = [String]()
                let beacon = NSKeyedUnarchiver.unarchiveObject(with: decodedBeacon) as! Beacon
                
                // Set value in beacons table for notifications
                database.child("beacons").child(deletedFriend.fbuid).child(userID).removeValue()
                friend_player_ids.append(deletedFriend.player_id)
            
                let content = [
                    "content_available": true,
                    "data": ["type": "beacon_removed", "nickname": beacon.owner, "title": beacon.gameTitle, "id": beacon.id],
                    "include_player_ids": friend_player_ids
                    ] as [String : Any]
            
                // Send OneSignal notification to all friends
                OneSignal.postNotification(content, onSuccess: { (result) in
                    print("successful beacon removal notification!")
                }, onFailure: { (error) in
                    print("failed beacon removal notification: \(String(describing: error))")
                })
            }
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "No friends yet."
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 40)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Tap the + button to add new friends!"
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Book", size: 20)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
    func emptyDataSetShouldAllowTouch(_ scrollView: UIScrollView!) -> Bool {
        return true
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
