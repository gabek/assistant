//
//  AppDelegate.swift
//  assistant
//
//  Created by Gabe Kangas on 2/12/20.
//  Copyright © 2020 Gabe Kangas. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let window: UIWindow = UIWindow()

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        window.rootViewController = MainViewController()
//        self.window = window
        window.makeKeyAndVisible()

//        dumpFonts()

        return true
    }

    func dumpFonts() {
        for family: String in UIFont.familyNames {
            print(family)
        }
    }

    // MARK: UISceneSession Lifecycle

//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }
}
