//
//  Sample.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

// 0. 샘플 유저
let sampleUser = UserModel(accountType: .google,
                           userUID: "sampleuser",
                           userEmail: "sameple@google.com",
                           dateRegistered: Date(),
                           userNickName: "샘플 User",
                           sectionList: sampleList,
                           friendList: samplefriends)
// 0-1. 샘플 섹션 리스트
let sampleList: [SectionList] = [
    SectionList(order: 0, sectionName: "개인", color: 0, multiList: [sampleMultiList1, sampleMultiList2]),
    SectionList(order: 1, sectionName: "공유", color: 1, multiList: [sampleMultiList3])
    ]
// 0-2. 샘플 친구 리스트
let samplefriends = [
    Friend(uid: "aaaa", order: 0, userEmail: "friend1@naver.com", userNickName: "아이언맨"),
    Friend(uid: "bbbb", order: 1, userEmail: "friend2@naver.com", userNickName: "배트맨"),
    Friend(uid: "cccc", order: 1, userEmail: "friend3@naver.com", userNickName: "첫사랑")
    ]

// 0-1-1. 샘플 멀티 리스트
let sampleMultiList1 = MultiList(multiID: contentID01, order: 0, listType: .checkList, isSettingDone: true)
let sampleMultiList2 = MultiList(multiID: contentID02, order: 1, listType: .linkList)
let sampleMultiList3 = MultiList(multiID: contentID03, order: 2, listType: .checkList)

let contentID01 = UUID()
let contentID02 = UUID()
let contentID03 = UUID()
let contentID04 = UUID()

// 0-1-1-1. 샘플 리스트
let sampleCheckList = CheckList(id: contentID01, title: "세차 용품", itemList: [
                            CheckRow(order: 0, title: "카샴푸", isDone: false),
                            CheckRow(order: 1, title: "접이식 바스켓", isDone: true),
                            CheckRow(order: 2, title: "미트", isDone: false),
                            CheckRow(order: 3, title: "휠미트", isDone: false),
                            CheckRow(order: 4, title: "철분 제거제", isDone: false),
                            CheckRow(order: 5, title: "물왁스", isDone: true),
                            CheckRow(order: 6, title: "휠 매트", isDone: true)
                        ])
let sampleLinkList = LinkList(id: contentID03, title: "세차 용품", itemList: [
                            LinkRow(order: 0, title: "네이버", url: "https://naver.com"),
                            LinkRow(order: 1, title: "다음", url: "https://daum.net"),
                            LinkRow(order: 2, title: "구글", url: "https://google.com"),
                            LinkRow(order: 3, title: "", url: "http://www.wave.com")
                          ])


let sampleShareMulti = [
    ShareMultiList(id: UUID(),
                   userEmail: samplefriends[0].userEmail,
                   userNickName: samplefriends[0].userNickName,
                   multiID: contentID01,
                   title: "여행 준비물",
                   multiListType: sampleMultiList1.listType,
                   shareType: .copy,
                   sharedTime: Date()),
    ShareMultiList(id: UUID(),
                   userEmail: samplefriends[1].userEmail,
                   userNickName: samplefriends[1].userNickName,
                   multiID: contentID02,
                   title: "수영장 리스트",
                   multiListType: sampleMultiList2.listType,
                   shareType: .groupShare,
                   sharedTime: Date(),
                   shareResult: .approve),
    ShareMultiList(id: UUID(),
                   userEmail: samplefriends[2].userEmail,
                   userNickName: samplefriends[2].userNickName,
                   multiID: contentID03,
                   title: "차크닉 장소 리스트",
                   multiListType: sampleMultiList2.listType,
                   shareType: .copy,
                   sharedTime: Date(),
                   shareResult: .reject)
]


