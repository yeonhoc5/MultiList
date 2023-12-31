//
//  UserData.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/23.
//

import Foundation
import SwiftUI
import FirebaseFirestore
import FirebaseStorage

class UserData: ObservableObject {
    // 0. 유저 정보
    @Published var user: UserModel! {
        didSet {
            self.randomNum = Int.random(in: 0..<cardBackground.count)
        }
    }
    @Published var myItems: [MyItemModel?] = [nil, nil, nil, nil]
    // 1. 섹션-멀티 리스트
    @Published var sectionShared: SectionList!
    @Published var sectionList: [SectionList] = []
    // 2. Setted 멀티 리스트
    @Published var textList: [TextList] = []
    @Published var checkList: [CheckList] = []
    @Published var linkList: [LinkList] = []
    // 3. 공유 멀티 리스트
    @Published var sharedMultiList: [ShareMultiList] = []
    @Published var sharingMultiList: [ShareMultiList] = []
    // 4. 친구 리스트
    @Published var friendList: [Friend] = []
    @Published var notYetFriendList: [Friend] = []
    let screenSize = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size
    let scale = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.scale
    let cardBackground = ["LoginCardBackground1", "LoginCardBackground2", "LoginCardBackground3"]
    var randomNum: Int = 0
    
    init() { }
    
    func logout() {
        self.user = nil
        // 1.
        self.myItems = [nil, nil, nil, nil]
        self.sectionShared = nil
        self.sectionList = []
        // 2.
        self.textList = []
        self.checkList = []
        self.linkList = []
        // 3.
        self.sharedMultiList = []
        self.sharingMultiList = []
        self.friendList = []
        self.notYetFriendList = []
    }
    
    func loadDataWithUser(user: UserModel) {
        if user.userUID == self.user.userUID {
            if user.accountType != .anonymousUser {
                self.loadMyItemsFromDB()
            }
            DispatchQueue.main.async {
                self.loadSectionListFromDB()
                if user.accountType != .anonymousUser {
                    self.loadFriendListFromDB()
                    self.loadShareListFromDB()
                }
            }
            if user.accountType != .anonymousUser {
                self.loadSectionSharedFromDB()
            }
        }
    }
    
    func loadMyItemsFromDB() {
        let db = Firestore.firestore()
        
        db.collection("users").document(user.userUID).collection("myItems").getDocuments { snapshot, error in
            if let snapshot = snapshot, error == nil {
                for doc in snapshot.documents {
                    let data = doc.data()
                    if let id = UUID(uuidString: doc.documentID) {
                        if let order = data["order"] as? Int,
                           let title = data["itemTitle"] as? String,
                           let itemType = data["itemType"] as? Int {
                            let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                            var myItem = MyItemModel(id: id, 
                                                     title: title,
                                                     order: order,
                                                     type: MyItemType.returnTypeValue(int: itemType),
                                                     lastDate: lastDate)
                            if myItem.type == .text {
                                let content = data["content"] as? String
                                myItem.itemText = content
                            } else if myItem.type == .image {
                                if let path = data["content"] as? String {
                                    Task {
                                        let image = try? await StorageManager.shared.getImage(storagePath: path)
                                        DispatchQueue.main.async {
                                            withAnimation {
                                                self.myItems[order]?.itemPhoto = image
                                            }
                                        }
                                    }
                                }
                            }
                            self.myItems[order] = myItem
                        }
                    }
                }
                print("load [My Items] Done")
            } else {
                print("Error : My Items Load")
            }
        }
    }
    
    
    func loadSectionSharedFromDB() {
        guard user != nil, user.accountType != .anonymousUser else { return }
        let db = Firestore.firestore()
        let path = db.collection(PathString.user.pathString()).document(self.user.userUID).collection(PathString.sectionShared.pathString())
        
        path.getDocuments { snapshot, error in
            if let snapshot = snapshot {
                
                if snapshot.isEmpty {
                    // sectionShare 생성
                    let sectionShared = SectionList(order: 0, sectionName: "공유받은 항목", color: 0)
                    
                    path.document(sectionShared.sectionID.uuidString).setData([
                        "order": sectionShared.order,
                        "color": sectionShared.color,
                        "sectionName": sectionShared.sectionName
                    ])
                    DispatchQueue.main.async {
                        self.sectionShared = sectionShared
                    }
                } else {
                    
                    for doc in snapshot.documents {
                        let id = doc.documentID
                        let data = doc.data()
                        if let uuid = UUID(uuidString: id),
                           let order = data["order"] as? Int,
                           let color = data["color"] as? Int,
                           let sectionName = data["sectionName"] as? String {
                            self.sectionShared = SectionList(sectionID: uuid,
                                                             order: order,
                                                             sectionName: sectionName,
                                                             color: color,
                                                             multiList: [])
                        }
                    }
                    self.loadMultiListFromDB(sectionType: .share, section: self.sectionShared)
                    print("load [SectionSHARE List] Done")
                }
            }
        }
    }
    
    func loadSectionListFromDB() {
        guard user != nil else { return }
        let db = Firestore.firestore()
        let path = db.collection(PathString.user.pathString()).document(self.user.userUID).collection(PathString.section.pathString())
        
        path.getDocuments { snapshot, error in
            var loadedSectionList: [SectionList] = []
            if let snapshot = snapshot {
                for section in snapshot.documents {
                    let data = section.data()
                    let uuid = section.documentID
                    guard let uuid = UUID(uuidString: uuid),
                          let order = data["order"] as? Int,
                          let color = data["color"] as? Int,
                          let name = data["sectionName"] as? String else {
                        return
                    }
                    let section = SectionList(sectionID: uuid, order: order, sectionName: name, color: color)
                    loadedSectionList.append(section)
                }
                self.sectionList = loadedSectionList.sorted(by: {$0.order < $1.order})
                for section in self.sectionList {
                    DispatchQueue.main.async {
                        self.loadMultiListFromDB(section: section)
                    }
                }
                print("load [Section List] Done")
            }
        }
    }
    
    func loadMultiListFromDB(sectionType: SectionType! = .list, section: SectionList) {
        let db = Firestore.firestore()
        let pathString = sectionType == .list ? PathString.section.pathString() : PathString.sectionShared.pathString()
        let path = db.collection(PathString.user.pathString()).document(self.user.userUID).collection(pathString).document(section.sectionID.uuidString).collection(PathString.multi.pathString())
        
        path.getDocuments { snapshot, error in
            if let snapshot = snapshot {
                
                var itemList: [MultiList] = []
                
                for multi in snapshot.documents {
                    let data = multi.data()
                    if let uuid = UUID(uuidString: multi.documentID),
                       let order = data["order"] as? Int,
                       let listType = data["listType"] as? Int,
                       let isSettingDone = data["isSettingDone"] as? Bool,
                       let isHidden = data["isHidden"] as? Bool {
                        let multiList = MultiList(multiID: uuid,
                                                  order: order,
                                                  listType: MultiListType.returnTypeValue(int: listType),
                                                  isSettingDone: isSettingDone,
                                                  isHidden: isHidden)
                        itemList.append(multiList)
                        if multiList.isSettingDone {
                            if multiList.listType == .textList {
                                self.loadTextListFromDB(multiList: multiList)
                            } else if multiList.listType == .checkList {
                                self.loadCheckListFromDB(multiList: multiList)
                            } else if multiList.listType == .linkList {
                                self.loadLinkListFromDB(multiList: multiList)
                            }
                        }
                    }
                }
                itemList = itemList.sorted(by: { $0.order < $1.order })
                if sectionType == .list {
                    if let sectionIndex = self.sectionList.firstIndex(where: {$0.sectionID == section.sectionID}) {
                        withAnimation {
                            self.sectionList[sectionIndex].multiList = itemList
                            self.checkMultiListOrder(sectionIndex: sectionIndex, itemList: itemList)
                        }
                    }
                } else if sectionType == .share {
                    self.sectionShared.multiList = itemList
                }
            }
        }
    }
    
    
    func checkMultiListOrder(sectionIndex: Int, itemList: [MultiList]) {
        var sortedList = itemList.filter({ $0.isHidden == false && $0.isTemp == false }).sorted(by: { $0.order < $1.order })
        
        for i in sortedList  {
            if let index = sortedList.firstIndex(of: i) {
                if index != i.order {
                    self.sectionList[sectionIndex].multiList[index].order = index
                    
                    let db = Firestore.firestore()
                    db.collection("users").document(user.userUID).collection("sectionList").document(sectionList[sectionIndex].sectionID.uuidString).collection("itemList").document(i.multiID.uuidString).updateData([
                             "order": index
                    ])
                }
            }
        }
        sortedList.append(contentsOf: itemList.filter({$0.isTemp == true}))
        sortedList.append(contentsOf: itemList.filter({$0.isHidden == true}))
        self.sectionList[sectionIndex].multiList = sortedList
    }
    
    func loadTextListFromDB(multiList: MultiList) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.content(type: multiList.listType).pathString()).document(multiList.multiID.uuidString)
//        // 1. 접근 권한 있는지 체크
//        path.collection("sharedPeople").document(user.userUID).getDocument { snapshot, error in
//            if snapshot?.exists == true {
                // 2. 권한 체크 후 로드
        path.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot,
               let id = UUID(uuidString: snapshot.documentID) {
                if let data = snapshot.data(),
                   let title = data["title"] as? String {
                    
                    let newTextList = TextList(id: id, title: title, itemList: [], sharedPeople: [])
                    
                    path.collection(PathString.row.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var itemList: [TextRow] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                if let id = UUID(uuidString: item.documentID) {
                                    guard let order = data["order"] as? Int,
                                          let title = data["title"] as? String else { return }
                                    let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                                    let itemRow = TextRow(id: id, order: order, title: title, lastDate: lastDate, chargedPerson: nil)
                                    itemList.append(itemRow)
                                } else {
                                    guard let order = data["order"] as? Int,
                                          let title = data["title"] as? String else { return }
                                    let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                                    let itemRow = TextRow(id: UUID(), order: order, title: title, lastDate: lastDate, chargedPerson: nil)
                                    itemList.append(itemRow)
                                }
                            }
                            itemList = itemList.sorted(by: { $0.order < $1.order })
                            newTextList.itemList = itemList
                        }
                    }
                    
                    path.collection(PathString.sharedPeaple.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var people: [Person] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                let id = item.documentID
                                guard let email = data["userEmail"] as? String,
                                      let nickName = data["userNickName"] as? String,
                                      let isEditable = data["isEditable"] as? Bool else { return }
                                let newPerson = Person(id: id, userName: nickName, userEmail: email, isEditable: isEditable)
                                people.append(newPerson)
                            }
                            newTextList.sharedPeople = people
                            if self.textList.filter({ $0.id == newTextList.id }).count == 0 {
                                self.textList.append(newTextList)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadCheckListFromDB(multiList: MultiList) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.content(type: multiList.listType).pathString()).document(multiList.multiID.uuidString)
//        // 1. 접근 권한 있는지 체크
//        path.collection("sharedPeople").document(user.userUID).getDocument { snapshot, error in
//            if snapshot?.exists == true {
                // 2. 권한 체크 후 로드
        path.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot,
               let id = UUID(uuidString: snapshot.documentID) {
                if let data = snapshot.data(),
                   let title = data["title"] as? String,
                   let isDone = data["isDone"] as? Bool,
                   let cycle = data["cycle"] as? Int {
                    
                    let newCheckList = CheckList(id: id, title: title, isDone: isDone, itemList: [], cycle: cycle, sharedPeople: [])
                    
                    path.collection(PathString.row.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var itemList: [CheckRow] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                if let id = UUID(uuidString: item.documentID) {
                                    guard let order = data["order"] as? Int,
                                          let title = data["title"] as? String,
                                          let isDone = data["isDone"] as? Bool else { return }
                                    let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                                    let itemRow = CheckRow(id: id, order: order, title: title, isDone: isDone, lastDate: lastDate, chargedPerson: nil)
                                    itemList.append(itemRow)
                                } else {
                                    guard let order = data["order"] as? Int,
                                          let title = data["title"] as? String,
                                          let isDone = data["isDone"] as? Bool else { return }
                                    let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                                    let itemRow = CheckRow(id: UUID(), order: order, title: title, isDone: isDone, lastDate: lastDate, chargedPerson: nil)
                                    itemList.append(itemRow)
                                }
                            }
                            itemList = itemList.sorted(by: { $0.order < $1.order })
                            newCheckList.itemList = itemList
                        }
                    }
                    
                    path.collection(PathString.sharedPeaple.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var people: [Person] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                let id = item.documentID
                                guard let email = data["userEmail"] as? String,
                                      let nickName = data["userNickName"] as? String,
                                      let isEditable = data["isEditable"] as? Bool else { return }
                                let newPerson = Person(id: id, userName: nickName, userEmail: email, isEditable: isEditable)
                                people.append(newPerson)
                            }
                            newCheckList.sharedPeople = people
                            if self.checkList.filter({ $0.id == newCheckList.id }).count == 0 {
                                self.checkList.append(newCheckList)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func loadLinkListFromDB(multiList: MultiList) {
        let db = Firestore.firestore()
        let path = db.collection(MultiListType.returnPath(type: .linkList)).document(multiList.multiID.uuidString)
        
        path.addSnapshotListener { snapshot, error in
            if let snapshot = snapshot,
               let id = UUID(uuidString: snapshot.documentID) {
                if let data = snapshot.data(),
                   let title = data["title"] as? String {

                    let newLinkList = LinkList(id: id, title: title, itemList: [], sharedPeople: [])
                    
                    path.collection(PathString.row.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var itemList: [LinkRow] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                guard let id = UUID(uuidString: item.documentID),
                                      let order = data["order"] as? Int,
                                      let title = data["title"] as? String,
                                      let url = data["url"] as? String else { return }
                                let lastDate = (data["lastDate"] as? Timestamp)?.dateValue() ?? Date()
                                let itemRow = LinkRow(id: id, order: order, title: title, url: url, lastDate: lastDate, chargedPerson: nil)
                                itemList.append(itemRow)
                            }
                            itemList = itemList.sorted(by: { $0.order < $1.order })
                            newLinkList.itemList = itemList
                        }
                    }
                    
                    path.collection(PathString.sharedPeaple.pathString()).addSnapshotListener { snapshot, error in
                        if let snapshot = snapshot {
                            var people: [Person] = []
                            for item in snapshot.documents {
                                let data = item.data()
                                let id = item.documentID
                                guard let email = data["userEmail"] as? String,
                                      let nickName = data["userNickName"] as? String,
                                      let isEditable = data["isEditable"] as? Bool else { return }
                                let newPerson = Person(id: id, userName: nickName, userEmail: email, isEditable: isEditable)
                                people.append(newPerson)
                            }
                            newLinkList.sharedPeople = people
                            if self.linkList.filter({$0.id == newLinkList.id}).count == 0 {
                                self.linkList.append(newLinkList)
                            }
                        }
                    }
                    
                }
            }
        }
    }
    
    func loadFriendListFromDB() {
        let db = Firestore.firestore()
        
        db.collection(PathString.user.pathString()).document(user.userUID).collection(PathString.friend.pathString()).addSnapshotListener({ snapshot, error in
            if let snapshot = snapshot, error == nil {
                var loadedFriendList: [Friend] = []
                for doc in snapshot.documents {
                    let docData = doc.data()
                    guard let order = docData["order"] as? Int,
                          let nickName = docData["nickName"] as? String,
                          let email = docData["userEmail"] as? String else { return }
                    let friend = Friend(uid: doc.documentID, order: order, userEmail: email, userNickName: nickName)
                    loadedFriendList.append(friend)
                }
                loadedFriendList = loadedFriendList.sorted(by: {$0.order < $1.order})
                self.friendList = loadedFriendList
                self.loadNotYetFriendListFromDB()
            }
        })
    }
    
    func loadNotYetFriendListFromDB() {
        let db = Firestore.firestore()
        let friendEmailList = self.friendList.compactMap({ $0.userEmail })
        
        db.collection(PathString.user.pathString()).document(user.userUID).collection("notYetFriendList").addSnapshotListener({ snapshot, error in
            if let snapshot = snapshot, error == nil {
                var loadedPeopleList: [Friend] = []
                for doc in snapshot.documents {
                    let docData = doc.data()
                    guard let nickName = docData["nickName"] as? String,
                          let email = docData["userEmail"] as? String else { return }
                    let friend = Friend(uid: doc.documentID, order: 0, userEmail: email, userNickName: nickName)
                    
                    if friendEmailList.contains(friend.userEmail) {
                        db.collection(PathString.user.pathString()).document(self.user.userUID).collection("notYetFriendList").document(doc.documentID).delete()
                    } else if loadedPeopleList.compactMap({$0.userEmail}).contains(friend.userEmail) {
                        db.collection(PathString.user.pathString()).document(self.user.userUID).collection("notYetFriendList").document(doc.documentID).delete()
                    } else {
                        loadedPeopleList.append(friend)
                    }
                }
                loadedPeopleList = loadedPeopleList.sorted(by: {$0.userNickName < $1.userNickName})
                
                
                
                
                
                self.notYetFriendList = loadedPeopleList
            }
        })
    }
    
    
    func loadShareListFromDB() {
        let db = Firestore.firestore()
        let path = db.collection(PathString.user.pathString()).document(user.userUID)
        path.collection(PathString.shared.pathString()).addSnapshotListener({ snapshot, error in
            if let snapshot = snapshot {
                self.sharedMultiList = self.returnShareMulti(snapshot: snapshot, shareSheetType: .recieve)
            }
        })
          
        path.collection(PathString.sharing.pathString()).getDocuments { snapshot, error in
            if let snapshot = snapshot {
                self.sharingMultiList = self.returnShareMulti(snapshot: snapshot, shareSheetType: .send)
            }
        }
        
        path.collection(PathString.sharing.pathString()).addSnapshotListener { snapshot, error in
            if let snapshot = snapshot {
                for doc in snapshot.documents {
                    let data = doc.data()
                    if let docID = UUID(uuidString: doc.documentID),
                       let shareResult = data["shareResult"] as? Int {
                        if let index = self.sharingMultiList.firstIndex(where: {$0.id == docID}) {
                            self.sharingMultiList[index].shareResult = ShareResult.returnTypeValue(int: shareResult)
                        }
                    }
                }
            }
        }
        
        path.collection(PathString.shared.pathString()).addSnapshotListener { snapshot, error in
            if let snapshot = snapshot {
                for doc in snapshot.documents {
                    let data = doc.data()
                    if let docID = UUID(uuidString: doc.documentID),
                       let shareResult = data["shareResult"] as? Int {
                        if let index = self.sharedMultiList.firstIndex(where: {$0.id == docID}) {
                            self.sharedMultiList[index].shareResult = ShareResult.returnTypeValue(int: shareResult)
                        }
                    }
                }
            }
        }
        
    }
    
    func returnShareMulti(snapshot: QuerySnapshot, shareSheetType: ShareListSheet) -> [ShareMultiList] {
        var list: [ShareMultiList] = []
        for doc in snapshot.documents {
            let data = doc.data()
            if let docID = UUID(uuidString: doc.documentID),
               let name = data["userNickName"] as? String,
               let email = data["userEmail"] as? String,
               let multiId = data["multiID"] as? String,
               let multiID = UUID(uuidString: multiId),
               let title = data["title"] as? String,
               let multiListType = data["multiListType"] as? Int,
               let shareType = data["shareType"] as? Int,
               let sharedTime = data["sharedTime"] as? Timestamp,
               let shareResult = data["shareResult"] as? Int {
                let sharedItem = ShareMultiList(id: docID,
                                                userEmail: email,
                                                userNickName: name,
                                                multiID: multiID,
                                                title: title,
                                                multiListType: MultiListType.returnTypeValue(int: multiListType),
                                                shareType: ShareType.returnTypeValue(int: shareType),
                                                sharedTime: sharedTime.dateValue(),
                                                shareResult: ShareResult.returnTypeValue(int: shareResult))
                if shareSheetType == .send {
                    list.append(sharedItem)
                } else {
                    if ShareResult.returnTypeValue(int: shareResult) == .undetermined {
                        list.append(sharedItem)
                    }
                }

            }
        }
        
        list = list.sorted(by: { $0.sharedTime > $1.sharedTime })
        return list
    }
    
    
    func addSectionToDB(newSection: SectionList, completion: @escaping () -> Void) {
        let db = Firestore.firestore()
        db.collection(PathString.user.pathString()).document(user.userUID).collection(PathString.section.pathString()).document(newSection.sectionID.uuidString).setData([
            "order": newSection.order,
            "color": newSection.color,
            "sectionName": newSection.sectionName
        ])
        completion()
    }
    
    func addMultiToDB(sectionType: SectionType! = .list, section: SectionList, newMultiList: MultiList, completion: @escaping () -> Void) {
        let pathString = sectionType == .list ? PathString.section.pathString() : PathString.sectionShared.pathString()
        DispatchQueue(label: "firebase", qos: .background).async {
            let db = Firestore.firestore()
            db.collection(PathString.user.pathString()).document(self.user.userUID).collection(pathString
            ).document(section.sectionID.uuidString).collection(PathString.row.pathString()).document(newMultiList.multiID.uuidString).setData([
                "order": newMultiList.order,
                "listType": MultiListType.returnIntValue(type: newMultiList.listType),
                "isSettingDone": true as Bool,
                "isHidden": newMultiList.isHidden as Bool
            ])
        }
        completion()
    }
    
    func addFriendToMyInfo(friend: Friend, addMeToFriend: Bool! = false) {
        let newFriend = friend
        newFriend.order = self.friendList.count
        
        let db = Firestore.firestore()
        let path = db.collection("users").document(self.user.userUID).collection("friendList")
        let uid = path.document().documentID
        path.document(uid).setData([
            "order": newFriend.order,
            "nickName": newFriend.userNickName,
            "userEmail": newFriend.userEmail
        ])
        newFriend.id = uid
        
        self.friendList.append(newFriend)
        if addMeToFriend {
            addMeToFriendList(friend: newFriend)
        }
    }
    
    func addMeToFriendList(friend: Friend) {
        let db = Firestore.firestore()
        db.collection("users").whereField("email", isEqualTo: friend.userEmail).getDocuments { snapshot, error in
            if let snapshot = snapshot, error == nil {
                for doc in snapshot.documents {
                    doc.reference.collection("notYetFriendList").document(friend.id).setData([
                        "nickName": self.user.userNickName,
                        "userEmail": self.user.userEmail
                    ])
                }
            }
        }
    }
    
    
    func deleteSectionList(userID: String, section: SectionList, sectionType: SectionType! = .list) {
        let db = Firestore.firestore()
        let path = db.collection(PathString.user.pathString()).document(userID)
        // 0-1. 섹션리스트
        if sectionType == .list {
            if let index = sectionList.firstIndex(of: section) {
                // 1. 프라퍼티에서 지우기
                self.sectionList.remove(at: index)
                // 2. DB에서 지우기
                let pathDetail = path.collection(PathString.section.pathString()).document(section.sectionID.uuidString)
                
                for multi in section.multiList {
                    if multi.isSettingDone {
                        // 1. 컨텐츠에서 유저 제거 && 유저 0일 시 컨텐츠 제거
                        removeSharedPersonAtContent(user: user, type: multi.listType, multiID: multi.multiID)
                    }
                    // 2. section 아래 멀티 리스트 지우기
                    pathDetail.collection(PathString.multi.pathString()).document(multi.multiID.uuidString).delete()
                }
                
                // 3. 섹션 지우기
                pathDetail.delete()
            }
        } else if sectionType == .share {
            // 0-1. 섹션 Shared
            // 2. DB에서 지우기
            let pathDetail = path.collection(PathString.sectionShared.pathString()).document(section.sectionID.uuidString)
            for multi in section.multiList {
                if multi.isSettingDone {
                    // 1. 컨텐츠에서 유저 제거 && 유저 0일 시 컨텐츠 제거
                    removeSharedPersonAtContent(user: user, type: multi.listType, multiID: multi.multiID)
                }
                // 2. section 아래 멀티 리스트 지우기
                pathDetail.collection(PathString.multi.pathString()).document(multi.multiID.uuidString).delete()
            }
            // 3. 섹션 지우기
            pathDetail.delete()
            self.sectionShared = nil
        }
    }
    
    func removeSharedPersonAtContent(user: UserModel, type: MultiListType, multiID: UUID) {
        let db = Firestore.firestore()
        let pathString = MultiListType.returnPath(type: type)
        
        let path = db.collection(pathString).document(multiID.uuidString).collection(PathString.sharedPeaple.pathString())
        path.whereField("userEmail", isEqualTo: user.userEmail).getDocuments { snapshot, _ in
            if let snapshot = snapshot {
                for doc in snapshot.documents {
                    path.document(doc.documentID).delete()
                }
                path.getDocuments { snapshots, errors in
                    if let snapshots = snapshots {
                        if snapshots.isEmpty {
                            switch type {
                            case .textList:
                                if let index = self.textList.firstIndex(where: {$0.id == multiID}) {
                                    let path = db.collection(pathString).document(multiID.uuidString)
                                    self.deleteRow(path: path)
                                    self.textList.remove(at: index)
                                }
                            case .checkList:
                                if let index = self.checkList.firstIndex(where: {$0.id == multiID}) {
                                    let path = db.collection(pathString).document(multiID.uuidString)
                                    self.deleteRow(path: path)
                                    self.checkList.remove(at: index)
                                }
                            case .linkList:
                                if let index = self.linkList.firstIndex(where: {$0.id == multiID}) {
                                    let path = db.collection(pathString).document(multiID.uuidString)
                                    self.deleteRow(path: path)
                                    self.linkList.remove(at: index)
                                }
                            default: break
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteRow(path: DocumentReference) {
        let rowPath = path.collection(PathString.row.pathString())
        rowPath.getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for doc in snapshot.documents {
                    rowPath.document(doc.documentID).delete()
                }
                path.delete()
            }
        }
    }
    
    func reOrderingMultiList(sectionType: SectionType! = .list,
                             section: SectionList,
                             editCase: EditCase,
                             part: PartCase,
                             sectionOriOrder: Int! = nil,
                             sectionListToOrder: Int! = nil,
                             multiListOrder: Int! = nil,
//                             toMultiListOrder: Int! = nil,
                             isHidden: Bool! = false) {
        let db = Firestore.firestore()
        let pathString = sectionType == .list ? PathString.section.pathString() : PathString.sectionShared.pathString()
        let path = db.collection("users").document(self.user.userUID).collection(pathString)
        switch editCase {
        case .delete:
            switch part {
            case .multi:
                if multiListOrder != nil {
                if sectionType == .list {
                    let set = self.sectionList[section.order].multiList.filter({ $0.isHidden == isHidden })
                    
                    for i in 0..<set.count where set[i].order > multiListOrder {
                        if let firstIndex = self.sectionList[section.order].multiList.firstIndex(of: set[i]) {
                            self.sectionList[section.order].multiList[firstIndex].order -= 1
                            let multi = sectionList[section.order].multiList[firstIndex]
                            DispatchQueue(label: "firebase").async {
                                path.document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).updateData([
                                    "order": multi.order
                                ])
                            }
                        }
                    }
                } else {
                    for i in 0..<self.sectionShared.multiList.count where self.sectionShared.multiList[i].order > multiListOrder {
                        self.sectionShared.multiList[i].order -= 1
                        let multi = sectionShared.multiList[i]
                        DispatchQueue(label: "firebase").async {
                            path.document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).updateData([
                                "order": multi.order
                            ])
                        }
                    }
                }
            }
            case .section:
                for i in 0..<self.sectionList.count where self.sectionList[i].order > section.order {
                    self.sectionList[i].order -= 1
                    DispatchQueue(label: "firebase").async {
                        path.document(self.sectionList[i].sectionID.uuidString).updateData([
                            "order": self.sectionList[i].order
                        ])
                    }
                }
            }
        case .reOder:
            switch part {
            case .section:
                guard let ori = sectionOriOrder, let to = sectionListToOrder else { return }
                // 1. 프라퍼티 배열 순서 바꾸기
                self.sectionList.move(fromOffsets: IndexSet(integer: ori), toOffset: ori > to ? to : to+1)
                // 2. 순서값 바꾸기
                for i in min(ori, to)...max(ori, to) {
                    let section = self.sectionList[i]
                    guard let changedIndex = self.sectionList.firstIndex(of: section) else { return }
                    self.sectionList[i].order = changedIndex
                    DispatchQueue(label: "firebase").async {
                        path.document(self.sectionList[i].sectionID.uuidString).updateData([
                            "order": changedIndex
                        ])
                    }
                }
            case .multi:
                if sectionType == .list {
                    let set = self.sectionList[section.order].multiList.filter({ $0.isHidden == isHidden })
                    
                    
//                    for i in min(fromMultiListOrder, toMultiListOrder)...max(fromMultiListOrder, toMultiListOrder) {
//                        let multi = self.sectionList[sectionOriOrder].multiList[i]
//                        guard let changedIndex = self.sectionList[sectionOriOrder].multiList.firstIndex(of: multi) else { return }
//                        self.self.sectionList[section.order].multiList[i].order = changedIndex
//                        DispatchQueue(label: "firebase").async {
//                            path.document(self.sectionList[i].sectionID.uuidString).updateData([
//                                "order": changedIndex
//                            ])
//                        }
//                    }
//                    
//                    for i in 0..<set.count where set[i].order > fromMultiListOrder {
//                        if let firstIndex = self.sectionList[section.order].multiList.firstIndex(of: set[i]) {
//                            self.sectionList[section.order].multiList[firstIndex].order -= 1
//                            self.sectionLis
//                            let multi = sectionList[section.order].multiList[firstIndex]
//                            DispatchQueue(label: "firebase").async {
//                                path.document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).updateData([
//                                    "order": multi.order
//                                ])
//                            }
//                        }
//                    }
                } else {
                    for i in 0..<self.sectionShared.multiList.count where self.sectionShared.multiList[i].order > multiListOrder {
                        self.sectionShared.multiList[i].order -= 1
                        let multi = sectionShared.multiList[i]
                        DispatchQueue(label: "firebase").async {
                            path.document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).updateData([
                                "order": multi.order
                            ])
                        }
                    }
                }
                // 2. ori
//                if let sectionIndex = userData.sectionList.firstIndex(where: {$0.sectionID == section.sectionID}) {
//                    self.userData.sectionList[sectionIndex].order = to
//                    DispatchQueue(label: "firebase").async {
//                        path.document(section.sectionID.uuidString).updateData([
//                            "order": to
//                        ])
//                    }
//                }
            }
            let reOrderdSectionList = sectionList.sorted(by: {$0.order < $1.order})
            self.sectionList = reOrderdSectionList
        case .hidden:
            if multiListOrder != nil {
                let multiSet = self.sectionList[section.order].multiList.filter({ $0.isHidden == isHidden })
                for i in 0..<multiSet.count where multiSet[i].order > multiListOrder {
                    if let index = self.sectionList[section.order].multiList.firstIndex(of: multiSet[i]) {
                        self.sectionList[section.order].multiList[index].order -= 1
                        let multi = sectionList[section.order].multiList[index]
                        DispatchQueue(label: "firebase").async {
                            path.document(section.sectionID.uuidString).collection("itemList").document(multi.multiID.uuidString).updateData([
                                "order": multi.order
                            ])
                        }
                    }
                }
                self.sectionList[section.order].multiList = self.sectionList[section.order].multiList.sorted(by: { $0.order < $1.order })
            }
        }
    }
    
    func deleteFriend(uid: String, reorder: Bool! = true) {
        guard let index = friendList.firstIndex(where: {$0.id == uid }) else { return }
        let friend = friendList[index]
        // 친구 삭제
        let db = Firestore.firestore()
        db.collection("users").document(user.userUID).collection("friendList").document(friend.id).delete { error in
            guard error == nil else { return }
            // 친구 리오더
            if reorder {
                for frnd in self.friendList where frnd.order > friend.order {
                    frnd.order -= 1
                    db.collection("users").document(self.user.userUID).collection("friendList").document(frnd.id).updateData([
                        "order": frnd.order
                    ])
                }
            }
        }
    }
    
    func deleteNotYetFriend(friend: Friend) {
        // 친구 삭제
        let db = Firestore.firestore()
        let path = db.collection("users").document(user.userUID).collection("notYetFriendList")
            
        path.document(friend.id).delete { error in
            guard error == nil else { return }
        }
    }
    
    
    func deleteMyItem(itemNumber: Int, delteMode: ItemSaveMode! = .saveFirst) {
        guard let myItem = self.myItems[itemNumber] else { return }
        let db = Firestore.firestore()
        let path = db.collection("users").document(self.user.userUID).collection("myItems")
        if myItem.type == .text {
            path.document(myItem.id.uuidString).delete { error in
                if error == nil {
                    self.myItems[myItem.order] = nil
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
                                self.myItems[myItem.order] = nil
                            }
                        }
                    }
                }
            }
        }
    }
    
    func deleteStorageData(snapshot: DocumentSnapshot?, error: Error?, result: @escaping (Bool) -> Void) {
        if let snapshot = snapshot, error == nil {
            if let data = snapshot.data() {
                if let photoPath = data["content"] as? String {
                    let storage = Storage.storage()
                    storage.reference(withPath: photoPath).delete { error in
                        print(error?.localizedDescription)
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
    
    func deleteUserData(user: UserModel, completion: @escaping () -> Void) {
        // 1. 섹션리스트 & 멀티리스트 & 컨텐트에서 이름 빼기(or 지우기)
        for section in self.sectionList {
            deleteSectionList(userID: user.userUID, section: section)
        }
        if user.accountType != .anonymousUser {
            // 2. shared section 삭제
            if let sectionShared = self.sectionShared {
                self.deleteSectionList(userID: user.userUID, section: sectionShared, sectionType: .share)
            }
            // 3. 친구 리스트 삭제
            for friend in self.friendList {
                self.deleteFriend(uid: friend.id)
            }
            // 4. 알 수도 있는 친구 리스트 삭제
            for people in self.notYetFriendList {
                self.deleteNotYetFriend(friend: people)
            }
            // 5. sharedMulti 삭제
            self.deleteShareMultiList(userID: user.userUID, MultiListSet: self.sharedMultiList, pathString: PathString.shared.pathString())
            self.deleteShareMultiList(userID: user.userUID, MultiListSet: self.sharingMultiList, pathString: PathString.sharing.pathString())
            
        }
        completion()
    }
    
    func deleteShareMultiList(userID: String, MultiListSet: [ShareMultiList], pathString: String) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(userID)
        for item in MultiListSet {
            path.collection(pathString).document(item.id.uuidString).delete()
        }
    }
    
}
