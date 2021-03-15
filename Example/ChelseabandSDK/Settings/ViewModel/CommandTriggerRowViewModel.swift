//
//  AlertRowViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift
import ChelseabandSDK

struct CommandTriggerRowViewModel: ToggleViewModelType {

    let title: String
    let value: Bool
    let image: UIImage?
    let trigger: CommandTrigger

    init(image: UIImage, trigger: CommandTrigger, value: Bool) {
        self.trigger = trigger
        self.value = value
        self.title = trigger.title
        self.image = image
    }
}
