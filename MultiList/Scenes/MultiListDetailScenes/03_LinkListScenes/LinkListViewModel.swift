//
//  LinkListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI
import Photos
import FirebaseFirestore

class LinkListViewModel: ObservableObject {
    let userData: UserData
    var linkListID: UUID
    
    
    init(userData: UserData, linkListID: UUID) {
        self.userData = userData
        self.linkListID = linkListID
    }
    
    func addLinkRow(count: Int, string: String) {
        let newLinkRow = LinkRow(order: count, title: "", url: string)
        let db = Firestore.firestore()
        db.collection("linkLists").document(self.linkListID.uuidString).collection("itemList").document(newLinkRow.id.uuidString).setData([
            "order": newLinkRow.order,
            "title": newLinkRow.title,
            "url": newLinkRow.url
        ])
        
        guard let index = userData.linkList.firstIndex(where: {$0.id == self.linkListID}) else { return }
        userData.linkList[index].itemList.append(newLinkRow)
    }
    
    func deleteLinkRow(index: Int) {
        if let linkIndex = self.userData.linkList.firstIndex(where: { $0.id == self.linkListID} ) {
            deleteLinkRowDB(id: userData.linkList[linkIndex].itemList[index].id) { bool in
                if bool {
                    self.userData.linkList[linkIndex].itemList.remove(at: index)
                    self.reOrdering(onIndex: index)
                }
            }
        }
    }
    
    func deleteLinkRowDB(id: UUID, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("linkLists").document(linkListID.uuidString).collection("itemList").document(id.uuidString).delete()
        completion(true)
    }
    
    
    func reOrdering(editCase: EditCase = .delete, onIndex: Int, indexSet: IndexSet! = nil) {
        if let linkIndex = self.userData.linkList.firstIndex(where: { $0.id == self.linkListID} ) {
            switch editCase {
            case .reOder:
                // 1. 프라퍼티 배열의 순서 수정
                self.userData.linkList[linkIndex].itemList.move(fromOffsets: indexSet, toOffset: onIndex)
                // 2. 수정된 배열의 순서값 수정
                guard let ori = indexSet.first else { return }
                for i in min(ori, onIndex)...max(ori, onIndex - 1) {
                    let item = self.userData.linkList[linkIndex].itemList[i]
                    guard let changedIndex = self.userData.linkList[linkIndex].itemList.firstIndex(where: { $0.id == item.id }) else { return }
                    self.userData.linkList[linkIndex].itemList[i].order = changedIndex
                    // 3. db 반영
                    DispatchQueue(label: "firebase").async {
                        let db = Firestore.firestore()
                        db.collection("linkLists").document(self.linkListID.uuidString).collection("itemList").document(item.id.uuidString).updateData([
                            "order": changedIndex
                        ])
                    }
                }
                
            case .delete:
                let itemList = userData.linkList[linkIndex].itemList
                for index in onIndex..<itemList.count {
                    downLinkRowOrderDB(id: itemList[index].id, order: itemList[index].order) {
                        self.userData.checkList[linkIndex].itemList[index].order -= 1
                    }
                }
            case .hidden:
                break
            }
        }
    }
    
    func downLinkRowOrderDB(id: UUID, order: Int, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("linkLists").document(linkListID.uuidString).collection("itemList").document(id.uuidString).updateData([
                "order": order-1
            ])
        completion()
    }
    
    
    func modifyRow(itemID: UUID, index: Int, newTitle: String, newURL: String) {
        if let linkIndex = self.userData.linkList.firstIndex(where: { $0.id == self.linkListID} ) {
            withAnimation {
                userData.linkList[linkIndex].itemList[index].title = newTitle
            }
        }
        let db = Firestore.firestore()
        db.collection(PathString.content(type: .linkList).pathString()).document(self.linkListID.uuidString).collection("itemList").document(itemID.uuidString).updateData([
            "title": newTitle,
            "url": newURL
        ])
    }
    
    func copyLinkToClipboard(text: String, action: @escaping () -> Void) {
        let clipboard = UIPasteboard.general
        clipboard.setValue(text, forPasteboardType: UTType.plainText.identifier)
        action()
    }
    
}
