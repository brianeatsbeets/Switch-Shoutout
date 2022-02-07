//
//  AppDelegate.swift
//  Switch Shoutout
//
//  Created by Brian Aguirre on 2/14/18.
//  Copyright © 2018 Brian Aguirre. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import OneSignal

typealias GameDictionaryClosure = (NSDictionary?, String?) -> Void
typealias GameImageClosure = (UIImage?) -> Void
typealias GameCountClosure = (GameListStatus?) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, OSSubscriptionObserver {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        FirebaseApp.configure()
        
        let onesignalInitSettings = [kOSSettingsKeyAutoPrompt: false]
        
        let notificationReceivedBlock: OSHandleNotificationReceivedBlock = { result in
            // This block gets called when the user reacts to a notification received
            let payload: OSNotificationPayload = result!.payload
            
            print("Received notification: \(String(describing: payload.additionalData))")
            
            if payload.additionalData != nil {
                if let additionalData = payload.additionalData as? [String : Any] {
                    print(additionalData)
                    NotificationCenter.default.post(name: .didReceiveNotification, object: nil, userInfo: additionalData)
                }
            }
        }
        
        OneSignal.initWithLaunchOptions(launchOptions,
                                        appId: "af70f788-b600-4db4-9e6e-95f4a0cab0c9",
                                        handleNotificationReceived: notificationReceivedBlock,
                                        handleNotificationAction: nil,
                                        settings: onesignalInitSettings)
        
        OneSignal.inFocusDisplayType = OSNotificationDisplayType.none
        
        OneSignal.add(self as OSSubscriptionObserver)
        
        if !launchedBefore  {
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
            
            // If user is still logged in via Firebase's auth after deleting and reinstalling the app, log them out to show a fresh login screen
            if(Auth.auth().currentUser != nil) {
                do {
                    try Auth.auth().signOut()
                    print("User was logged in before app was installed and was successfully logged out")
                }
                catch {
                    print("User was logged in before app was installed, but was unable to be logged out upon reinstalling and running the app for the first time")
                }
            }
        }
        
        setGlobalStyles()
        
        setInitialView(options: launchOptions)
        
        return true
    }
    
    func onOSSubscriptionChanged(_ stateChanges: OSSubscriptionStateChanges!) {
        
        // If player_id is set
        if let player_id = stateChanges.to.userId {
            
            // If player_id already exists in user defaults
            if let decodedplayer_id = UserDefaults.standard.object(forKey: "player_id") as? Data {
                let savedplayer_id = NSKeyedUnarchiver.unarchiveObject(with: decodedplayer_id) as! String
                
                // If new player_id and saved player_id don't match, update it
                if savedplayer_id != player_id {
                    print("Updated player_id in userdefaults: \(player_id)")
                    setUpdatedPlayer_id(stateChanges: stateChanges, player_id: player_id)
                }
                else {
                    print("player_id matches saved player_id")
                }
            }
            else {
                
                // If player_id doesn't exist in user defaults, set it
                print("Set player_id in userdefaults: \(player_id)")
                setUpdatedPlayer_id(stateChanges: stateChanges, player_id: player_id)
            }
        }
    }
    
    func setUpdatedPlayer_id(stateChanges: OSSubscriptionStateChanges!, player_id: String) {
        
        // Set player_id in user defaults
        let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: player_id)
        UserDefaults.standard.set(encodedData, forKey: "player_id")
        
        // Set a flag to update player_id in firebase
        // Checked right before the observer is created in HomeViewController
        UserDefaults.standard.set(true, forKey: "player_idWasUpdated")
        print("player_id was updated from OneSignal")
    
        // Post notification to update player_id in firebase
        // Only applies if the observer has already been created in HomeViewController
        NotificationCenter.default.post(name: .didUpdateSubscription, object: nil, userInfo: ["stateChanges": stateChanges])
    }
    
    func setGlobalStyles() {
        if let font = UIFont(name: "Avenir-Heavy", size: 19) {
            // Gives navigation bar Avenir Heavy font if available and sets text color to white
            UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: font]
        }
        
        if let font = UIFont(name: "Avenir-Roman", size: 11) {
            // Gives tab bar Avenir Roman font if available          
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: font], for: UIControl.State.normal)
            UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: font], for: UIControl.State.selected)
        }
        
        // Changes navigation bar background color
        UINavigationBar.appearance().barTintColor = UIColor.red
        // Changes navigation bar back button title and icon color
        UINavigationBar.appearance().tintColor = UIColor.white
        // Changes tab bar background color
        UITabBar.appearance().backgroundColor = UIColor.lightGray
        // Changes text field tint color
        UITextField.appearance().tintColor = UIColor.white
    }
    
    // Show the signup or login screen depending on current user status
    func setInitialView(options: [UIApplication.LaunchOptionsKey: Any]?) {
        if Auth.auth().currentUser == nil {
            let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let nav = mainStoryboard.instantiateViewController(withIdentifier: "welcomeNC") as! UINavigationController
            self.window?.rootViewController = nav
        }
        else if options != nil {
            
            // Check if user tapped on friend request notification
            let info = options?[.remoteNotification] as? [String:[String:Any]]
            NSLog("info::::: \(String(describing: info?["custom"]?["a"]))")
            NSLog("info2::::: \(String(describing: (info?["custom"]?["a"] as? [String:String])?["type"]))")
            NSLog("info3::::: \(String(describing: info))")
            if (info?["custom"]?["a"] as? [String:String])?["type"] == "friend_request" {
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let nav = mainStoryboard.instantiateViewController(withIdentifier: "homeVC") as! UITabBarController
                self.window?.rootViewController = nav
                nav.selectedIndex = 0
                nav.selectedIndex = 2
                UserDefaults.standard.set(true, forKey: "DidLaunchFromFriendRequest")
            }
        }
}
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Switch_Shoutout")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
}

