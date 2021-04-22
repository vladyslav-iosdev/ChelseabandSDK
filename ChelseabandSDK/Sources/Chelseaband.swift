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
import CoreLocation

public typealias Peripheral = ScannedPeripheral
public typealias BluetoothState = RxBluetoothKit.BluetoothState

public protocol ChelseabandType {
    
    var macAddressObservable: BehaviorSubject<String> { get }
    
    var reactionOnVoteObservable: Observable<(VotingResult, String)> { get }
    
    var connectionObservable: Observable<Device.State> { get }

    var batteryLevelObservable: Observable<UInt64> { get }

    var bluetoothHasConnected: Observable<Void> { get }

    var isSearching: Observable<Bool> { get }
    
    var bluetoothState: Observable<BluetoothState> { get }

    var lastConnectedPeripheralUUID: String? { get set }

    init(device: DeviceType, apiBaseEndpoint: String, apiKey: String)
    
    func connect(peripheral: Peripheral)

    func isConnected(peripheral: Peripheral) -> Bool

    func isLastConnected(peripheral: Peripheral) -> Bool

    func disconnect()

    func perform(command: Command) -> Observable<Void>

    func performSafe(command: Command, timeOut: DispatchTimeInterval) -> Observable<Void>

    func setFMCToken(_ token: String)

    func sendVotingCommand(message: String, id: String) -> Observable<VotingResult>

    func sendMessageCommand(message: String, id: String) -> Observable<Void>

    func sendGoalCommand(id: String) -> Observable<Void>
    
    func sendReaction(id: String)

    func startScanForPeripherals() -> Observable<[Peripheral]>

    func stopScanForPeripherals()
}

public final class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt64> {
        return batteryLevelSubject
    }
    
    public var reactionOnVoteObservable: Observable<(VotingResult, String)> {
        return reactionOnVoteSubject.map { $0 }
    }
    
    public var connectionObservable: Observable<Device.State> {
        return device.connectionObservable
    }

    public var bluetoothHasConnected: Observable<Void> {
        return device.bluetoothHasConnected
    }

    public var isSearching: Observable<Bool> {
        return device.bluetoothIsSearching
    }
    
    public var bluetoothState: Observable<BluetoothState> {
        return device.bluetoothState
    }

    public var lastConnectedPeripheralUUID: String? {
        get {
            UserDefaults.standard.lastConnectedPeripheralUUID
        }
        set {
            UserDefaults.standard.lastConnectedPeripheralUUID = newValue
        }
    }
    
    public var macAddressObservable: BehaviorSubject<String> = .init(value: "")

    private var reactionOnVoteSubject: PublishSubject<(VotingResult, String)> = .init()
    private var readCharacteristicSubject: PublishSubject<Data> = .init()
    private var batteryLevelSubject: BehaviorSubject<UInt64> = .init(value: 0)
    private let device: DeviceType
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var longLifeDisposeBag = DisposeBag()
    private let locationTracker: LocationTracker
    private let tokenBehaviourSubject = BehaviorSubject<String?>(value: nil)
    private let commandIdBehaviourSubject = BehaviorSubject<String?>(value: nil)

    required public init(device: DeviceType, apiBaseEndpoint: String, apiKey: String) {
        self.device = device
        UserDefaults.standard.apiBaseEndpoint = apiBaseEndpoint
        UserDefaults.standard.apiKey = apiKey
        
        locationTracker = LocationManagerTracker()
        observeForFCMTokenChange()
    }
    private var connectedPeripheral: Peripheral?

    public func isConnected(peripheral: Peripheral) -> Bool {
        return connectedPeripheral?.peripheral.identifier == peripheral.peripheral.identifier
    }

    public func connect(peripheral: Peripheral) {
        connectionDisposable = device
            .connect(peripheral: peripheral)
            .subscribe(onNext: { [weak self] _ in
                guard let strongSelf = self else { return }
                strongSelf.connectedPeripheral = peripheral
                strongSelf.lastConnectedPeripheralUUID = peripheral.peripheral.identifier.uuidString

                strongSelf.setupChelseaband(device: strongSelf.device)
                strongSelf.locationTracker.startObserving()
                strongSelf.observeForConnectionStatusChange()
                strongSelf.observeLocationChange()
                strongSelf.observeMACAddress()
                
            }, onError: { [weak self] error in
                guard let strongSelf = self else { return }

                strongSelf.disconnect()
            })
    }

    public func isLastConnected(peripheral: Peripheral) -> Bool {
        lastConnectedPeripheralUUID == peripheral.peripheral.identifier.uuidString
    }

    private var fcmTokenObservable: Observable<String> {
        tokenBehaviourSubject
            .compactMap{ $0 }
    }
    
    private var commandIdObservable: Observable<String> {
        commandIdBehaviourSubject
            .compactMap{ $0 }
    }

    private var connectedOrDisconnectedObservable: Observable<Device.State> {
        connectionObservable
            .skip(1)
            .filter { $0 == .connected || $0 == .disconnected }
    }

    private func observeForConnectionStatusChange() {
        Observable.combineLatest(fcmTokenObservable, connectedOrDisconnectedObservable)
            .map { $0.1 }
            .subscribe(onNext: {
                API().sendBand(status: $0.isConnected)
            }).disposed(by: disposeBag)
    }

    private func observeForFCMTokenChange() {
        fcmTokenObservable
            .subscribe(onNext: { token in
                API().register(fmcToken: token)
            }).disposed(by: longLifeDisposeBag)
    }

    private func observeLocationChange() {
        //NOTE: throttle to avoid to many requests to server
        Observable.combineLatest(fcmTokenObservable, locationTracker.location.throttle(.seconds(60), scheduler: MainScheduler.instance))
            .map { $0.1 }
            .flatMap { location -> Observable<CLLocationCoordinate2D> in
                self.connectionObservable
                    .filter { $0.isConnected }
                    .map{ _ in location }
            }
            .subscribe(onNext: {
                API().sendLocation(latitude: $0.latitude, longitude: $0.longitude)
            }).disposed(by: disposeBag)
    }

    private func setupChelseaband(device: DeviceType) {
        disposeBag = DisposeBag()
        locationTracker.stopObserving()
        
        device
            .readCharacteristicObservable
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap { $0.characteristic.value }
            .catchError { _ in .never() } //NOTE: update this to avoid sending never when error
            .subscribe(readCharacteristicSubject)
            .disposed(by: disposeBag)

        synchonizeBattery()
        synchonizeDeviceTime()

        synchonizeAccelerometer()
    }

    private func synchonizeBattery() {
        let batteryCommand = BatteryCommand()
        batteryCommand.batteryLevel
            .subscribe(batteryLevelSubject)
            .disposed(by: disposeBag)

        perform(command: batteryCommand)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func synchonizeAccelerometer() {
        let accelerometerCommand = AccelerometerCommand()
        Observable.combineLatest(commandIdObservable, accelerometerCommand.axisObservable)
            .filter{ !$0.1.values.isEmpty }
            .subscribe(onNext: { values in
                API().sendAccelerometer(values.1.values, forId: values.0)
        }).disposed(by: disposeBag)

        perform(command: accelerometerCommand)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func synchonizeDeviceTime() {
        let timeCommand = TimeCommand()

        perform(command: timeCommand)
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func observeMACAddress() {
        let macAddressCommand = MACAddressCommand()

        //NOTE: combinelatest didn't work because observing of fcm didn't call after connection to the band at first time
        macAddressCommand.MACAddressObservable
            .subscribe(onNext: { MACAddress in
                API().register(bandMacAddress: MACAddress)
                self.macAddressObservable.onNext(MACAddress)
            }).disposed(by: disposeBag)

        perform(command: macAddressCommand).subscribe(onNext: { _ in

        }).disposed(by: disposeBag)
    }

    public func sendMessageCommand(message: String, id: String) -> Observable<Void> {
        commandIdBehaviourSubject.onNext(id)

        let command0 = MessageCommand(value: message)

        return performSafe(command: command0, timeOut: .seconds(5))
    }

    public func sendGoalCommand(id: String) -> Observable<Void> {
        commandIdBehaviourSubject.onNext(id)
        
        return performSafe(command: GoalCommand(), timeOut: .seconds(5))
    }

    public func sendVotingCommand(message: String, id: String) -> Observable<VotingResult> {
        commandIdBehaviourSubject.onNext(id)

        let command0 = VotingCommand(value: message)
        command0.votingObservable.subscribe(onNext: { response in
            API().sendVotingResponse(response, id)
            self.reactionOnVoteSubject.onNext((response, id))
        }).disposed(by: disposeBag)

        let command1 = performSafe(command: command0, timeOut: .seconds(5))
        return Observable.zip(command1, command0.votingObservable).map { (_, response) -> VotingResult in
            return response
        }
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
            .flatMap { _ -> Observable<Void> in
                self.perform(command: command)
            }
    }

    public func disconnect() {
        connectionDisposable?.dispose()
        connectionDisposable = .none
        connectedPeripheral = .none
        lastConnectedPeripheralUUID = .none
        macAddressObservable.onNext(" ")
    }

    public func setFMCToken(_ token: String) {
        tokenBehaviourSubject.onNext(token)
    }
    
    public func sendReaction(id: String) {
        API().sendReaction(id)
    }

    public func startScanForPeripherals() -> Observable<[Peripheral]> {
        device
            .startScanForPeripherals()
            .share(replay: 1)
    }

    public func stopScanForPeripherals() {
        device.stopScanForPeripherals()
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
        device.write(data: data, timeout: .seconds(5))
    }
}
