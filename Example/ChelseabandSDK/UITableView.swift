//
//  UITableView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

protocol WithReusableIdentifier {
    static var reusableIdentifier: String { get }
}

extension WithReusableIdentifier {
    static var reusableIdentifier: String {
        String(describing: self)
    }
}

extension UITableViewCell: WithReusableIdentifier {
}

extension UITableViewHeaderFooterView: WithReusableIdentifier {
}

extension UICollectionViewCell: WithReusableIdentifier {
}

extension UICollectionReusableView: WithReusableIdentifier {
}

extension UITableView {

    func registerHeaderFooterView(_ reusable: UITableViewHeaderFooterView.Type) {
        register(reusable.self, forHeaderFooterViewReuseIdentifier: reusable.reusableIdentifier)
    }

    func register(_ reusable: UITableViewCell.Type) {
        register(reusable.self, forCellReuseIdentifier: reusable.reusableIdentifier)
    }

    func dequeueReusableCell<T>(for indexPath: IndexPath) -> T where T: WithReusableIdentifier {
        return dequeueReusableCell(withIdentifier: T.reusableIdentifier, for: indexPath) as! T
    }

    func dequeueReusableHeaderFooterView<T>() -> T where T: WithReusableIdentifier {
        return dequeueReusableHeaderFooterView(withIdentifier: T.reusableIdentifier) as! T
    }
}

