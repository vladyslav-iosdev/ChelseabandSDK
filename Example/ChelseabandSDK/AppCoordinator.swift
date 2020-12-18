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
    private lazy var device = Device(configuration: ChelseabandConfiguration.initial)
    private lazy var chelseaband: ChelseabandType = Chelseaband(device: device)

    private lazy var settings: SettingsServiceType = SettingsService()
    private let disposeBag = DisposeBag()
    var coordinators: [Coordinator] = []

    init(window: UIWindow) {
        self.window = window

        device.bluetoothHasConnected.subscribe(onNext: { [weak self] _ in
            guard let strongSelf = self else { return }

            strongSelf.chelseaband.connect()
        }).disposed(by: disposeBag)
    }

    func start() {
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        UINavigationBar.setupAppearence()

        let coordinator = DeviceCoordinator(navigationController: navigationController, chelseaband: chelseaband, settings: settings)
        addCoordinator(coordinator)

        coordinator.start()

        let cmd = GoalCommand()

        chelseaband.performSafe(command: cmd, timeOut: .seconds(5))
            .debug("\(self).initial-command")
            .subscribe { e in

            }.disposed(by: disposeBag)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {

    }

    func applicationWillEnterForeground(_ application: UIApplication) {

    }
}

