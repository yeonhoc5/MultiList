//
//  TextListModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import SwiftUI

// 타입 1. 체크리스트
class TextList: NSObject, Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var itemList: [TextRow]
    var cycle: Int = 0
    // 0: 없음 / 1: 매일 / 2: 일주 / 3: 월별 / 4: 연별
    @Published var sharedPeople: [Person]
    
    init(id: UUID! = UUID(), title: String, isDone: Bool! = false, itemList: [TextRow]! = nil, sharedPeople: [Person] = []) {
        self.id = id
        self.title = title
        self.itemList = itemList
        self.sharedPeople = sharedPeople
    }
}


struct TextRow: Identifiable {
    let id: UUID
    var order: Int
    var title: String
    var chargedPerson: Person?
    
    init(id: UUID! = UUID(), order: Int, title: String, chargedPerson: Person? = nil) {
        self.id = id
        self.order = order
        self.title = title
        self.chargedPerson = chargedPerson
    }
}


