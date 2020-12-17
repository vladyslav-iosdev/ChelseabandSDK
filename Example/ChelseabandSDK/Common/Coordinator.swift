//
//  Coordinator.swift
//  ChelseabandSDK_Example
//
//  Created by Vladyslav Shepitko on 25.11.2020.
//  Copyright © 2020 CocoaPods. All rights reserved.
//

import Foundation

protocol Coordinator: class {
    var coordinators: [Coordinator] { get set }
}

extension Coordinator {
    func addCoordinator(_ coordinator: Coordinator) {
        coordinators.append(coordinator)
    }

    func removeCoordinator(_ coordinator: Coordinator) {
        coordinators = coordinators.filter { $0 !== coordinator } 
    }

    func removeAllCoordinators() {
        coordinators.removeAll()
    }
}
