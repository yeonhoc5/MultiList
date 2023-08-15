//
//  HomeViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import Foundation
import FirebaseRemoteConfig

class HomeViewModel: ObservableObject {
    @Published var isShowingProgressView: Bool = false
    @Published var isLoggedIn: Bool = false
    
    @Published var isShowingAlert: Bool = false
    
    @Published var user: UserModel!
    
    var title: String = "non"
    var message: String = "non"
    
    init() {
        Task {
            try await checkRemoteConfig()
        }
        addNotificationObserverToUser()
    }
    
    func addNotificationObserverToUser() {
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("settedUser"), object: nil, queue: .main, using: { notification in
            print("노티피케이션 수신 완료")
            DispatchQueue.main.async {
                self.user = notification.object as? UserModel
            }
        })
        
        _ = NotificationCenter.default.addObserver(forName: Notification.Name("progressView"), object: nil, queue: .main, using: { _ in
            DispatchQueue.main.async {
                self.isShowingProgressView = true
            }
        })
        
    }
    
    func checkRemoteConfig() async throws {
        let remoteConfig = RemoteConfig.remoteConfig()
        
        let setting = RemoteConfigSettings()
        setting.minimumFetchInterval = 0
        remoteConfig.configSettings = setting
        remoteConfig.defaultValue(forKey: "RemoteConfigDefaults")
        
        do {
            let fetch = try await remoteConfig.fetchAndActivate()
            if fetch == .successFetchedFromRemote{
                DispatchQueue.main.async {
                    self.title = remoteConfig["title"].stringValue ?? ""
                    self.message = remoteConfig["message"].stringValue ?? ""
                    self.isShowingAlert = remoteConfig["isShowingAlert"].boolValue
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func loadUserDataFromFirebase(id: String) {
        
    }
}
