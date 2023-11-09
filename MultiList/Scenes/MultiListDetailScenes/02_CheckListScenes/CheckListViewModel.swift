//
//  CheckListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import SwiftUI
import FirebaseFirestore

class CheckListViewModel: ObservableObject {
    let userData: UserData
    var checkListID: UUID
    
    init(userData: UserData, checkListID: UUID) {
        self.userData = userData
        self.checkListID = checkListID
    }
    
    func addCheckRow(index: Int, string: String) {
        let newCheckRow = CheckRow(order: index, title: string)
        addCheckRowToDB(newCheckRow: newCheckRow) {
            if let index = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID }) {
                withAnimation {
                    self.userData.checkList[index].itemList.append(newCheckRow)
                }
            }
        }
    }
    
    func addCheckRowToDB(newCheckRow: CheckRow, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("checkLists").document(checkListID.uuidString).collection("itemList").document(newCheckRow.id.uuidString).setData([
            "order": newCheckRow.order,
            "title": newCheckRow.title,
            "isDone": newCheckRow.isDone
        ])
        completion()
    }
    
    func toggleCheckRow(indexSet: [Int], bool: Bool) {
        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID} ) {
            for int in indexSet {
                withAnimation {
                    self.userData.checkList[checkIndex].itemList[int].isDone = bool
                }
                let itemID = self.userData.checkList[checkIndex].itemList[int].id
                toggleCheckRowDB(id: itemID, index: int, bool: bool) { result in
                    
                }
            }
        }
    }
    
    func toggleCheckRowDB(id: UUID, index: Int, bool: Bool, complection: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("checkLists").document(checkListID.uuidString).collection("itemList").document(id.uuidString).updateData([
            "isDone": bool
        ])
        complection(true)
    }
    
    
    func deleteCheckRow(index: Int) {
        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID} ) {
            deleteCheckRowDB(id: userData.checkList[checkIndex].itemList[index].id) { bool in
                if bool {
                    self.userData.checkList[checkIndex].itemList.remove(at: index)
                    self.reOrdering(onIndex: index)
                }
            }
        }
    }
    
    func deleteCheckRowDB(id: UUID, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("checkLists").document(checkListID.uuidString).collection("itemList").document(id.uuidString).delete()
        completion(true)
    }
    
    
    func reOrdering(editCase: EditCase = .delete, onIndex: Int, indexSet: IndexSet! = nil) {
        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID} ) {
            switch editCase {
            case .reOder:
                // 1. 프라퍼티 배열의 순서 수정
                self.userData.checkList[checkIndex].itemList.move(fromOffsets: indexSet, toOffset: onIndex)
                // 2. 수정된 배열의 순서값 수정
                guard let ori = indexSet.first else { return }
                for i in min(ori, onIndex)...max(ori, onIndex - 1) {
                    let item = self.userData.checkList[checkIndex].itemList[i]
                    guard let changedIndex = self.userData.checkList[checkIndex].itemList.firstIndex(where: { $0.id == item.id }) else { return }
                    self.userData.checkList[checkIndex].itemList[i].order = changedIndex
                    // 3. db 반영
                    DispatchQueue(label: "firebase").async {
                        let db = Firestore.firestore()
                        db.collection("checkLists").document(self.checkListID.uuidString).collection("itemList").document(item.id.uuidString).updateData([
                            "order": changedIndex
                        ])
                    }
                }    
            case .delete:
                let itemList = userData.checkList[checkIndex].itemList
                for index in onIndex..<userData.checkList[checkIndex].itemList.count {
                    downCheckRowID(id: itemList[index].id, order: itemList[index].order) {
                        self.userData.checkList[checkIndex].itemList[index].order -= 1
                    }
                }
            default: break
            }
        }
    }
    
    func downCheckRowID(id: UUID, order: Int, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection("checkLists").document(checkListID.uuidString).collection("itemList").document(id.uuidString).updateData([
            "order": order-1
        ])
        completion()
    }
    
    func reOrderCheckItems() {
        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID} ) {
            let items = userData.checkList[checkIndex].itemList
            let checkOrderItems = items.filter({$0.isDone == true}) + items.filter({$0.isDone == false})
            
            if items != checkOrderItems {
                withAnimation {
                    userData.checkList[checkIndex].itemList = checkOrderItems
                }
                for i in checkOrderItems  {
                    
                    if let index = checkOrderItems.firstIndex(of: i), index != i.order {
                        let db = Firestore.firestore()
                        db.collection(PathString.content(type: .checkList).pathString()).document(checkListID.uuidString).collection("itemList").document(i.id.uuidString).updateData([
                            "order": index
                        ])
                    }
                    
                }
            }
        }
    }
    
//    func moveRows(indexSet: IndexSet, destination: Int) {
////        self.checkList.itemList.move(fromOffsets: indexSet, toOffset: destination)
//        guard let source = indexSet.first,
//              let object = self.userData.checkList.first(where: {$0.id == checkListID}) else { return }
//        if source < destination {
////            let indexRange = (source..<destination)
//            // 1. 배열에서 순서 바꾸기
//            withAnimation {
//                object.itemList.move(fromOffsets: indexSet, toOffset: destination)
//            }
//            // 2. order값 변경하기
//            for i in source..<(destination-1) {
//                object.itemList[i].order -= 1
//            }
//            object.itemList[destination - 1].order = destination - 1
//            DispatchQueue(label: "firebase", qos: .background).async {
//                // 3. db에 반영하기
//                
//                
//            }
//        } else {
////            let indexRange = (destination...source)
//            // 1. 배열에서 순서 바꾸기
//            object.itemList.move(fromOffsets: indexSet, toOffset: destination)
//            // 2. order값 변경하기
//            for i in (destination+1)...source {
//                object.itemList[i].order += 1
//            }
//            object.itemList[destination].order = destination
//            // 3. db에 반영하기
//        }
    
//        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkList.id} ) {
//            reOrdering(editCase: .reOder, checkIndex: checkIndex)
//        }
        
//    }
    
    func modifyRowTitle(id: UUID, index: Int, newString: String, completion: @escaping () -> Void) {
        if let checkIndex = self.userData.checkList.firstIndex(where: { $0.id == self.checkListID} ) {
            withAnimation {
                userData.checkList[checkIndex].itemList[index].title = newString
            }
        }
        let db = Firestore.firestore()
        db.collection("checkLists").document(checkListID.uuidString).collection("itemList").document(id.uuidString).updateData([
            "title": newString
        ])
    }
    
}
