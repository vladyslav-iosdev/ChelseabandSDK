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

protocol ToggleViewModel {
    var image: Observable<UIImage> { get }
    var title: Observable<String> { get }
    var value: Observable<Bool> { get }
}

struct AlertRowViewModel: ToggleViewModel {
    
    let title: Observable<String>
    let value: Observable<Bool>
    let image: Observable<UIImage>
    let trigger: LightTrigger

    init(image: UIImage, trigger: LightTrigger, value: Observable<Bool>) {
        self.trigger = trigger
        self.value = value
        self.title = Observable.just(trigger.title)
        self.image = Observable.just(image)
    }
}
