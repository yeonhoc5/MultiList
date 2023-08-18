//
//  ListViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/16.
//

import Foundation
import FirebaseFirestore


class ListViewModel: ObservableObject {
    var user: UserModel
    @Published var sectionList: [SectionList] = []
    
    init(user: UserModel = sampleUser) {
        self.user = user
        self.sectionList = user.sectionList
        addUserObserver()
    }
    
    func addUserObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("userSetted"), object: nil, queue: .main, using: { notification in
            print("리스트 뷰: 노티피케이션 수신 완료")
            if let user = notification.object as? UserModel {
                self.user = user
                self.loadSectionListFromDB(userUID: user.userUID)
            }
        })

        NotificationCenter.default.addObserver(forName: Notification.Name("userIsNil"), object: nil, queue: .main) { _ in
            self.user = sampleUser
            self.sectionList = self.user.sectionList
        }
    }
    
    
    func addSectionToUser(section: SectionList) {
        sectionList.append(section)
        DispatchQueue.main.async {
            self.addDataToFireStore(newSection: section)
        }
    }
    
    func addDataToFireStore(newSection: SectionList) {
        let db = Firestore.firestore()
        db.collection("users").document(user.userUID).collection("sectionList").document(newSection.sectionID.uuidString).setData([
            "order": newSection.order,
            "color": newSection.color,
            "sectionName": newSection.sectionName
        ])
    }
    
    func loadSectionListFromDB(userUID: String) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(userUID).collection("sectionList")
        
        var loadedSectionList: [SectionList] = []
        
        path.getDocuments { snapshot, error in
            if let snapshot = snapshot {
                for section in snapshot.documents {
                    let data = section.data()
                      guard let order = data["order"] as? Int,
                          let color = data["color"] as? Int,
                          let name = data["sectionName"] as? String else {
                        return
                    }
                    let section = SectionList(order: order, sectionName: name, color: color)
                    loadedSectionList.append(section)
                }
                self.sectionList = loadedSectionList.sorted(by: {$0.order < $1.order})
            }
        }
        
        
    }
    
}

