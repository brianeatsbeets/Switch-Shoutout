//
//  RegisterViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase
import SVProgressHUD
import OneSignal

class RegisterViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var registrationLabel: UILabel!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var password2Textfield: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    
    var friendCodeFilled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextfield.becomeFirstResponder()
        
        nextButton.isEnabled = false
        registrationLabel.isHidden = true
        
        emailTextfield.delegate = self
        passwordTextfield.delegate = self
        password2Textfield.delegate = self
        
        emailTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
        passwordTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
        password2Textfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    @objc func textDidChange(textField: UITextField) {
        if (emailTextfield.text?.isEmpty)! || (passwordTextfield.text?.isEmpty)! || (password2Textfield.text?.isEmpty)! {
            nextButton.isEnabled = false
        }
        else {
            nextButton.isEnabled = true
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
            // Not found, so attempt to create new account
            nextButtonPressed(self)
        }
        
        return false
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        if passwordTextfield.text != password2Textfield.text {
            registrationLabel.text = "Passwords do not match."
            registrationLabel.isHidden = false
        }
        else {
            SVProgressHUD.show()
            Auth.auth().createUser(withEmail: emailTextfield.text!, password: passwordTextfield.text!) {
                (user, error) in
                if error != nil {
                    print(error!.localizedDescription)
                    
                    if let errorCode = AuthErrorCode(rawValue: error!._code) {
                        switch errorCode {
                        case .invalidEmail:
                            self.registrationLabel.text = "Invalid email."
                        case .emailAlreadyInUse:
                            self.registrationLabel.text = "Email is already in use."
                        case .weakPassword:
                            self.registrationLabel.text = "Password must be at least 6 characters long."
                        default:
                            self.registrationLabel.text = "Error creating account. If your issue persists, please contact 123@test.com to report a problem."
                            break
                        }
                        self.registrationLabel.isHidden = false
                    }
                }
                else {
                    print("Registration successful!")
                    
                    let database = Database.database().reference()
                    let userDefaults = UserDefaults.standard
                    
                    OneSignal.setSubscription(true)
                    
                    // Fill user info with default values
                    database.child("users").child(Auth.auth().currentUser!.uid).child("friend_code").setValue("SW-0000-0000-0000")
                    database.child("users").child(Auth.auth().currentUser!.uid).child("nickname").setValue("nickname")
                    
                    // Set email in user defaults
                    let email = Auth.auth().currentUser!.email as String? ?? "Could not fetch email"
                    
                    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: email)
                    userDefaults.set(encodedData, forKey: "Email")
                    
                    //userDefaults.set(false, forKey: "CompletedRegistration")
                    
                    self.registrationLabel.isHidden = true
                    self.performSegue(withIdentifier: "goToRegistration2", sender: self)
                }
                
                SVProgressHUD.dismiss()
            }
        }
    }
    
}
