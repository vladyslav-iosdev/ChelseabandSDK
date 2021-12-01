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

    var batteryLevelObservable: Observable<UInt8> { get }
    
    var firmwareVersionObservable: Observable<String?> { get }

    var bluetoothHasConnected: Observable<Void> { get }

    var isSearching: Observable<Bool> { get }
    
    var bluetoothState: Observable<BluetoothState> { get }

    var lastConnectedPeripheralUUID: String? { get set }
    
    var locationManager: LocationManager { get }
    
    var isAuthorize: Observable<Bool> { get }

    init(device: DeviceType, apiBaseEndpoint: String, apiKey: String)
    
    func connect(peripheral: Peripheral)

    func isConnected(peripheral: Peripheral) -> Bool

    func isLastConnected(peripheral: Peripheral) -> Bool

    func disconnect(forgotLastPeripheral: Bool)
    
    func updateBandSettings(bandOrientation: BandOrientation) -> Observable<Void>

    // TODO: remove in future unused function perform
    func perform(command: Command) -> Observable<Void>

    func performSafe(command: Command, timeOut: DispatchTimeInterval) -> Observable<Void>
    
    func perform(command: CommandNew) -> Observable<Void>

    func performSafe(command: CommandNew, timeOut: DispatchTimeInterval) -> Observable<Void>
    
    func performRead(command: PerformReadCommandProtocol) -> Observable<Void>
    
    func performSafeRead(command: PerformReadCommandProtocol, timeOut: DispatchTimeInterval) -> Observable<Void>

    func setFCMToken(_ token: String)
    
    func register(phoneNumber: String) -> Observable<Void>
    
    func verify(phoneNumber: String, withOTPCode: String, andFCM: String) -> Observable<Bool>

    func sendVotingCommand(message: String, id: String) -> Observable<VotingResult>

    func sendMessageCommand(message: String, id: String) -> Observable<Void>
    
    func uploadImage(_ binImage: Data, imageType: ImageControlCommand.AlertImage) -> Observable<Void>
    
    func fetchFreshTicketAndUploadOnBand() -> Observable<TicketType>
    
    func fetchTicket() -> Observable<TicketType?>
    
    func sendMessageCommand(_ message: String, withType type: MessageType, id: String) -> Observable<Void>

    func sendGoalCommand(id: String) -> Observable<Void>
    
    func sendGoalCommandNew(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendVibrationCommand(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendLedCommand(data: Data, decoder: JSONDecoder) -> Observable<Void>
    
    func sendReaction(id: String)

    func startScanForPeripherals() -> Observable<[Peripheral]>

    func stopScanForPeripherals()
    
    func updateFirmware() -> Observable<Double>
}

public enum ChelseabandError: LocalizedError {
    case destroyed
    case userHaventTicket
    case bandDisconnected
    
    public var errorDescription: String? {
        switch self {
        case .destroyed:
            return "Chelseaband SDK was destroyed"
        case .userHaventTicket:
            return "Looks like user still haven't ticket on server"
        case .bandDisconnected:
            return "Looks like band is disconnected, connect band to phone and try again"
        }
    }
}

public final class Chelseaband: ChelseabandType {

    public var batteryLevelObservable: Observable<UInt8> {
        return batteryLevelSubject
    }
    
    public var firmwareVersionObservable: Observable<String?> {
        device.firmwareVersionSubject
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
    
    public var locationManager: LocationManager {
        locationTracker
    }
    
    public var isAuthorize: Observable<Bool> { UserDefaults.standard.isAuthorizeObservable }
    
    public var macAddressObservable: BehaviorSubject<String> = .init(value: "")

    private var reactionOnVoteSubject: PublishSubject<(VotingResult, String)> = .init()
    private var readCharacteristicSubject: PublishSubject<Data> = .init()
    private var batteryLevelSubject: BehaviorSubject<UInt8> = .init(value: 0)
    private let device: DeviceType
    private let statistic: Statistics
    private var connectionDisposable: Disposable? = .none
    private var disposeBag = DisposeBag()
    private var longLifeDisposeBag = DisposeBag()
    private let locationTracker: LocationTracker
    private let tokenBehaviourSubject = BehaviorSubject<String?>(value: nil)
    private let commandIdBehaviourSubject = BehaviorSubject<String?>(value: nil)
    private var suotaUpdate: SUOTAUpdateType? = nil

    required public init(device: DeviceType, apiBaseEndpoint: String, apiKey: String) {
        self.device = device
        self.statistic = API()
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
                strongSelf.statistic.register(bandName: peripheral.peripheral.name ?? "")
                strongSelf.lastConnectedPeripheralUUID = peripheral.peripheral.identifier.uuidString

                strongSelf.setupChelseaband(device: strongSelf.device)
                strongSelf.locationTracker.startObserving()
                strongSelf.observeForConnectionStatusChange()
                strongSelf.observeLocationChange()
                strongSelf.observeMACAddress()
                
            }, onError: { [weak self] error in
                guard let strongSelf = self else { return }
                
                strongSelf.disconnect(forgotLastPeripheral: false)
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
                self.statistic.sendBand(status: $0.isConnected)
            }).disposed(by: disposeBag)
    }

    private func observeForFCMTokenChange() {
        fcmTokenObservable
            .subscribe(onNext: { token in
                self.statistic.register(fcmToken: token)
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
                self.statistic.sendLocation(latitude: $0.latitude, longitude: $0.longitude)
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

        synchronizeBattery()
        synchonizeDeviceTime()

        synchonizeAccelerometer()
    }

    private func synchronizeBattery() {
        device.batteryCharacteristicObservable
            .flatMap { $0.observeValueUpdateAndSetNotification() }
            .compactMap{ $0.characteristic.value }
            .compactMap{ $0.uint8 }
            .bind(to: batteryLevelSubject)
            .disposed(by: disposeBag)
    }

    private func synchonizeAccelerometer() {
        let accelerometerCommand = AccelerometerCommand()
        Observable.combineLatest(commandIdObservable, accelerometerCommand.axisObservable)
            .filter{ !$0.1.values.isEmpty }
            .subscribe(onNext: { values in
                self.statistic.sendAccelerometer(values.1.values, forId: values.0)
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
                self.statistic.register(bandMacAddress: MACAddress)
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
    
    public func uploadImage(_ binImage: Data, imageType: ImageControlCommand.AlertImage) -> Observable<Void> {
        guard imageType.imageLength == binImage.count else {
            return Observable<Void>.error(ImageControlCommandError.wrongImageSize)
        }
        
        let imageControl = ImageControlCommand(imageType, imageData: binImage)
        let imageChunk = ImageChunkCommand(binImage)
        let commands = [
            performSafe(command: imageControl, timeOut: .seconds(5)),
            performSafe(command: imageChunk, timeOut: .seconds(5)),
            performSafeRead(command: imageControl, timeOut: .seconds(5))
        ]
        
        return Observable<Void>.create { [weak self] seal in
            let commandsDisposable = Observable.from(commands)
                .concatMap { $0 }
                .retryWhen { error in
                    error
                        .scan(0) { attempts, error in
                            let max = 3
                            guard attempts < max else { throw ImageControlCommandError.tooManyAttempts }
                            guard case ImageControlCommandError.imageHashNotEqual = error else { throw error }
                            return attempts + 1
                        }
                }
                .materialize()
                .subscribe(
                    onNext: { result in
                        switch result {
                        case .error(let error):
                            seal.onError(error)
                        default:
                            break
                        }
                    }, onCompleted: {
                        seal.onNext(())
                        seal.onCompleted()
                    })
            
            return Disposables.create {
                commandsDisposable.dispose()
            }
        }
    }
    
    public func fetchFreshTicketAndUploadOnBand() -> Observable<TicketType> {
        Observable.combineLatest(statistic.fetchTicket(), connectionObservable)
            .skipWhile { !$0.1.isConnected }
            .timeout(.seconds(15), scheduler: MainScheduler.instance)
            .take(1)
            .catchError { error in
                if case RxSwift.RxError.timeout = error {
                    throw ChelseabandError.bandDisconnected
                } else {
                    throw error
                }
            }
            .map{ $0.0 }
            .map { serverTicket -> TicketType in
                if let ticket = serverTicket {
                    return ticket
                } else {
                    throw ChelseabandError.userHaventTicket
                }
            }
            .flatMap { [weak self] ticket -> Observable<Observable<TicketType>> in
                guard let strongSelf = self else { throw ChelseabandError.destroyed }
                do {
                    let seatCommand = try SeatPositionCommand(fromTicket: ticket)
                    let nfcCommand = try NFCCommand(fromTicket: ticket)
                    return Observable.from([nfcCommand.perform(on: strongSelf).map { ticket },
                                            seatCommand.perform(on: strongSelf).map { ticket }])
                } catch let error {
                    throw error
                }
            }
            .concatMap { $0 }
            .takeLast(1)
    }
    
    public func fetchTicket() -> Observable<TicketType?> {
        statistic.fetchTicket()
            .take(1)
    }
    
    public func sendMessageCommand(_ message: String, withType type: MessageType, id: String) -> Observable<Void> {
        commandIdBehaviourSubject.onNext(id)
        
        let messageCommand = MessageCommandNew(message, type: type)

        return performSafe(command: messageCommand, timeOut: .seconds(5))
    }

    public func sendGoalCommand(id: String) -> Observable<Void> {
        commandIdBehaviourSubject.onNext(id)
        
        return performSafe(command: GoalCommand(), timeOut: .seconds(5))
    }
    
    public func sendGoalCommandNew(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let scoreCommand = try ScoreCommand(fromData: data, withDecoder: decoder)
            return performSafe(command: scoreCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }

    public func sendVotingCommand(message: String, id: String) -> Observable<VotingResult> {
        commandIdBehaviourSubject.onNext(id)

        let command0 = VotingCommand(value: message)
        command0.votingObservable.subscribe(onNext: { response in
            self.statistic.sendVotingResponse(response, id)
            self.reactionOnVoteSubject.onNext((response, id))
        }).disposed(by: disposeBag)

        let command1 = performSafe(command: command0, timeOut: .seconds(5))
        return Observable.zip(command1, command0.votingObservable).map { (_, response) -> VotingResult in
            return response
        }
    }
    
    public func sendVibrationCommand(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let vibrationCommand = try VibrationCommandNew(fromData: data, withDecoder: decoder)
            return performSafe(command: vibrationCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }
    
    public func sendLedCommand(data: Data, decoder: JSONDecoder) -> Observable<Void> {
        do {
            let ledCommand = try LEDCommandNew(fromData: data, withDecoder: decoder)
            return performSafe(command: ledCommand, timeOut: .seconds(5))
        } catch {
            return Observable<Void>.error(error)
        }
    }
    
    public func updateFirmware() -> Observable<Double> {
        if let suota = suotaUpdate {
            return suota.percentOfUploadingObservable
        }
        
        //TODO: remove contentsOfFile logic
        let suota = SUOTAUpdate(updateDevice: device,
                                withData: NSData(contentsOfFile: Bundle.main.path(forResource: "fanband", ofType: "img")!)! as Data)
        
        suota.percentOfUploadingObservable
            .subscribe(onError: { [weak self] _ in
                self?.suotaUpdate = nil
            }, onCompleted: { [weak self] in
                self?.suotaUpdate = nil
            })
            .disposed(by: disposeBag)
        
        suotaUpdate = suota
        return suota.percentOfUploadingObservable
    }
    
    public func updateBandSettings(bandOrientation: BandOrientation) -> Observable<Void> {
        let deviceSettingsCommand = DeviceSettingsCommand(bandOrientation: bandOrientation)
        return performSafe(command: deviceSettingsCommand, timeOut: .seconds(5))
    }

    public func perform(command: Command) -> Observable<Void> {
        command
            .perform(on: self, notifyWith: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }
    
    public func perform(command: CommandNew) -> Observable<Void> {
        command
            .perform(on: self)
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
    
    public func performSafe(command: CommandNew, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .skipWhile { _ in self.suotaUpdate != nil }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Void> in
                self.perform(command: command)
            }
    }
    
    public func performSafeRead(command: PerformReadCommandProtocol, timeOut: DispatchTimeInterval = .seconds(3)) -> Observable<Void> {
        connectionObservable
            .skipWhile { !$0.isConnected }
            .skipWhile { _ in self.suotaUpdate != nil }
            .take(1)
            .timeout(timeOut, scheduler: MainScheduler.instance)
            .flatMap { _ -> Observable<Void> in
                self.performRead(command: command)
            }
    }
    
    public func performRead(command: PerformReadCommandProtocol) -> Observable<Void> {
        command
            .performRead(on: self)
            .observeOn(MainScheduler.instance)
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
    }

    public func disconnect(forgotLastPeripheral: Bool) {
        connectionDisposable?.dispose()
        connectionDisposable = .none
        connectedPeripheral = .none
        if forgotLastPeripheral {
            lastConnectedPeripheralUUID = .none
        }
        macAddressObservable.onNext(" ")
    }

    public func setFCMToken(_ token: String) {
        tokenBehaviourSubject.onNext(token)
    }
    
    public func register(phoneNumber: String) -> Observable<Void> {
        statistic.register(phoneNumber: phoneNumber)
    }
    
    public func verify(phoneNumber: String, withOTPCode OTPCode: String, andFCM fcm: String) -> Observable<Bool> {
        statistic.verify(phoneNumber: phoneNumber, withOTPCode: OTPCode, andFCM: fcm)
    }
    
    public func sendReaction(id: String) {
        statistic.sendReaction(id)
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
    
    public func write(command: WritableCommand) -> Observable<Void> {
        device.write(command: command, timeout: .seconds(5))
    }
    
    public func read(command: ReadableCommand) -> Observable<Data?> {
        device.read(command: command, timeout: .seconds(5))
    }
}
