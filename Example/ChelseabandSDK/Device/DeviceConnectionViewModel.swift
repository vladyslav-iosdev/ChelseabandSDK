//
//  DeviceConnectionViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit 
import RxCocoa
import RxSwift
import ChelseabandSDK

private extension Device.State {
    var connectionButtonEnabled: Bool {
        switch self {
        case .connected, .scanning, .connecting:
            return false
        case .disconnected:
            return true
        }
    }

    var connectionIconTintColor: UIColor {
        switch self {
        case .scanning, .connecting:
            return .darkGray
        case .connected:
            return UIColor(hex: "60BF00")
        case .disconnected:
            return UIColor(hex: "D0021B")
        }
    }

    var connectionIcon: UIImage? {
        switch self {
        case .scanning, .connecting, .connected:
            return UIImage(named: "ble_connected")?.withRenderingMode(.alwaysTemplate)
        case .disconnected:
            return UIImage(named: "ble_disconnected")?.withRenderingMode(.alwaysTemplate)
        }
    }

    var connectionStateText: String {
        switch self {
        case .scanning:
            return "Scanning"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected - Tap to Connect"
        }
    }
}

class DeviceConnectionViewModel: ViewModelType {

    struct Input {
        let connectionObservable: Observable<Void>
    }

    struct Output {
        let connectionObservable: Driver<Void>
        let connectionIconObservable: Driver<UIImage?>
        let connectionIconTintColorObservable: Driver<UIColor>
        let connectionStateTextObservable: Driver<String>
        let statusObservable: Driver<Device.State>
        let cancelConnectionTextObservable: Driver<String>
    }

    private let status: Observable<Device.State>

    init(status: Observable<Device.State>) {
        self.status = status
    }

    func transform(input: Input) -> Output {
        let connectionButtonEnabled = status
            .startWith(.disconnected)
            .map { $0.connectionButtonEnabled }

        let connectionIconTintColorObservable = status
            .startWith(.disconnected)
            .map { $0.connectionIconTintColor }
            .asDriver(onErrorJustReturn: .black)

        let connectionIconObservable = status
            .startWith(.disconnected)
            .map { $0.connectionIcon }
            .asDriver(onErrorJustReturn: nil)

        let connectionStateTextObservable = status
            .startWith(.disconnected)
            .map { $0.connectionStateText }
            .asDriver(onErrorJustReturn: String())

        let connectWhenDisconnectedObservable = Observable.combineLatest(connectionButtonEnabled, input.connectionObservable)
            .filter{ $0.0 }
            .mapToVoid()
            .asDriver(onErrorJustReturn: ())

        return .init(
            connectionObservable: connectWhenDisconnectedObservable,
            connectionIconObservable: connectionIconObservable,
            connectionIconTintColorObservable: connectionIconTintColorObservable,
            connectionStateTextObservable: connectionStateTextObservable,
            statusObservable: status.asDriver(onErrorJustReturn: .disconnected),
            cancelConnectionTextObservable: .just("Cancel")
        )
    }
}
