//
//  VibrationSectionViewModel.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 03.12.2020.
//  Copyright © 2020 Sonerim. All rights reserved.
//

import UIKit

struct VibrationSectionViewModel {
    var rows: [AlertRowViewModel] = []

    private let settingsService: SettingsServiceType

    init(settingsService: SettingsServiceType) {
        self.settingsService = settingsService
    }

    var numberOfRows: Int {
        rows.count
    }
}
