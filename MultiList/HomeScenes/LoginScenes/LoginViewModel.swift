//
//  LoginViewModel.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import SwiftUI
import CryptoKit
import KakaoSDKUser



class LoginViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    
    // 0: not / 1: 익명 / 2: 구글 / 3: 네이버 / 4: 카카오 / 5: 애플
    var loginType: Int = 0
    
    var loggedInID: String = ""
    var loggedInName: String = ""
    
    // 애플 로그인은 처음 가입할 때만 이름을 주기 때문에 따로 저장
    var appleIDName: String = ""
    // 애플 로그인에 사용
    var currentNonce: String!
    
    var errorMessage: String = ""
    
    init() {
        loadPreviousUser()
    }
    
    func loadPreviousUser() {
        if let user = Auth.auth().currentUser {
            let userDefaults = UserDefaults.standard
            let type = userDefaults.integer(forKey: "loginType")
            let uid = user.uid
            let name = userDefaults.string(forKey: "userName") ?? "anyway"
            
            completeLogin(type: type, id: uid, name: name, autoLogin: true)
        }
    }
    
    // 0. 익명 로그인
    func loginAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            if let id = result?.user.uid, error == nil {
                self.completeLogin(type: 0, id: id, name: "익명의 손")
            } else {
                self.errorMessage = error?.localizedDescription ?? "익명 로그인 중 Error가 발생했습니다."
            }
        }
    }
    
    // 1. 구글 로그인
    func loginWithGoogle() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        guard let presentingViewcontroller = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewcontroller) { result, error in
            guard error == nil else { return }
            if error == nil {
                guard let user = result?.user,
                      let token = user.idToken?.tokenString else { return }
                let credential = GoogleAuthProvider.credential(withIDToken: token, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if error == nil {
                        self.completeLogin(type: 1, id: authResult?.user.uid ?? "google Login", name: user.profile?.name ?? "손")
                    } else {
                        self.errorMessage = error?.localizedDescription ?? "로그인 중 Error가 발생했습니다."
                    }
                }
            } else {
                self.errorMessage = error?.localizedDescription ?? "구글 로그인 중 Error가 발생했습니다."
            }
            
        }
    }
    
    // 2. 네이버 로그인
    func loginWithNaver() {
        let email = "aa"
        let userName = "bb"
        let password = "pa"
        loginWithEmail(email: email, userName: userName, password: password) {
            
        }
    }
    
    // 3. 카카오 로그인
    func loginWithKakao() {
        
        var email: String!
        var userName: String!
        var password: String!
        
        
        
        if (UserApi.isKakaoTalkLoginAvailable()) {
            UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
                
                guard let token = oauthToken?.idToken else { return }
//                let provider = OAuthProvider(providerID: "oidc.kakao")
                
                let credential = OAuthProvider.credential(withProviderID: "oidc.kakao", idToken: token, accessToken: oauthToken?.accessToken)
                
                Auth.auth().signIn(with: credential) { result, error in
                    if error != nil {
                        self.errorMessage = "카카오 로그인 중 Error가 발생했습니다."
                    } else {
                        UserApi.shared.me { user, error in
                            if let account = user?.kakaoAccount,
                               error == nil {
                                email = account.email
                                userName = account.profile?.nickname
                                
                                Auth.auth().signIn(withCustomToken: oauthToken?.accessToken ?? "") { result, error in
                                    self.loginType = 3
                                    self.loggedInID = email
                                    self.loggedInName = userName
                                    withAnimation {
                                        self.isLoggedIn = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // 5. ID / 패스워드 로그인 (네이버 / 카카오 로그인 처리)
    func loginWithEmail(email: String, userName: String, password: String, completion: (() -> Void)?) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("error: \(error.localizedDescription)")
            }
            if result != nil {
                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
                changeRequest?.displayName = userName
                print("사용자 이메일: \(String(describing: result?.user.email))")
            }
            completion?()
        }
    }
    
    func handleRequest(request: ASAuthorizationAppleIDRequest, result: @escaping (ASAuthorizationAppleIDRequest) -> Void) -> Void {
        self.randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = self.sha256(currentNonce)
        result(request)
    }
    
    func loginWithApple(result: Result<ASAuthorization, Error>, completion: @escaping () -> Void) {
        switch result {
        case .success(let authResults):
            switch authResults.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                
                var fullName = "appleID"
                if let familyName = appleIDCredential.fullName?.familyName,
                   let givenName = appleIDCredential.fullName?.givenName {
                    fullName = familyName + givenName
                } else {
                    let userDefaults = UserDefaults.standard
                    if let name = userDefaults.string(forKey: "appleIDName") {
                        fullName = name
                    }
                }
                
                guard let nonce = self.currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    return
                }

                //Creating a request for firebase
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)

                //Sending Request to Firebase
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if (error != nil) {
                        // Error. If error.code == .MissingOrInvalidNonce, make sure
                        // you're sending the SHA256-hashed nonce as a hex string with
                        // your request to Apple.
                        print(error?.localizedDescription as Any)
                        return
                    } else {
                        self.completeLogin(type: 5, id: authResult?.user.uid ?? "apple Login", name: fullName)
                    }
                }
                //Prints the current userID for firebase
                print("\(String(describing: Auth.auth().currentUser?.uid))")
                default:
                    break
                }
            default:
                break
        }
        completion()
    }
    
    
    // 10. 로그아웃 (통합)
    func logout(completion: @escaping () -> Void) {
        do {
            let user = Auth.auth().currentUser
            if user?.isAnonymous == true {
                user?.delete(completion: { error in
                    if error != nil {
                        self.errorMessage = String(error?.localizedDescription ?? "")
                        print(self.errorMessage)
                    } else {
                        self.loginType = 0
                        let userDefaults = UserDefaults.standard
                        userDefaults.removeObject(forKey: "loginType")
                        print("Anonymous User deleted")
                    }
                })
            }
            
            try Auth.auth().signOut()
            completion()
            if Auth.auth().currentUser == nil {
                withAnimation(.easeInOut) {
                    self.isLoggedIn = false
                }
                self.loggedInID = ""
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    
    func completeLogin(type: Int, id: String, name: String, autoLogin: Bool = false) {
        self.loginType = type
        self.loggedInID = id
        self.loggedInName = name
        withAnimation {
            isLoggedIn = true
        }
        if !autoLogin {
            DispatchQueue.main.async {
                self.saveIDinDevice(type: type, uid: id, name: name)
            }
        }
    }
    
    func saveIDinDevice(type: Int, uid: String, name: String) {
        let userDefault = UserDefaults.standard
        userDefault.set(type, forKey: "loginType")
        userDefault.set(uid, forKey: "userID")
        userDefault.set(name, forKey: "userName")
        if type == 5 {
            userDefault.set(name, forKey: "appleIDName")
        }
        if userDefault.string(forKey: "userID") == loggedInID,
           userDefault.integer(forKey: "loginType") == self.loginType {
            print("save Success")
        } else {
            print("save Fail")
        }
    }
}

extension LoginViewModel {
    
    func randomNonceString(length: Int = 32) {
      precondition(length > 0)
      var randomBytes = [UInt8](repeating: 0, count: length)
      let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
      if errorCode != errSecSuccess {
        fatalError(
          "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
        )
      }

      let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")

      let nonce = randomBytes.map { byte in
        // Pick a random character from the set, wrapping around if needed.
        charset[Int(byte) % charset.count]
      }
        self.currentNonce = String(nonce)
    }

    func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }
}


