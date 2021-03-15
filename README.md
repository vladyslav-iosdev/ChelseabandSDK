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

Call `dissconnect` method to disconnect from the device.

```
chelseaband.disconnect()
```

`chelseaband` provides several banch of commands for bluetooth device (commands scope can be finded in `ChelseabandSDK/Commands` foldel):

- TimeCommand
- GoalCommand
- LEDCommand
- BatteryCommand
- MessageCommand
- VibrationCommand
- ScreenCommand
- VotingCommand
- AccelerometerCommand
- HardwareEnablement


## Author

vladyslav-iosdev, vladyslav.shepitko@gmail.com

## License

ChelseabandSDK is available under the MIT license. See the LICENSE file for more info.
