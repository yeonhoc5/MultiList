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
    var quality: CGFloat = 1.0
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func loadPhoto(item: [PhotosPickerItem], result: @escaping (UIImage, Double) -> Void) {
        Task {
            if let photo = item.first, let data = try? await photo.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data),
                   let jpegImage = self.jpegImage(image: image),
                   let returnImage = UIImage(data: jpegImage) {
                    result(returnImage, self.returnPhotoSize(photo: returnImage))
                }
            }
        }
    }
    
    func jpegImage(image: UIImage) -> Data? {
        if let data = image.jpegData(compressionQuality: quality) {
            if data.count <= 1024 * 1024 {
                return data
            } else {
                self.quality *= 0.9
                return jpegImage(image: image)
            }
        } else {
            return nil
        }
    }
 
    func returnPhotoSize(photo: UIImage) -> Double {
        if let data = photo.jpegData(compressionQuality: 1.0) {
            let size = (Double(data.count) / 1024 / 1024)
            return size
        } else {
            return 0
        }
    }
    
}
