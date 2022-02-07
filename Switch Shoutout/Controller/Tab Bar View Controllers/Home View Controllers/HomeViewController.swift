//
//  HomeViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import Reachability
import Alamofire
import AlamofireImage
import OneSignal

enum GameListStatus {
    case noChange
    case adding
    case removing
    case redownloading
}

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BeaconDelegate, RedownloadDelegate, BeaconCheckDelegate {
    
    @IBOutlet weak var beaconLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var createBeaconButton: UIButton!
    @IBOutlet weak var yourCurrentBeaconLabel: UILabel!
    @IBOutlet weak var beaconTableView: UITableView!
    @IBOutlet weak var activeFriendBeaconsLabel: UILabel!
    @IBOutlet weak var currentBeaconStrip: UIView!
    @IBOutlet weak var backgroundBeaconImageView: UIImageView!
    
    
    lazy var database = Database.database().reference()
    lazy var currentUID = Auth.auth().currentUser!.uid
    var gameArray = [Game]()
    var loadCount = 0
    let reachability = Reachability()!
    var connected = false
    var beaconArray = [Beacon]()
    var failedToDownloadImages = false
    var didSetMyGames = false
    
    // Observer variables
    private var observerRefHandle: DatabaseHandle?
    private var removalObserverRefHandle: DatabaseHandle?
    private lazy var friendRef = Database.database().reference().child("users").child(currentUID).child("friend_requests")
    private lazy var beaconRef = Database.database().reference().child("beacons").child(currentUID)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show()
        
        checkForUpdatedPlayer_id()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveNotification(_:)), name: .didReceiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(checkForUpdatedPlayer_id), name: .didUpdateSubscription, object: nil)
        
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
        })
        
        print("View did load")
        
        beaconTableView.register(UINib (nibName: "BeaconTableViewCell", bundle: nil), forCellReuseIdentifier: "beaconCell")
        
        // Set HomeViewController as delegate for SettingsTableViewController for redownloading of games
        let settingsView = self.tabBarController?.viewControllers?[3].children[0] as! SettingsTableViewController
        settingsView.delegate = self
        
        // Set HomeViewController as delegate for FriendRequestTableViewController for checking friend beacons after adding new friends
        // Delegate method still not being called
        let friendRequestsView = self.storyboard?.instantiateViewController(withIdentifier: "friendRequestVC") as! FriendRequestTableViewController
        friendRequestsView.delegate = self
        
        //checkRegistration()
        
        setUIElements()
        
        runReachability()
        
        fetchUserInfo()
        
        getFriendList()
        
        checkForBeacon()
        
        //createObservers()
        
        checkForGameListChanges(completionHandler: { status in
            
            switch status! {
            case .noChange:
                print("case no change")
                self.checkForFriendBeacons()
                self.setMyGames()
            default:
                self.updateGameList(status: status!)
                SVProgressHUD.show(withStatus: "Updating Game List...")
            }
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        viewBeacons()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return beaconArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "beaconCell", for: indexPath) as! BeaconTableViewCell
        
        cell.userLabel.text = beaconArray[indexPath.row].owner
        cell.gameLabel.text = beaconArray[indexPath.row].gameTitle
        
        let userDefaults = UserDefaults.standard
        if let decoded  = userDefaults.object(forKey: "AllGamesList") as? Data {
            var gameList = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Game]
            
            let game = gameList.filter {$0.title == beaconArray[indexPath.row].gameTitle}
            
            if game.isEmpty { // This would happen if a friend created a beacon for a game that the current user hasn't downloaded yet
                // Need to know what the game genre is - maybe add as an additional field for beacons in firebase, or have the game check to update default images on startup
                cell.gameImage.image = UIImage(named: "default")
                gameList.append(Game(_title: beaconArray[indexPath.row].gameTitle, _image: UIImage(named: "default")!))
                
                // Save to user defaults
                print("Saving new game to user defaults")
                let sortedGameList = gameList.sorted(by: { $0.title < $1.title })
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: sortedGameList)
                userDefaults.set(encodedData, forKey: "AllGamesList")
            }
            else {
                print(game[0].image)
                cell.gameImage.image = game[0].image
            }
        }
        else {
//            let alert = UIAlertController(title: "Slow Connection", message: "There appears to be a slow internet connection. Data will continue to be downloaded in the background.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(alert, animated: true)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.layer.backgroundColor = UIColor.clear.cgColor
        cell.contentView.backgroundColor = UIColor.clear
    }
    
    @objc func onDidReceiveNotification(_ notification: Notification) {
        if let data = notification.userInfo as? [String : Any] {
            if data["type"] as! String == "beacon" {
                self.tabBarController?.tabBar.items![0].badgeValue = "!"
                
                self.beaconArray.append(Beacon(_gameTitle: data["title"] as! String, _owner: data["nickname"] as! String, _id: data["id"] as! Int))
                print("appended beacon from notification center listener")
                
                print("reloading table data from notification center listener")
                self.beaconTableView.reloadData()
            }
            else if data["type"] as! String == "beacon_removed" {
                self.beaconArray = self.beaconArray.filter { $0.id != data["id"] as! Int }
                print("removed beacon from notification center listener")
                
                print("reloading table data from notification center listener")
                self.beaconTableView.reloadData()
            }
            else if data["type"] as! String == "friend_request" {
                self.tabBarController?.tabBar.items![2].badgeValue = "!"
            }
        }
    }
    
    @objc func checkForUpdatedPlayer_id() {
        if UserDefaults.standard.bool(forKey: "player_idWasUpdated") {
            let decodedplayer_id = UserDefaults.standard.object(forKey: "player_id") as! Data
            let player_id = NSKeyedUnarchiver.unarchiveObject(with: decodedplayer_id) as! String
            
            // Set the player_id in firebase
            database.child("users").child(Auth.auth().currentUser!.uid).child("player_id").setValue(player_id)
            
            UserDefaults.standard.set(false, forKey: "player_idWasUpdated")
            
            print("Set player_id in firebase: \(player_id)")
        }
    }
    
    func setUIElements() {
        createBeaconButton.titleLabel?.minimumScaleFactor = 0.5
        createBeaconButton.titleLabel?.numberOfLines = 1
        createBeaconButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        createBeaconButton.contentVerticalAlignment = .top
        createBeaconButton.titleEdgeInsets = UIEdgeInsets.init(top: 20.0, left: 10.0, bottom: 0.0, right: 10.0)
        
        beaconLabel.transform = CGAffineTransform(rotationAngle: -CGFloat.pi / 32)
        
        beaconLabel.isHidden = true
        yourCurrentBeaconLabel.isHidden = true
        removeButton.isHidden = true
        createBeaconButton.isHidden = true
        activeFriendBeaconsLabel.isHidden = true
        currentBeaconStrip.isHidden = true
    }
    
    func runReachability() {
        reachability.whenReachable = { reachability in
            if reachability.connection == .wifi {
                print("Reachable via WiFi")
            } else {
                print("Reachable via Cellular")
            }
            
            if !self.connected {
                self.dismiss(animated: true, completion: nil)
            }
            
            self.connected = true
            
        }
        reachability.whenUnreachable = { _ in
            //SVProgressHUD.dismiss()
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
    
    // Download user email, friend code, and nickname and save to user defaults if it doesn't already exist
    func fetchUserInfo() {
        if UserDefaults.standard.object(forKey: "Email") == nil {
            print("No user data present in user defaults. Downloading now.")
            let userDefaults = UserDefaults.standard
            let currentUser = Auth.auth().currentUser!
            
            var encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: currentUser.email!)
            userDefaults.set(encodedData, forKey: "Email")
            
            let database = Database.database().reference()
            database.child("users").child(currentUser.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                if let details = snapshot.value as? Dictionary<String, Any> {
                    let friendCode = details["friend_code"] as? String ?? "SW-0000-0000-0000"
                    let nickname = details["nickname"] as? String ?? "nickname"
                    
                    encodedData = NSKeyedArchiver.archivedData(withRootObject: friendCode)
                    userDefaults.set(encodedData, forKey: "FriendCode")
                    
                    encodedData = NSKeyedArchiver.archivedData(withRootObject: nickname)
                    userDefaults.set(encodedData, forKey: "Nickname")
                }
            })
        }
        else {
            print("user info already saved in user defaults")
        }
    }
    
//    func createObservers() {
//
//        // Friend request observer
//        let friendRequestQuery = friendRef.queryOrdered(byChild: "read").queryEqual(toValue: false)
//        observerRefHandle = friendRequestQuery.observe(.childAdded, with: { (snapshot) in
//
//        })
//    }
    
    func viewBeacons() {
        // Remove Home tab bar item badge
        if let tabItems = self.tabBarController?.tabBar.items {
            let tabItem = tabItems[0]
            tabItem.badgeValue = nil
        }
        
        // Mark beacon as read
        let database = Database.database().reference()
        let currentID = Auth.auth().currentUser!.uid
        
        database.child("beacons").child(currentID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let beacons = snapshot.value as? NSDictionary {
                if self.removalObserverRefHandle != nil {
                    self.beaconRef.removeObserver(withHandle: self.removalObserverRefHandle!)
                }
                
                for beacon in beacons {
                    let friendUid = beacon.key as! String
                    database.child("beacons").child(currentID).child(friendUid).child("read").setValue(true) { (error, ref) -> Void in
                        if let error = error {
                            print("Error setting \(friendUid)'s beacon to read: \(error.localizedDescription)")
                        }
                    }
                }
            }
            else {
                print("Didn't find any beacons")
            }
        })
    }
    
    func getFriendList() {
        var friendArray = [User]()
        let currentID = Auth.auth().currentUser!.uid
        let userDefaults = UserDefaults.standard

        self.database.child("users").child(currentID).child("friends").observeSingleEvent(of: .value, with: { (snapshot) in
            var i = 0
            
            if snapshot.exists() {
                // Fill array of current friends
                if let friends = snapshot.value as? NSDictionary {
                    for friend in friends {
                        //uidArray.append(friend.key as! String)
                        
                        // Get friend details
                        self.database.child("users").child(friend.key as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                            if let details = snapshot.value as? Dictionary<String, Any> {
                                friendArray.append(User(_friendcode: details["friend_code"]! as! String, _nickname: details["nickname"]! as! String, _fbuid: friend.key as! String, _player_id: details["player_id"] as? String ?? "none"))
                            }
                            
                            if i == friends.count - 1 {
                                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: friendArray)
                                userDefaults.set(encodedData, forKey: "FriendList")
                            }
                            
                            i += 1
                        })
                    }
                }
            }
            
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    // Called after returning from Choose A Game to update beacon
    func setBeacon(beacon: Game) {
        if !beacon.title.isEmpty {
            beaconLabel.font = beaconLabel.font.withSize(150)
            beaconLabel.text = beacon.title
            beaconLabel.fitToAvoidWordWrapping()
            
            beaconLabel.isHidden = false
            yourCurrentBeaconLabel.isHidden = false
            removeButton.isHidden = false
            createBeaconButton.isHidden = true
            activeFriendBeaconsLabel.isHidden = false
            currentBeaconStrip.isHidden = false
            backgroundBeaconImageView.image = beacon.image
        }
        else {
            beaconLabel.isHidden = true
            yourCurrentBeaconLabel.isHidden = true
            removeButton.isHidden = true
            createBeaconButton.isHidden = false
            activeFriendBeaconsLabel.isHidden = false
            currentBeaconStrip.isHidden = true
            backgroundBeaconImageView.image = nil
        }
    }
    
    func checkForBeacon() {
                
        let userDefaults = UserDefaults.standard
        guard let decodedBeacon = userDefaults.object(forKey: "CurrentBeacon") as? Data else {
            print("didn't find current beacon")
            beaconLabel.isHidden = true
            yourCurrentBeaconLabel.isHidden = true
            removeButton.isHidden = true
            createBeaconButton.isHidden = false
            activeFriendBeaconsLabel.isHidden = false
            currentBeaconStrip.isHidden = true
            backgroundBeaconImageView.image = nil
            
            return
        }
        
        print("found current beacon")
        let currentBeacon = NSKeyedUnarchiver.unarchiveObject(with: decodedBeacon) as! Beacon
        
        beaconLabel.font = beaconLabel.font.withSize(150)
        beaconLabel.text = currentBeacon.gameTitle
        beaconLabel.fitToAvoidWordWrapping()
        
        beaconLabel.isHidden = false
        yourCurrentBeaconLabel.isHidden = false
        removeButton.isHidden = false
        createBeaconButton.isHidden = true
        activeFriendBeaconsLabel.isHidden = false
        currentBeaconStrip.isHidden = false
        
        if let decodedBeaconImage = userDefaults.object(forKey: "CurrentBeaconImage") as? Data {
            backgroundBeaconImageView.image = NSKeyedUnarchiver.unarchiveObject(with: decodedBeaconImage) as? UIImage
        }
    }
    
    func checkForFriendBeacons() {
        beaconArray.removeAll()
        
        print("Flag 1")
        
        database.child("beacons").child(currentUID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let friendBeacons = snapshot.value as? Dictionary<String, Dictionary<String, Any>> {
                for beacon in friendBeacons {
                    self.beaconArray.append(Beacon(_gameTitle: beacon.value["game"]! as! String, _owner: beacon.value["nickname"]! as! String, _id: beacon.value["id"]! as! Int))
                    print("appended beacon")
                }
            }
            else {
                print("no active friend beacons")
            }
            print("Reloading data 1")
            self.beaconTableView.reloadData()
            SVProgressHUD.dismiss()
        })
    }
    
//    // Check if user completed registration
//    func checkRegistration() {
//        if !UserDefaults.standard.bool(forKey: "CompletedRegistration") {
//            let alert = UIAlertController(title: "Whoops!", message: "Looks like you weren't able to set your friend code and nickname during registration. You can set them at any time by navigating to the settings menu.", preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//            self.present(alert, animated: true)
//            //UserDefaults.standard.set(true, forKey: "CompletedRegistration")
//        }
//    }
    
    @IBAction func createBeaconPressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "No games added!", message: "You must add a game before you can create a beacon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        let userDefaults = UserDefaults.standard
        guard let decoded  = userDefaults.object(forKey: "MyGamesList") as? Data else {
            self.present(alert, animated: true)
            print("No user default data for my games")
            return
        }
        
        let myGameArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Game]
        
        if myGameArray.isEmpty {
            self.present(alert, animated: true)
            print("my games list is empty")
        }
        else {
            let userDefaults = UserDefaults.standard
            if userDefaults.object(forKey: "MyGamesList") == nil {
                let alert = UIAlertController(title: "Thou shall not pass", message: "You cannot have more than 1 active beacon at a time.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true)
            }
            else {
                self.performSegue(withIdentifier: "goToChooseAGame", sender: nil)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? ChooseAGameTableViewController {
            destination.delegate = self
        }
    }
    
    @IBAction func removeButtonPressed(_ sender: Any) {
        var friend_player_ids = [String]()
        
        self.database.child("users").child(currentUID).child("beacons").removeValue()
        
        let userDefaults = UserDefaults.standard
        
        if let decodedBeacon = userDefaults.object(forKey: "CurrentBeacon") as? Data {
            let beacon = NSKeyedUnarchiver.unarchiveObject(with: decodedBeacon) as! Beacon
            
            // Remove beacon and image in user defaults
            userDefaults.removeObject(forKey: "CurrentBeacon")
            userDefaults.removeObject(forKey: "CurrentBeaconImage")
            
            // Remove beacon in friends' beacon lists
            if let decoded = userDefaults.object(forKey: "FriendList") as? Data {
                // Set value in beacons table for notifications
                if let friendArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [User] {
                    for friend in friendArray {
                        database.child("beacons").child(friend.fbuid).child(currentUID).removeValue()
                        friend_player_ids.append(friend.player_id)
                    }
                    
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
                else {
                    print("No friends in friend array")
                }
            }
            else {
                print("No friend array in user defaults")
            }
            
            beaconLabel.text = "None"
            beaconLabel.isHidden = true
            yourCurrentBeaconLabel.isHidden = true
            removeButton.isHidden = true
            createBeaconButton.isHidden = false
            currentBeaconStrip.isHidden = true
            backgroundBeaconImageView.image = nil
        }
    }
    
    //
    //
    //
    //
    // -----------------------------Game List Update Functions---------------------------
    //
    //
    //
    //
    
    func checkForGameListChanges(completionHandler: @escaping (GameCountClosure)) {
        
        var currentGameCount = 0
        
        let userDefaults = UserDefaults.standard
        if let decoded  = userDefaults.object(forKey: "AllGamesList") as? Data {
            let gameList = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Game]
            currentGameCount = gameList.count
        }
        
        self.database.child("games").observeSingleEvent(of: .value, with: { (snapshot) in
            var status: GameListStatus
            
            if snapshot.childrenCount == currentGameCount {
                status = GameListStatus.noChange
                completionHandler(status)
            }
            else if snapshot.childrenCount > currentGameCount {
                //UserDefaults.standard.set(snapshot.childrenCount, forKey: "currentGameCount")
                print("New games are available and will be downloaded")
                status = GameListStatus.adding
                completionHandler(status)
            }
            else {
                print("1 or more games were deleted and will be removed from user defaults")
                //UserDefaults.standard.set(snapshot.childrenCount, forKey: "currentGameCount")
                status = GameListStatus.removing
                completionHandler(status)
            }
        }) { (error) in
            print(error.localizedDescription)
        }
    }
    
    func updateGameList(status: GameListStatus) {
        print("updating game list")
        
        var finalGameDictionary = Dictionary<String, String>()
        
        pullGameDictionary() { gameDictionary, currentBeacon in
            
            finalGameDictionary = gameDictionary as! Dictionary<String, String>
            
            let userDefaults = UserDefaults.standard
            
            // Check if a game list already exists in user defaults
            var allGamesList = [Game]()
            var myGamesList = [Game]()
            
            if let allGamesDecoded = userDefaults.object(forKey: "AllGamesList") as? Data {
                allGamesList = NSKeyedUnarchiver.unarchiveObject(with: allGamesDecoded) as! [Game]
            }
            
            if let myGamesDecoded = userDefaults.object(forKey: "MyGamesList") as? Data {
                myGamesList = NSKeyedUnarchiver.unarchiveObject(with: myGamesDecoded) as! [Game]
            }
            
            switch status {
                
            case .adding:
                
                // In the list of games to add, remove the games that already exist in user defaults so we don't wind up with duplicate games
                if userDefaults.object(forKey: "AllGamesList") != nil {
                    for game in allGamesList {
                        for item in finalGameDictionary {
                            if game.title == item.key {
                                finalGameDictionary.removeValue(forKey: item.key)
                            }
                        }
                    }
                }
                
                // Pull in game images and append the games
                var i = 0
                
                for (title, genre) in finalGameDictionary {
                    
                    var gameImage = UIImage()
                    
                    Alamofire.request(genre, method: .get).responseImage { response in
                        if let image = response.result.value {
                            print("got image!")
                            gameImage = image
                        }
                        else {
                            gameImage = UIImage(named: "default")!
                            print("didn't get image")
                        }
                        
                        self.gameArray.append(Game(_title: title, _image: gameImage))
                        print("Appended game: " + title)
                        
                        if i == (finalGameDictionary.count - 1) {
                            self.setNewGames()
                            self.checkForFriendBeacons()
                        }
                        
                        i += 1
                    }
                }
                
            case .removing:
                var index = 0
                
                for game in allGamesList {
                    if finalGameDictionary[game.title] == nil {
                        // Remove the game from allGamesList
                        let deletedGameTitle = allGamesList.remove(at: index).title
                        print("deletedGameTitle: \(deletedGameTitle)")
                        
                        // Remove the game from myGamesList
                        if (!myGamesList.isEmpty) {
                            myGamesList = myGamesList.filter {$0.title != deletedGameTitle}
                        }
                        
                        // Remove the game from the user's games in Firebase
                        let userID = Auth.auth().currentUser!.uid
                        self.database.child("users").child(userID).child("games").child(deletedGameTitle).removeValue()
                        
                        // Remove beacon if it matches a game that is getting deleted
                        if currentBeacon == deletedGameTitle {
                            
                            self.database.child("users").child(self.currentUID).child("beacons").removeValue()
                            
                            userDefaults.removeObject(forKey: "CurrentBeacon")
                            self.beaconLabel.text = "None"
                            self.beaconLabel.isHidden = true
                            self.yourCurrentBeaconLabel.isHidden = true
                            self.removeButton.isHidden = true
                            self.createBeaconButton.isHidden = false
                            self.currentBeaconStrip.isHidden = true
                            
                            self.checkForFriendBeacons()
                            
                            // Remove beacon from friends' beacon list
                            if let decoded = userDefaults.object(forKey: "FriendList") as? Data {
                                if let friendArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as? [User] {
                                    for friend in friendArray {
                                        self.database.child("beacons").child(friend.fbuid).child(self.currentUID).removeValue()
                                    }
                                }
                                else {
                                    print("No friends in friend array")
                                }
                            }
                            else {
                                print("No friend array in user defaults")
                            }
                        }
                    }
                    index += 1
                }
                
                let myGamesEncodedData: Data = NSKeyedArchiver.archivedData(withRootObject: myGamesList)
                userDefaults.set(myGamesEncodedData, forKey: "MyGamesList")
                
                let allGamesEncodedData: Data = NSKeyedArchiver.archivedData(withRootObject: allGamesList)
                userDefaults.set(allGamesEncodedData, forKey: "AllGamesList")
                
                SVProgressHUD.dismiss()
                
            case .redownloading:
                self.gameArray.removeAll()
                
                // Pull in game images and append the games
                var i = 0
                
                for (title, genre) in finalGameDictionary {
                    
                    var gameImage = UIImage()
                    
                    Alamofire.request(genre, method: .get).responseImage { response in
                        if let image = response.result.value {
                            print("got image!")
                            gameImage = image
                        }
                        else {
                            gameImage = UIImage(named: "default")!
                            print("didn't get image")
                        }
                        
                        self.gameArray.append(Game(_title: title, _image: gameImage))
                        print("Appended game: " + title)
                        
                        if i == (finalGameDictionary.count - 1) {
                            self.setNewGames()
                            self.checkForFriendBeacons()
                        }
                        
                        i += 1
                    }
                }
                
            default:
                print("This shouldn't appear!")
                self.checkForFriendBeacons()
            }
        }
    }
    
    func pullGameDictionary(completionHandler: @escaping (GameDictionaryClosure)) {
        
        self.database.child("games").observeSingleEvent(of: .value, with: { (snapshot) in
            if let gameDictionary = snapshot.value as? NSDictionary {
                
                // Grab the current beacon in case it needs to be removed in the event that the game is being removed
                let userDefaults = UserDefaults.standard
                if let decodedBeacon = userDefaults.object(forKey: "CurrentBeacon") as? Data {
                    let currentBeacon = NSKeyedUnarchiver.unarchiveObject(with: decodedBeacon) as! Beacon
                    completionHandler(gameDictionary, currentBeacon.gameTitle)
                }
                else {
                    completionHandler(gameDictionary, nil)
                }
            }
        }) { (error) in
            print("Error getting dictionary: " + error.localizedDescription)
        }
    }
    
    // Push game list to user defaults
    func setNewGames() {
        let userDefaults = UserDefaults.standard
        
        if userDefaults.object(forKey: "AllGamesList") != nil { // If the list exists, pull it, append to it, and push it
            let decoded  = userDefaults.object(forKey: "AllGamesList") as! Data
            var gameList = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Game]
            
            gameList.append(contentsOf: gameArray)
            
            let sortedGameList = gameList.sorted(by: { $0.title < $1.title })
            
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: sortedGameList)
            userDefaults.set(encodedData, forKey: "AllGamesList")
            
            setMyGames()
        }
        else { // If the list doesn't exist, create and push it
            let sortedGameList = self.gameArray.sorted(by: { $0.title < $1.title })
            
            let userDefaults = UserDefaults.standard
            let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: sortedGameList)
            userDefaults.set(encodedData, forKey: "AllGamesList")
            
            setMyGames()
        }
    }
    
    // Assigns user's added games in firebase to user defaults
    func setMyGames() {
        let userDefaults = UserDefaults.standard
        
        self.database.child("users").child(currentUID).child("games").observeSingleEvent(of: .value, with: { (snapshot) in
            if let myGames = snapshot.value as? NSDictionary {
                var myGameArray = [Game]()
                
                if let decoded  = userDefaults.object(forKey: "AllGamesList") as? Data {
                    let gameArray = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! [Game]
                    
                    for (title, _) in myGames {
                        var temp = gameArray.filter {$0.title == title as! String}
                        if  !temp.isEmpty {
                            myGameArray.append(temp[0])
                        }
                    }
                    myGameArray = myGameArray.sorted(by: { $0.title < $1.title })
                    
                    let encodedData = NSKeyedArchiver.archivedData(withRootObject: myGameArray)
                    userDefaults.set(encodedData, forKey: "MyGamesList")
                }
                else {
                    print("Warning Will Robinson! AllGamesList does not exist!")
                    
                    let alert = UIAlertController(title: "Whoops!", message: "The list of all games is empty. You might see this if you've attempted to redownload games from the settings menu on a slow internet connection. If that's the case, navigate back to this screen in a little bit and it should be populated. Otherwise, please restart the app or tap 'Redownload Games' in the settings menu to repopulate the list of games.", preferredStyle: .alert)
                    
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    
                    self.present(alert, animated: true)
                }
                
            }
            else {
                print("No games in Firebase")
            }
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
}
