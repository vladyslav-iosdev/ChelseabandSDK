//
//  SettingsView.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

extension SettingsViewController: UITableViewDelegate {

    class SettingsView: UITableView {

        init() {
            super.init(frame: .zero, style: .grouped)
            tableFooterView = UIView()
            backgroundColor = .white
        }

        required init?(coder: NSCoder) {
            return nil
        }
    }

}
