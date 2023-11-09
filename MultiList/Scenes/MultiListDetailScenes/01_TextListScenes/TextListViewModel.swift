//
//  TextListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/18.
//

import SwiftUI
import FirebaseFirestore


class TextListViewModel: ObservableObject {
    let userData: UserData
    var textListID: UUID
    
    init(userData: UserData, textListID: UUID) {
        self.userData = userData
        self.textListID = textListID
    }
    
    func addTextRow(index: Int, string: String) {
        let newTextRow = TextRow(order: index, title: string)
        addTextRowToDB(newTextRow: newTextRow) {
            if let index = self.userData.textList.firstIndex(where: { $0.id == self.textListID }) {
                withAnimation {
                    self.userData.textList[index].itemList.append(newTextRow)
                }
            }
        }
    }
    
    func addTextRowToDB(newTextRow: TextRow, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("textLists").document(textListID.uuidString).collection("itemList").document(newTextRow.id.uuidString).setData([
            "order": newTextRow.order,
            "title": newTextRow.title
        ])
        completion()
    }
    
    func deleteTextRow(index: Int) {
        if let textIndex = self.userData.textList.firstIndex(where: { $0.id == self.textListID} ) {
            deleteTextRowDB(id: userData.textList[textIndex].itemList[index].id) { bool in
                if bool {
                    self.userData.textList[textIndex].itemList.remove(at: index)
                    self.reOrdering(onIndex: index)
                }
            }
        }
    }
    
    func deleteTextRowDB(id: UUID, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("textLists").document(textListID.uuidString).collection("itemList").document(id.uuidString).delete()
        completion(true)
    }
    
    
    func reOrdering(editCase: EditCase = .delete, onIndex: Int, indexSet: IndexSet! = nil) {
        if let textIndex = self.userData.textList.firstIndex(where: { $0.id == self.textListID} ) {
            switch editCase {
            case .reOder:
                // 1. 프라퍼티 배열의 순서 수정
                self.userData.textList[textIndex].itemList.move(fromOffsets: indexSet, toOffset: onIndex)
                // 2. 수정된 배열의 순서값 수정
                guard let ori = indexSet.first else { return }
                for i in min(ori, onIndex)...max(ori, onIndex - 1) {
                    let item = self.userData.textList[textIndex].itemList[i]
                    guard let changedIndex = self.userData.textList[textIndex].itemList.firstIndex(where: { $0.id == item.id }) else { return }
                    self.userData.textList[textIndex].itemList[i].order = changedIndex
                    // 3. db 반영
                    DispatchQueue(label: "firebase").async {
                        let db = Firestore.firestore()
                        db.collection("textLists").document(self.textListID.uuidString).collection("itemList").document(item.id.uuidString).updateData([
                            "order": changedIndex
                        ])
                    }
                }
            case .delete:
                let itemList = userData.textList[textIndex].itemList
                for index in onIndex..<userData.textList[textIndex].itemList.count {
                    downCheckRowID(id: itemList[index].id, order: itemList[index].order) {
                        self.userData.textList[textIndex].itemList[index].order -= 1
                    }
                }
            default: break
            }
        }
    }
    
    func downCheckRowID(id: UUID, order: Int, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("textLists").document(textListID.uuidString).collection("itemList").document(id.uuidString).updateData([
            "order": order-1
        ])
        completion()
    }

    func modifyTitle(new: String, multiList: MultiList, oriTitle: String) {
        let newTitle = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newTitle.count != 0 && newTitle != oriTitle else { return }
        let db = Firestore.firestore()
        
        if let textIndex = userData.textList.firstIndex(where: {$0.id == multiList.multiID}) {
            userData.textList[textIndex].title = newTitle
            db.collection(MultiListType.returnPath(type: .textList)).document(multiList.multiID.uuidString).updateData([
                "title": newTitle
            ])
        }
    }
    
    func modifyRowTitle(id: UUID, index: Int, newString: String, completion: @escaping () -> Void) {
        if let textIndex = self.userData.textList.firstIndex(where: { $0.id == self.textListID} ) {
            withAnimation {
                userData.textList[textIndex].itemList[index].title = newString
            }
        }
        let db = Firestore.firestore()
        db.collection("textLists").document(textListID.uuidString).collection("itemList").document(id.uuidString).updateData([
            "title": newString
        ])
    }
    
}


