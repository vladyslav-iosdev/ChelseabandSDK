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
    private let settings: SettingsServiceType
    private let chelseaband: ChelseabandType
    private let navigationController: UINavigationController

    weak var delegate: SettingsCoordinatorDelegate?

    private lazy var viewController: SettingsViewController = {
        let controller = SettingsViewController(viewModel: .init(settingsService: settings, chelseaband: chelseaband))
        controller.navigationItem.leftBarButtonItem = .backBarButton(self, action: #selector(dissmiss))
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

    @objc private func dissmiss() {
        delegate?.didDissmiss(in: self)
    }

    func start() {
        navigationController.pushViewController(viewController, animated: true)
    }

    private func set(sound: Sound, trigger: SoundTrigger) {
        let chelseaband = self.chelseaband

        settings
            .set(sound: sound, trigger: trigger)
            .flatMap { _ -> Single<Void> in
                let command = SoundCommand(sound: sound, trigger: trigger)
                return chelseaband.perform(command: command).asSingle()
            }
            .subscribe { [weak self] event in
                guard let strongSelf = self else { return }

                switch event {
                case .error:
                    strongSelf.navigationController.showError(message: "Operation failure")
                case .success:
                    break
                }
            }.disposed(by: disposeBag)
    }

    private func set(light value: Bool, trigger: LightTrigger) {
        settings
            .set(value: value, trigger: trigger)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let strongSelf = self else { return .never() }

                return strongSelf.sendCombinedLightAndVibration(settings: strongSelf.settings, chelseaband: strongSelf.chelseaband)
            }
            .subscribe { [weak self] event in
                guard let strongSelf = self else { return }

                switch event {
                case .error:
                    strongSelf.navigationController.showError(message: "Operation failure")
                case .success:
                    break
                }
            }.disposed(by: disposeBag)
    }

    private func set(vibrate: Bool) {
        settings
            .set(vibrate: vibrate)
            .flatMap { [weak self] _ -> Single<Void> in
                guard let strongSelf = self else { return .never() }

                return strongSelf.sendCombinedLightAndVibration(settings: strongSelf.settings, chelseaband: strongSelf.chelseaband)
            }
            .subscribe { [weak self] event in
                guard let strongSelf = self else { return }

                switch event {
                case .error:
                    strongSelf.navigationController.showError(message: "Operation failure")
                case .success:
                    break
                }
            }.disposed(by: disposeBag)
    }

    private func sendCombinedLightAndVibration(settings: SettingsServiceType, chelseaband: ChelseabandType) -> Single<Void> {
        let lights = Observable.from(LightTrigger.allCases)
            .flatMap { Observable.combineLatest(settings.getLight(trigger: $0), Observable<LightTrigger>.just($0)) }
            .toArray()
            .asObservable()

        let vibration = settings.vibrate
            .map { Vibration.init($0) }

        return Observable.combineLatest(lights, vibration)
            .flatMap { lights, vibration -> Observable<Void> in
                let lights = lights.filter{ $0.0 }.map{ $0.1 }
                let command = LightCommand(lights: lights, vibration: vibration)

                return chelseaband.perform(command: command)
            }.asSingle()
    }
}

extension UIViewController {
    func showError(message: String) {
        let controller = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        controller.addAction(.init(title: "Ok", style: .default))

        present(controller, animated: true)
    }
}

