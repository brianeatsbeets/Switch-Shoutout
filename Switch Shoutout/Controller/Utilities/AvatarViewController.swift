//
//  AvatarViewController.swift
//  Switch Shoutout
//
//  Created by Aguirre, Brian P. on 7/9/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import Firebase

class AvatarViewController: UIViewController {
    
    var currentlySelected = UIImageView()
    var tag = Int()
    var avatarDictionary = Dictionary<Int, String>()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: #selector(self.returnToSender))
        doneButton.isEnabled = false
        self.navigationItem.rightBarButtonItem = doneButton
        
        avatarDictionary.updateValue("avatar_a", forKey: 1)
        avatarDictionary.updateValue("avatar_b", forKey: 2)
        avatarDictionary.updateValue("avatar_c", forKey: 3)
        avatarDictionary.updateValue("avatar_d", forKey: 4)
        avatarDictionary.updateValue("avatar_e", forKey: 5)
        avatarDictionary.updateValue("avatar_f", forKey: 6)
        avatarDictionary.updateValue("avatar_g", forKey: 7)
        avatarDictionary.updateValue("avatar_h", forKey: 8)
        avatarDictionary.updateValue("avatar_i", forKey: 9)
        avatarDictionary.updateValue("avatar_j", forKey: 10)
        avatarDictionary.updateValue("avatar_k", forKey: 11)
        avatarDictionary.updateValue("avatar_l", forKey: 12)
        avatarDictionary.updateValue("avatar_m", forKey: 13)
        avatarDictionary.updateValue("avatar_n", forKey: 14)
        avatarDictionary.updateValue("avatar_o", forKey: 15)
        avatarDictionary.updateValue("avatar_p", forKey: 16)
        avatarDictionary.updateValue("avatar_q", forKey: 17)
        avatarDictionary.updateValue("avatar_r", forKey: 18)
        avatarDictionary.updateValue("avatar_s", forKey: 19)
        avatarDictionary.updateValue("avatar_t", forKey: 20)
        avatarDictionary.updateValue("avatar_u", forKey: 21)
        avatarDictionary.updateValue("avatar_v", forKey: 22)
        avatarDictionary.updateValue("avatar_w", forKey: 23)
        avatarDictionary.updateValue("avatar_x", forKey: 24)
        avatarDictionary.updateValue("avatar_y", forKey: 25)
        avatarDictionary.updateValue("avatar_z", forKey: 26)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //self.tabBarController?.tabBar.isHidden = true
    }
    
    @IBAction func avatarPressed(_ sender: Any) {
        guard let button = sender as? UIButton else {
            return
        }
        
        // Find the UIImageView associated witj the button
        for view in button.superview!.subviews
        {
            if let selectedImage = view as? UIImageView{
                
                // Hide or unhide the button that was selected
                selectedImage.isHidden.toggle()
                
                // If no button is selected, disable the Done button
                if !selectedImage.isHidden {
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
                else {
                    self.navigationItem.rightBarButtonItem?.isEnabled = false
                }
                
                // If the seleced image is different than the previously selected button, deselect the previous button
                if selectedImage != currentlySelected {
                    currentlySelected.isHidden = true
                }
                
                // Replace the previously selected button witht he currently selected button in this variable
                currentlySelected = selectedImage
                tag = button.tag
            }
        }
    }
    
    @objc func returnToSender() {
        Database.database().reference().child("users").child(Auth.auth().currentUser!.uid).child("avatar").setValue(avatarDictionary[tag])
        
        let userDefaults = UserDefaults.standard
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: avatarDictionary[tag]!)
        userDefaults.set(encodedData, forKey: "UserAvatar")
        
        self.navigationController?.popViewController(animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
