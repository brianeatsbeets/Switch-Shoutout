//
//  ChangeFriendCodeViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/16/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import InputMask

class ChangeFriendCodeViewController: UIViewController, MaskedTextFieldDelegateListener {
    
    @IBOutlet weak var friendcodeTextfield: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var maskedDelegate: MaskedTextFieldDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 25))
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.font = UIFont(name: "Avenir-Heavy", size: 19)
        titleLabel.textColor = UIColor.white
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor=0.5;
        titleLabel.text = "Change Friend Code"
        
        self.navigationItem.titleView = titleLabel
        
        friendcodeTextfield.tintColor = UIColor.black
        friendcodeTextfield.becomeFirstResponder()
        
        // Set mask for testfield
        maskedDelegate = MaskedTextFieldDelegate(primaryFormat: "SW-[0000]-[0000]-[0000]")
        maskedDelegate.listener = self
        
        friendcodeTextfield.delegate = maskedDelegate
        
        // Set default text to "SW-"
        maskedDelegate.put(text: "SW-", into: friendcodeTextfield)
        
        // Disable Save button until field is completely filled
        saveButton.isEnabled = false
    }
    
    // Checks if the mask was filled
    func textField(_ textField: UITextField, didFillMandatoryCharacters complete: Bool, didExtractValue value: String) {
        if complete {
            saveButton.isEnabled = true
        }
        else {
            saveButton.isEnabled = false
        }
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        let database = Database.database().reference()
        database.child("users").child(Auth.auth().currentUser!.uid).child("friend_code").setValue(friendcodeTextfield.text)
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: friendcodeTextfield.text!)
        userDefaults.set(encodedData, forKey: "FriendCode")
        
        navigationController?.popViewController(animated: true)
    }
}
