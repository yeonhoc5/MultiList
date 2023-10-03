//
//  FriendModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

class Friend: ObservableObject {
    var id: String
    @Published var order: Int // 순서로 사용
    let userEmail: String
    @Published var userNickName: String
    
    init(uid: String, order: Int, userEmail: String, userNickName: String) {
        self.id = uid
        self.order = order
        self.userEmail = userEmail
        self.userNickName = userNickName
    }
}
