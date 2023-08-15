//
//  UserModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation

let sampleUser = UserModel(accountType: 1,
                           userUID: "sampleuser",
                           userEmail: "sameple@google.com",
                           dateRegistered: Date(),
                           userNickName: "샘플 User",
                           sectionList: [])

struct UserModel: Codable {
    var accountType: Int
    
    let userUID: String
    let userEmail: String?
    let dateRegistered: Date
    
    var userNickName: String = "익명의 손님"
    var freindList: [Friend] = []
    var sectionList: [SectionList] = []
}

struct Friend: Codable {
    let userUID: String
    let userEmail: String
    var userNickName: String
}

struct SectionList: Codable {
    var sectionID: UUID
    var order: Int // 순서값으로 이용
    var sectionName: String
    var multiList: [MultiList]
}

struct MultiList: Codable {
    let multiID: UUID
    var order: Int
    let listType: Int
    var contents: Contents
//    var users: [listAtUser]
}

struct Contents: Codable {
    let contentID: String
    var title: String
}

typealias listAtUser = (UserModel, Bool)
