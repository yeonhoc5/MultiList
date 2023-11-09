//
//  TextItemViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/26.
//

import Foundation


class TextItemViewModel: ObservableObject {
    
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
}
