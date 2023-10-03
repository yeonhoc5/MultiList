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
}
