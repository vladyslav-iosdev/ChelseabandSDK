//
//  UIStackView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

extension UIStackView {
    func addArrangedSubviews(_ views: [UIView]) {
        views.forEach { view in
            self.addArrangedSubview(view)
        }
    }
} 
