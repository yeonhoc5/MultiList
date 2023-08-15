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
import NaverThirdPartyLogin
import FirebaseFirestore

class LoginViewModel: NSObject, ObservableObject {
    
    @Published var isShowingProgressView: Bool = false
    @Published var user: UserModel! {
        didSet {
            let settedUser = Notification(name: Notification.Name("settedUser"), object: self.user)
            print("노티피케이션 전송 요청")
            NotificationCenter.default.post(settedUser)
        }
    }
    @Published var isLoggedIn: Bool = false
    @Published var messageData: String!
    
    
    // 0: not / 1: 익명 / 2: 구글 / 3: 네이버 / 4: 카카오 / 5: 애플
    var loginType: Int = 0
    var loggedInID: String = ""
    var loggedInName: String = ""
    
    // 애플 로그인은 처음 가입할 때만 이름을 주기 때문에 따로 저장
    var appleIDName: String = ""
    // 애플 로그인에 사용
    var currentNonce: String!
    
    var errorMessage: String = ""
    
    override init() {
        super.init()
        loadPreviousUser()
        setUserObserver()
    }
    
    func setUserObserver() {
        NotificationCenter.default.addObserver(forName: Notification.Name("userIsNil"), object: nil, queue: .main) { _ in
            self.user = nil
            self.isLoggedIn = false
        }
    }
    
    func loadPreviousUser() {
        if let user = Auth.auth().currentUser {
            let userDefaults = UserDefaults.standard
            guard let userData = userDefaults.data(forKey: "multiUser"),
                  let multiUser = try? PropertyListDecoder().decode(UserModel.self, from: userData),
                  user.uid == multiUser.userUID
            else { return }
            
            print("load previous User Done")
            DispatchQueue.main.async {
                self.user = multiUser
                self.isLoggedIn = true
            }
        }
    }
    
    // 0. 익명 로그인
    func loginAnonymously() {
        DispatchQueue.main.async {
            self.showingProgressView()
        }
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            if let uid = result?.user.uid, error == nil {
                let uid = uid
                let email = "anonymous"
                let name = "익명의 손"
                let date = result?.user.metadata.creationDate ?? Date()
                self.completeLogin(type: 0, uid: uid, email: email, name: name, date: date)
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
            guard error == nil else {
                self.errorMessage = error?.localizedDescription ?? "구글 로그인 중 Error가 발생했습니다."
                return
            }

            guard let user = result?.user,
                  let token = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: token, accessToken: user.accessToken.tokenString)
            DispatchQueue.main.async {
                self.showingProgressView()
            }
            Auth.auth().signIn(with: credential) { authResult, error in
                if let uid = authResult?.user.uid, error == nil {
                    let uid = uid
                    let email = user.profile?.email ?? "알수없는계정"
                    let name = user.profile?.name ?? "구글 손"
                    let date = authResult?.user.metadata.creationDate ?? Date()
                    self.completeLogin(type: 1, uid: uid, email: email, name: name, date: date)
                } else {
                    self.errorMessage = error?.localizedDescription ?? "로그인 중 Error가 발생했습니다."
                }
            }
        }
    }
    
    func showingProgressView() {
        NotificationCenter.default.post(name: NSNotification.Name("progressView"), object: nil)
    }
    
    // 2. 네이버 로그인
    func loginWithNaver() {
//        let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance()
//        naverInstance?.delegate = self
//        naverInstance?.requestThirdPartyLogin()
        NaverThirdPartyLoginConnection.getSharedInstance().requestThirdPartyLogin()
    }
    
    // 3. 카카오 로그인
    func loginWithKakao() {
        guard UserApi.isKakaoTalkLoginAvailable() else { return }
        
        UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
            guard let token = oauthToken?.idToken else { return }
            let credential = OAuthProvider.credential(withProviderID: "oidc.kakao", idToken: token, accessToken: oauthToken?.accessToken)
            DispatchQueue.main.async {
                self.showingProgressView()
            }
            Auth.auth().signIn(with: credential) { result, error in
                guard let user = result?.user, error == nil else {
                    self.errorMessage = "가입 중 Error가 발생했습니다."
                    return
                }
                UserApi.shared.me { kakaoUser, error in
                    guard let account = kakaoUser?.kakaoAccount, error == nil else {
                        self.errorMessage = "카카오 계정에서 정보를 얻지 못했습니다.."
                        return
                    }
                    let uid = user.uid
                    let email = account.email ?? "알수없는계정"
                    let name = account.profile?.nickname ?? "카카오 손"
                    let date = result?.user.metadata.creationDate ?? Date()
                    self.completeLogin(type: 3, uid: uid, email: email, name: name, date: date)
                }
            }
        }
    }
    
    // 4. 애플 로그인
    func loginWithApple(result: Result<ASAuthorization, Error>) {
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
                DispatchQueue.main.async {
                    self.showingProgressView()
                }
                //Sending Request to Firebase
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if (error != nil) {
                        // Error. If error.code == .MissingOrInvalidNonce, make sure
                        // you're sending the SHA256-hashed nonce as a hex string with
                        // your request to Apple.
                        print(error?.localizedDescription as Any)
                        return
                    } else {
                        if let uid = authResult?.user.uid, error == nil {
                            DispatchQueue.main.async {
                                self.showingProgressView()
                            }
                            let uid = uid
                            let email = authResult?.user.email ?? "알 수 없는 계정"
                            let name = fullName
                            let date = authResult?.user.metadata.creationDate ?? Date()
                            self.completeLogin(type: 4, uid: uid, email: email, name: name, date: date)
                        }
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
    }
    
    
//    // 5. ID / 패스워드 로그인 (네이버 로그인 처리)
//    func loginWithEmail(email: String, userName: String, password: String, completion: (() -> Void)?) {
//        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//            if let error = error {
//                print("error: \(error.localizedDescription)")
//            }
//            if result != nil {
//                let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
//                changeRequest?.displayName = userName
//                print("사용자 이메일: \(String(describing: result?.user.email))")
//            }
//            completion?()
//        }
//    }

    // firebase 로그인 완료 시 공통 처리 내용
    func completeLogin(type: Int, uid: String, email: String, name: String, date: Date) {
        let multiUser = UserModel(accountType: type, userUID: uid, userEmail: email, dateRegistered: date, userNickName: name)
        self.user = multiUser
        DispatchQueue.main.async {
            withAnimation {
                self.isLoggedIn = true
            }
        }
        
        makeUserDataAtFireStore(user: multiUser)
        
        DispatchQueue.main.async {
            self.saveIDinDevice(user: multiUser)
        }
    }
    
    func makeUserDataAtFireStore(user: UserModel) {
        let db = Firestore.firestore()
        // 1. 유저 정보
        if let email = user.userEmail {
            db.collection("users").document(user.userUID).setData(["accountType": user.accountType,
                                                                   "email": email,
                                                                   "name": user.userNickName,
                                                                   "creationDate": user.dateRegistered])
        } else {
            self.messageData = "데이터 생성 중 오류가 발생했습니다."
        }
        
    }

    func saveIDinDevice(user: UserModel) {
        let userDefaults = UserDefaults.standard
        userDefaults.set(try? PropertyListEncoder().encode(user), forKey: "multiUser")
        print("User Save Done")
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
                DispatchQueue.main.async {
                    withAnimation(.easeInOut) {
                        self.isLoggedIn = false
                        self.user = nil
                    }
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
        
    }
    
    
    func returningDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "KR")
        formatter.dateFormat = "YYYY년 MM월 dd일"
        
        let str = formatter.string(from: date)
        return str
    }
    
}


// 애플 로그인 처리
extension LoginViewModel {
    
    func handleRequest(request: ASAuthorizationAppleIDRequest, result: @escaping (ASAuthorizationAppleIDRequest) -> Void) -> Void {
        self.randomNonceString()
        request.requestedScopes = [.fullName, .email]
        request.nonce = self.sha256(currentNonce)
        result(request)
    }
    
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


// 네이버 로그인 처리
extension LoginViewModel: NaverThirdPartyLoginConnectionDelegate {
    
    func oauth20ConnectionDidFinishRequestACTokenWithRefreshToken() {
        print("토큰 요청 완료")
    }
    
    func oauth20ConnectionDidFinishDeleteToken() {
        print("토큰 삭제 완료")
    }

    func oauth20Connection(_ oauthConnection: NaverThirdPartyLoginConnection!, didFailWithError error: Error!) {
        errorMessage = error.localizedDescription
    }
    
    func oauth20ConnectionDidFinishRequestACTokenWithAuthCode() {
        print("네이버 로그인 시도 0-1")
        guard let loginInstance = NaverThirdPartyLoginConnection.getSharedInstance() else { return }
        print("네이버 로그인 시도 0-2")
        getNaverUserInfo(loginInstance.tokenType, loginInstance.accessToken)
        
    }
    
    func getNaverUserInfo( _ tokenType : String?, _ accessToken : String?) {
        guard let tokenType = tokenType else { return }
        guard let accessToken = accessToken else { return }
        print("네이버 로그인 시도 1")
        guard let url = URL(string: "https://openapi.naver.com/v1/nid/me") else { return }
        print("네이버 로그인 시도 2")
        let authorization = "\(tokenType) \(accessToken)"
        print("네이버 로그인 시도 4")
        let urlSesstion = URLSession(configuration: .default)
        var request = try? URLRequest(url: url, method: .get)
        request?.headers = ["Authorization": authorization]
        
        
        if let request = request {
            print("네이버 로그인 시도 5")
            urlSesstion.dataTask(with: request) { data, response, error in
                print("네이버 로그인 시도 6")
                guard let response = response as? HTTPURLResponse else { return }
                print("네이버 로그인 시도 7")
                
                let decoder = JSONDecoder()
                
                if let data = data, error == nil, 200..<300 ~= response.statusCode {
                    
                    let jsonData = try? JSONSerialization.data(withJSONObject: data)
                    
//                    guard let result = serialization
//                    guard let result = decoder([String: Any], from: data) else { return }
//                    guard let result = data.value as? [String: Any] else { return }
//                    guard let object = result["response"] as? [String: Any] else { return }
//                    guard let name = object["name"] as? String else { return }
//                    guard let email = object["email"] as? String else { return }
//                    guard let id = object["id"] as? String else {return}
                    
                }
            }
        }

            
//        let req = AF.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: ["Authorization": authorization])
//
//        req.responseJSON { [weak self] response in
//            let decoder = JSONDecoder()
//
//           print("response: ",response)
//        }
    }
    
    func startNaverLogin() {
        guard let loginInstance = NaverThirdPartyLoginConnection.getSharedInstance() else { return }
            
        //이미 로그인되어있는 경우
        if loginInstance.isValidAccessTokenExpireTimeNow() {
            getNaverUserInfo(loginInstance.tokenType, loginInstance.accessToken)
            return
        }
            
        loginInstance.delegate = self
        loginInstance.requestThirdPartyLogin()
    }
    
    
    
    
}
