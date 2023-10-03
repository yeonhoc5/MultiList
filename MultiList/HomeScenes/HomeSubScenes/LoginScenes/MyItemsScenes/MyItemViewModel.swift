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
                "itemType": MyItemType.returnIntValue(type: myItem.type)
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
                changeTextContent(path: path, myItem: myItem, itemText: content)
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
                changeTextContent(path: path, myItem: myItem, itemText: content)
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
    
    func changeTextContent(path: CollectionReference, myItem: MyItemModel, itemText: String) {
        path.document(myItem.id.uuidString).updateData([
            "content": itemText
        ])
        self.userData.myItems[myItem.order]?.itemText = itemText
    }
    
    func changePhotoContent(path: CollectionReference, myItem: MyItemModel, itemPhoto: UIImage, saveMode: ItemSaveMode! = .saveFirst, completion: @escaping (Bool) -> Void) {
        guard let data = itemPhoto.pngData() else { return }
        
        let storage = Storage.storage()
        let storagePath = storage.reference().child(userData.user.userUID).child("myItems").child(myItem.id.uuidString)
        
        if saveMode == .changeContent || saveMode == .changeAll {
            print("step 1: delete before file")
            path.document(myItem.id.uuidString).getDocument { snapshot, error in
                self.deleteStorageData(snapshot: snapshot, error: error) { bool in
                    print(bool)
                }
            }
        }
        
        DispatchQueue.global(qos: .background).async {
            let uploadTask = storagePath.putData(data) { metaData, error in
                if let metaData = metaData, error == nil,
                   let imagePath: String = metaData.path {
                    print("step 3: upload new file")
                    path.document(myItem.id.uuidString).updateData([
                        "content": imagePath
                    ])
                    DispatchQueue.main.async {
                        self.userData.myItems[myItem.order]?.itemPhoto = itemPhoto
                    }
                    completion(true)
                    print("upload done")
                } else {
                    print(error?.localizedDescription)
                }
            }
            uploadTask.resume()
        }
            
//            path.document(myItem.id.uuidString).getDocument { snapshot, error in
//                print("step 1-1: found file to delete")
//                if let snapshot = snapshot,
//                   let data = snapshot.data(),
//                   let imagePath: String = data["content"] as? String {
//                    storage.reference(withPath: imagePath).delete { error in
//                        if error == nil {
//                            print("step 2: nil before file")
//                            self.userData.myItems[myItem.order]?.itemPhoto = nil
//                        } else {
//                            print(error?.localizedDescription)
//                        }
//                    }
//                }
//            }
    }
    
    func deleteMyItem(itemNumber: Int, delteMode: ItemSaveMode! = .saveFirst) {
        guard let myItem = userData.myItems[itemNumber] else { return }
        let db = Firestore.firestore()
        let path = db.collection("users").document(userData.user.userUID).collection("myItems")
        
        if myItem.type == .text {
            path.document(myItem.id.uuidString).delete { error in
                if error == nil {
                    self.userData.myItems[myItem.order] = nil
                } else {
                    print(error?.localizedDescription)
                }
            }
        } else if myItem.type == .image {
            path.document(myItem.id.uuidString).getDocument { snapshot, error in
                self.deleteStorageData(snapshot: snapshot, error: error) { bool in
                    if bool {
                        path.document(myItem.id.uuidString).delete { error in
                            if error == nil {
                                self.userData.myItems[myItem.order] = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteStorageData(snapshot: DocumentSnapshot?, error: Error?, result: @escaping (Bool) -> Void) {
        print("step 1-2: ready to delete1")
        if let snapshot = snapshot, error == nil {
            print("step 1-3: ready to delete2")
            if let data = snapshot.data() {
                print("step 1-3-1: ready to delete2-1")
                if let photoPath = data["content"] as? String {
                    print("step 1-4: ready to delete3")
                    let storage = Storage.storage()
                    storage.reference(withPath: photoPath).delete { error in
                        print("step 1-5: ready to delete4")
                        if !storage.reference(withPath: photoPath).isAccessibilityElement {
                            result(true)
                        } else {
                            result(error == nil)
                        }
                    }
                } else {
                    result(true)
                }
            }
        }
    }
    
    func trimmingString(string: String) -> String {
        let str = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return str
    }
    
    
    func saveTextAtClipboard(text: String, result: @escaping () -> Void) {
        let clipboard = UIPasteboard.general
        clipboard.setValue(text, forPasteboardType: UTType.plainText.identifier)
    }
}
