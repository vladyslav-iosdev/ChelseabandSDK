//
//  UINavigationBar.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

extension UINavigationBar {
    static func setupAppearence() {
        UINavigationBar.appearance().barTintColor = UIColor(hex: "033876")
        UINavigationBar.appearance().tintColor = .white

        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().isTranslucent = false

        let image = UIImage(named: "back")

        UINavigationBar.appearance().backIndicatorImage = image
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = image
    }
}
