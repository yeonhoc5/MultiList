//
//  CheckListModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/20.
//

import SwiftUI

// 타입 1. 체크리스트
class CheckList: NSObject, Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var isDone: Bool
    @Published var itemList: [CheckRow]
    var cycle: Int = 0
    // 0: 없음 / 1: 매일 / 2: 일주 / 3: 월별 / 4: 연별
    @Published var sharedPeople: [Person]
    
    init(id: UUID! = UUID(), title: String, isDone: Bool! = false, itemList: [CheckRow]! = nil, cycle: Int! = 0, sharedPeople: [Person] = []) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.itemList = itemList
        self.cycle = cycle
        self.sharedPeople = sharedPeople
    }
}

//class CheckRow: Identifiable, ObservableObject {
//    @Published var id: Int // 순서로 활용
//    @Published var title: String
//    @Published var isDone: Bool
//    @Published var chargedPerson: Person?
//
//    init(id: Int, title: String, isDone: Bool! = false, chargedPerson: Person? = nil) {
//        self.id = id
//        self.title = title
//        self.isDone = isDone
//        self.chargedPerson = chargedPerson
//    }
//    func reOrder(upOrDown: ReOrdering, quantity: Int! = 1) {
//        if upOrDown == .up {
//            self.order += quantity
//        } else {
//            self.order -= quantity
//        }
//    }
//
//    func checkRow(bool: Bool) {
//        self.isDone = bool
//    }
//}


struct CheckRow: Identifiable {
    let id: UUID
    var order: Int
    var title: String
    var isDone: Bool
    var chargedPerson: Person?
    
    init(id: UUID! = UUID(), order: Int, title: String, isDone: Bool! = false, chargedPerson: Person? = nil) {
        self.id = id
        self.order = order
        self.title = title
        self.isDone = isDone
        self.chargedPerson = chargedPerson
    }
}

enum ReOrdering {
    case up, down
}

struct Person: Identifiable{
    var id: String
    var userEmail: String
    var isEditable: Bool
}


