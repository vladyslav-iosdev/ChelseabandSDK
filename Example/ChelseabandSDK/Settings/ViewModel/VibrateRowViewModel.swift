//
//  VibrateRowViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift

import UIKit
import RxSwift

struct VibrateRowViewModel: ToggleViewModelType {
    let title: String
    let value: Bool
    let image: UIImage?

    init(image: UIImage?, title: String, value: Bool) {
        self.value = value
        self.title = title
        self.image = image
    }
}

