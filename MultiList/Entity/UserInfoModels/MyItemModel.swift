//
//  MyItemModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/25.
//

import UIKit

enum MyItemType: String {
    case text = "텍스트"
    case image = "사진"
    
    static func returnIntValue(type: MyItemType) ->  Int {
        switch type {
        case .text: return 0
        case .image: return 1
        }
    }
    static func returnTypeValue(int: Int) -> MyItemType {
        switch int {
        case 0: return MyItemType.text
        default: return MyItemType.image
        }
    }
}

struct MyItemModel {
    
    let id: UUID
    var title: String
    var order: Int
    let type: MyItemType
    
    var itemText: String!
    var itemPhoto: UIImage!
    
    init(id: UUID! = UUID(), title: String, order: Int, type: MyItemType, itemText: String! = nil, itemPhoto: UIImage! = nil) {
        self.id = id
        self.title = title
        self.order = order
        self.type = type
        self.itemText = itemText
        self.itemPhoto = itemPhoto
    }
    
}

