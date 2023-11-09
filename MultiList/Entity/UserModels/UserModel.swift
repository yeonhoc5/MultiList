//
//  UserModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation

struct UserModel {
    
    var accountType: UserType
    let userUID: String
    let userEmail: String
    let dateRegistered: Date
    
    var userNickName: String
    
    init(accountType: UserType, 
         userUID: String,
         userEmail: String,
         dateRegistered: Date,
         userNickName: String! = "손님") {
        self.accountType = accountType
        self.userUID = userUID
        self.userEmail = userEmail
        self.dateRegistered = dateRegistered
        self.userNickName = userNickName
    }
}
