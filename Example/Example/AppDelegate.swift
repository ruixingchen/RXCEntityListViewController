//
//  AppDelegate.swift
//  Example
//
//  Created by ruixingchen on 2019/10/31.
//  Copyright © 2019 ruixingchen. All rights reserved.
//

import UIKit
import RXCFirstTimeViewController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        UIViewController.ftv_start()
        #if (debug || DEBUG)
        RXCEntityListViewController.debugMode = true
        #endif

        window = UIWindow()
        window?.rootViewController = ViewController(style: .grouped, useCollectionView: false, useASDK: false)
        window?.makeKeyAndVisible()

        return true
    }




}

