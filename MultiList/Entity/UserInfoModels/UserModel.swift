//
//  UserModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation

//class UserModel: ObservableObject {
//
//    var accountType: Int
//    let userUID: String
//    let userEmail: String
//    let dateRegistered: Date
//
//    @Published var userNickName: String
//    // 데이터 1.
//    @Published var sectionList: [SectionList] = []
//    @Published var friendList: [Friend] = []
//    // 데이터 3.
//    @Published var sharedMultiList: [ShareMultiList] = []
//    @Published var sharingMultiList: [ShareMultiList] = []
//
//
//    init(accountType: Int, userUID: String, userEmail: String, dateRegistered: Date, userNickName: String! = "익명의 손님", sectionList: [SectionList] = [], friendList: [Friend] = []) {
//        self.accountType = accountType
//        self.userUID = userUID
//        self.userEmail = userEmail
//        self.dateRegistered = dateRegistered
//        self.userNickName = userNickName
//        self.sectionList = sectionList
//        self.friendList = friendList
//    }
//}


struct UserModel {
    
    var accountType: UserType
    let userUID: String
    let userEmail: String
    let dateRegistered: Date
    
    var userNickName: String
    
    init(accountType: UserType, userUID: String, userEmail: String, dateRegistered: Date, userNickName: String! = "손님",
         sectionList: [SectionList] = [], friendList: [Friend] = []) {
        self.accountType = accountType
        self.userUID = userUID
        self.userEmail = userEmail
        self.dateRegistered = dateRegistered
        self.userNickName = userNickName
//        self.sectionList = sectionList
//        self.friendList = friendList
    }
}


enum UserType: String {
    case anonymousUser
    case google
    case naver
    case kakao
    case appleUser
    
    static func returnIntValue(type: UserType) -> Int {
        switch type {
        case .anonymousUser: return 0
        case .google: return 1
        case .naver: return 2
        case .kakao: return 3
        case .appleUser: return 4
        }
    }
    
    static func returnTypeValue(int: Int) -> UserType {
        switch int {
        case 0: return .anonymousUser
        case 1: return .google
        case 2: return .naver
        case 3: return .kakao
        case 4: return .appleUser
        default: break
        }
        return .anonymousUser
    }
}
