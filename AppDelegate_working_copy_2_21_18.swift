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
import FirebaseStorage
import FirebaseStorageUI
import SVProgressHUD

typealias GameDictionaryClosure = (NSDictionary?) -> Void
typealias GameImageClosure = (UIImage?) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var gameArray = [Game]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let currentGameCount = UserDefaults.standard.integer(forKey: "currentGameCount")
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        
        if !launchedBefore  {
            print("First launch, setting UserDefault.")
            UserDefaults.standard.set(true, forKey: "launchedBefore")
        }
        
        FirebaseApp.configure()
        
        pullGameDictionary(count: currentGameCount) { gameDictionary in
            for (title, imagePath) in gameDictionary! {
                
                let storage = Storage.storage().reference()
                let imageRef = storage.child(imagePath as! String)
                
                self.pullGameImage(reference: imageRef) {gameImage in
                    self.gameArray.append(Game(_title: title as! String, _image: gameImage!, _added: false))
                    
                    print("Appended game")
                    
                    let sortedGameList = self.gameArray.sorted(by: { $0.title < $1.title })
                    
                    let userDefaults = UserDefaults.standard
                    let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: sortedGameList)
                    userDefaults.set(encodedData, forKey: "sortedGameList")
                    userDefaults.synchronize()
                }
            }
            
            if Auth.auth().currentUser == nil {
                // Show the signup or login screen               // Look into if bundle is necessary
                let mainStoryboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                let nav = mainStoryboard.instantiateViewController(withIdentifier: "welcomeNC") as! UINavigationController
                self.window?.rootViewController = nav
            }
            
        }
        
        return true
    }
    
    func pullGameDictionary(count: Int, completionHandler: @escaping (GameDictionaryClosure)) {
        
        let database = Database.database().reference()
        
        database.child("games").observeSingleEvent(of: .value, with: { (snapshot) in
            let gameDictionary = snapshot.value as? NSDictionary
            
            if snapshot.childrenCount == count {
                print("No new games")
                return
            }
            else {
                UserDefaults.standard.set(snapshot.childrenCount, forKey: "currentGameCount")
                print("New games are available and will be downloaded")
            }
            
            completionHandler(gameDictionary)
            
        }) { (error) in
            print("Error getting dictionary: " + error.localizedDescription)
        }
    }
    
    func pullGameImage (reference: StorageReference, completionHandler: @escaping (GameImageClosure)) {
        
        // Download in memory with a maximum allowed size of 1MB (1 * 1024 * 1024 bytes)
        reference.getData(maxSize: 1 * 1024 * 1024) { data, error in
            if error != nil {
                print("Error fetching image: " + (error?.localizedDescription)!)
                completionHandler(nil)
            } else {
                print("Image successfully downloaded")
                let image = UIImage(data: data!)
                completionHandler(image)
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

