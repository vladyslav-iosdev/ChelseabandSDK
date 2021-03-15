//
//  SettingsService.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import UIKit
import RxSwift
import ChelseabandSDK

protocol SettingsServiceType {
    var vibrate: Bool { get }

    func set(vibrate newValue: Bool)

    func getLight(trigger: CommandTrigger) -> Bool
    func set(lightEnabled: Bool, trigger: CommandTrigger)

    func getSound(trigger: CommandTrigger) -> Sound
    func set(sound: Sound, trigger: CommandTrigger)

    var connectionDate: Observable<Date?> { get }
    func set(connectionDate: Date)

    var isDebugEnabled: Bool { get set }

    var enabledLights: [CommandTrigger] { get }

    var sounds: [(value: Sound, trigger: CommandTrigger)] { get }
}

class SettingsService: SettingsServiceType {

    private enum Keys {
        static let vibrate = "vibrateKey"

        static let newsLight = "newsLightKey"
        static let goalLight = "goalLightKey"
        static let gestureLight = "gestureLightKey"

        static let newsSound = "newsSoundKey"
        static let goalSound = "goalSoundKey"
        static let gestureSound = "gestureSoundKey"
        static let connectionDate = "connectionDateKey"
        static let isDebugEnabled = "isDebugEnabledKey"
    }

    var enabledLights: [CommandTrigger] {
        CommandTrigger.allCases.map { trigger -> (value: Bool, trigger: CommandTrigger) in
            return (getLight(trigger: trigger), trigger)
        }.filter{ $0.0 }.map{ $0.1 }
    }

    var sounds: [(value: Sound, trigger: CommandTrigger)] {
        CommandTrigger.allCases.map { trigger -> (value: Sound, trigger: CommandTrigger) in
            return (getSound(trigger: trigger), trigger)
        }
    }

    private static func key(soundTrigger: CommandTrigger) -> String {
        switch soundTrigger {
        case .goal:
            return Keys.goalSound
        case .news:
            return Keys.newsSound
        case .gesture:
            return Keys.gestureSound
        }
    }

    private static func key(trigger: CommandTrigger) -> String {
        switch trigger {
        case .goal:
            return Keys.goalLight
        case .news:
            return Keys.newsLight
        case .gesture:
            return Keys.gestureLight
        }
    }

    private let defaults: UserDefaults

    var isDebugEnabled: Bool {
        get {
            defaults.bool(forKey: Keys.isDebugEnabled)
        } set {
            defaults.set(newValue, forKey: Keys.isDebugEnabled)
        }
    }

    func getLight(trigger: CommandTrigger) -> Bool {
        defaults.bool(forKey: SettingsService.key(trigger: trigger))
    }

    func set(lightEnabled: Bool, trigger: CommandTrigger) {
        defaults.set(lightEnabled, forKey: SettingsService.key(trigger: trigger))
    }

    func set(connectionDate value: Date) {
        defaults.set(value.timeIntervalSince1970, forKey: Keys.connectionDate)
    }

    var connectionDate: Observable<Date?> {
        defaults.rx.observe(Double.self, Keys.connectionDate).map {
            if let value = $0 {
                return Date(timeIntervalSince1970: value)
            } else {
                return nil
            }
        }
    }

    func getSound(trigger: CommandTrigger) -> Sound {
        if let value = defaults.string(forKey: SettingsService.key(soundTrigger: trigger)) {
            return Sound(rawValue: value) ?? Sound.off
        } else {
            return Sound.off
        }
    }

    func set(sound: Sound, trigger: CommandTrigger) {
        defaults.set(sound.rawValue, forKey: SettingsService.key(soundTrigger: trigger))
    }

    var vibrate: Bool {
        defaults.bool(forKey: Keys.vibrate)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(vibrate newValue: Bool) {
        defaults.set(newValue, forKey: Keys.vibrate)
    }

}
