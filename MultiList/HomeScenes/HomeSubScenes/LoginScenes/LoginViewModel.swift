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


enum LoginResult {
    case loginSuccess
    case loginFail
    case linkSuccess
    case linkFail
}

class LoginViewModel: NSObject, ObservableObject {
    let userData: UserData
    @Published var isPreviousUser: Bool = false
    
    
    @Published var message: String!
    
    // 애플 로그인은 처음 가입할 때만 이름을 주기 때문에 따로 저장
    var appleIDName: String = ""
    // 애플 로그인에 사용
    var currentNonce: String!
    @Published var isShowingProgressView: Bool = false
    
    init(userData: UserData) {
        self.userData = userData
        super.init()
        loadPreviousUser()
    }
    
    func loadPreviousUser() {
        if let user = Auth.auth().currentUser, self.userData.user == nil {
            self.isPreviousUser = true
            loadUserDataFromFirebase(id: user.uid) { user in
                //                DispatchQueue.main.async {
                withAnimation {
                    // 로드 유저 정보
                    self.userData.user = user
                    // 로드 Section-멀티리스트 정보 / 친구 정보 / 공유받은 리스트
                    self.userData.loadDataWithUser(user: user)
                }
                //                }
                print("load previous User Done")
            }
        }
    }
    
    // MARK: - [로그인]
    // MARK: 0. 익명 로그인
    func loginAnonymously(completion: @escaping (LoginResult) -> Void) {
        Auth.auth().signInAnonymously { [weak self] result, error in
            guard let self = self else { return }
            if let uid = result?.user.uid, error == nil {
                let uid = uid
                let email = UUID().uuidString
                let name = "익명의 손님"
                let date = result?.user.metadata.creationDate ?? Date()
                self.completeLogin(type: .anonymousUser,
                                   uid: uid,
                                   email: email,
                                   name: name,
                                   date: date)
                completion(.loginSuccess)
            } else {
                self.message = error?.localizedDescription ?? "익명 로그인 중 Error가 발생했습니다."
                completion(.loginFail)
            }
        }
    }
    
    // MARK: 1. Google 로그인
    func loginWithGoogle(completion: @escaping (LoginResult) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        guard let presentingViewcontroller = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.configuration = config
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewcontroller) { result, error in
            guard error == nil else {
                self.message = error?.localizedDescription ?? "구글 로그인 중 Error가 발생했습니다."
                return
            }
            
            guard let user = result?.user,
                  let token = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: token, accessToken: user.accessToken.tokenString)
            
            if self.userData.user == nil {
                Auth.auth().signIn(with: credential) { authResult, error in
                    if let uid = authResult?.user.uid, error == nil {
                        let uid = uid
                        let email = user.profile?.email ?? "알수없는계정"
                        let name = user.profile?.name ?? "구글 손님"
                        let date = authResult?.user.metadata.creationDate ?? Date()
                        self.completeLogin(type: .google,
                                           uid: uid,
                                           email: email,
                                           name: name,
                                           date: date)
                        completion(.loginSuccess)
                    } else {
                        self.message = error?.localizedDescription ?? "로그인 중 Error가 발생했습니다."
                        completion(.loginFail)
                    }
                }
            } else {
                Auth.auth().currentUser?.link(with: credential, completion: { authResult, error in
                    if error == nil {
                        if let uid = authResult?.user.uid, error == nil {
                            let uid = uid
                            let email = user.profile?.email ?? "알수없는계정"
                            let name = user.profile?.name ?? "구글 손님"
                            let date = authResult?.user.metadata.creationDate ?? Date()
                            let linkedUser = UserModel(accountType: .google,
                                                       userUID: uid,
                                                       userEmail: email,
                                                       dateRegistered: date,
                                                       userNickName: name)
                            self.linkAnonymousUserToSnsAccount(linkedUser: linkedUser)
                            completion(.linkSuccess)
                        } else {
                            self.message = error?.localizedDescription ?? "영구 계정 연결 중 Error가 발생했습니다."
                        }
                    } else {
                        completion(.linkFail)
                    }
                })
            }
            
        }
    }
    
    // MARK: 2. naver 로그인 - 미완성
    func loginWithNaver() {
        //        let naverInstance = NaverThirdPartyLoginConnection.getSharedInstance()
        //        naverInstance?.delegate = self
        //        naverInstance?.requestThirdPartyLogin()
        NaverThirdPartyLoginConnection.getSharedInstance().requestThirdPartyLogin()
    }
    
    // MARK: 3. Kakao 로그인
    func loginWithKakao(completion: @escaping (LoginResult) -> Void) {
        guard UserApi.isKakaoTalkLoginAvailable() else { return }
        
        UserApi.shared.loginWithKakaoTalk {(oauthToken, error) in
            guard let token = oauthToken?.idToken else { return }
            let credential = OAuthProvider.credential(withProviderID: "oidc.kakao", idToken: token, accessToken: oauthToken?.accessToken)
            
            UserApi.shared.me { kakaoUser, error in
                if self.userData.user == nil {
                    Auth.auth().signIn(with: credential) { result, error in
                        guard let user = result?.user, error == nil else {
                            self.message = "가입 중 Error가 발생했습니다."
                            completion(.loginFail)
                            return
                        }
                        guard let account = kakaoUser?.kakaoAccount, error == nil else {
                            self.message = "카카오 계정에서 정보를 얻지 못했습니다.."
                            completion(.loginFail)
                            return
                        }
                        let uid = user.uid
                        let email = account.email ?? "알수없는계정"
                        let name = account.profile?.nickname ?? "카카오 손님"
                        let date = result?.user.metadata.creationDate ?? Date()
                        self.completeLogin(type: .kakao,
                                           uid: uid,
                                           email: email,
                                           name: name,
                                           date: date)
                        completion(.loginSuccess)
                    }
                } else {
                    Auth.auth().currentUser?.link(with: credential, completion: { result, error in
                        if error == nil {
                            guard let user = result?.user, error == nil else {
                                self.message = "가입 중 Error가 발생했습니다."
                                return
                            }
                            guard let account = kakaoUser?.kakaoAccount, error == nil else {
                                self.message = "카카오 계정에서 정보를 얻지 못했습니다.."
                                return
                            }
                            let uid = user.uid
                            let email = account.email ?? "알수없는계정"
                            let name = account.profile?.nickname ?? "카카오 손님"
                            let date = result?.user.metadata.creationDate ?? Date()
                            self.completeLogin(type: .kakao,
                                               uid: uid,
                                               email: email,
                                               name: name,
                                               date: date)
                            completion(.linkSuccess)
                        } else {
                            completion(.linkFail)
                        }
                    })
                }
            }
        }
    }
    
    // MARK: 4. Apple 로그인
    func loginWithApple(result: Result<ASAuthorization, Error>, completion: @escaping (LoginResult) -> Void) {
        switch result {
        case .success(let authResults):
            switch authResults.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                guard let nonce = self.currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                    completion(.loginFail)
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                    completion(.loginFail)
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    completion(.loginFail)
                    return
                }
                
//                authResults.credential.
                
                //Creating a request for firebase
                let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: idTokenString, rawNonce: nonce)
//
                //Sending Request to Firebase
                
                
                print(appleIDCredential.email ?? "email 확인 불가")
                
                if userData.user == nil {
                    Auth.auth().signIn(with: credential) { (authResult, error) in
                        if (error != nil) {
                            // Error. If error.code == .MissingOrInvalidNonce, make sure
                            // you're sending the SHA256-hashed nonce as a hex string with
                            // your request to Apple.
                            print(error?.localizedDescription as Any)
                            completion(.loginFail)
                            return
                        } else {
                            if let uid = authResult?.user.uid, error == nil {
                                let uid = uid
                                let email = authResult?.user.email ?? "알 수 없는 계정"
                                
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
                                
                                let name = fullName
                                let date = authResult?.user.metadata.creationDate ?? Date()
                                self.completeLogin(type: .appleUser,
                                                   uid: uid,
                                                   email: email,
                                                   name: name,
                                                   date: date)
                                completion(.loginSuccess)
                            }
                        }
                    }
                } else {
                    // 익명 계정 -> apple id로 연결
                    Auth.auth().currentUser?.link(with: credential, completion: { authResult, error in
                        if error == nil {
                            if let uid = authResult?.user.uid, error == nil {
                                let uid = uid
                                let email = authResult?.user.email ?? "알 수 없는 계정"

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

                                let name = fullName
                                let date = authResult?.user.metadata.creationDate ?? Date()

                                let linkedUser = UserModel(accountType: .appleUser,
                                                           userUID: uid,
                                                           userEmail: email,
                                                           dateRegistered: date,
                                                           userNickName: name)
                                self.linkAnonymousUserToSnsAccount(linkedUser: linkedUser)
                                completion(.linkSuccess)
                            }
                        } else {
                            completion(.linkFail)
                        }
                    })
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
    // MARK: 로그인 완료 시 데이터 만들기
    // firebase 로그인 완료 시 공통 처리 내용
    func completeLogin(type: UserType, uid: String, email: String, name: String, date: Date) {
        let multiUser = UserModel(accountType: type,
                                  userUID: uid,
                                  userEmail: email,
                                  dateRegistered: date,
                                  userNickName: name)
        // 데이터 세팅 후 유저 로딩
        let db = Firestore.firestore()
        // 첫 사용자면 데이터 세팅
        let path = db.collection("users").document(multiUser.userUID)
        path.getDocument { snapshot, error in
            if snapshot?.exists == false {
                db.collection("users").document(multiUser.userUID).setData(["accountType": UserType.returnIntValue(type: multiUser.accountType),
                                                                            "email": multiUser.userEmail,
                                                                            "name": multiUser.userNickName,
                                                                            "creationDate": multiUser.dateRegistered])
                print("새로운 유저 데이터 생성 완료")
                
                let firstSection = SectionList(order: 0, sectionName: "리스트 1", color: 0)
                
                db.collection("users").document(multiUser.userUID).collection(PathString.section.pathString()).document(firstSection.sectionID.uuidString).setData([
                    "order": firstSection.order,
                    "color": firstSection.color,
                    "sectionName": firstSection.sectionName
                ])
                
                // sectionShare 생성
                let sectionShare = SectionList(order: 10000, sectionName: "공유받은 항목", color: 0)
                
                db.collection("users").document(multiUser.userUID).collection(PathString.sectionShared.pathString()).document(sectionShare.sectionID.uuidString).setData([
                    "order": sectionShare.order,
                    "color": sectionShare.color,
                    "sectionName": sectionShare.sectionName
                ])
                
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.userData.user = multiUser
                    }
                    self.userData.sectionList.append(firstSection)
                    self.userData.sectionShared = sectionShare
                }
            } else {
                self.loadUserDataFromFirebase(id: multiUser.userUID) { user in
                    print("기존 유저 로딩 완료")
                    DispatchQueue.main.async {
                        withAnimation {
                            self.userData.user = user
                        }
                        self.userData.loadDataWithUser(user: user)
                    }
                }
            }
        }
    }
    
    // MARK: - [로그아웃]
    // MARK: 1. 로그아웃 (익명 계정은 탈퇴 처리)
//    func logout(completion: @escaping () -> Void) {
//        do {
//            let user = Auth.auth().currentUser
//            if user?.isAnonymous == true {
//                user?.delete(completion: { error in
//                    if error != nil {
//                        self.message = String(error?.localizedDescription ?? "")
//                        print(self.message!)
//                    } else {
//                        let userDefaults = UserDefaults.standard
//                        userDefaults.removeObject(forKey: "loginType")
//                        print("Anonymous User deleted")
//                    }
//                })
//            }
//
//            try Auth.auth().signOut()
//            completion()
//            if Auth.auth().currentUser == nil {
//                DispatchQueue.main.async {
//                    withAnimation(.easeInOut) {
//                        self.userData.logout()
//                    }
//                }
//            }
//        } catch let error {
//            print(error.localizedDescription)
//        }
//
//    }
    
}
 

// MARK: - [기타 function]
extension LoginViewModel {
    
    func returningDeleteDay(date: Date) -> String {
        let calendar = Calendar.current
        let dDay = calendar.dateComponents([.day], from: date, to: Date()).day
        return String(30 - (dDay ?? 0))
    }
    
    func loadUserDataFromFirebase(id: String, result: @escaping (UserModel) -> Void) {
        let db = Firestore.firestore()
        let path = db.collection("users").document(id)
        path.getDocument { snapshot, error in
            if let snapshot = snapshot, error == nil {
                
                guard let data = snapshot.data(),
                      let type = data["accountType"] as? Int,
                      let email = data["email"] as? String,
                      let name = data["name"] as? String,
                      let creDate = data["creationDate"] as? Timestamp
                else {
                    self.message = "User 정보 Parsing 중 에러가 발생했습니다.\n\(String(describing: error?.localizedDescription))"
                    print(self.message!)
                    return
                }
                    
                let loadedUser = UserModel(accountType: UserType.returnTypeValue(int: type),
                                           userUID: id,
                                           userEmail: email,
                                           dateRegistered: creDate.dateValue(),
                                           userNickName: name)
                result(loadedUser)
            } else {
                self.message = "2. User 정보 SnapShot 중 에러가 발생했습니다..\n\(String(describing: error?.localizedDescription))"
                print(self.message!)
            }
            
        }
    }
    
    func linkAnonymousUserToSnsAccount(linkedUser: UserModel) {
        self.userData.user = linkedUser
        
        let db = Firestore.firestore()
        db.collection("users").document(linkedUser.userUID).updateData([
            "accountType": UserType.returnIntValue(type: linkedUser.accountType),
            "email": linkedUser.userEmail,
            "name": linkedUser.userNickName
        ])
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
        message = error.localizedDescription
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
