//
//  DetailMultiListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/21.
//

import SwiftUI
import FirebaseFirestore

class DetailMultiListViewModel: ObservableObject {
    
    let userData: UserData
    let sectionUID: UUID
    @Published var multiList: MultiList
    
    var message: String!
    
    @Published var isShowingAlert: Bool = false
    @Published var contentTitle: String = ""
    
    init(userData: UserData, sectionUID: UUID,  multiList: MultiList) {
        self.userData = userData
        self.multiList = multiList
        self.sectionUID = sectionUID
    }
    
    func settingContent(type: MultiListType) {
        guard let sectionIndex = self.userData.sectionList.firstIndex(where: {$0.sectionID == self.sectionUID}),
              let multiIndex = self.userData.sectionList[sectionIndex].multiList.firstIndex(where: {$0.multiID == multiList.multiID}) else { return }
        if type == .textList {
            // 1. textList 추가
            let textList = TextList(id: multiList.multiID, title: "New 텍스트리스트", itemList: [])
            addTextListToDB(textList: textList) {
                self.userData.textList.append(textList)
            }
        } else if type == .checkList {
            // 2. checkList 추가
            let checkList = CheckList(id: multiList.multiID, title: "New 체크리스트", itemList: [])
            addCheckListToDB(checkList: checkList) {
                self.userData.checkList.append(checkList)
            }
        } else if type == .linkList {
            // 3. linkList 추가
            let linkList = LinkList(id: multiList.multiID, title: "New 링크리스트", itemList: [])
            addLinkListToDB(linkList: linkList) {
                self.userData.linkList.append(linkList)
            }
        }
        let db = Firestore.firestore()
        db.collection("users").document(userData.user.userUID).collection("sectionList").document(sectionUID.uuidString).collection("itemList").document(multiList.multiID.uuidString).updateData([
            "listType": MultiListType.returnIntValue(type: type),
            "isSettingDone": true
        ])
        withAnimation {
            self.userData.sectionList[sectionIndex].multiList[multiIndex].listType = type
            self.userData.sectionList[sectionIndex].multiList[multiIndex].isSettingDone = true
            self.multiList.listType = type
            self.multiList.isSettingDone = true
        }
    }
    
    // 0. add 텍스트 리스트 to DB
    func addTextListToDB(textList: TextList, result: @escaping () -> Void) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.content(type: .textList).pathString()).document(textList.id.uuidString)
        
        path.setData([
            "title": textList.title
        ])
        
        path.collection("sharedPeople").document(userData.user.userUID).setData([
            "userEmail": userData.user.userEmail,
            "isEditable": true
        ])
        
        result()
    }
    
    // 1. add 체크리스트 to DB
    func addCheckListToDB(checkList: CheckList, result: @escaping () -> Void) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.content(type: .checkList).pathString()).document(checkList.id.uuidString)
        
        path.setData([
            "title": checkList.title,
            "cycle": 0,
            "isDone": false
        ])
        
        path.collection("sharedPeople").document(userData.user.userUID).setData([
            "userEmail": userData.user.userEmail,
            "isEditable": true
        ])
        
        result()
    }

    // 2. add 링크리스트 to DB
    func addLinkListToDB(linkList: LinkList, result: @escaping () -> Void) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.content(type: .linkList).pathString()).document(linkList.id.uuidString)
            
        path.setData([
            "title": linkList.title,
        ])
        
        path.collection("sharedPeople").document(userData.user.userUID).setData([
            "userEmail": userData.user.userEmail,
            "isEditable": true
        ])
        
        result()
    }
    
    func modifyTitle(new: String) {
        let newTitle = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newTitle.count != 0 && newTitle != contentTitle else { return }
        let db = Firestore.firestore()
        if multiList.listType == .checkList {
            if let checkIndex = userData.checkList.firstIndex(where: {$0.id == self.multiList.multiID}) {
                userData.checkList[checkIndex].title = newTitle
                self.contentTitle = newTitle
                db.collection(MultiListType.returnPath(type: .checkList)).document(multiList.multiID.uuidString).updateData([
                    "title": newTitle
                ])
            }
        } else if multiList.listType == .linkList {
            if let linkIndex = userData.linkList.firstIndex(where: {$0.id == self.multiList.multiID}) {
                userData.linkList[linkIndex].title = newTitle
                self.contentTitle = newTitle
                db.collection(MultiListType.returnPath(type: .linkList)).document(multiList.multiID.uuidString).updateData([
                    "title": newTitle
                ])
            }
        }
    }
    
}

