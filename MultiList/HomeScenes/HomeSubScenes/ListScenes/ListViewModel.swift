//
//  ListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import Foundation
import SwiftUI
import FirebaseFirestore

enum EditCase {
    case reOder, delete, hidden
}
enum PartCase {
    case section, multi
}


class ListViewModel: ObservableObject {
    let userData: UserData
    var multiListToShare: MultiList!
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    // MARK: - 1. add Section
    
    func addSectionToUser(string: String) {
        let title = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let order = userData.sectionList.count
        let color = (userData.sectionList.last?.color ?? 0) + 1
        let newSection = SectionList(order: order, sectionName: title, color: color)
        
        DispatchQueue.main.async {
            self.userData.addSectionToDB(newSection: newSection) {
                self.userData.sectionList.append(newSection)
            }
        }
    }
    
    
    
    // MARK: -= add MultiList
    func addMultiList(section: SectionList) {
        let uuid = UUID()
        let newMultiList = MultiList(multiID: uuid, order: section.multiList.filter({ $0.isHidden == false }).count, listType: .checkList)
        
        if let index = self.userData.sectionList.firstIndex(where: { $0.sectionID == section.sectionID }) {
            self.userData.addMultiToDB(section: section, newMultiList: newMultiList) {
                self.userData.sectionList[index].multiList.append(newMultiList)
            }
        }
    }
    
    
    // MARK: - 2. delete Section / delete MultiList
    
    func deleteSectionList(section: SectionList, result: @escaping () -> Void) {   
        self.userData.deleteSectionList(userID: userData.user.userUID, section: section)
        self.userData.reOrderingMultiList(section: section, editCase: .delete, part: .section)
        result()
    }
//
    func deleteMultiList(sectionType: SectionType, section: SectionList, multi: MultiList, part: PartCase = .multi) {
        let pathString = sectionType == .list ? PathString.section.pathString() : PathString.sectionShared.pathString()
        if sectionType == .list {
            self.userData.sectionList[section.order].multiList.remove(at: multi.order)
        } else {
            self.userData.sectionShared.multiList.remove(at: multi.order)
        }
        

        DispatchQueue(label: "firebase", qos: .background).async {
            let db = Firestore.firestore()
            db.collection("users").document(self.userData.user.userUID).collection(pathString).document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).delete()
            
            if multi.isSettingDone {
                self.userData.removeSharedPersonAtContent(user: self.userData.user, type: multi.listType, multiID: multi.multiID)
            }
            DispatchQueue.main.async {
                self.userData.reOrderingMultiList(sectionType: sectionType,
                                                  section: section,
                                                  editCase: .delete,
                                                  part: .multi,
                                                  multiListOrder: multi.order,
                                                  isHidden: false)
            }
        }
    }
    
    func editSectionList(sectionList: SectionList, title: String, order: Int, color: Int) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(self.userData.user.userUID).collection("sectionList").document(sectionList.sectionID.uuidString)
        
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines) == "" ? sectionList.sectionName : title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        path.updateData([
            "sectionName": title,
            "color": color
        ])
        
        if let sectionIndex = userData.sectionList.firstIndex(where: {$0.sectionID == sectionList.sectionID}) {
            self.userData.sectionList[sectionIndex].sectionName = title
            self.userData.sectionList[sectionIndex].color = color
            if sectionList.order != order {
                self.userData.reOrderingMultiList(section: sectionList,
                                                  editCase: .reOder,
                                                  part: .section,
                                                  sectionOriOrder: sectionList.order,
                                                  sectionListToOrder: order)
            }
        }
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
    
    func settingContent(type: MultiListType, section: SectionList, multiList: MultiList) {
        guard let sectionIndex = self.userData.sectionList.firstIndex(where: {$0.sectionID == section.sectionID}),
              let multiIndex = self.userData.sectionList[sectionIndex].multiList.firstIndex(where: {$0.multiID == multiList.multiID}) else { return }
        if type == .checkList {
            // checkList 추가
            let newCheckList = CheckList(id: multiList.multiID, title: "New 체크리스트", itemList: [])
            addCheckListToDB(checkList: newCheckList) {
                self.userData.checkList.append(newCheckList)
            }
        } else if type == .linkList {
            // linkList 추가
            let newLinkList = LinkList(id: multiList.multiID, title: "New 링크리스트", itemList: [])
            addLinkListToDB(linkList: newLinkList) {
                self.userData.linkList.append(newLinkList)
            }
        }
        let db = Firestore.firestore()
        db.collection("users").document(userData.user.userUID).collection("sectionList").document(section.sectionID.uuidString).collection("itemList").document(multiList.multiID.uuidString).updateData([
            "listType": MultiListType.returnIntValue(type: type),
            "isSettingDone": true
        ])
        withAnimation {
            self.userData.sectionList[sectionIndex].multiList[multiIndex].listType = type
            self.userData.sectionList[sectionIndex].multiList[multiIndex].isSettingDone = true
        }
        
    }
    
    
    
    // 1. add 체크리스트 to DB
    func addCheckListToDB(checkList: CheckList, result: @escaping () -> Void) {
        let db = Firestore.firestore()
        let path = db.collection("checkLists").document(checkList.id.uuidString)
        
        path.setData([
            "title": checkList.title,
            "cycle": 0,
            "isDone": false,
        ])
        
        path.collection("sharedPeople").document(userData.user.userUID).setData([
            "userEmail": userData.user.userEmail,
            "isEditable": true
        ])
        
        result()
    }

    // 2. add 링크리스트 to DB
    func addLinkListToDB(linkList: LinkList, result: @escaping () -> Void) {
        let db = Firestore.firestore()
        let path = db.collection("linkLists").document(linkList.id.uuidString)
        
        path.setData([
            "title": linkList.title,
            "isDone": false
        ])
        
        path.collection("sharedPeople").document(userData.user.userUID).setData([
            "userEmail": userData.user.userEmail,
            "isEditable": true
        ])
        
        result()
    }

    
    // 3. 보관함으로 이동
    func moveAtSectionStorage(sectionIndex: Int, multiList: MultiList) {
        let section = userData.sectionList[sectionIndex]
        let newOrder = 10000 + section.multiList.filter({ $0.isHidden == true }).count
        
        if let multiIndex = userData.sectionList[sectionIndex].multiList.firstIndex(of: multiList) {
            let db = Firestore.firestore()
            db.collection("users").document(userData.user.userUID).collection("sectionList").document(section.sectionID.uuidString).collection("itemList").document(multiList.multiID.uuidString).updateData([
                "isHidden": true,
                "order": newOrder
            ]) { error in
                if error == nil {
                    withAnimation {
                        self.userData.sectionList[sectionIndex].multiList[multiIndex].isHidden = true
                    }
                    self.userData.sectionList[sectionIndex].multiList[multiIndex].order = newOrder
                    self.userData.reOrderingMultiList(section: section,
                                                      editCase: .hidden,
                                                      part: .multi,
                                                      multiListOrder: multiList.order,
                                                      isHidden: false)
                }
            }
        }
    }
    
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
    
    func moveMultiItem(moveType: MultiMoveType, fromSectionType: SectionType, fromSectionIndex: Int! = nil,
                       toSectionIndex: Int! = nil, fromMultiIndex: Int, toMultiIndex: Int, toMoveItem: MultiList! = nil) {
        let db = Firestore.firestore()
        
        switch moveType {
        case .inline:
            if fromSectionType == .share {
                if let section = self.userData.sectionShared {
                    for i in (min(fromMultiIndex, toMultiIndex)...max(fromMultiIndex, toMultiIndex)) {
                        let multi = section.multiList[i]
                        if let changedIndex = section.multiList.firstIndex(of: multi) {
                            userData.sectionShared.multiList[i].order = changedIndex
                            updateMultiOrderInDB(path: PathString.sectionShared.pathString(),
                                                 sectionID: section.sectionID.uuidString,
                                                 multiID: multi.multiID.uuidString,
                                                 changedIndex: changedIndex)
                        }
                    }
                }
            } else {
                if let sectionIndex = fromSectionIndex {
                    let section = self.userData.sectionList[sectionIndex]
                    for i in (min(fromMultiIndex, toMultiIndex)...max(fromMultiIndex, toMultiIndex)) {
                        let multi = section.multiList[i]
                        if let changedIndex = section.multiList.firstIndex(of: multi) {
                            userData.sectionList[sectionIndex].multiList[i].order = changedIndex
                            updateMultiOrderInDB(path: PathString.section.pathString(), 
                                                 sectionID: section.sectionID.uuidString,
                                                 multiID: multi.multiID.uuidString, 
                                                 changedIndex: changedIndex)
                        }
                    }
                }
            }
        case .shareToList:
            
            // 1. 원래 위치에서 빼기
            if let removeIndex = self.userData.sectionShared.multiList.firstIndex(of: toMoveItem) {
                let multiToRemove = userData.sectionShared.multiList[removeIndex]
                self.userData.sectionShared.multiList.remove(at: removeIndex)
                // 1-1. DB에서 제거
                db.collection("users").document(userData.user.userUID).collection(PathString.sectionShared.pathString()).document(userData.sectionShared.sectionID.uuidString).collection(PathString.multi.pathString()).document(multiToRemove.multiID.uuidString).delete()
            // 2. 원래 위치 오더 정리하기
                self.userData.reOrderingMultiList(sectionType: .share, section: userData.sectionShared, editCase: .delete, part: .multi, multiListOrder: removeIndex)
            }
    
    
            if let toSectionIndex = toSectionIndex,
               let tempMulti = userData.sectionList[toSectionIndex].multiList.filter({$0.isTemp == true}).first,
               let tempIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: tempMulti) {
                // 3. 새로운 섹션의 오더 정리하기
                let section = userData.sectionList[toSectionIndex]
                let multiSet = userData.sectionList[toSectionIndex].multiList.filter({$0.isHidden == false})
                for i in (tempIndex+1)..<multiSet.count {
                    let multi = multiSet[i]
                    userData.sectionList[toSectionIndex].multiList[i].order += 1
                    updateMultiOrderInDB(path: PathString.section.pathString(),
                                         sectionID: section.sectionID.uuidString,
                                         multiID: multi.multiID.uuidString,
                                         changedIndex: userData.sectionList[toSectionIndex].multiList[i].order)
                }
                
                userData.sectionList[toSectionIndex].multiList.remove(at: tempIndex)
                
                // 4. 새로운 곳에 넣기
                userData.sectionList[toSectionIndex].multiList.insert(toMoveItem, at: tempIndex)
                userData.sectionList[toSectionIndex].multiList[tempIndex].order = tempIndex
                db.collection("users").document(userData.user.userUID).collection(PathString.section.pathString()).document(section.sectionID.uuidString).collection(PathString.multi.pathString()).document(toMoveItem.multiID.uuidString).setData([
                    "order": tempIndex,
                    "listType": MultiListType.returnIntValue(type: toMoveItem.listType),
                    "isSettingDone": toMoveItem.isSettingDone as Bool,
                    "isHidden": toMoveItem.isHidden as Bool
                    
                    
                ])
            }
            
        case .listToList:
            // 1. 원래 위치에서 빼기
            if let fromSectionIndex = fromSectionIndex,
               let removeIndex = self.userData.sectionList[fromSectionIndex].multiList.firstIndex(of: toMoveItem) {
                let section = self.userData.sectionList[fromSectionIndex]
                let multiToRemove = self.userData.sectionList[fromSectionIndex].multiList[removeIndex]
                self.userData.sectionList[fromSectionIndex].multiList.remove(at: removeIndex)
                // 1-1. DB에서 제거
                db.collection("users").document(userData.user.userUID).collection(PathString.section.pathString()).document(section.sectionID.uuidString).collection(PathString.multi.pathString()).document(multiToRemove.multiID.uuidString).delete()
            // 2. 원래 위치 오더 정리하기
                self.userData.reOrderingMultiList(sectionType: .list, section: userData.sectionList[fromSectionIndex], editCase: .delete, part: .multi, multiListOrder: removeIndex)
            }
    
    
            if let toSectionIndex = toSectionIndex,
               let tempMulti = userData.sectionList[toSectionIndex].multiList.filter({$0.isTemp == true}).first,
               let tempIndex = userData.sectionList[toSectionIndex].multiList.firstIndex(of: tempMulti) {
                // 3. 새로운 섹션의 오더 정리하기
                let section = userData.sectionList[toSectionIndex]
                let multiSet = userData.sectionList[toSectionIndex].multiList.filter({$0.isHidden == false})
                for i in (tempIndex+1)..<multiSet.count {
                    let multi = multiSet[i]
                    userData.sectionList[toSectionIndex].multiList[i].order += 1
                    updateMultiOrderInDB(path: PathString.section.pathString(),
                                         sectionID: section.sectionID.uuidString,
                                         multiID: multi.multiID.uuidString,
                                         changedIndex: userData.sectionList[toSectionIndex].multiList[i].order)
                }
                
                userData.sectionList[toSectionIndex].multiList.remove(at: tempIndex)
                
                // 4. 새로운 곳에 넣기
                userData.sectionList[toSectionIndex].multiList.insert(toMoveItem, at: tempIndex)
                userData.sectionList[toSectionIndex].multiList[tempIndex].order = tempIndex
                db.collection("users").document(userData.user.userUID).collection(PathString.section.pathString()).document(section.sectionID.uuidString).collection(PathString.multi.pathString()).document(toMoveItem.multiID.uuidString).setData([
                    "order": tempIndex,
                    "listType": MultiListType.returnIntValue(type: toMoveItem.listType),
                    "isSettingDone": toMoveItem.isSettingDone as Bool,
                    "isHidden": toMoveItem.isHidden as Bool
                    
                    
                ])
            }
        }
    }
    
    func updateMultiOrderInDB(path: String, sectionID: String, multiID: String, changedIndex: Int) {
        let db = Firestore.firestore()
        db.collection("users").document(userData.user.userUID).collection(path).document(sectionID).collection("itemList").document(multiID).updateData([
            "order": changedIndex
        ])
    }
    
}

enum MultiMoveType {
    case inline
    case shareToList
    case listToList
}
