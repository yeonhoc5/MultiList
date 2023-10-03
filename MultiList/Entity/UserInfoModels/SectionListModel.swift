//
//  SectionListModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

//class SectionList: Equatable, Hashable, ObservableObject {
//    static func == (lhs: SectionList, rhs: SectionList) -> Bool {
//        return lhs.sectionID == rhs.sectionID
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(sectionID)
//    }
//
//    let sectionID: UUID
//    @Published var order: Int // 순서값으로 이용
//    @Published var sectionName: String
//    @Published var color: Int
//    @Published var multiList: [MultiList]
//
//    init(sectionID: UUID = UUID(), order: Int, sectionName: String, color: Int, multiList: [MultiList] = []) {
//        self.sectionID = sectionID
//        self.order = order
//        self.sectionName = sectionName
//        self.color = color
//        self.multiList = multiList
//    }
//}

enum SectionType {
    case share
    case list
}

struct SectionList: Equatable, Hashable {
    static func == (lhs: SectionList, rhs: SectionList) -> Bool {
        return lhs.sectionID == rhs.sectionID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sectionID)
    }

    let sectionID: UUID
    var order: Int // 순서값으로 이용
    var sectionName: String
    var color: Int
    var multiList: [MultiList]

    init(sectionID: UUID = UUID(), order: Int, sectionName: String, color: Int, multiList: [MultiList] = []) {
        self.sectionID = sectionID
        self.order = order
        self.sectionName = sectionName
        self.color = color
        self.multiList = multiList
    }
}
