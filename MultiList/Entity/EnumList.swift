//
//  EnumList.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/11/23.
//

import Foundation

enum NetworkError: String {
    case badNetwork = "네트워크 오류"
    case badServer = "정보를 읽지 못했습니다."
    case badURL = "정보를 찾을 수 없습니다."
}

enum ReOrdering {
    case up, down
}

// MARK: - 0. UserType
enum UserType: String {
    case anonymousUser
    case google
    case naver
    case kakao
    case appleUser
    
    static func returnIntValue(type: UserType) -> Int {
        switch type {
        case .anonymousUser: return 0
        case .google: return 1
        case .naver: return 2
        case .kakao: return 3
        case .appleUser: return 4
        }
    }
    
    static func returnTypeValue(int: Int) -> UserType {
        switch int {
        case 0: return .anonymousUser
        case 1: return .google
        case 2: return .naver
        case 3: return .kakao
        case 4: return .appleUser
        default: break
        }
        return .anonymousUser
    }
}
// MARK: - 1. MyItems
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

enum MultilistError: String, Error {
    case imageCompressionError = "이미지 변환 중 오류가 발생했습니다."
}
