//
//  AddFriendViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/2/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import InputMask

class AddFriendViewController: UIViewController, UITextFieldDelegate, MaskedTextFieldDelegateListener {
    
    @IBOutlet weak var nicknameTextfield: UITextField!
    @IBOutlet weak var friendcodeTextfield: UITextField!
    @IBOutlet weak var addFriendsLabel: UILabel!
    
    var maskedDelegate: MaskedTextFieldDelegate!
    var allUsers = [User]()
    var searchResults = [User]()
    let searchButton: UIBarButtonItem = UIBarButtonItem(title: "Search", style: UIBarButtonItem.Style.done, target: self, action: #selector(searchButtonAction))

    override func viewDidLoad() {
        super.viewDidLoad()
        
        nicknameTextfield.tintColor = UIColor.black
        friendcodeTextfield.tintColor = UIColor.black
        
        addSearchButtonOnKeyboard()
        
        // Set mask for testfield
        maskedDelegate = MaskedTextFieldDelegate(primaryFormat: "SW-[0000]-[0000]-[0000]")
        maskedDelegate.listener = self
        
        friendcodeTextfield.delegate = maskedDelegate
        
        // Set default text to "SW-"
        maskedDelegate.put(text: "SW-", into: friendcodeTextfield)
        
        nicknameTextfield.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addFriendsLabel.isHidden = true
    }
    
    // Checks if the mask was filled and enables the search button accordingly
    func textField(_ textField: UITextField, didFillMandatoryCharacters complete: Bool, didExtractValue value: String) {
        if complete {
            searchButton.isEnabled = true
        }
        else {
            searchButton.isEnabled = false
        }
    }
    
    // Add a search button to the numberpad keyboard for searching by friend code
    func addSearchButtonOnKeyboard() {
        let searchToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        searchToolbar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(searchButton)
        
        searchToolbar.items = items
        searchToolbar.sizeToFit()
        
        self.friendcodeTextfield.inputAccessoryView = searchToolbar
    }
    
    // Runs a search on friend code with the search button is pressed on the keyboard
    @objc func searchButtonAction() {
        friendcodeTextfield.resignFirstResponder()
        
        SVProgressHUD.show()
        
        Database.database().reference().child("users").queryOrdered(byChild: "friend_code").queryEqual(toValue: friendcodeTextfield.text).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.searchResults.removeAll()
            
            if let matchingUsers = snapshot.value as? Dictionary<String, Dictionary<String, Any>> {
                for user in matchingUsers {
                    if Auth.auth().currentUser!.uid != user.key {
                        self.searchResults.append(User(_friendcode: user.value["friend_code"] as? String ?? "Could not fetch friend code", _nickname: user.value["nickname"] as? String ?? "Could not fetch nickname", _fbuid: user.key, _player_id: user.value["player_id"]! as? String ?? "Could not fetch player_id"))
                    }
                }
            }
            
            SVProgressHUD.dismiss()
            
            if self.searchResults.isEmpty {
                self.addFriendsLabel.isHidden = false
            }
            else {
                self.addFriendsLabel.isHidden = true
                self.performSegue(withIdentifier: "goToSearchResults", sender: self)
            }
        })
    }
    
    // Runs a search on nickname with the search button is pressed on the keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        SVProgressHUD.show()
        
        Database.database().reference().child("users").queryOrdered(byChild: "nickname").queryEqual(toValue: textField.text).observeSingleEvent(of: .value, with: { (snapshot) in
            
            self.searchResults.removeAll()
            
            if let matchingUsers = snapshot.value as? Dictionary<String, Dictionary<String, Any>> {
                for user in matchingUsers {
                    if Auth.auth().currentUser!.uid != user.key {
                        self.searchResults.append(User(_friendcode: user.value["friend_code"] as? String ?? "Could not fetch friend code", _nickname: user.value["nickname"] as? String ?? "Could not fetch nickname", _fbuid: user.key, _player_id: user.value["player_id"] as? String ?? "Could not fetch player_id"))
                    }
                }
            }
            
            SVProgressHUD.dismiss()
            
            if self.searchResults.isEmpty {
                self.addFriendsLabel.isHidden = false
            }
            else {
                self.addFriendsLabel.isHidden = true
                self.performSegue(withIdentifier: "goToSearchResults", sender: self)
            }
        })
        
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.identifier == "goToSearchResults"
        {
            let destination = segue.destination as? SearchResultsTableViewController
            destination?.passedUserList = self.searchResults
        }
    }
}
