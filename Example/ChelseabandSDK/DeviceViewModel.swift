//
//  DeviceViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 15.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit 
import RxSwift
import RxCocoa
import ChelseabandSDK

extension Device.State {
    func date(date: String) -> String {
        switch self {
        case .disconnected, .connecting, .scanning:
            return "Last connected" + "\n" + date
        case .connected:
            return "Connected since" + "\n" + date
        }
    }

    var deviceImage: UIImage {
        switch self {
        case .disconnected, .connecting, .scanning:
            return UIImage(named: "device_disconnected")!
        case .connected:
            return UIImage(named: "device_connected")!
        }
    }
}

class DeviceViewModel: ViewModelType {

    struct Input {

    }

    struct Output {
        let connectionViewModel: DeviceConnectionViewModel
        let batteryViewModel: BatteryViewModel
        let connectionDate: Driver<NSAttributedString>
        let deviceImage: Driver<UIImage>
    }

    private let chelseaband: ChelseabandType
    private let settings: SettingsServiceType

    init(chelseaband: ChelseabandType, settings: SettingsServiceType) {
        self.chelseaband = chelseaband
        self.settings = settings
    }

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, d MMM yyyy HH:mm:ss"

        return formatter
    }()

    func transform(input: Input) -> Output {
        let connectionObservable = chelseaband.connectionObservable.startWith(.disconnected(nil))

        let connectionViewModel: DeviceConnectionViewModel = .init(status: connectionObservable)
        let batteryViewModel = BatteryViewModel(
            batteryLevelObservable: chelseaband.batteryLevelObservable,
            status: connectionObservable
        )

        let y = settings.connectionDate
            .startWith(nil)
            .debug("date")
            .compactMap { date -> String? in
                if let value = date {
                    return self.formatter.string(from: value)
                } else {
                    return nil
                }
            }

        let connectionAttributedDate = Observable.combineLatest(connectionObservable, y)
            .map { $0.0.date(date: $0.1) }
            .map { NSAttributedString(string: $0, attributes: [:]) }
            .asDriver(onErrorJustReturn: .init())

        let deviceImageObservable = connectionObservable
            .map{ $0.deviceImage }
            .asDriver(onErrorJustReturn: .init())

        return .init(
            connectionViewModel: connectionViewModel,
            batteryViewModel: batteryViewModel,
            connectionDate: connectionAttributedDate,
            deviceImage: deviceImageObservable
        )
    }
}
