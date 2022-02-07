//
//  ChooseAGameTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/18/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import OneSignal

protocol BeaconDelegate: class {
    func setBeacon(beacon: Game)
}

class ChooseAGameTableViewController: UITableViewController {
    
    @IBOutlet var chooseAGameTableView: UITableView!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    var myGamesList = [Game]()
    var selectedGame = Game()
    weak var delegate: BeaconDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        chooseAGameTableView.register(UINib (nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "gameCell")
        
        doneButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        
        let userDefaults = UserDefaults.standard
        
        let decodedMyGames = userDefaults.object(forKey: "MyGamesList") as! Data
        myGamesList = NSKeyedUnarchiver.unarchiveObject(with: decodedMyGames) as! [Game]
        
        chooseAGameTableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myGamesList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameCell", for: indexPath) as! GameTableViewCell

        cell.cellImage.image = myGamesList[indexPath.row].image
        cell.cellLabel.text = myGamesList[indexPath.row].title
        
        if selectedGame.title == myGamesList[indexPath.row].title {
            cell.cellBackground.image = #imageLiteral(resourceName: "cell_background_2_selected")
        }
        else {
            cell.cellBackground.image = #imageLiteral(resourceName: "cell_background")
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GameTableViewCell {
            cell.cellBackground.image = #imageLiteral(resourceName: "cell_background_2_selected")
        }
        
        doneButton.isEnabled = true
        selectedGame.title = myGamesList[indexPath.row].title
        selectedGame.image = myGamesList[indexPath.row].image
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GameTableViewCell {
            cell.cellBackground.image = #imageLiteral(resourceName: "cell_background")
        }
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        
        let userDefaults = UserDefaults.standard
        let database = Database.database().reference()
        let userID = Auth.auth().currentUser!.uid
        var friend_player_ids = [String]()
        var nickname = ""
        
        if let decodedNickname = userDefaults.object(forKey: "Nickname") as? Data {
            nickname = NSKeyedUnarchiver.unarchiveObject(with: decodedNickname) as! String
        }
        
        // Set own value for beacon
        database.child("users").child(userID).child("beacons").setValue(selectedGame.title)
        let beacon = Beacon(_gameTitle: selectedGame.title, _owner: nickname)
        print(beacon.gameTitle + ", " + beacon.owner)
        
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: beacon)
        userDefaults.set(encodedData, forKey: "CurrentBeacon")
        
        let encodedData2: Data = NSKeyedArchiver.archivedData(withRootObject: selectedGame.image)
        userDefaults.set(encodedData2, forKey: "CurrentBeaconImage")
        
        // Set beacon for HomeViewController
        delegate?.setBeacon(beacon: selectedGame)
        
        if let decoded = userDefaults.object(forKey: "FriendList") as? Data {
            // Set value in beacons table for in-app badges
            if let friendArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [User] {
                for friend in friendArray {
                    let data = ["game" : selectedGame.title, "nickname" : Auth.auth().currentUser!.displayName!, "id" : beacon.id, "read" : false] as [String : Any]
                    database.child("beacons").child(friend.fbuid).child(userID).setValue(data)
                    
                    friend_player_ids.append(friend.player_id)
                }
                
                let content = [
                    "contents": ["en": "\(nickname) wants to play \(selectedGame.title)."],
                    "headings": ["en": "Incoming Beacon!"],
                    "content_available": true,
                    "data": ["type": "beacon", "nickname": beacon.owner, "title": beacon.gameTitle, "id": beacon.id],
                    "include_player_ids": friend_player_ids
                    ] as [String : Any]
                
                // Send OneSignal notification to all friends
                OneSignal.postNotification(content, onSuccess: { (result) in
                    print("successful notification!")
                }, onFailure: { (error) in
                    print("failed notification: \(String(describing: error))")
                })
                
                print("sent beacon to \(friend_player_ids)")
            }
        }
        else {
            print("No friend array in user defaults")
        }
        
        
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
    }

}
