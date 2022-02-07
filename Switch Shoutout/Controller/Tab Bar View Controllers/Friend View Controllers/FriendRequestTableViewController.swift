//
//  FriendRequestTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/2/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet

protocol BeaconCheckDelegate: class {
    func checkForFriendBeacons()
}

class FriendRequestTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var friendRequestsTableView: UITableView!
    
    var friendArray = [User]()
    weak var delegate: BeaconCheckDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib (nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        UserDefaults.standard.set(false, forKey: "newFriendRequest")
        
        // Remove Friends tab bar item badge
        if let tabItems = self.tabBarController?.tabBar.items {
            let tabItem = tabItems[2]
            tabItem.badgeValue = nil
        }
        
        friendArray.removeAll()
        
        let database = Database.database().reference()
        let currentID = Auth.auth().currentUser!.uid
        
        database.child("users").child(currentID).child("friend_requests").observeSingleEvent(of: .value, with: { (snapshot) in
             if let users = snapshot.value as? NSDictionary {
                for user in users {
                    let friendUid = user.key as! String
                    let friendDetails = user.value as! NSDictionary
                    
                    database.child("users").child(currentID).child("friend_requests").child(friendUid).child("read").setValue(true)
                    
                    self.friendArray.append(User(_friendcode: friendDetails["friend_code"] as! String, _nickname: friendDetails["nickname"] as! String, _fbuid: friendUid as String, _player_id: friendDetails["player_id"] as! String))
                    
                    self.friendRequestsTableView.reloadData()
                }
             }
             else {
                print("Couldn't fetch friend request 1")
            }
        })
        
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
        cell.nicknameLabel.text = friendArray[indexPath.row].nickname
        cell.friendcodeLabel.text = friendArray[indexPath.row].friendcode
        cell.userButton.setTitle("Confirm", for: UIControl.State.normal)
        cell.userButton.tag = indexPath.row
        cell.userButton.addTarget(self, action: #selector(confirmButtonPressed(_:)), for: UIControl.Event.touchUpInside)

        return cell
    }
    
    @objc func confirmButtonPressed(_ sender: UIButton) {
        let buttonRow = sender.tag
        
        sender.backgroundColor = UIColor.gray
        sender.isUserInteractionEnabled = false
        sender.setTitle("Confirmed", for: UIControl.State.normal)
        
        // Remove the friend request in Firebase
        let database = Database.database().reference()
        let currentID = Auth.auth().currentUser!.uid
        let friend = friendArray[buttonRow]
        let friendUid = friendArray[buttonRow].fbuid
        database.child("users").child(currentID).child("friend_requests").child(friendUid).removeValue()
        database.child("users").child(friendUid).child("sent_requests").child(currentID).removeValue()
        
        // Add the friend to the friends list of both users in Firebase
        database.child("users").child(currentID).child("friends").child(friendUid).setValue("true")
        database.child("users").child(friendUid).child("friends").child(currentID).setValue("true")
        
        var friendList = [User]()
        
        let userDefaults = UserDefaults.standard
        if let decoded = userDefaults.object(forKey: "FriendList") as? Data {
            friendList = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [User]
        }
        
        friendList.append(User(_friendcode: friendArray[buttonRow].friendcode, _nickname: friendArray[buttonRow].nickname, _fbuid: friendArray[buttonRow].fbuid, _player_id: friendArray[buttonRow].player_id))
        
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: friendList)
        userDefaults.set(encodedData, forKey: "FriendList")
        
        // Check for friend beacons
        database.child("users").child(friendUid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let details = snapshot.value as? Dictionary<String, Any> {
                // Create beacon object
                let beaconTitle = details["beacons"] as! String
                let newBeacon = Beacon(_gameTitle: beaconTitle, _owner: friendUid)
                
                // Create friend beacon in beacon table for current user
                let data = ["game" : beaconTitle, "nickname" : friend.nickname, "id" : newBeacon.id, "read" : false] as [String : Any]
                database.child("beacons").child(friendUid).child(currentID).setValue(data) { (error, ref) -> Void in
                    print("Created friend beacon for current user")
                    self.delegate?.checkForFriendBeacons()
                }
            }
            else {
                print("no active beacons for this new friend")
            }
        })
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Remove the friend request in Firebase
            let database = Database.database().reference()
            let currentID = Auth.auth().currentUser!.uid
            let friendUid = friendArray[indexPath.row].fbuid
            database.child("users").child(currentID).child("friend_requests").child(friendUid).removeValue()
            database.child("users").child(friendUid).child("sent_requests").child(currentID).removeValue()
            
            // Delete the row from the data source
            friendArray.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "No friend requests."
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 40)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "¯\\_(ツ)_/¯"
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Book", size: 20)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }

}
