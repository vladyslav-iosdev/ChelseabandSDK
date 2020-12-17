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
    let title: Observable<String>
    let sound: Observable<Sound>
    let image: Observable<UIImage>
    let trigger: SoundTrigger

    init(image: UIImage, trigger: SoundTrigger, sound: Observable<Sound>) {
        self.trigger = trigger
        self.sound = sound
        self.title = Observable.just(trigger.title)
        self.image = Observable.just(image)
    }
}
