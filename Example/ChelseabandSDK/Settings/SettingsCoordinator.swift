//
//  SettingsCoordinator.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import ChelseabandSDK
import RxSwift
import RxCocoa

protocol SettingsCoordinatorDelegate: class {
    func didDissmiss(in coordinator: SettingsCoordinator)
}

class SettingsCoordinator: Coordinator {
    var coordinators: [Coordinator] = []

    private let disposeBag = DisposeBag()
    private var settings: SettingsServiceType
    private let chelseaband: ChelseabandType
    private let navigationController: UINavigationController

    weak var delegate: SettingsCoordinatorDelegate?

    private lazy var viewController: SettingsViewController = {
        let controller = SettingsViewController(viewModel: .init(settingsService: settings))
        controller.navigationItem.leftBarButtonItem = .backBarButton(self, action: #selector(dismiss))
        return controller
    }()

    init(settings: SettingsServiceType, chelseaband: ChelseabandType, navigationController: UINavigationController) {
        self.settings = settings
        self.chelseaband = chelseaband
        self.navigationController = navigationController

        viewController.lightChangeObservable.subscribe(onNext: { [weak self] (isOn, trigger) in
            self?.set(light: isOn, trigger: trigger)
        }).disposed(by: disposeBag)

        viewController.soundChangeObservable.subscribe(onNext: { [weak self] (sound, trigger) in
            self?.set(sound: sound, trigger: trigger)
        }).disposed(by: disposeBag)

        viewController.vibrationChangeObservable.subscribe(onNext: { [weak self] value in
            self?.set(vibrate: value)
        }).disposed(by: disposeBag)
    }

    @objc private func dismiss() {
        delegate?.didDissmiss(in: self)
    }

    func start() {
        navigationController.pushViewController(viewController, animated: true)
    }

    deinit {
        print("\(self).deinit")
    }

    private func set(sound: Sound, trigger: CommandTrigger) {
        let command = SoundCommand(sound: sound, trigger: trigger)

        chelseaband.perform(command: command)
            .subscribe { [weak self] event in
                guard let strongSelf = self else { return }

                if event.error == nil {
                    strongSelf.settings.set(sound: sound, trigger: trigger)
                } else {
                    strongSelf.navigationController.showError(message: "Failure to perform command")
                }
            }.disposed(by: disposeBag)
    }

    private func set(light value: Bool, trigger: CommandTrigger) {
        settings.set(lightEnabled: value, trigger: trigger)
        syncDeviceSettings()
    }

    private func set(vibrate: Bool) {
        settings.set(vibrate: vibrate)
        syncDeviceSettings()
    }

    private func syncDeviceSettings() {
        let speakerEnabled = settings.sounds.filter{ $0.value != .off }.count == 0

        let command = HardwareEnablement(led: settings.enabledLights, vibrationEnabled: settings.vibrate, screenEnabled: true, speakerEnabled: speakerEnabled)
        let hardwareEnablementObservable = chelseaband.perform(command: command)
            .debug("syncLightsAndVibrationObservable")

        hardwareEnablementObservable.subscribe { [weak self] event in
            guard let strongSelf = self else { return }

            if event.error == nil {
                //no-op
            } else {
                strongSelf.navigationController.showError(message: "Failure to perform command")
            }
        }.disposed(by: disposeBag)
    }
}

extension UIViewController {
    func showError(message: String) {
        let controller = UIAlertController(title: "Error",
                                           message: message,
                                           preferredStyle: .alert)
        controller.addAction(.init(title: "OK",
                                  style: .default))

        present(controller, animated: true)
    }
}

