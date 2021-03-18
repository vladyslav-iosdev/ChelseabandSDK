# ChelseabandSDK

[![CI Status](https://img.shields.io/travis/vladyslav-iosdev/ChelseabandSDK.svg?style=flat)](https://travis-ci.org/vladyslav-iosdev/ChelseabandSDK)
[![Version](https://img.shields.io/cocoapods/v/ChelseabandSDK.svg?style=flat)](https://cocoapods.org/pods/ChelseabandSDK)
[![License](https://img.shields.io/cocoapods/l/ChelseabandSDK.svg?style=flat)](https://cocoapods.org/pods/ChelseabandSDK)
[![Platform](https://img.shields.io/cocoapods/p/ChelseabandSDK.svg?style=flat)](https://cocoapods.org/pods/ChelseabandSDK)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

ChelseabandSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'ChelseabandSDK'
```

Folder `ChelseabandSDK` contains example usage of SDK.

For library usage first you need is to define configuration for `Chelseaband`
Configuration protocol contains identifiers of service to use, read/write characteristics identifiers

```
enum ChelseabandConfiguration: Configuration {
    case initial

    public var service: ID {
        switch self {
        case .initial:
            return ID(string: "<Your identifier>")
        }
    }

    public var writeCharacteristic: ID {
        switch self {
        case .initial:
            return ID(string: "<Your identifier>")
        }
    }

    public var readCharacteristic: ID {
        switch self {
        case .initial:
            return ID(string: "Your identifier")
        }
    }
}
```
Next step you need to create an instance of `chelseaband`, object responsible for hight lever access to device. Its creating requires `DeviceType`  protocol that represents low level access to bluetooth device. It responsible for scanning new devices, connection to the device. Reconnecting when connection failure. Using protocol type `DeviceType` allows you to easily add replaced `dummy` objects instead default implementation of `Device`.

```
private lazy var chelseaband: ChelseabandType =  {
    let device = Device(configuration: ChelseabandConfiguration.initial)
    return Chelseaband(device: device)
}
```
`chelseaband` allows you to handle bluetooth connection state, and provides observable `bluetoothHasConnected` that fires when state has changed.

```
chelseaband.bluetoothHasConnected.subscribe(onNext: { [weak self] _ in
    guard let strongSelf = self else { return }

    strongSelf.chelseaband.connect()
}).disposed(by: disposeBag)
```

Call `disconnect` method to disconnect from the device.

```
chelseaband.disconnect()
```
Very important thing that need to be performed when provider get connected to the device is to syncronize settings with the device.  
```
chelseaband.connectionObservable
    .filter { $0.isConnected }
    .flatMap { _ -> Observable<Void> in
        return Observable.combineLatest(
            self.syncDeviceSettings()
        ).mapToVoid()
    }
    .subscribe()
    .disposed(by: disposeBag) 
```

Sync device settings include performing two commands, syncronize Sounds settings and hardware enablement.
```
func syncDeviceSettings() -> Observable<Void> {
    let syncSoundsObservable = Observable.of(settings.sounds)
        .flatMap { Observable.from($0) }
        .flatMap { sound, trigger -> Observable<Void> in
            let command = SoundCommand(sound: sound, trigger: trigger)
            return self.chelseaband.perform(command: command)
        }

    let speakerEnabled = settings.sounds.filter{ $0.value != .off }.count == 0

    let command = HardwareEnablement(led: settings.enabledLights, vibrationEnabled: settings.vibrate, screenEnabled: true, speakerEnabled: speakerEnabled)
    let hardwareEnablementObservable = chelseaband.perform(command: command)

    return Observable.combineLatest(syncSoundsObservable, hardwareEnablementObservable).mapToVoid()
} 
```

`chelseaband` provides several banch of commands for bluetooth device (commands scope can be finded in `ChelseabandSDK/Commands` foldel):

- TimeCommand - performs time syncronization with device. Notice! This command get calles automatically when provider get connected to ble device.
- GoalCommand - sends Goal command to the device.
- BatteryCommand - performs fetching battery electric charge percentage, get called every 5 seconds `by default`.   This command get calles automatically when provider get connected to ble device.  
- MessageCommand - sends text message to the device.
- VotingCommand - performs send start voting on the device. Command accepts:
    - `message: String` - voting message string.
To get response from command subscribe to `votingObservable`  from `VotingCommand`. `votingObservable` opdates on users accepts or declines voting alert. Returns type `VotingResult`.
```public enum VotingResult {
    case approve
    case refuse
    case ignore
}
```

- HardwareEnablement - 


## Author

vladyslav-iosdev, vladyslav.shepitko@gmail.com

## License

ChelseabandSDK is available under the MIT license. See the LICENSE file for more info.
