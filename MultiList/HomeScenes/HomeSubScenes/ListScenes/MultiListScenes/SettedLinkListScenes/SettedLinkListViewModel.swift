//
//  SettedLinkListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/11.
//

import Foundation

class SettedLinkListViewModel: ObservableObject {
    let userData: UserData
    @Published var linkList: LinkList
    
    init(userData: UserData, linkList: LinkList) {
        self.userData = userData
        self.linkList = linkList
    }
    
    func returningSharingcount() -> Int {
        return userData.linkList.first(where: {$0.id == linkList.id})?.sharedPeople.count ?? 1
    }
}
