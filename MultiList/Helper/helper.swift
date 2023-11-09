//
//  helper.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/15.
//

import SwiftUI

enum PathString {
    case user
    
    case sectionShared
    case section
    case multi
    
    case friend
    case shared
    case sharing
    
    case content(type: MultiListType)
    
    case row
    case sharedPeaple
    
    func pathString() -> String {
        switch self {
        case .user:
            return "users"
        case .sectionShared:
            return "sectionShared"
        case .section:
            return "sectionList"
        case .multi:
            return "itemList"
        case .friend:
            return "friendList"
        case .shared:
            return "sharedList"
        case .sharing:
            return "sharingList"
        case .content(let type):
            switch type {
            case .textList: return "textLists"
            case .checkList: return "checkLists"
            case .linkList: return "linkLists"
            case .reservationList: return "reservationLists"
            default: return ""
            }
        case .row: return "itemList"
        case .sharedPeaple: return "sharedPeople"
        }
        
    }
    
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    func checkMarkView(color: Color, fontWeight: Font.Weight) -> some View {
        Image(systemName: "checkmark")
            .resizable()
            .frame(width: 16, height: 17)
            .foregroundColor(color)
            .fontWeight(fontWeight)
            .offset(x: 0, y: -4)
    }
    
    var nowMark: some View {
        Text("now")
            .foregroundColor(.teal)
            .font(.caption).fontWeight(.heavy)
            .offset(y: -15)
    }
}

struct SampleMark: View {
    var body: some View {
        ZStack {
            Rectangle().fill(Color.red.opacity(0.4))
            Rectangle().fill(Color.primaryInverted)
                .padding(5)
            
            Text("S A M P L E").foregroundColor(.red.opacity(0.4)).fontWeight(.bold)
        }
        
    }
    
}
