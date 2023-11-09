//
//  FriendModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

// 친구 목록
class Friend: ObservableObject {
    var id: String
    @Published var order: Int // 순서로 사용
    let userEmail: String
    @Published var userNickName: String
    @Published var stillValid: Bool = true
    
    init(uid: String, order: Int, userEmail: String, userNickName: String) {
        self.id = uid
        self.order = order
        self.userEmail = userEmail
        self.userNickName = userNickName
    }
}

// 공유하는 사람 목록
struct Person: Identifiable{
    var id: String
    var userName: String
    var userEmail: String
    var isEditable: Bool
    
}
