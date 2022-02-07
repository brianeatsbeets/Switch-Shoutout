//
//  MyGamesTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet

// Protocol to facilitate passing of the game list array between MyGamesTableViewController and AddGamesTableViewController
protocol AddGamesDelegate {
    func passDataBack(data: [Game])
}

class MyGamesTableViewController: UITableViewController, AddGamesDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet var myGamesTableView: UITableView!
    
    var allGamesList = [Game]()
    var myGamesList = [Game]()
    var editPressed = false
    var comingFromAddGames = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myGamesTableView.register(UINib (nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "gameCell")
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        if (!comingFromAddGames) {
            let userDefaults = UserDefaults.standard
            if let decodedMyGames = userDefaults.object(forKey: "MyGamesList") as? Data {
                myGamesList = NSKeyedUnarchiver.unarchiveObject(with: decodedMyGames) as! [Game]
            }
            
            if let decodedAllGames = userDefaults.object(forKey: "AllGamesList") as? Data {
                allGamesList = NSKeyedUnarchiver.unarchiveObject(with: decodedAllGames) as! [Game]
            }
        }
        
        myGamesTableView.reloadData()
        comingFromAddGames = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        editPressed = false
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if(!editPressed) {
            DispatchQueue.global().async {
                let userDefaults = UserDefaults.standard
                let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: self.myGamesList)
                userDefaults.set(encodedData, forKey: "MyGamesList")
            }
        }
        else {
            editPressed = false
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Nothing's here..."
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 40)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Tap Edit to add games that you own."
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Book", size: 20)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    @IBAction func editButtonPressed(_ sender: Any) {
        editPressed = false
        performSegue(withIdentifier: "goToEditGames", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "goToEditGames"
        {
            let destination = segue.destination as? AddGamesTableViewController
            destination?.delegate = self
            destination?.passedGameList = self.myGamesList
            print("Sending to Add Games:")
            for game in myGamesList {
                print(game.title)
            }
        }
    }
    
    func passDataBack(data: [Game]) {
        myGamesList = data
        comingFromAddGames = true
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
        cell.cellLabel.font = cell.cellLabel.font.withSize(19)
        cell.cellLabel.text = myGamesList[indexPath.row].title
        cell.cellLabel.fitToAvoidWordWrapping()
        
        cell.selectionStyle = .none

        return cell
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from myGamesList
            let deletedGameTitle = myGamesList[indexPath.row].title
            myGamesList = myGamesList.filter {$0.title != deletedGameTitle}
            
            let database = Database.database().reference()
            let userID = Auth.auth().currentUser?.uid
            database.child("users").child(userID!).child("games").child(deletedGameTitle).removeValue()
            
            // Delete the game from the user's games in Firebase
//            myGamesRoot.observeSingleEvent(of: .value, with: { (snapshot) in
//                if let myGames = snapshot.value as? NSDictionary {
//                    for (title, _) in myGames {
//                        if deletedGameTitle == title as! String {
//                            myGamesRoot.child(title as! String).removeValue()
//                            break
//                        }
//                    }
//                }
//                else {
//                    print("Unable to read my games from Firebase")
//                }
//            })
            
            // Remove the user's beacon if it matches the game being deleted
            let beaconsRoot = database.child("users").child(userID!).child("beacons")
            beaconsRoot.observeSingleEvent(of: .value, with: { (snapshot) in
                if let beacon = snapshot.value as? String {
                    if beacon == deletedGameTitle {
                        beaconsRoot.removeValue()
                    }
                }
            })
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
}
