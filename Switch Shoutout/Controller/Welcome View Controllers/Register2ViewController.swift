//
//  Register2ViewController.swift
//  Switch Shoutout
//
//  Created by Aguirre, Brian P. on 6/8/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import InputMask

class Register2ViewController: UIViewController, MaskedTextFieldDelegateListener, UITextFieldDelegate {

    @IBOutlet weak var registration2Label: UILabel!
    @IBOutlet weak var friendcodeTextfield: UITextField!
    @IBOutlet weak var nicknameTextfield: UITextField!
    @IBOutlet weak var registrationButton: UIButton!
    
    var friendcodeIsComplete = false
    var maskedDelegate: MaskedTextFieldDelegate!
    let nextButton: UIBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItem.Style.done, target: self, action: #selector(nextButtonAction))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = true
        
        addNextButtonOnKeyboard()

        friendcodeTextfield.becomeFirstResponder()
        
        registrationButton.isEnabled = false
        
        friendcodeTextfield.delegate = self
        nicknameTextfield.delegate = self
        
        nicknameTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
        
        // Set mask for testfield
        maskedDelegate = MaskedTextFieldDelegate(primaryFormat: "SW-[0000]-[0000]-[0000]")
        maskedDelegate.listener = self
        
        friendcodeTextfield.delegate = maskedDelegate
        
        // Set default text to "SW-"
        maskedDelegate.put(text: "SW-", into: friendcodeTextfield)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        formFilledCheck()
    }
    
    @objc func textDidChange(textField: UITextField) {
        formFilledCheck()
    }
    
    // Checks if the mask was filled
    func textField(_ textField: UITextField, didFillMandatoryCharacters complete: Bool, didExtractValue value: String) {
        if complete {
            friendcodeIsComplete = true
            nextButton.isEnabled = true
            if !(nicknameTextfield.text?.isEmpty)! {
                registrationButton.isEnabled = true
            }
        }
        else {
            nextButton.isEnabled = false
            friendcodeIsComplete = false
            registrationButton.isEnabled = false
        }
    }
    
    // Add a next button to the numberpad keyboard
    func addNextButtonOnKeyboard() {
        let nextToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 320, height: 50))
        nextToolbar.barStyle = UIBarStyle.default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        
        var items = [UIBarButtonItem]()
        items.append(flexSpace)
        items.append(nextButton)
        
        nextToolbar.items = items
        nextToolbar.sizeToFit()
        
        self.friendcodeTextfield.inputAccessoryView = nextToolbar
    }
    
    @objc func nextButtonAction() {
        // Shift focus to the username textfield
        friendcodeTextfield.superview?.viewWithTag(1)?.becomeFirstResponder()
    }
    
    func formFilledCheck() {
        if friendcodeIsComplete && !(nicknameTextfield.text?.isEmpty)! {
            registrationButton.isEnabled = true
        }
        else {
            registrationButton.isEnabled = false
        }
    }
    
    // Used to navigate to the next text field in the chain
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        
        // Try to find next responder
        let nextResponder = textField.superview?.viewWithTag(nextTag)
        
        if nextResponder != nil {
            // Found next responder, so set it
            nextResponder?.becomeFirstResponder()
        } else {
            // Not found, so attempt to complete registration
            registerButtonPressed(self)
        }
        
        return false
    }
    
    @IBAction func registerButtonPressed(_ sender: Any) {
        
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show()
        
        let database = Database.database().reference()
        
        // Set friend code and nickname in firebase
        database.child("users").child(Auth.auth().currentUser!.uid).child("friend_code").setValue(friendcodeTextfield.text)
        database.child("users").child(Auth.auth().currentUser!.uid).child("nickname").setValue(nicknameTextfield.text)
        
        // Set friend code and nickname in user defaults
        let userDefaults = UserDefaults.standard
        var encodedData = NSKeyedArchiver.archivedData(withRootObject: friendcodeTextfield.text ?? "SW-0000-0000-0000")
        userDefaults.set(encodedData, forKey: "FriendCode")
        
        encodedData = NSKeyedArchiver.archivedData(withRootObject: nicknameTextfield.text ?? "nickname")
        userDefaults.set(encodedData, forKey: "Nickname")
        
        if let user = Auth.auth().currentUser {
            let changeRequest = user.createProfileChangeRequest()
            
            changeRequest.displayName = self.nicknameTextfield.text
            changeRequest.commitChanges { error in
                if let error = error {
                    print(error)
                } else {
                    print("updated displayName!")
                }
            }
        }
        
        //userDefaults.set(true, forKey: "CompletedRegistration")
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "homeVC")
        
        UIApplication.shared.keyWindow?.setRootViewController(viewController)
    }
}
