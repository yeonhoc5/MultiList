//
//  ShareListSheetViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class ShareListSheetViewModel: ObservableObject {
    
    let userData: UserData
    
    init(userData: UserData) {
        self.userData = userData
    }
    
    func returningDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KR")
        formatter.dateFormat = "YY/MM/dd HH:mm"
        
        let str = formatter.string(from: date)
        return str
    }
    
    func shareResult(friendEmail: String, shareID: UUID, multiID: UUID, result: ShareResult) {
        guard userData.user != nil else { return }
        let db = Firestore.firestore()
        // 1. 친구 공유한 목록에 "거절" 결과 보내기
        db.collection("users").whereField("email", isEqualTo: friendEmail).getDocuments { snapshot, error in
            if let snapshot = snapshot, error == nil {
                for doc in snapshot.documents {
                    doc.reference.collection("sharingList").document(shareID.uuidString).updateData([
                        "shareResult": ShareResult.returnIntValue(result: result)
                    ])
                }
            }
        }
        
//         2. 내 리스트에서 지우기
        db.collection("users").document(userData.user.userUID).collection("sharedList").document(shareID.uuidString).delete()
        
//         3. 프라퍼티에서 지우기
        if let index = self.userData.sharedMultiList.firstIndex(where: { $0.id == shareID }) {
            withAnimation {
                self.userData.sharedMultiList.remove(at: index)
            }
        }
    }
    
    func approveShare(friendEmail: String, shareID:UUID, multiID: UUID, multiType: MultiListType, shareType: ShareType) {
        guard userData.user != nil else { return }
        
        let db = Firestore.firestore()
        
        // 섹션 확인
        guard let sectionShared = self.userData.sectionShared else { return }
        
        if shareType == .groupShare {
        
            // 0. 이미 참여하고 있는 것인지 확인
            let multiIDSet1 = self.userData.sectionList.flatMap { $0.multiList }.compactMap{ $0.multiID }
            let multiIDSet2 = self.userData.sectionShared.multiList.compactMap{ $0.multiID }
            guard multiIDSet1.contains(multiID) == false && multiIDSet2.contains(multiID) == false else {
                self.shareResult(friendEmail: friendEmail,
                                      shareID: shareID,
                                      multiID: multiID,
                                      result: .approve)
                return
            }
            
            // 멀티 리스트 인스턴스 생성
            let newMultiList = MultiList(multiID: multiID, order: sectionShared.multiList.count, listType: multiType, isSettingDone: true)
            
            // load 텍스트 / 체크 / 링크
            if newMultiList.listType == .textList {
                self.userData.loadTextListFromDB(multiList: newMultiList)
            } else if newMultiList.listType == .checkList {
                self.userData.loadCheckListFromDB(multiList: newMultiList)
            } else if newMultiList.listType == .linkList {
                self.userData.loadLinkListFromDB(multiList: newMultiList)
            }
            
            // Content 리스트에 sharedPerson 추가
            let path = db.collection(MultiListType.returnPath(type: newMultiList.listType)).document(multiID.uuidString)
            path.collection("sharedPeople").document(userData.user.userUID).setData([
                "userEmail": userData.user.userEmail,
                "userNickName" : userData.user.userNickName,
                "isEditable": true
            ])
            // sectionShare에 추가
            self.userData.addMultiToDB(sectionType: .share, section: sectionShared, newMultiList: newMultiList) {
                withAnimation {
                    self.userData.sectionShared.multiList.append(newMultiList)
                }
            }
            
            // shareSheet 리스트에서 지우기
            self.shareResult(friendEmail: friendEmail,
                                  shareID: shareID,
                                  multiID: multiID,
                                  result: .approve)
            
        } else if shareType == .copy {
            
            // 멀티 리스트 인스턴스 생성
            let newMultiList = MultiList(multiID: UUID(), order: sectionShared.multiList.count, listType: multiType, isSettingDone: true)
            
            if newMultiList.listType == .textList {
                // 로드 체크 or 링크
                let path = db.collection(PathString.content(type: newMultiList.listType).pathString()).document(multiID.uuidString)
                path.getDocument { snapshot, error in
                    if let snapshot = snapshot {
                       
                        if let data = snapshot.data(),
                           let title = data["title"] as? String {
                            let copyedTextList = TextList(title: title, itemList: [])
                            path.collection(PathString.row.pathString()).getDocuments { snapshots, error in
                                if let snapshots = snapshots {
                                    var copyedItemList: [TextRow] = []
                                    for doc in snapshots.documents {
                                        let data = doc.data()
                                        if let order = data["order"] as? Int,
                                           let title = data["title"] as? String {
                                            let textkRow = TextRow(order: order, title: title)
                                            copyedItemList.append(textkRow)
                                        }
                                    }
                                    copyedItemList = copyedItemList.sorted(by: { $0.order < $1.order })
                                    copyedTextList.itemList = copyedItemList
                                    // DB에 업로드
                                    self.userData.addMultiToDB(sectionType: .share, section: sectionShared, newMultiList: newMultiList) {
                                        let path = db.collection(PathString.content(type: .textList).pathString()).document(newMultiList.multiID.uuidString)
                                        path.setData([
                                            "title": copyedTextList.title
                                        ])
                                        for row in copyedTextList.itemList {
                                            path.collection(PathString.row.pathString()).document(row.id.uuidString).setData([
                                                "order": row.order,
                                                "title": row.title
                                            ])
                                        }
                                        withAnimation {
                                            self.userData.sectionShared.multiList.append(newMultiList)
                                            self.userData.textList.append(copyedTextList)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if newMultiList.listType == .checkList {
                // 로드 체크 or 링크
                let path = db.collection(PathString.content(type: newMultiList.listType).pathString()).document(multiID.uuidString)
                path.getDocument { snapshot, error in
                    if let snapshot = snapshot {
                       
                        if let data = snapshot.data(),
                           let title = data["title"] as? String,
                           let isDone = data["isDone"] as? Bool,
                           let cycle = data["cycle"] as? Int {
                            let copyedCheckList = CheckList(id: newMultiList.multiID, title: title, isDone: isDone, itemList: [], cycle: cycle, sharedPeople: [])
                            path.collection(PathString.row.pathString()).getDocuments { snapshots, error in
                                if let snapshots = snapshots {
                                    var copyedItemList: [CheckRow] = []
                                    for doc in snapshots.documents {
                                        let data = doc.data()
                                        if let order = data["order"] as? Int,
                                           let title = data["title"] as? String,
                                           let isDone = data["isDone"] as? Bool {
                                            let checkRow = CheckRow(order: order, title: title, isDone: isDone)
                                            copyedItemList.append(checkRow)
                                        }
                                    }
                                    copyedItemList = copyedItemList.sorted(by: { $0.order < $1.order })
                                    copyedCheckList.itemList = copyedItemList
                                    // DB에 업로드
                                    self.userData.addMultiToDB(sectionType: .share, section: sectionShared, newMultiList: newMultiList) {
                                        let path = db.collection(PathString.content(type: .checkList).pathString()).document(newMultiList.multiID.uuidString)
                                        path.setData([
                                            "title": copyedCheckList.title,
                                            "isDone": copyedCheckList.isDone,
                                            "cycle": copyedCheckList.cycle
                                        ])
                                        for row in copyedCheckList.itemList {
                                            path.collection(PathString.row.pathString()).document(row.id.uuidString).setData([
                                                "order": row.order,
                                                "title": row.title,
                                                "isDone": row.isDone
                                            ])
                                        }
                                        withAnimation {
                                            self.userData.sectionShared.multiList.append(newMultiList)
                                            self.userData.checkList.append(copyedCheckList)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else if newMultiList.listType == .linkList {
                // 로드 체크 or 링크
                let path = db.collection(PathString.content(type: newMultiList.listType).pathString()).document(multiID.uuidString)
                path.getDocument { snapshot, error in
                    if let snapshot = snapshot {
                       
                        if let data = snapshot.data(),
                           let title = data["title"] as? String {
                            let copyedLinkList = LinkList(id: newMultiList.multiID, title: title, itemList: [], sharedPeople: [])

                            path.collection(PathString.row.pathString()).getDocuments { snapshots, error in
                                if let snapshots = snapshots {
                                    var copyedItemList: [LinkRow] = []
                                    for doc in snapshots.documents {
                                        let data = doc.data()
                                        if let order = data["order"] as? Int,
                                           let title = data["title"] as? String,
                                           let url = data["url"] as? String {
                                            let linkRow = LinkRow(order: order, title: title, url: url)
                                            copyedItemList.append(linkRow)
                                        }
                                    }
                                    copyedItemList = copyedItemList.sorted(by: { $0.order < $1.order })
                                    copyedLinkList.itemList = copyedItemList
                                    // DB에 업로드
                                    self.userData.addMultiToDB(sectionType: .share, section: sectionShared, newMultiList: newMultiList) {
                                        let path = db.collection(PathString.content(type: .linkList).pathString()).document(newMultiList.multiID.uuidString)
                                        path.setData([
                                            "title": copyedLinkList.title
                                        ])
                                        for row in copyedLinkList.itemList {
                                            path.collection(PathString.row.pathString()).document(row.id.uuidString).setData([
                                                "order": row.order,
                                                "title": row.title,
                                                "url": row.url
                                            ])
                                        }
                                        withAnimation {
                                            self.userData.sectionShared.multiList.append(newMultiList)
                                            self.userData.linkList.append(copyedLinkList)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
            
            // Content 리스트에 sharedPerson 추가
            let path = db.collection(PathString.content(type: multiType).pathString()).document(newMultiList.multiID.uuidString)
            path.collection("sharedPeople").document(userData.user.userUID).setData([
                "userEmail": self.userData.user.userEmail,
                "userNickName": self.userData.user.userNickName,
                "isEditable": true
            ])

            // shareSheet 리스트에서 지우기
            self.shareResult(friendEmail: friendEmail,
                                  shareID: shareID,
                                  multiID: multiID,
                                  result: .approve)
        }
    }
    
    
    func cancelShare(friendEmail: String, shareID:UUID) {
        guard userData.user != nil else { return }
        let db = Firestore.firestore()
        // 1. (DB) 친구 shared에서 reject 처리
        db.collection(PathString.user.pathString()).whereField("email", isEqualTo: friendEmail).getDocuments { snapshot, error in
            if error == nil {
                if let snapshot = snapshot {
                    if snapshot.isEmpty {
                        db.collection(PathString.user.pathString()).document(self.userData.user.userUID).collection(PathString.sharing.pathString()).document(shareID.uuidString).delete { error in
                            if error == nil {
                                // 3. (프라퍼티) 내 리스트에서 삭제
                                if let firstIndex = self.userData.sharingMultiList.firstIndex(where: { $0.id == shareID }) {
                                    withAnimation {
                                        self.userData.sharingMultiList.remove(at: firstIndex)
                                    }
                                }
                            }
                        }
                    } else {
                        for doc in snapshot.documents {
                            doc.reference.collection(PathString.shared.pathString()).document(shareID.uuidString).updateData([
                                "shareResult": ShareResult.returnIntValue(result: .reject)
                            ]) { error in
                                if error == nil {
                                    print("친구 리스트에 삭제되었습니다.")
                                } else {
                                    print("해당 리스트가 없습니다.")
                                }
                                db.collection(PathString.user.pathString()).document(self.userData.user.userUID).collection(PathString.sharing.pathString()).document(shareID.uuidString).delete { error in
                                    if error == nil {
                                        // 3. (프라퍼티) 내 리스트에서 삭제
                                        if let firstIndex = self.userData.sharingMultiList.firstIndex(where: { $0.id == shareID }) {
                                            withAnimation {
                                                self.userData.sharingMultiList.remove(at: firstIndex)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                print("친구를 찾지 못했습니다.")
                // 내 리스트에서 삭제
                db.collection(PathString.user.pathString()).document(self.userData.user.userUID).collection(PathString.sharing.pathString()).document(shareID.uuidString).delete { error in
                    if error == nil {
                        //  (프라퍼티) 내 리스트에서 삭제
                        if let firstIndex = self.userData.sharingMultiList.firstIndex(where: { $0.id == shareID }) {
                            withAnimation {
                                self.userData.sharingMultiList.remove(at: firstIndex)
                            }
                        }
                    }
                }
                
            }
        }
    }
    
}

