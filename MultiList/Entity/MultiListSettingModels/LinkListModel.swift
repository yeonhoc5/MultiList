//
//  LinkListModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/22.
//

import Foundation

// 타입 1. 체크리스트
class LinkList: Identifiable, ObservableObject {
    let id: UUID
    @Published var title: String
    @Published var itemList: [LinkRow]
    @Published var sharedPeople: [Person] = []
    
    init(id: UUID! = UUID(), title: String, itemList: [LinkRow] = [], sharedPeople: [Person] = []) {
        self.id = id
        self.title = title
        self.itemList = itemList
        self.sharedPeople = sharedPeople
    }
    
}

struct LinkRow: Identifiable {
    let id: UUID
    var order: Int
    var title: String
    var url: String
    var lastDate: Date
    var chargedPerson: Person?
    
    init(id: UUID! = UUID(), order: Int, title: String, url: String, lastDate: Date! = Date(), chargedPerson: Person? = nil) {
        self.id = id
        self.order = order
        self.title = title
        self.url = url
        self.lastDate = lastDate
        self.chargedPerson = chargedPerson
    }
}


//class LinkRow: Identifiable, Codable, ObservableObject {
//    var id: UUID
//    var order: Int
//    var title: String
//    var url: String
//    var chargedPerson: Person?
//
//    init(id: UUID! = UUID(), order: Int, title: String, url: String, chargedPerson: Person? = nil) {
//        self.id = id
//        self.order = order
//        self.title = title
//        self.url = url
//        self.chargedPerson = chargedPerson
//    }
//}
