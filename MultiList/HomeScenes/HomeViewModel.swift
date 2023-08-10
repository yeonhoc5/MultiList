//
//  HomeViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import Foundation
import FirebaseRemoteConfig

class HomeViewModel: ObservableObject {
    @Published var isShowingAlert: Bool = false
    @Published var isLoggedIn: Bool = false
    var title: String = "non"
    var message: String = "non"
    
    init() {
        Task {
            try await checkRemoteConfig()
        }
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
