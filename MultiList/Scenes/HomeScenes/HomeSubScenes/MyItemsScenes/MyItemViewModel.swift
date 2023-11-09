//
//  MyItemViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/26.
//

import SwiftUI
import Photos
import FirebaseFirestore
import FirebaseStorage

enum ItemSaveMode {
    case saveFirst
    case changeTitle
    case changeContent
    case changeAll
    case notChanged
}

class MyItemViewModel: ObservableObject {
    let userData: UserData
    
    var isShowingContentAlert: Bool = false
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func saveMyItem(myItem: MyItemModel, itemText: String! = nil, itemPhoto: UIImage! = nil, saveMode: ItemSaveMode! = .saveFirst, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(userData.user.userUID).collection("myItems")
        
        switch saveMode {
        case .saveFirst:
            path.document(myItem.id.uuidString).setData([
                "itemTitle": myItem.title,
                "order": myItem.order,
                "itemType": MyItemType.returnIntValue(type: myItem.type),
                "lastDate": myItem.lastDate
            ])
            self.userData.myItems[myItem.order] = myItem
            switch myItem.type {
            case .text:
                guard let content = itemText else { return }
                changeTextContent(path: path, myItem: myItem, itemText: content)
            case .image:
                guard let content = itemPhoto else { return }
                changePhotoContent(path: path, myItem: myItem, itemPhoto: content) { bool in
                    completion(bool)
                }
            }
            print("saved")
        case .changeTitle:
            changeTitle(path: path, myItem: myItem)
            print("title Changed")
        case .changeContent:
            switch myItem.type {
            case .text:
                guard let content = itemText else { return }
                changeTextContent(path: path, myItem: myItem, itemText: content, saveMode: .changeContent)
            case .image:
                guard let content = itemPhoto else { return }
                changePhotoContent(path: path, myItem: myItem, itemPhoto: content, saveMode: .changeContent) { bool in
                    completion(bool)
                }
            }
            print("contents Changed")
        case .changeAll:
            changeTitle(path: path, myItem: myItem)
            switch myItem.type {
            case .text:
                guard let content = itemText else { return }
                changeTextContent(path: path, myItem: myItem, itemText: content, saveMode: .changeAll)
            case .image:
                guard let content = itemPhoto else { return }
                changePhotoContent(path: path, myItem: myItem, itemPhoto: content, saveMode: .changeAll) { bool in
                    completion(bool)
                }
            }
            print("All Changed")
        case .notChanged:
            break
        case .none:
            break
        }
    }
    
    func changeTitle(path: CollectionReference, myItem: MyItemModel) {
        path.document(myItem.id.uuidString).updateData([
            "itemTitle": myItem.title
        ])
        self.userData.myItems[myItem.order]?.title = myItem.title
    }
    
    func changeTextContent(path: CollectionReference, myItem: MyItemModel, itemText: String, saveMode: ItemSaveMode! = .saveFirst) {
        if saveMode == .saveFirst {
            path.document(myItem.id.uuidString).updateData([
                "content": itemText
            ])
        } else {
            path.document(myItem.id.uuidString).updateData([
                "content": itemText,
                "lastDate": Date()
            ])
        }
        
        self.userData.myItems[myItem.order]?.itemText = itemText
    }
    
    func changePhotoContent(path: CollectionReference, myItem: MyItemModel, itemPhoto: UIImage, saveMode: ItemSaveMode! = .saveFirst, completion: @escaping (Bool) -> Void) {
//        guard let data = itemPhoto.pngData() else { return }
        
        let storage = Storage.storage()
        let storagePath = storage.reference().child(userData.user.userUID).child("myItems").child(myItem.id.uuidString)
        
        if saveMode == .changeContent || saveMode == .changeAll {
            path.document(myItem.id.uuidString).getDocument { snapshot, error in
                self.userData.deleteStorageData(snapshot: snapshot, error: error) { bool in
                    print(bool)
                }
            }
        }
        Task {
            let uploadPath = try await StorageManager.shared.saveImage(storagePath: storagePath, image: itemPhoto) {
                print("step 0")
                completion(true)
            }
            if saveMode == .saveFirst {
                try await path.document(myItem.id.uuidString).updateData([
                    "content": uploadPath
                ])
            } else {
                try await path.document(myItem.id.uuidString).updateData([
                    "content": uploadPath,
                    "lastDate": Date()
                ])
            }
            
            DispatchQueue.main.async {
                self.userData.myItems[myItem.order]?.itemPhoto = itemPhoto
            }
        }
    }
    
    func reloadPhoto(itemID: UUID, itemOrder: Int) {
        let db = Firestore.firestore()
        db.collection("users").document(userData.user.userUID).collection("myItems").document(itemID.uuidString).getDocument(completion: { snapshot, error in
            if let data = snapshot?.data(),
               let path = data["content"] as? String {
                Task {
                    let image = try await StorageManager.shared.getImage(storagePath: path)
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            self.userData.myItems[itemOrder]?.itemPhoto = image
                        }
                    }
//                    reference.downloadURL { url, error in
//                        if let url = url, error == nil,
//                           let data = NSData(contentsOf: url),
//                           let image = UIImage(data: data as Data) {
//                        }
//                    }
                }
            }
        })
    }
    
    
    func trimmingString(string: String) -> String {
        let str = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return str
    }
    
    
    func saveTextAtClipboard(text: String, result: @escaping () -> Void) {
        let clipboard = UIPasteboard.general
        clipboard.setValue(text, forPasteboardType: UTType.plainText.identifier)
        result()
    }
    
    func savePhotoAtPhotoAlbum(image: UIImage, result: @escaping () -> Void) {
        UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
        result()
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            
        } else {
            withAnimation {
                self.isShowingContentAlert = true
            }
        }
    }
}
