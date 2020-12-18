//
//  DeviceCoordinator.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import RxBluetoothKit
import ChelseabandSDK
import RxSwift

class DeviceCoordinator: Coordinator {
    
    var coordinators: [Coordinator] = []
    private let disposeBag = DisposeBag()

    private lazy var viewController: DeviceViewController = {
        return .init(viewModel: DeviceViewModel(chelseaband: chelseaband, settings: settings))
    }()

    private let chelseaband: ChelseabandType
    private let settings: SettingsServiceType
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController, chelseaband: ChelseabandType, settings: SettingsServiceType) {
        self.chelseaband = chelseaband
        self.settings = settings
        self.navigationController = navigationController

//        viewController
//            .settingsButtonObservable
//            .do(onNext: { [weak self] in
//                self?.showSettings()
//            })
//            .subscribe()
//            .disposed(by: disposeBag)

        viewController.connectButtonObservable.subscribe { _ in
            chelseaband.connect()
        }.disposed(by: disposeBag)

        viewController.disconnectButtonObservable.subscribe { _ in
            chelseaband.disconnect()
        }.disposed(by: disposeBag)
//
//        viewController.sendNewButtonObservable.subscribe { _ in
//            self.sendNews()
//        }.disposed(by: disposeBag)
//
//        viewController.sendGoalButtonObservable.subscribe { _ in
//            self.sendGoal()
//        }.disposed(by: disposeBag)

//        Observable.combineLatest(chelseaband.connectionObservable, Observable.just(chelseaband), Observable.just(settings))
//            .filter { $0.0.isConnected }
//            .map{ ($0.1, $0.2) }
//            .flatMap { val -> Observable<Void> in
//                let x1 = self.setConnectionDate(settings: val.1)
//                let x2 = self.syncDeviceSettings(chelseaband: val.0, settings: val.1)
//
//                return Observable.combineLatest(x1, x2).mapToVoid()
//            }
//            .subscribe()
//            .disposed(by: disposeBag)
//
//        chelseaband.batteryLevelObservable.subscribe { e in
//            print("battery level: \(e)")
//        }.disposed(by: disposeBag)
    }

    func start() {
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.viewControllers = [viewController]
    }

    private func setConnectionDate(settings: SettingsServiceType) -> Observable<Void> {
        let now = Date()
        return settings.set(connectionDate: now).asObservable()
    }

    private func syncDeviceSettings(chelseaband: ChelseabandType, settings: SettingsServiceType) -> Observable<Void> {
        let syncSoundsObservable = Observable.from(SoundTrigger.allCases)
            .flatMap {
                Observable.combineLatest(settings.getSound(trigger: $0), Observable<SoundTrigger>.just($0))
            }.flatMap { sound, trigger -> Observable<Void> in
                let command = SoundCommand(sound: sound, trigger: trigger)
                return chelseaband.perform(command: command)
            }.debug("SoundCommand")

        let lights = Observable.from(LightTrigger.allCases)
            .flatMap { Observable.combineLatest(settings.getLight(trigger: $0), Observable<LightTrigger>.just($0)) }
            .toArray()
            .asObservable()

        let vibration = settings.vibrate
            .map { Vibration.init($0) }

        let syncLightsAndVibrationObservable = Observable.combineLatest(lights, vibration)
            .flatMap { lights, vibration -> Observable<Void> in
                let lights = lights.filter{ $0.0 }.map { $0.1 }
                let command = LightCommand(lights: lights, vibration: vibration)

                return chelseaband.perform(command: command)
            }.debug("syncLightsAndVibrationObservable")

        return Observable.combineLatest(syncSoundsObservable, syncLightsAndVibrationObservable).mapToVoid()
    }

    private func sendGoal() {
        let cmd = GoalCommand()
        chelseaband.perform(command: cmd).subscribe { e in
            print(e)
        }.disposed(by: disposeBag)
    }

    private func sendNews() {
        let value = "Using this option CocoaPods will assume the given folder to be the root of the Pod and will link the files directly from there in the Pods project."
        let command = NewsCommand(value: value)

        chelseaband.perform(command: command).debug("NewsCommand-Main").subscribe { e in
            print("asasdasd \(e)")
        }.disposed(by: disposeBag)
    }

    private func showSettings() {
        let coordinator = SettingsCoordinator(settings: settings, chelseaband: chelseaband, navigationController: navigationController)
        coordinator.delegate = self
        addCoordinator(coordinator)
        
        coordinator.start()
    }
}

extension DeviceCoordinator: SettingsCoordinatorDelegate {

    func didDissmiss(in coordinator: SettingsCoordinator) {
        navigationController.popViewController(animated: true)
        removeCoordinator(coordinator)
    }
}
