//
//  ChangeNicknameViewController.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 3/1/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase

class ChangeNicknameViewController: UIViewController {

    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var nicknameTextfield: UITextField!
    
    var textFieldDelegate: UITextFieldDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nicknameTextfield.tintColor = UIColor.black
        nicknameTextfield.becomeFirstResponder()
        
        nicknameTextfield.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
        
        saveButton.isEnabled = false
    }
    
    @objc func textDidChange(textField: UITextField) {
        saveButton.isEnabled = !(nicknameTextfield.text?.isEmpty)!
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let database = Database.database().reference()
        database.child("users").child(Auth.auth().currentUser!.uid).child("nickname").setValue(nicknameTextfield.text)
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: nicknameTextfield.text!)
        userDefaults.set(encodedData, forKey: "Nickname")
        
        navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
