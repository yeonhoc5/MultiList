//
//  MyItemModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/25.
//

import UIKit

struct MyItemModel {
    
    let id: UUID
    var title: String
    var order: Int
    let type: MyItemType
    var lastDate: Date
    
    var itemText: String!
    var itemPhoto: UIImage!
    
    init(id: UUID! = UUID(), title: String, order: Int, type: MyItemType, lastDate: Date! = Date(), itemText: String! = nil, itemPhoto: UIImage! = nil) {
        self.id = id
        self.title = title
        self.order = order
        self.type = type
        self.lastDate = lastDate
        
        self.itemText = itemText
        self.itemPhoto = itemPhoto
    }
    
}

