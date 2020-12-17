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
    var vibrate: Observable<Bool> { get }
    func set(vibrate newValue: Bool) -> Single<Void>

    func getLight(trigger: LightTrigger) -> Observable<Bool>
    func set(value: Bool, trigger: LightTrigger) -> Single<Void>

    func getSound(trigger: SoundTrigger) -> Observable<Sound>
    func set(sound: Sound, trigger: SoundTrigger) -> Single<Void>

    var connectionDate: Observable<Date?> { get }
    func set(connectionDate: Date) -> Single<Void>
}

class SettingsService: SettingsServiceType {

    private enum Keys {
        static let vibrate = "vibrateKey"

        static let newsLight = "newsLightKey"
        static let goalLight = "goalLightKey"

        static let newsSound = "newsSoundKey"
        static let goalSound = "goalSoundKey"
        static let gestureSound = "gestureSoundKey"
        static let connectionDate = "connectionDateKey"
    }

    private static func key(soundTrigger: SoundTrigger) -> String {
        switch soundTrigger {
        case .goal:
            return Keys.goalSound
        case .news:
            return Keys.newsSound
        case .gesture:
            return Keys.gestureSound
        }
    }

    private static func key(lightTrigger: LightTrigger) -> String {
        switch lightTrigger {
        case .goal:
            return Keys.goalLight
        case .news:
            return Keys.newsLight
        }
    }

    private let defaults: UserDefaults

    func getLight(trigger: LightTrigger) -> Observable<Bool> {
        defaults.rx.observe(Bool.self, SettingsService.key(lightTrigger: trigger)).map { value in
            return value ?? false
        }.take(1)
    }

    func set(value: Bool, trigger: LightTrigger) -> Single<Void> {
        return Single.create { [weak self] seal -> Disposable in
            self?.defaults.set(value, forKey: SettingsService.key(lightTrigger: trigger))

            seal(.success(()))

            return Disposables.create()
        }
    }

    func set(connectionDate value: Date) -> Single<Void> {
        return Single.create { [weak self] seal -> Disposable in
            self?.defaults.set(value, forKey: Keys.connectionDate)

            seal(.success(()))

            return Disposables.create()
        }
    }

    var connectionDate: Observable<Date?> {
        defaults.rx.observe(Date.self, Keys.connectionDate)
    }

    func getSound(trigger: SoundTrigger) -> Observable<Sound> {
        defaults.rx.observe(String.self, SettingsService.key(soundTrigger: trigger)).map { value in
            if let val = value {
                return Sound(rawValue: val) ?? Sound.off
            } else {
                return Sound.off
            }
        }.take(1)
    }

    func set(sound: Sound, trigger: SoundTrigger) -> Single<Void> {
        return Single.create { [weak self] seal -> Disposable in
            self?.defaults.set(sound.rawValue, forKey: SettingsService.key(soundTrigger: trigger))

            seal(.success(()))

            return Disposables.create()
        }
    }

    var vibrate: Observable<Bool> {
        defaults.rx.observe(Bool.self, Keys.vibrate).map { value in
            value ?? false
        }.take(1)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set(vibrate newValue: Bool) -> Single<Void> {
        return Single.create { [weak self] seal -> Disposable in
            self?.defaults.set(newValue, forKey: Keys.vibrate)

            seal(.success(()))

            return Disposables.create()
        }
    }

}
