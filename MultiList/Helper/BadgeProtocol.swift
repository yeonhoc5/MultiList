//
//  BadgeProtocol.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/10/23.
//

import SwiftUI

protocol BadgeNumberProvidable: AnyObject {
    var applicationIconBadgeNumber: Int { get set }
}

extension UIApplication: BadgeNumberProvidable {}

actor AppAlertBadgeManager {
    
    let application: BadgeNumberProvidable
    
    init(application: BadgeNumberProvidable) {
        self.application = application
    }
    
    @MainActor
    func setAlertBadge(number: Int) {
        application.applicationIconBadgeNumber = number
    }
    
    @MainActor
    func resetAlertBadgetNumber() {
        application.applicationIconBadgeNumber = 0
    }
}
