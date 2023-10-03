//
//  NotSettedViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/18.
//

import Foundation
import FirebaseFirestore


class NotSettedViewModel: ObservableObject {
    let userData: UserData
    @Published var multiList: MultiList
    
    init(userData: UserData, multiList: MultiList) {
        self.userData = userData
        self.multiList = multiList
    }
    
//    func checkContent(multiList: MultiList) {
//        if multiList.isSettingDone {
//            let db = Firestore.firestore()
//            switch multiList.listType {
//            case 0:
//                let path = db.collection("checkLists").document(multiList.multiID.uuidString)
//                path.getDocument { snapshot, error in
//                    if let snapshot = snapshot, let data = snapshot.data() {
//                        if let title = data["title"] as? String,
//                           let isDone = data["isDone"] as? Bool,
//                           let cycle = data["cycle"] as? Int,
//                           let itemList = data["itemList"] as? [CheckRow],
//                           let shared = data["sharedPeople"] as? [Person] {
//                            let itemList = itemList.sorted(by: { $0.order < $1.order })
//                            let content = CheckList(id: multiList.multiID,
//                                                     title: title,
//                                                     isDone: isDone,
//                                                     itemList: itemList,
//                                                     cycle: cycle,
//                                                     sharedPeople: shared)
//                            self.userData.checkList.append(content)
//                        }
//                    }
//                }
//            case 1:
//                let path = db.collection("linkLists").document(multiList.multiID.uuidString)
//                path.getDocument { snapshot, error in
//                    if let snapshot = snapshot, let data = snapshot.data() {
//                        if let title = data["title"] as? String,
//                           let itemList = data["itemList"] as? [LinkRow],
//                           let shared = data["sharedPeople"] as? [Person] {
//                            let itemList = itemList.sorted(by: { $0.order < $1.order })
//                            let content = LinkList(id: multiList.multiID,
//                                                   title: title,
//                                                   itemList: itemList,
//                                                   sharedPeople: shared)
//                            self.userData.linkList.append(content)
//                        }
//                    }
//                }
//            default: break
//            }
//        }
//    }
    
    func changeTitle(newTitle: String) {
        
    }
    
    func addSubContents() {
        
    }
    
    func changeSubContents() {
        
    }
    
    func deleteSubContents() {
        
    }
    
    
}
