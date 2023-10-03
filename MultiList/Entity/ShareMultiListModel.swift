//
//  ShareMultiList.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/05.
//

import Foundation

class SharedMultiList: ObservableObject {
    @Published var sharedMultiList: [ShareMultiList]
    
    init(sharedMultiList: [ShareMultiList]) {
        self.sharedMultiList = sharedMultiList
    }
}

class SharingMultiList: ObservableObject {
    @Published var sharingMultiList: [ShareMultiList]
    
    init(sharingMultiList: [ShareMultiList]) {
        self.sharingMultiList = sharingMultiList
    }
}


struct ShareMultiList: Identifiable {
    
    let id: UUID
    let userEmail: String
    let userNickName: String
    let multiID: UUID
    let title: String
    let multiListType: MultiListType
    let shareType: ShareType
    let sharedTime: Date
    var shareResult: ShareResult 
    
    init(id: UUID! = UUID(), userEmail: String, userNickName: String, multiID: UUID, title: String, multiListType: MultiListType, shareType: ShareType, sharedTime: Date, shareResult: ShareResult! = .undetermined) {
        self.id = id
        self.userEmail = userEmail
        self.userNickName = userNickName
        self.multiID = multiID
        self.title = title
        self.multiListType = multiListType
        self.shareType = shareType
        self.sharedTime = sharedTime
        self.shareResult = shareResult
    }
    
}


enum ShareType: String, CaseIterable {
    case copy = "복사본"
    case groupShare = "공동 작업"
//    case notification = "통지문(나만 수정)"
//    case questionair = "설문지(받은 사람만 수정)"
    
    
    static func returnImageName(type: ShareType) -> String {
        switch type {
        case .copy:
            return "doc.on.doc"
        case .groupShare:
            return "person.2.fill"
        }
    }
    
    
    static func returnIntValue(type: ShareType) -> Int {
        switch type {
        case .copy:
            return 0
        case .groupShare:
            return 1
        }
    }
    
    static func returnTypeValue(int: Int) -> ShareType {
        switch int {
        case 0:
            return .copy
        case 1:
            return .groupShare
        default:
            break
        }
        return .copy
    }
}


enum ShareResult {
    case undetermined
    case approve
    case reject
    
    static func returnIntValue(result: ShareResult) -> Int {
        switch result {
        case .undetermined:
            return 0
        case .approve:
            return 1
        case .reject:
            return 2
        }
    }
    
    static func returnTypeValue(int: Int) -> ShareResult {
        switch int {
        case 0:
            return .undetermined
        case 1:
            return .approve
        case 2:
            return .reject
        default:
            break
        }
        return .undetermined
    }
}
