//
//  MultiListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/18.
//

import Foundation


class MultiListViewModel: ObservableObject {
    @Published var content: Contents
    
    init(content: Contents) {
        self.content = content
    }

    
    func changeTitle(newTitle: String) {
        
    }
    
    func addSubContents() {
        
    }
    
    func changeSubContents() {
        
    }
    
    func deleteSubContents() {
        
    }
    
    
}
