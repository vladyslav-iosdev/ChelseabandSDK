//
//  SettingsViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import ChelseabandSDK

enum SettingsSection {
    case sounds(viewModels: [SoundRowViewModel])
    case alerts(viewModels: [AlertRowViewModel], headerViewModel: SettingsSectionViewModel)
    case vibration(viewModel: VibrateRowViewModel)
}

enum DeviceError: Error {
    case general(Error)
}

class SettingsViewModel: ViewModelType {

    struct Input {

    }

    struct Output {
        let sections: Driver<[SettingsSection]>
        let title: Driver<String>
    }

    private let settingsService: SettingsServiceType
    private let chelseaband: ChelseabandType
    private let sections: Driver<[SettingsSection]>
    private let disposeBag = DisposeBag()

    init(settingsService: SettingsServiceType, chelseaband: ChelseabandType) {
        self.settingsService = settingsService
        self.chelseaband = chelseaband

        let image = UIImage(named: "like")!

        sections = BehaviorRelay<[SettingsSection]>(value: [
            .sounds(viewModels: [
                SoundRowViewModel(image: image, trigger: .goal, sound: settingsService.getSound(trigger: .goal)),
                SoundRowViewModel(image: image, trigger: .news, sound: settingsService.getSound(trigger: .news)),
                SoundRowViewModel(image: image, trigger: .gesture, sound: settingsService.getSound(trigger: .gesture))
            ]),
            .alerts(viewModels: [
                AlertRowViewModel(image: image, trigger: .goal, value: settingsService.getLight(trigger: .goal)),
                AlertRowViewModel(image: image, trigger: .news, value: settingsService.getLight(trigger: .news))
            ], headerViewModel: .init(title: "Enable Light Flashers for: ")),
            .vibration(viewModel:
                VibrateRowViewModel(image: image, title: "Vibrate on Alerts", value: settingsService.vibrate)
            )
        ]).asDriver()
    }

    func transform(input: Input) -> Output {
        return Output(sections: sections, title: .just("Sounds and Alerts"))
    }
}

extension Sound: DropdownPickerValue {
    
}
