//
//  SigninWithAppleID.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/08.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct SigninWithAppleID: View {
    let viewModel: LoginViewModel
    
    var body: some View {
        ZStack {
            Color.black
            SignInWithAppleButton(.continue) { request in
                let nonce = viewModel.randomNonceString()
                viewModel.currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = viewModel.sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authResults):
                    switch authResults.credential {
                    case let appleIDCredential as ASAuthorizationAppleIDCredential:

                        guard let nonce = viewModel.currentNonce else {
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
                        let credential = OAuthProvider.credential(withProviderID: "apple.com",idToken: idTokenString,rawNonce: nonce)

                        //Sending Request to Firebase
                        Auth.auth().signIn(with: credential) { (authResult, error) in
                            if (error != nil) {
                                // Error. If error.code == .MissingOrInvalidNonce, make sure
                                // you're sending the SHA256-hashed nonce as a hex string with
                                // your request to Apple.
                                print(error?.localizedDescription as Any)
                                return
                            }
                            viewModel.isLoggedIn = true
                            viewModel.loginType = 5
                            viewModel.loggedInID = authResult?.user.uid ?? "얼라라"
//                            viewModel.loggedInName = authResult?.user.displayName
                            print(authResult?.user.displayName)
                            print(authResult?.user.email)
                            print(authResult?.user.description.utf8)
                            print(authResult?.user.metadata.lastSignInDate)
                            print(authResult?.user.phoneNumber)
                            print(authResult?.user.photoURL)
                            print(authResult?.additionalUserInfo?.isNewUser)
                            print(authResult?.additionalUserInfo?.profile)
                            print(authResult?.additionalUserInfo?.username)
                            print("you're in")
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
            .frame(width: 100, height: 70)
        }
    }
}
struct SigninWithAppleID_Previews: PreviewProvider {
    static var previews: some View {
        SigninWithAppleID(viewModel: LoginViewModel())
    }
}
