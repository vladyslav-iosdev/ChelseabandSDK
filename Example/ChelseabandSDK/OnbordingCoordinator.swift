//
//  OnbordingCoordinator.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit

class OnbordingCoordinator: Coordinator {
    var coordinators: [Coordinator] = []
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let controller = OnbordingViewController()

        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.viewControllers = [controller]
    }
}

