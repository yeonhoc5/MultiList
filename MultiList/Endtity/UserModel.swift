//
//  UserModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation

struct UserModel: Codable {
    var accountType: Int
    
    let userUID: String
    let userEmail: String?
    let dateRegistered: Date
    
    var userNickName: String = "익명의 손님"
    var sectionList: [SectionList] = []
    var friendList: [Friend] = []
}

struct Friend: Codable {
    let userUID: String
    let userEmail: String
    var userNickName: String
}

struct SectionList: Codable {
    var sectionID: UUID = UUID()
    var order: Int // 순서값으로 이용
    var sectionName: String
    var color: Int
    var multiList: [MultiList]
    
    init(order: Int, sectionName: String, color: Int, multiList: [MultiList] = []) {
        self.order = order
        self.sectionName = sectionName
        self.color = color
        self.multiList = multiList
    }
}

struct MultiList: Codable {
    var multiID: UUID = UUID()
    var order: Int
    let listType: Int
}

struct Contents: Codable {
    var contentID: UUID
    var title: String
}

typealias listAtUser = (UserModel, Bool)

let samplefriends = [
    Friend(userUID: "asdf", userEmail: "friend1@naver.com", userNickName: "개똥이"),
    Friend(userUID: "base", userEmail: "friend1@naver.com", userNickName: "옥자"),
    Friend(userUID: "ddase", userEmail: "friend1@naver.com", userNickName: "점순이")
    ]


let sampleMultiList1 = MultiList(order: 0, listType: 0)
let sampleMultiList2 = MultiList(order: 1, listType: 1)
let sampleMultiList3 = MultiList(order: 0, listType: 0)
let sampleMultiList4 = MultiList(order: 0, listType: 1)


let sampleContent1 = Contents(contentID: UUID(), title: "토레스 구매")
let sampleContent2 = Contents(contentID: UUID(), title: "오키나와 준비")
let sampleContent3 = Contents(contentID: UUID(), title: "영화 리스트")
let sampleContent4 = Contents(contentID: UUID(), title: "앱 제작")


let sampleList: [SectionList] = [
    SectionList(order: 0, sectionName: "개인", color: 0, multiList: [
        sampleMultiList1, sampleMultiList2
    ]),
    SectionList(order: 1, sectionName: "공유", color: 1, multiList: [
        sampleMultiList3
    ]),
    SectionList(order: 2, sectionName: "달마다", color: 2, multiList: [
        sampleMultiList4
    ])
]

let sampleUser = UserModel(accountType: 1,
                           userUID: "sampleuser",
                           userEmail: "sameple@google.com",
                           dateRegistered: Date(),
                           userNickName: "샘플 User",
                           sectionList: sampleList,
                           friendList: samplefriends)

