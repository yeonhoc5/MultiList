//
//  FindUserFriendViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import Foundation
import FirebaseFirestore
import SwiftUI

enum FindFriendResult {
    case myself
    case already
    case notMine
    case success
    case fail
    case none
}


class FindUserFriendViewModel: ObservableObject {
    
    let userData: UserData
    @Published var resultFriend: Friend?
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    
    func findFriendInDB(email: String, result: @escaping (FindFriendResult, Friend) -> Void) {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.count != 0 {
            let check = checkAlreadyFriend(email: email)
            switch check {
            case .myself:
                let tempFriend = Friend(uid: "tempUID", order: 99, userEmail: email, userNickName: "")
                result(check, tempFriend)
            case .already:
                let alreadyFriend = userData.friendList.filter({$0.userEmail == email}).first!
                result(check, alreadyFriend)
            case .notMine:
                let db = Firestore.firestore()
                db.collection("users").whereField("email", isEqualTo: email).getDocuments { snapshot, error in
                    if snapshot?.isEmpty == false {
                        if let snapshot = snapshot, error == nil {
                            for doc in snapshot.documents {
                                let data = doc.data()
                                if let nickName = data["name"] as? String,
                                   let email = data["email"] as? String {
                                    let foundedFriend = Friend(uid: "tempUID", order: 99, userEmail: email, userNickName: nickName)
                                    result(.success, foundedFriend)
                                }
                            }
                        }
                    } else {
                        let unknown = Friend(uid: "tempUID", order: 99, userEmail: email, userNickName: "")
                        result(.fail, unknown)
                    }
                }
            default: break
            }
        }
    }
    
    func checkAlreadyFriend(email: String) -> FindFriendResult {
        if userData.user.userEmail == email {
            return .myself
        } else if userData.friendList.compactMap({$0.userEmail}).contains(email) {
            return .already
        } else {
            return .notMine
        }
    }
    
}
