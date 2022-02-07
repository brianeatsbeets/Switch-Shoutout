//
//  SearchResultsTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/2/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import OneSignal

class SearchResultsTableViewController: UITableViewController {
    
    var passedUserList = [User]()
    var currentFriends = [String]()
    var currentRequests = [String]()
    var currentNickname = ""
    var currentFriendcode = ""
    var currentplayer_id = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib (nibName: "UserTableViewCell", bundle: nil), forCellReuseIdentifier: "userCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let database = Database.database().reference()
        let currentID = Auth.auth().currentUser!.uid
        
        // Get current user nickname, friend code, and player_id
        database.child("users").child(currentID).observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            self.currentNickname = (value?["nickname"] as? String ?? "Could not fetch nickname")
            self.currentFriendcode = (value?["friend_code"] as? String ?? "Could not fetch friend code")
            self.currentplayer_id = (value?["player_id"] as? String ?? "Could not fetch player_id")
            //self.currentAvatar = (value?["avatar"] as? String ?? "avatar_blank")
        }) { (error) in
            print(error.localizedDescription)
        }
        
        // Fill array of current friends
        database.child("users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            if let friends = snapshot.value as? NSDictionary {
                for friend in friends {
                    self.currentFriends.append(friend.key as! String)
                    print("Added friend to currentFriends: " + (friend.key as! String))
                }
                
                self.tableView.reloadData()
            }
        }) { (error) in
            print(error.localizedDescription)
        }
        
        // Fill array of current requests
        database.child("users").child(currentID).child("sent_requests").observeSingleEvent(of: .value, with: { (snapshot) in
            if let requests = snapshot.value as? NSDictionary {
                for request in requests {
                    self.currentRequests.append(request.key as! String)
                    print("Added friend to currentRequests: " + (request.value as! String))
                }
                self.tableView.reloadData()
            }
            else {
                print("Sent requests = nil")
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return passedUserList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath) as! UserTableViewCell
        
        cell.nicknameLabel.text = passedUserList[indexPath.row].nickname
        cell.friendcodeLabel.text = passedUserList[indexPath.row].friendcode
        
        if currentRequests.contains(passedUserList[indexPath.row].fbuid) {
            cell.userButton.setTitle("Request Sent", for: UIControl.State.normal)
            cell.userButton.backgroundColor = UIColor.gray
            cell.userButton.isUserInteractionEnabled = false
        }
        else if currentFriends.contains(passedUserList[indexPath.row].fbuid) {
            cell.userButton.setTitle("Added", for: UIControl.State.normal)
            cell.userButton.backgroundColor = UIColor.gray
            cell.userButton.isUserInteractionEnabled = false
        }
        else {
            cell.userButton.setTitle("Add", for: UIControl.State.normal)
        }
        
        cell.userButton.tag = indexPath.row
        cell.userButton.addTarget(self, action: #selector(addButtonPressed(_:)), for: UIControl.Event.touchUpInside)
        
        cell.userButton.titleLabel?.numberOfLines = 1
        cell.userButton.titleLabel?.adjustsFontSizeToFitWidth = true
        cell.userButton.titleLabel?.lineBreakMode = NSLineBreakMode.byClipping
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.cellForRow(at: indexPath) != nil {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc func addButtonPressed(_ sender: UIButton) {
        print("Add button pressed")
        
        let buttonRow = sender.tag
        
        sender.setTitle("Request Sent", for: UIControl.State.normal)
        
        let database = Database.database().reference()
        let currentID = Auth.auth().currentUser!.uid 
        let uid = passedUserList[buttonRow].fbuid
        print("fbuid: " + uid)
        
        // Send user info
        database.child("users").child(uid).child("friend_requests").child(currentID).child("nickname").setValue(currentNickname)
        database.child("users").child(uid).child("friend_requests").child(currentID).child("friend_code").setValue(currentFriendcode)
        database.child("users").child(uid).child("friend_requests").child(currentID).child("player_id").setValue(currentplayer_id)
        database.child("users").child(uid).child("friend_requests").child(currentID).child("read").setValue(false)
        
        // Add request to sent requests
        database.child("users").child(currentID).child("sent_requests").child(uid).setValue("true")
        
        var nickname = "User"
        if let decodedNickname = UserDefaults.standard.object(forKey: "Nickname") as? Data {
            nickname = NSKeyedUnarchiver.unarchiveObject(with: decodedNickname) as! String
        }
        
        // Send push notification
        database.child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            if let value = snapshot.value as? Dictionary<String, Any> {
                if let player_id = value["player_id"] as? String {
                    let content = [
                        "contents": ["en": "\(nickname) sent you a friend request."],
                        "include_player_ids": [player_id],
                        "ios_badgeType": "Increase",
                        "ios_badgeCount": 1,
                        "data": ["type": "friend_request"]
                        ] as [String : Any]
                    OneSignal.postNotification(content, onSuccess: { (result) in
                        print("successful friend request notification!")
                    }, onFailure: { (error) in
                        print("failed friend request notification: \(String(describing: error))")
                    })
                }
            }
        })
        
        // Change button UI
        sender.setTitle("Request Sent", for: UIControl.State.normal)
        sender.backgroundColor = UIColor.gray
        sender.isUserInteractionEnabled = false
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
