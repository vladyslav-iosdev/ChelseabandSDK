//
//  AppDelegate.swift
//  ChelseabandSDK
//
//  Created by vladyslav-iosdev on 11/24/2020.
//  Copyright (c) 2020 vladyslav-iosdev. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .white

        appCoordinator = AppCoordinator(window: window)
        appCoordinator.start()

        self.window = window

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        appCoordinator.applicationDidEnterBackground(application)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        appCoordinator.applicationWillEnterForeground(application)
    }
}
