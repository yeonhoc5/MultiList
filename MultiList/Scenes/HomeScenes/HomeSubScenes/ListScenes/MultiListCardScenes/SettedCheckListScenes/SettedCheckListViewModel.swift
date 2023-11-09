//
//  SettedCheckListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/11.
//

import Foundation

class SettedCheckListViewModel: ObservableObject {
    let userData: UserData
    @Published var checkList: CheckList
    
    init(userData: UserData, checkList: CheckList) {
        self.userData = userData
        self.checkList = checkList
    }
    
    func returningSharingcount() -> Int {
        return userData.checkList.first(where: {$0.id == checkList.id})?.sharedPeople.count ?? 1
    }
    
}

