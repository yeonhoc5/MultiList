//
//  FindUserFriendViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class FindUserFriendViewModel: ObservableObject {
    
    let userData: UserData
    @Published var resultFriend: Friend?
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    
    func findFriendInDB(email: String, result: @escaping (FindFriendResult) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.count != 0 {
            let db = Firestore.firestore()
            db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                if snapshot?.isEmpty == false {
                    if let snapshot = snapshot, error == nil {
                        for doc in snapshot.documents {
                            let data = doc.data()
                            if let nickName = data["name"] as? String,
                               let email = data["email"] as? String {
                                let foundFriend = Friend(uid: "tempUID", order: 99, userEmail: email, userNickName: nickName)
                                result(self.checkAlreadyFriend(friend: foundFriend))
                            }
                        }
                    }
                } else {
                    result(.fail)
                }
            }
        }
    }
    
    func checkAlreadyFriend(friend: Friend) -> FindFriendResult {
        if userData.user.userEmail == friend.userEmail {
            return .myself
        } else if userData.friendList.compactMap({$0.userEmail}).contains(friend.userEmail) {
            return .already
        } else {
            self.resultFriend = friend
            return .success
        }
    }
    
    func addFriendToMyInfo(friend: Friend) {
        var newFriend = friend
        newFriend.order = self.userData.friendList.count
        
        let db = Firestore.firestore()
        let path = db.collection("users").document(userData.user.userUID).collection("friendList")
        let uid = path.document().documentID
        path.document(uid).setData([
            "order": newFriend.order,
            "nickName": newFriend.userNickName,
            "userEmail": newFriend.userEmail
        ])
        newFriend.id = uid
        
        self.userData.friendList.append(newFriend)
    }
    
    
}
