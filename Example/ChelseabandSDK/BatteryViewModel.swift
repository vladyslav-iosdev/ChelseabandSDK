//
//  BatteryViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ChelseabandSDK

private extension BatteryLevel {

    var image: UIImage? {
        switch self {
        case .full:
            return UIImage(named: "1")
        case .middleUp:
            return UIImage(named: "2")
        case .middle:
            return UIImage(named: "3")
        case .low:
            return UIImage(named: "4")
        case .empty:
            return UIImage(named: "5")
        }
    }
}

class BatteryViewModel: ViewModelType {

    struct Input {

    }

    struct Output {
        let batteryImage: Driver<UIImage?>
        let batteryPercentage: Driver<String>
        let isHidden: Driver<Bool>
    }

    private let batteryLevelObservable: Observable<UInt64>
    private let status: Observable<Device.State>

    init(batteryLevelObservable: Observable<UInt64>, status: Observable<Device.State>) {
        self.batteryLevelObservable = batteryLevelObservable
        self.status = status
    }

    func transform(input: Input) -> Output {
        let batteryImageObservable = batteryLevelObservable
            .startWith(0)
            .compactMap { BatteryLevel(value: $0) }
            .map { $0.image }
            .debug("bat-i")
            .asDriver(onErrorJustReturn: nil)

        let batteryPercentageObservable = batteryLevelObservable
            .startWith(0)
            .compactMap { "\($0)%" }
            .debug("bat-p")
            .asDriver(onErrorJustReturn: .init())

        let isHiddenObservable = status
            .startWith(.disconnected(nil))
            .map { !$0.isConnected }
            .debug("bat-i-h")
            .asDriver(onErrorJustReturn: true)

        return .init(
            batteryImage: batteryImageObservable,
            batteryPercentage: batteryPercentageObservable,
            isHidden: isHiddenObservable
        )
    }
}
