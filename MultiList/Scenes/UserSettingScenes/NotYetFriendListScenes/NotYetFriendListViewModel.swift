//
//  NotYetFriendListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 11/8/23.
//

import SwiftUI


class NotYetFriendListViewModel: ObservableObject {
    
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func addNotYetFriendToMe(friend: Friend) {
        userData.addFriendToMyInfo(friend: friend)
        if let index = userData.notYetFriendList.firstIndex(where: { $0.userEmail == friend.userEmail }) {
            withAnimation {
                userData.notYetFriendList.remove(at: index)
            }
        }
    }
    
    
}
