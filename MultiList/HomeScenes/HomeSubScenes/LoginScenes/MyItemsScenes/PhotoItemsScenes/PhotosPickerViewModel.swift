//
//  PhotosPickerViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/25.
//

import SwiftUI
import PhotosUI


class PhotosPickerViewModel: ObservableObject {
    
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func loadPhoto(item: [PhotosPickerItem], result: @escaping (UIImage) -> Void) {
        Task {
            if let photo = item.first, let data = try? await photo.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    result(image)
                }
            }
        }
    }
    
}
