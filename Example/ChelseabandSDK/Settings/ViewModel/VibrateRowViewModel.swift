//
//  VibrateRowViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 07.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift

struct VibrateRowViewModel: ToggleViewModel {
    let title: Observable<String>
    let value: Observable<Bool>
    let image: Observable<UIImage>

    init(image: UIImage, title: String, value: Observable<Bool>) {
        self.value = value
        self.title = Observable.just(title)
        self.image = Observable.just(image)
    }

}
