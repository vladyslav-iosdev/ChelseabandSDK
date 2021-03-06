//
//  SoundRowViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import RxSwift
import RxCocoa
import ChelseabandSDK 

struct SoundRowViewModel {
    let title: String
    let sound: Sound
    let image: UIImage
    let trigger: CommandTrigger

    init(image: UIImage, trigger: CommandTrigger, sound: Sound) {
        self.trigger = trigger
        self.sound = sound
        self.title = trigger.title
        self.image = image
    }
}
