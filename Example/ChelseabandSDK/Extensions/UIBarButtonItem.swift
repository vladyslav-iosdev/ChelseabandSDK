//
//  UIBarButtonItem.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import SnapKit

extension UIBarButtonItem {

    static var logoBarButtonView: UIBarButtonItem {
        let iconImageView = UIImageView(image: UIImage(named: "navigation_logo"))

        iconImageView.snp.makeConstraints {
            $0.height.width.equalTo(30)
        }

        let titleView: UILabel = {
            let view = UILabel()
            view.textColor = .white
            view.text = "Chealsea FC"
            return view
        }()

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10

        stackView.addArrangedSubviews([iconImageView, titleView])

        return UIBarButtonItem.init(customView: stackView)
    }

    static var moreBarButton: UIBarButtonItem {
        return .init(image: UIImage(named: "more"), style: .done, target: nil, action: nil)
    }

    static func backBarButton(_ target: Any?, action: Selector?) -> UIBarButtonItem {
        return .init(image: UIImage(named: "back"), style: .done, target: target, action: action)
    }
}
