//
//  ViewController.swift
//  ChelseabandSDK
//
//  Created by vladyslav-iosdev on 11/24/2020.
//  Copyright (c) 2020 vladyslav-iosdev. All rights reserved.
//

import UIKit
import ChelseabandSDK
import SnapKit

class OnbordingViewController: UIViewController {

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let controller = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController() {
            addChild(controller)

            view.addSubview(controller.view)
            
            controller.view.snp.makeConstraints {
                $0.edges.equalTo(view.snp.edges)
            }

            controller.didMove(toParent: self)
        }
    }
}
