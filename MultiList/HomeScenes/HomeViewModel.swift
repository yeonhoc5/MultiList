//
//  HomeViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import Foundation
import FirebaseRemoteConfig
import FirebaseFirestore

class HomeViewModel: ObservableObject {
    
//    @Published var user: UserModel! {
//        didSet {
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                self.isShowingProgressView = false
//            }
//        }
//    }
    @Published var isShowingProgressView: Bool = false
    
    // 홈 알럿 프라퍼티
    var title: String = "non"
    var message: String = "non"
    @Published var isShowingAlert: Bool = false
    
    var isVertical: Bool {
        return screenSize.width < screenSize.height
    }
    
    
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
}
