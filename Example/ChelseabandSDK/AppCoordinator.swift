//
//  AppCoordinator.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import ChelseabandSDK
import RxSwift
import RxCocoa

class AppCoordinator: Coordinator {
    
    private let window: UIWindow
    private lazy var navigationController = UINavigationController()
    private lazy var chelseaband: ChelseabandType = {
        let device = Device(configuration: ChelseabandConfiguration.initial)
        return Chelseaband(device: device)
    }()
    private lazy var settings: SettingsServiceType = SettingsService()
    private let disposeBag = DisposeBag()
    var coordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window 
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        UINavigationBar.setupAppearence()

        let coordinator = DeviceCoordinator(navigationController: navigationController, chelseaband: chelseaband, settings: settings)
        addCoordinator(coordinator)

        coordinator.start()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }
}

