//
//  LogInViewController.swift
//  
//
//  Created by Brian Aguirre on 2/14/18.
//

import UIKit
import Firebase
import SVProgressHUD
import OneSignal

class LogInViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var loginLabel: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextfield.becomeFirstResponder()
        
        loginButton.isEnabled = false
        
        //Looks for single or multiple taps to dismiss keyboard
        //let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        //view.addGestureRecognizer(tap)
        
        emailTextfield.delegate = self
        passwordTextfield.delegate = self
        
        emailTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
        passwordTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
        loginLabel.isHidden = true
    }

    // Calls this function when the tap is recognized.
    @objc func dismissKeyboard() {
        // Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    @objc func textDidChange(textField: UITextField) {
        if (emailTextfield.text?.isEmpty)! || (passwordTextfield.text?.isEmpty)! {
            loginButton.isEnabled = false
        }
        else {
            loginButton.isEnabled = true
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
            // Not found, so attempt to log in
            loginPressed(self)
        }
        
        return false
    }
    
    @IBAction func loginPressed(_ sender: Any) {
        
        SVProgressHUD.setDefaultMaskType(.black)
        SVProgressHUD.show()
        
        Auth.auth().signIn(withEmail: emailTextfield.text!, password: passwordTextfield.text!) { (user, error) in
            
            if error != nil {
                print(error!.localizedDescription)
                
                if let errCode = AuthErrorCode(rawValue: error!._code) {
                    switch errCode {
                    case .invalidEmail:
                        print("Invalid email")
                        self.loginLabel.text = "Invalid email."
                    case .wrongPassword:
                        print("Invalid password")
                        self.loginLabel.text = "Invalid password."
                    case .userDisabled:
                        print("User account disabled")
                        self.loginLabel.text = "Your account has been disabled. Please contact 123@test.com to inquire about the status of your account."
                    case .userNotFound:
                        print("Account not found")
                        self.loginLabel.text = "This email address is not associated with an existing account. If you want to create a new account, go back and hit Register."
                    default:
                        print("Login Error: \(error!)")
                        self.loginLabel.text = "Unable to log in. If your issue persists, please contact 123@test.com to report a problem."
                    }
                }
                
                self.loginLabel.isHidden = false
                SVProgressHUD.dismiss()
            }
            else {
                
                print("Login successful!")
                self.loginLabel.isHidden = true
                
                OneSignal.setSubscription(true)
                
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let viewController = mainStoryboard.instantiateViewController(withIdentifier: "homeVC")
                
                UIApplication.shared.keyWindow?.setRootViewController(viewController)
            }
        }
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
