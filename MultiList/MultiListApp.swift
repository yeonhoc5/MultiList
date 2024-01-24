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
import NaverThirdPartyLogin


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
      // 1. firebase 초기화
      FirebaseApp.configure()
      // 2. 카카오 인증 초기화
      KakaoSDK.initSDK(appKey: Bundle.main.kakao)
      // 3. 네이버 인증 활성화 (1.네이버 앱에서 인증 -> 2.사파리에서 인증)
      NaverThirdPartyLoginConnection.getSharedInstance().isNaverAppOauthEnable = true
      NaverThirdPartyLoginConnection.getSharedInstance().isInAppOauthEnable = true
      // 네이버 추가 설정
      // 3-1. portrait 화면으로만 실행
      NaverThirdPartyLoginConnection.getSharedInstance().isOnlyPortraitSupportedInIphone()
      // 3-2. 그 외(NaverThirdPartyConstantsForApp.h의 마지막 4개 요소 가져오기)
      NaverThirdPartyLoginConnection.getSharedInstance().serviceUrlScheme = kServiceAppUrlScheme
      NaverThirdPartyLoginConnection.getSharedInstance().consumerKey = kConsumerKey
      NaverThirdPartyLoginConnection.getSharedInstance().consumerSecret = kConsumerSecret
      NaverThirdPartyLoginConnection.getSharedInstance().appName = kServiceAppName
      
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
        } else if scheme.contains("naver") {
            return NaverThirdPartyLoginConnection.getSharedInstance().application(app, open: url, options: options)            
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
            HomeView()
                .environmentObject(UserData())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onOpenURL(perform: { url in
                    if (AuthApi.isKakaoTalkLoginUrl(url)) {
                        _ = AuthController.handleOpenUrl(url: url)
                    }
                })
        }
    }
}
