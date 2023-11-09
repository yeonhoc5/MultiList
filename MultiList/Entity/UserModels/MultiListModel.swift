//
//  MultiListModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

//class MultiList: ObservableObject, Hashable {
//    static func == (lhs: MultiList, rhs: MultiList) -> Bool {
//        lhs.multiID == rhs.multiID
//    }
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(multiID)
//    }
//
//    let multiID: UUID
//    @Published var order: Int
//    @Published var listType: MultiListType
//    @Published var isSettingDone: Bool!
//    @Published var isHidden: Bool = false
//
//    init(multiID: UUID, order: Int, listType: MultiListType, isSettingDone: Bool! = false, isHidden: Bool! = false) {
//        self.multiID = multiID
//        self.order = order
//        self.listType = listType
//        self.isSettingDone = isSettingDone
//        self.isHidden = isHidden
//    }
//}

struct MultiList: Hashable {
    static func == (lhs: MultiList, rhs: MultiList) -> Bool {
        lhs.multiID == rhs.multiID
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(multiID)
    }

    let multiID: UUID
    var order: Int
    var listType: MultiListType
    var isSettingDone: Bool!
    var isHidden: Bool = false
    var isTemp: Bool

    init(multiID: UUID, order: Int, listType: MultiListType = .none, isSettingDone: Bool! = false, isHidden: Bool! = false, isTemp: Bool! = false) {
        self.multiID = multiID
        self.order = order
        self.listType = listType
        self.isSettingDone = isSettingDone
        self.isHidden = isHidden
        self.isTemp = isTemp
    }

}

enum MultiListType: String, CaseIterable {
    case none = "전체"
    
    case textList = "텍스트"
    case checkList = "체크"
    case linkList = "링크"
    case reservationList = "예약"
    
    static func returnIntValue(type: MultiListType) -> Int {
        switch type {
        case .none: return 0
        case .textList: return 1
        case .checkList: return 2
        case .linkList: return 3
        case .reservationList: return 4
        }
    }
    static func returnTypeValue(int: Int) -> MultiListType {
        switch int {
        case 0: return .none
        case 1: return .textList
        case 2: return .checkList
        case 3: return .linkList
        case 4: return .reservationList
        default: break
        }
        return .none
    }
    static func returnPath(type: MultiListType) -> String {
        switch type {
        case .none: return "notSetted"
        case .checkList: return "checkLists"
        case .linkList: return "linkLists"
        case .textList: return "textLists"
        case .reservationList: return "reservationLists"
        }
    }
}
