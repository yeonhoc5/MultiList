//
//  SharePeopleListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/01.
//

import Foundation
import FirebaseFirestore

class SharePeopleListViewModel: ObservableObject {
    
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    
    func sendShareMultilist(indexSet: [Int], multiList: MultiList, shareType: ShareType) {
        let indexSet = indexSet.sorted(by: { $0 < $1 })
        let freindToshare = userData.friendList.filter({ indexSet.contains($0.order) })
        let date = Date()
        let title: String
        switch multiList.listType {
        case .checkList: title = userData.checkList.first(where: {$0.id == multiList.multiID })?.title ?? "알 수 없는 리스트"
        case .linkList: title = userData.linkList.first(where: {$0.id == multiList.multiID })?.title ?? "알 수 없는 리스트"
        default: title = "알 수 없는 리스트"
        }
        
        let db = Firestore.firestore()
        let newShareID = UUID()
        
        for friend in freindToshare {
            db.collection("users").whereField("email", isEqualTo: friend.userEmail).getDocuments { snapshot, error in
                if let snapshot = snapshot {
                                        
                    for doc in snapshot.documents {
                        
                        doc.reference.collection("sharedList").document(newShareID.uuidString).setData([
                            "userNickName": self.userData.user.userNickName,
                            "userEmail": self.userData.user.userEmail,
                            "multiID": multiList.multiID.uuidString,
                            "title": title,
                            "multiListType": MultiListType.returnIntValue(type: multiList.listType),
                            "shareType": ShareType.returnIntValue(type: shareType),
                            "sharedTime": date,
                            "shareResult": ShareResult.returnIntValue(result: .undetermined)
                        ])
                                    
                        db.collection("users").document(self.userData.user.userUID).collection("sharingList").document(newShareID.uuidString).setData([
                            "userNickName": friend.userNickName,
                            "userEmail": friend.userEmail,
                            "multiID": multiList.multiID.uuidString,
                            "title": title,
                            "multiListType": MultiListType.returnIntValue(type: multiList.listType),
                            "shareType": ShareType.returnIntValue(type: shareType),
                            "sharedTime": date,
                            "shareResult": ShareResult.returnIntValue(result: .undetermined)
                        ])
                        
                        let sharingList = ShareMultiList(id: newShareID,
                                                         userEmail: friend.userEmail,
                                                         userNickName: friend.userNickName,
                                                         multiID: multiList.multiID,
                                                         title: title,
                                                         multiListType: multiList.listType,
                                                         shareType: shareType,
                                                         sharedTime: date,
                                                         shareResult: .undetermined)
                        
                        self.userData.sharingMultiList.append(sharingList)
                    }
                }
            }
        }
    }
}
