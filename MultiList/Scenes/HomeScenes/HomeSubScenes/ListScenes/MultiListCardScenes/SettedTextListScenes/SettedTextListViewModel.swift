//
//  SettedTextListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import Foundation

class SettedTextListViewModel: ObservableObject {
    let userData: UserData
    @Published var textList: TextList
    
    init(userData: UserData, textList: TextList) {
        self.userData = userData
        self.textList = textList
    }
    
    func returningSharingcount() -> Int {
        return userData.textList.first(where: {$0.id == textList.id})?.sharedPeople.count ?? 0
    }
}
