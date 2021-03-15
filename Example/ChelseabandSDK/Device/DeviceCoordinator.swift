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

        viewController
            .settingsButtonObservable
            .do(onNext: { [weak self] in
                self?.showSettings()
            })
            .subscribe()
            .disposed(by: disposeBag)

//        viewController.connectButtonObservable.subscribe { _ in
//            chelseaband.connect()
//        }.disposed(by: disposeBag)

        viewController.disconnectButtonObservable.subscribe { _ in
            chelseaband.disconnect()
        }.disposed(by: disposeBag)

        viewController.sendNewButtonObservable.subscribe { _ in
            self.sendNews()
        }.disposed(by: disposeBag)

        viewController.sendGoalButtonObservable.subscribe { _ in
            self.sendGoal()
        }.disposed(by: disposeBag)

        Observable.combineLatest(chelseaband.connectionObservable, Observable.just(chelseaband), Observable.just(settings))
            .filter { $0.0.isConnected }
            .flatMap { _ -> Observable<Void> in
                let x1 = self.setConnectionDate()
                let x2 = self.syncDeviceSettings()

                return Observable.combineLatest(x1, x2).mapToVoid()
            }
            .subscribe()
            .disposed(by: disposeBag)

        chelseaband.batteryLevelObservable.subscribe { e in
            print("battery level: \(e)")
        }.disposed(by: disposeBag)
    }

    func start() {
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.viewControllers = [viewController]
    }

    private func setConnectionDate(now: Date = .init()) -> Observable<Void> {
        let settings = self.settings

        return Observable<Void>.create { seal -> Disposable in
            settings.set(connectionDate: now)

            seal.onNext(())
            seal.onCompleted()

            return Disposables.create()
        }
    }

    private func syncDeviceSettings() -> Observable<Void> {
        let syncSoundsObservable = Observable.of(settings.sounds)
            .flatMap { Observable.from($0) }
            .flatMap { sound, trigger -> Observable<Void> in
                let command = SoundCommand(sound: sound, trigger: trigger)
                return self.chelseaband.perform(command: command)
            }.debug("SoundCommand")

        let speakerEnabled = settings.sounds.filter{ $0.value != .off }.count == 0

        let command = HardwareEnablement(led: settings.enabledLights, vibrationEnabled: settings.vibrate, screenEnabled: true, speakerEnabled: speakerEnabled)
        let hardwareEnablementObservable = chelseaband.perform(command: command)
            .debug("syncLightsAndVibrationObservable")

        return Observable.combineLatest(syncSoundsObservable, hardwareEnablementObservable).mapToVoid()
    }

    private func sendGoal() {
        let cmd = GoalCommand()
        chelseaband.perform(command: cmd).subscribe { e in
            print(e)
        }.disposed(by: disposeBag)
    }

    private func sendNews() {
        let value = "Using this option CocoaPods will assume the given folder to be the root of the Pod and will link the files directly from there in the Pods project."
        let command = MessageCommand(value: value)

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
