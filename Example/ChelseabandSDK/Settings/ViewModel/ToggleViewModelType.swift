//
//  ToggleViewModelType.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.03.2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import ChelseabandSDK

protocol ToggleViewModelType {
    var image: UIImage? { get }
    var title: String { get }
    var value: Bool { get }
}

struct ToggleViewModel: ToggleViewModelType {

    let title: String
    let value: Bool
    let image: UIImage?

    init(image: UIImage?, title: String, value: Bool) {
        self.value = value
        self.title = title
        self.image = image
    }
}
