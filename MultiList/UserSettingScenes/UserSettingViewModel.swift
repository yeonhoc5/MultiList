//
//  UserSettingViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserSettingViewModel: ObservableObject {
    @Published var user: UserModel!
    
    var messageAccount: String!
    
    init(user: UserModel!) {
        self.user = user
//        addUserObserver()
    }
    
//    func addUserObserver() {
//        NotificationCenter.default.addObserver(forName: Notification.Name("userSetted"), object: nil, queue: .main, using: { notification in
//            if let user = notification.object as? UserModel {
//                print("유저 세팅뷰: 노티피케이션 수신 완료")
//                self.user = user
//            }
//        })
//    }
    
    // 익명 로그인 시 SNS 계정으로 전환
    func changeEternalAccount() {
        
    }
    
    // 로그 아웃
    func signOut(completion: @escaping () -> Void) {
        do {
            try Auth.auth().signOut()
            if Auth.auth().currentUser == nil {
                self.user = nil
                self.userIsNil()
                completion()
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    // 탈퇴 (계정 삭제 & 데이터 삭제)
    func deleteAccount(completion: @escaping () -> Void) {
        let user = Auth.auth().currentUser
        user?.delete(completion: { error in
            if error != nil {
                self.messageAccount = String(error?.localizedDescription ?? "")
            } else {
                
                let db = Firestore.firestore()
                if let uid = user?.uid {
                    db.collection("users").document(uid).delete()
                    self.user = nil
                    self.userIsNil()
                    completion()
                }
                
            }
        })
    }
    
    func userIsNil() {
        NotificationCenter.default.post(name: Notification.Name("userIsNil"), object: nil)
    }
    
    
    // 닉네임 변경
    func changeNickName(newName: String) {
        user.userNickName = newName
    }
    
    func returningDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        
        let str = formatter.string(from: date)
        return str
    }
}