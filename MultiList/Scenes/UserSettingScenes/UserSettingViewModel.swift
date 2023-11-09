//
//  UserSettingViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

class UserSettingViewModel: ObservableObject {
    let userData: UserData
    var messageAccount: String!
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    // 로그 아웃
    func signOut(completion: @escaping () -> Void) {
        do {
            try Auth.auth().signOut()
            if Auth.auth().currentUser == nil {
                self.userData.logout()
                completion()
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    // 탈퇴 (계정 삭제 & 데이터 삭제)
    func deleteAccount(completion: @escaping () -> Void) {
        // myitem 중 이미지 삭제는 "Auth에 유저가 있어야 하는 규칙"을 세웠으니 유저 지우기 전에 먼저 삭제
        for item in userData.myItems {
            if let item = item {
                userData.deleteMyItem(itemNumber: item.order)
            }
        }
        let user = Auth.auth().currentUser
        self.userData.deleteUserData(user: self.userData.user) {
            user?.delete(completion: { error in
                if error != nil {
                    print(error?.localizedDescription)
                    self.messageAccount = String(error?.localizedDescription ?? "")
                } else {
                    let db = Firestore.firestore()
                    db.collection("users").document(self.userData.user.userUID).delete()
                    self.userData.logout()
                    completion()
                }
            })
        }
    }

    
    // 닉네임 변경
    func changeNickName(newName: String, uid: String! = nil) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(userData.user.userUID)
        let reName = newName.trimmingCharacters(in: .whitespacesAndNewlines).count == 0 ? userData.user.userNickName : newName
        if let uid = uid {
            path.collection("friendList").document(uid).updateData([
                "nickName": reName
            ])
            guard let index = self.userData.friendList.firstIndex(where: {$0.id == uid}) else { return }
            self.userData.friendList[index].userNickName = reName
        } else {
            path.updateData([
                "name": reName
            ])
            self.userData.user.userNickName = reName
        }
    }
    
    func returningDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KR")
        formatter.dateFormat = "YYYY년 MM월 dd일  (aa) hh시 mm분"
        
        let str = formatter.string(from: date)
        return str
    }
    
    func deleteFriend(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let friend = userData.friendList[index]
        userData.deleteFriend(uid: friend.id)
    }
    
    func reOrdering(onIndex: Int, indexSet: IndexSet! = nil) {
        guard let index = indexSet.first else { return }
        
        // 1. 프라퍼티 배열의 순서 수정
        self.userData.friendList.move(fromOffsets: indexSet, toOffset: onIndex)
        // 2. 수정된 배열의 순서값 수정
        for i in min(index, onIndex)...max(index, onIndex - 1) {
            let frnd = self.userData.friendList[i]
            guard let changedIndex = self.userData.friendList.firstIndex(where: { $0.id == frnd.id }) else { return }
            self.userData.friendList[i].order = changedIndex
            // 3. db 반영
            DispatchQueue(label: "firebase").async {
                let db = Firestore.firestore()
                db.collection("users").document(self.userData.user.userUID).collection("friendList").document(frnd.id).updateData([
                    "order": changedIndex
                ])
            }
        }
    }
}

enum UserCase {
    case user, friend
}
