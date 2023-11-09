//
//  TextListDetailViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 11/6/23.
//

import Foundation

class TextListDetailViewModel: ObservableObject {
    
    let userData: UserData
    var textListID: UUID
    
    init(userData: UserData, textListID: UUID) {
        self.userData = userData
        self.textListID = textListID
    }
    
    
    
}
