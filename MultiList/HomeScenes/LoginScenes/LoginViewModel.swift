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



class LoginViewModel: ObservableObject {
    
    @Published var isLoggedIn: Bool = false
    var loggedInID: String = ""
    var loggedInName: String = ""
    var loginType: Int = 0
    var errorMessage: String = ""
    
    var currentNonce: String?
    
    // 0: not / 1: 익명 / 2: 구글 / 3: 네이버 / 4: 카카오 / 5: 애플
    
    init() {
        loginCheck()
    }
    
    func loginCheck() {
        let userDefault = UserDefaults.standard
        loginType = userDefault.integer(forKey: "loginType")
        
        switch loginType {
        case 1: loginAnonymously()
        case 2: loginWithGoogle()
        case 3: loginWithNaver()
        case 4: loginWithKakao()
        case 5: loginWithApple()
        default: break
        }
    }
    
    
    func loginAnonymously() {
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            if let id = result?.user.uid, error == nil {
                self.loginType = 1
                self.loggedInName = "손"
                self.loggedInID = id
                self.saveIDinDevice(id: id, type: self.loginType)
            } else {
                self.errorMessage = error?.localizedDescription ?? "Error"
            }
            
        }
    }
    
    func loginWithGoogle() {
        
//        if token != nil {
        if self.loginType == 2 {
//            Auth.auth().signIn(withCustomToken: token) { result, error in
//                if let error = error {
//                    print("Firebase sign in error: \(error)")
//                    return
//                } else {
//                    self.loggedInID = result?.user.uid ?? ""
//                    self.loggedInName = result?.user.displayName ?? "손"
//                    self.loginType = 2
//                    self.saveIDinDevice(id: self.loggedInID, type: self.loginType)
//                    print("User is signed with Firebase & Google")
//                }
//            }
        } else {
            guard let clientID = FirebaseApp.app()?.options.clientID else { return }
            guard let presentingViewcontroller = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
                return
            }
            
            let config = GIDConfiguration(clientID: clientID)
            
            GIDSignIn.sharedInstance.configuration = config
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewcontroller) { result, error in
                guard error == nil else { return }
                
                guard let user = result?.user,
                      let token = user.idToken?.tokenString else { return }
                let credential = GoogleAuthProvider.credential(withIDToken: token, accessToken: user.accessToken.tokenString)
                
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let error = error {
                        print("Firebase sign in error: \(error)")
                        return
                    } else {
                        self.loggedInID = authResult?.user.uid ?? ""
                        self.loggedInName = user.profile?.name ?? ""
                        self.loginType = 2
                        self.saveIDinDevice(id: self.loggedInID, type: self.loginType)
                        print("User is signed with Firebase & Google")
                    }
                }
            }
        }
    }
    
    func loginWithNaver() {
        
    }
    
    func loginWithKakao() {
        
    }
    
    func loginWithApple() {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
          
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
  //      authorizationController.delegate = self
        authorizationController.performRequests()
    }
    
    
    
    func logout(completion: @escaping () -> Void) {
        do {
            let user = Auth.auth().currentUser
            if self.loginType == 1 {
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
    
    func saveIDinDevice(id: String, type: Int) {
        withAnimation {
            isLoggedIn = true
        }
        let userDefault = UserDefaults.standard
        userDefault.set(id, forKey: "userID")
        userDefault.set(type, forKey: "loginType")
        if userDefault.string(forKey: "userID") == loggedInID,
           userDefault.integer(forKey: "loginType") == self.loginType {
            print("save Success")
        } else {
            print("save Fail")
        }
    }
}

extension LoginViewModel {
    
    func randomNonceString(length: Int = 32) -> String {
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

      return String(nonce)
    }

    func sha256(_ input: String) -> String {
      let inputData = Data(input.utf8)
      let hashedData = SHA256.hash(data: inputData)
      let hashString = hashedData.compactMap {
        String(format: "%02x", $0)
      }.joined()

      return hashString
    }

//    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
//        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
//          guard let nonce = currentNonce else {
//            fatalError("Invalid state: A login callback was received, but no login request was sent.")
//          }
//          guard let appleIDToken = appleIDCredential.identityToken else {
//            print("Unable to fetch identity token")
//            return
//          }
//          guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
//            print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
//            return
//          }
//          // Initialize a Firebase credential, including the user's full name.
//          let credential = OAuthProvider.appleCredential(withIDToken: idTokenString,
//                                                            rawNonce: nonce,
//                                                            fullName: appleIDCredential.fullName)
//          // Sign in with Firebase.
//          Auth.auth().signIn(with: credential) { (authResult, error) in
//            if error != nil {
//              // Error. If error.code == .MissingOrInvalidNonce, make sure
//              // you're sending the SHA256-hashed nonce as a hex string with
//              // your request to Apple.
//              print(error?.localizedDescription)
//              return
//            } else {
//                self.loginType = 5
//                self.loggedInID = authResult?.user.uid ?? "얼라라"
//                self.loggedInName = authResult?.user.displayName ?? "얼라"
//                self.saveIDinDevice(id: self.loggedInID, type: self.loginType)
//                print("User is signed with Firebase & Google")
//            // User is signed in to Firebase with Apple.
//            // ...
//          }
//        }
//      }
//
//      func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
//        // Handle error.
//        print("Sign in with Apple errored: \(error)")
//      }
//
//    }
    
    
}


