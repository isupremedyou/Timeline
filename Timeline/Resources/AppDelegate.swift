//
//  AppDelegate.swift
//  Timeline
//
//  Created by Travis Chapman on 11/6/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        PostController.shared.fetchPosts()
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (successful, error) in
            if let error = error {
                print("Error: \n\(#function)\n\(error)\n\(error.localizedDescription)")
                return
            }
        }
        
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        PostController.shared.fetchPosts()
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
}

