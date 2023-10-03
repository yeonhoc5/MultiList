//
//  SharedPeopleListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/15.
//

import Foundation

class SharedPeopleListViewModel: ObservableObject {
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
}
