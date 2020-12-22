//
//  ChelseaBand.swift
//  ChelseabandSDK
//
//  Created by Vladyslav Shepitko on 24.11.2020.
//

import Foundation
import RxSwift 
import RxBluetoothKit
import CoreBluetooth

public protocol ChelseabandType {
    
    var connectionObservable: Observable<Device.State> { get }
    var batteryLevelObservable: Observable<UInt64> { get }
    
    init(device: DeviceType)
    
    func connect()
    func disconnect()

    func perform(command: Command) -> Observable<Void>

    func performSafe(command: Command, timeOut: DispatchTimeInterval) -> Observable<Void>
}

public final class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt64> {
        return batteryLevelSubject
    }
    
    public var connectionObservable: Observable<Device.State> {
        return device.connectionObservable
    } 

    private var readCharacteristicSubject: PublishSubject<Data> = .init()
    private var batteryLevelSubject: BehaviorSubject<UInt64> = .init(value: 0)
    private let device: DeviceType
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var setupDisposeBag = DisposeBag()

    required public init(device: DeviceType) {
        self.device = device
    }

    public func connect() {

        connectionDisposable = device
            .connect()
            .debug("\(self).main")
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }

                strongSelf.setupChelseaband(device: strongSelf.device)
            }, onError: { error in

            })
    }

    private func setupChelseaband(device: DeviceType) {
        setupDisposeBag = DisposeBag()

        device
            .readCharacteristicObservable
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap { $0.characteristic.value }
            .catchError { _ in .never() } //NOTE: update this to avoid sending never when error
            .subscribe(readCharacteristicSubject)
            .disposed(by: setupDisposeBag)

        let batteryCommand = BatteryCommand()
        batteryCommand.batteryLevel
            .debug("\(self).read-BatteryCommand")
            .subscribe(batteryLevelSubject)
            .disposed(by: setupDisposeBag)

        perform(command: batteryCommand)
            .subscribe()
            .disposed(by: setupDisposeBag)

        let timeCommand = TimeCommand()

        perform(command: timeCommand)
            .subscribe()
            .disposed(by: setupDisposeBag)
    }

    public func perform(command: Command) -> Observable<Void> {
        command
            .perform(on: self, notifyWith: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }

    public func performSafe(command: Command, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .debug("\(self).performSafe.trigger")
            .flatMap { _ -> Observable<Void> in
                self.perform(command: command)
            }
            .debug("\(self).performSafe.perform")
    }

    public func disconnect() {
        connectionDisposable?.dispose()
        connectionDisposable = .none
    }
}

extension Chelseaband: CommandNotifier {

    public var notifyObservable: Observable<Data> {
        readCharacteristicSubject
    }
}

extension Chelseaband: CommandExecutor {

    public var isConnected: Observable<Bool> {
        connectionObservable
            .startWith(.disconnected)
            .map { $0.isConnected }
    }

    public func write(data: Data) -> Observable<Void> {
        device.write(data: data, readTimeout: .milliseconds(250)).debug("\(self).write")
    }
}

