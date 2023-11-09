//
//  StorageManager.swift
//  MultiList
//
//  Created by yeonhoc5 on 10/10/23.
//

import FirebaseStorage
import SwiftUI

final class StorageManager {
    let storage = Storage.storage().reference()
    static let shared = StorageManager()
    var quality: CGFloat = 1.0
    private init() {}
    
    
    func jpegImage(image: UIImage) -> Data? {
        if let data = image.jpegData(compressionQuality: quality) {
            if data.count <= 1024 * 1024 {
                return data
            } else {
                self.quality *= 0.9
                print(data.count)
                return jpegImage(image: image)
            }
        } else {
            return nil
        }
    }
    
    
    func saveImage(storagePath: StorageReference, image: UIImage, completion: @escaping () -> Void) async throws -> (String) {
        let meta = StorageMetadata()
        meta.contentType = "image/jpeg"
        
        guard let data = self.jpegImage(image: image) else { 
            throw MultilistError.imageCompressionError }
        
        let returnedMetadata = try await storagePath.putDataAsync(data, metadata: meta)
        
        guard let returendPath = returnedMetadata.path else {
            throw URLError(.badServerResponse)
        }
        completion()
        return returendPath
    }
    
    func getData(storagePath: String) async throws -> Data? {
        let storage = Storage.storage()
        let data = try await storage.reference(withPath: storagePath).data(maxSize: 50 * 1024 * 1024)
        return data
    }
    
    func getImage(storagePath: String) async throws -> UIImage {
        let data = try await getData(storagePath: storagePath) ?? nil
         
        guard let data = data, let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
}
