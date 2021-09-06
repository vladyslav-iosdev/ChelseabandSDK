//
//  Date.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 06.09.2021.
//

import Foundation

extension Date {
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}
