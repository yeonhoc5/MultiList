//
//  MultiListApp.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import FirebaseCore
import GoogleSignIn
import KakaoSDKCommon
import KakaoSDKAuth


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      // firebase 초기화
      FirebaseApp.configure()
      // 카카오 인증 초기화
      KakaoSDK.initSDK(appKey: "291aa22306bb5331561ca6af5b6c34b1")
    return true
  }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        guard let scheme = url.scheme else { return false }
        
        if scheme.contains("google") {
            return GIDSignIn.sharedInstance.handle(url)
        } else if scheme.contains("kakao") {
            if AuthApi.isKakaoTalkLoginUrl(url) {
                return AuthController.handleOpenUrl(url: url)
            } else { return false}
        } else {
            return false
        }
    }
    
}


@main
struct MultiListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
//            ContentView()
            HomeView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL(perform: { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                })
        }
    }
}
