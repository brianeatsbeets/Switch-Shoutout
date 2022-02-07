//
//  AddGamesTableViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/16/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import DZNEmptyDataSet

extension AddGamesTableViewController: UISearchResultsUpdating {
    // MARK: - UISearchResultsUpdating Delegate
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

class AddGamesTableViewController: UITableViewController, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet var addGamesTableView: UITableView!
    
    var passedGameList = [Game]() // Array of current My Games list passed from MyGamesTableViewController
    var allGamesList = [Game]()
    var filteredGames = [Game]() // Array of games filtered via search
    var delegate: AddGamesDelegate?
    var userID = "" // Given value in viewDidLoad due to Firebase not being configured this early
    let searchController = UISearchController(searchResultsController: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userID = Auth.auth().currentUser!.uid
        addGamesTableView.register(UINib (nibName: "GameTableViewCell", bundle: nil), forCellReuseIdentifier: "gameCell")
        
        self.tableView.emptyDataSetSource = self;
        self.tableView.emptyDataSetDelegate = self;
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Games"
        searchController.searchBar.tintColor = UIColor.white // Sets the color of the cancel text
        
        for textField in searchController.searchBar.subviews.first!.subviews where textField is UITextField {
            textField.subviews.first?.backgroundColor = .white
            textField.subviews.first?.layer.cornerRadius = 10.5
        }
        
        
        
        navigationItem.searchController = searchController
        definesPresentationContext = true

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.hidesBackButton = true
        
        let userDefaults = UserDefaults.standard
        if let decodedAllGames = userDefaults.object(forKey: "AllGamesList") as? Data {
            allGamesList = NSKeyedUnarchiver.unarchiveObject(with: decodedAllGames) as! [Game]
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            
            let database = Database.database().reference()
            let myGamesRoot = database.child("users").child(userID).child("games")
            var removedGames = [Game]()
            
            // Add my games to Firebase
            for game in self.allGamesList {
                let gameArray = passedGameList.filter {$0.title == game.title}
                if !gameArray.isEmpty {
                    myGamesRoot.child(game.title).setValue(true)
                }
                else {
                    // Remove my games from Firebase
                    myGamesRoot.observeSingleEvent(of: .value, with: { (snapshot) in
                        if let myGames = snapshot.value as? NSDictionary {
                            for (title, _) in myGames {
                                if game.title == title as! String {
                                    myGamesRoot.child(game.title).removeValue()
                                    removedGames.append(game)
                                }
                            }
                        }
                        else {
                            print("Unable to read my games from Firebase")
                        }
                    })
                    
                    // Remove the user's beacon if it is for any removed games
                    let beaconsRoot = database.child("users").child(userID).child("beacons")
                    beaconsRoot.observeSingleEvent(of: .value, with: { (snapshot) in
                        if let beacon = snapshot.value as? String {
                            for game in removedGames {
                                if beacon == game.title {
                                    beaconsRoot.removeValue()
                                    break
                                }
                            }
                        }
                    })
                }
            }
            
            // Update User Defaults
            let userDefaults = UserDefaults.standard
            let encodedData = NSKeyedArchiver.archivedData(withRootObject: passedGameList)
            userDefaults.set(encodedData, forKey: "MyGamesList")
            
            // Pass edited My Games list back to MyGamesTableViewController to be updated and displayed
            // Using protocols and delegates to pass data back is much faster than accessing and reading from user defaults
            passedGameList = passedGameList.sorted(by: { $0.title < $1.title })
            delegate?.passDataBack(data: passedGameList)
        }
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        filteredGames = allGamesList.filter({( game : Game) -> Bool in
            return game.title.lowercased().contains(searchText.lowercased())
        })
        
        tableView.reloadData()
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        var text = ""
        
        if isFiltering() {
            text = "No Results"
        }
        else {
            text = "Whoops!"
        }
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Heavy", size: 40)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        
        var text = ""
        
        if !isFiltering() {
            text = "The list of all games is empty. You might see this if you've attempted to redownload games from the settings menu on a slow internet connection. If that's the case, navigate back to this screen in a little bit and it should be populated. Otherwise, please restart the app or tap 'Redownload Games' in the settings menu to repopulate the list of games."
        }
        
        let paragraph = NSMutableParagraphStyle()
        
        paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
        paragraph.alignment = NSTextAlignment.center
        
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Avenir-Book", size: 20)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray, NSAttributedString.Key.paragraphStyle: paragraph] as [NSAttributedString.Key : Any]
        
        return NSAttributedString(string: text, attributes: attributes)
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredGames.count
        }
        
        return allGamesList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "gameCell", for: indexPath) as? GameTableViewCell
        
        var gameList = [Game]()
        
        if isFiltering() {
            gameList = filteredGames
        }
        else {
            gameList = allGamesList
        }
        
        cell?.cellImage.image = gameList[indexPath.row].image
        cell?.cellLabel.font = cell?.cellLabel.font.withSize(19)
        cell?.cellLabel.text = gameList[indexPath.row].title
        cell?.cellLabel.fitToAvoidWordWrapping()
        
        let gameTitle = gameList[indexPath.row].title
        let gameArray = passedGameList.filter {$0.title == gameTitle}
        
        cell?.cellBackground.image = #imageLiteral(resourceName: "cell_background")
        
        if !gameArray.isEmpty {
            cell?.checkCircle.isHidden = false
        }
        else {
            cell?.checkCircle.isHidden = true
        }

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GameTableViewCell{
            
            var gameList = [Game]()
            
            if isFiltering() {
                gameList = filteredGames
            }
            else {
                gameList = allGamesList
            }
            
            if cell.checkCircle.isHidden == false {
                cell.checkCircle.isHidden = true
                
                // Look for a game in My Games that has the same title as the game being removed
                passedGameList = passedGameList.filter {$0.title != gameList[indexPath.row].title}
            }
            else{
                cell.checkCircle.isHidden = false
                passedGameList.append(gameList[indexPath.row])
            }
        }
        
        tableView.deselectRow(at: indexPath, animated: false)
    }
}
