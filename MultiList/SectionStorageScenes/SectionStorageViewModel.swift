//
//  SectionStorageViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/04.
//

import SwiftUI
import FirebaseFirestore


class SectionStorageViewModel: ObservableObject {
    
    let userData: UserData
    @Published var section: SectionList
    
    var width: CGFloat = min(screenSize.width, screenSize.height)
    
    init(userData: UserData, section: SectionList) {
        self.userData = userData
        self.section = section
    }

    // 0. 리턴 리스트 타입 필터링
    func filteredSection(filter: MultiListType) -> [MultiList] {
        let multiList = section.multiList.filter({ $0.isHidden == true })
        if filter == .allList {
            return multiList
        } else {
            return multiList.filter({ $0.listType == filter }).sorted(by: { $0.order < $1.order })
        }
    }
    
    // 1. 이름 바꾸기
    func modifyTitle(new: String, multiList: MultiList, oriTitle: String) {
        let newTitle = new.trimmingCharacters(in: .whitespacesAndNewlines)
        guard newTitle.count != 0 && newTitle != oriTitle else { return }
        let db = Firestore.firestore()
        if multiList.listType == .checkList {
            if let checkIndex = userData.checkList.firstIndex(where: {$0.id == multiList.multiID}) {
                userData.checkList[checkIndex].title = newTitle
                db.collection(MultiListType.returnPath(type: .checkList)).document(multiList.multiID.uuidString).updateData([
                    "title": newTitle
                ])
            }
        } else if multiList.listType == .linkList {
            if let linkIndex = userData.linkList.firstIndex(where: {$0.id == multiList.multiID}) {
                userData.linkList[linkIndex].title = newTitle
                db.collection(MultiListType.returnPath(type: .linkList)).document(multiList.multiID.uuidString).updateData([
                    "title": newTitle
                ])
            }
        }
    }
    
    func deleteMultiList(section: SectionList, multi: MultiList) {
        guard let firstIndex = section.multiList.firstIndex(where: { $0.multiID == multi.multiID }) else { return }
        
        // 1. 현재 섹션 프라퍼티에서 지우기
        self.section.multiList.remove(at: firstIndex)
        // 2. userData 섹션 프라퍼티에서 지우기
        self.userData.sectionList[section.order].multiList.remove(at: firstIndex)
        // 3. db에서 지우기
        DispatchQueue(label: "firebase", qos: .background).async {
            let db = Firestore.firestore()
            db.collection("users").document(self.userData.user.userUID).collection("sectionList").document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).delete()
            if multi.isSettingDone {
                self.userData.removeSharedPersonAtContent(user: self.userData.user, type: multi.listType, multiID: multi.multiID)
            }
            DispatchQueue.main.async {
                self.userData.reOrderingMultiList(sectionType: .list,
                                                  section: section,
                                                  editCase: .delete,
                                                  part: .multi,
                                                  multiListOrder: multi.order,
                                                  isHidden: true)
            }
        }
    }
    
    func deleteContent(multiList: MultiList) {
        let db = Firestore.firestore()
        db.collection(MultiListType.returnPath(type: multiList.listType)).document(multiList.multiID.uuidString).delete()
    }
    

    
    func editMultiName(multiList: MultiList, string: String) {
        let db = Firestore.firestore()
        if multiList.listType == .checkList {
            if let checkIndex = self.userData.checkList.firstIndex(where: {$0.id == multiList.multiID}) {
                self.userData.checkList[checkIndex].title = string
                db.collection("checkLists").document(multiList.multiID.uuidString).updateData([
                    "title": string
                ])
            }
        } else if multiList.listType == .linkList {
            if let linkIndex = self.userData.linkList.firstIndex(where: {$0.id == multiList.multiID}) {
                self.userData.linkList[linkIndex].title = string
                db.collection("linkLists").document(multiList.multiID.uuidString).updateData([
                    "title": string
                ])
            }
        }
        
    }
    
    
    // 3. 섹션으로 이동
    func hiddenAtSectionStorage(sectionIndex: Int, multiList: MultiList) {
        let newOrder = section.multiList.filter({ $0.isHidden == false }).count
        if let index = section.multiList.firstIndex(of: multiList) {
            let db = Firestore.firestore()
            db.collection(PathString.user.pathString()).document(userData.user.userUID).collection(PathString.section.pathString()).document(section.sectionID.uuidString).collection("itemList").document(multiList.multiID.uuidString).updateData([
                "isHidden": false,
                "order": newOrder
            ]) { error in
                if error == nil {
                    self.userData.sectionList[sectionIndex].multiList[index].isHidden = false
                    self.userData.sectionList[sectionIndex].multiList[index].order = newOrder
                    withAnimation {
                        self.section.multiList.remove(at: index)
                    }
                    self.userData.reOrderingMultiList(section: self.section,
                                                      editCase: .hidden,
                                                      part: .multi,
                                                      multiListOrder: multiList.order,
                                                      isHidden: true)
                    
                }
            }
        }
    }
    
}
