//
//  LoginView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @StateObject var viewModel = LoginViewModel()
    
    @Binding var isShowingProgressView: Bool
    var nameSpace: Namespace.ID
    
    var body: some View {
        Group {
            if viewModel.user == nil {
                notLoggedInView
                    .matchedGeometryEffect(id: "loggin", in: nameSpace)
            } else {
                loggedInView(user: viewModel.user)
                    .matchedGeometryEffect(id: "loggout", in: nameSpace)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.isShowingProgressView = false
            }
        }
    }
}

extension LoginView {
    
    // 1. sampleView
    func loggedInView(user: UserModel) -> some View {
        ZStack {
            Rectangle()
                .foregroundColor(.orange)
            VStack {
                HStack {
                    Text("UID: \(user.userUID) (tyep: \(user.accountType))")
                    Spacer()
                }
                HStack {
                    Text("계정: \(user.userEmail ?? "이메일을 파악할 수 없습니다.")")
                    Spacer()
                }
                HStack {
                    Text("닉네임: \(user.userNickName)")
                    Spacer()
                }
                HStack {
                    Text("가입일: \(viewModel.returningDate(date: user.dateRegistered))")
                    Spacer()
                }
            }
            .frame(maxWidth: 400)
            .padding(10)
        }
        .cornerRadius(10)
    }
    
    // 2. not 로그인 뷰
//    func notLoggedInView(isVertical: Bool, screenSize: CGSize) -> some View {
    var notLoggedInView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.primary)
            VStack(spacing: 15) {
                buttonLogin(title: "익명으로 시작하기") {
                    viewModel.loginAnonymously()
                }
                HStack {
                    Text("SNS ID로 로그인하면 다른 기기에서도 볼 수 있어요.")
                        .font(.footnote)
                        .foregroundColor(.primaryInverted)
                    Spacer()
                }
                .padding(.top, 10)
                OStack(alignment: .center, spacing: 10, isVerticalFirst: false) {
                    
                    buttonLogin(image: "logo_google") {
                        viewModel.loginWithGoogle()
                    }
                    .cornerRadius(5, antialiased: true)
                    .shadow(color: .black, radius: 0.4, x: 0, y: 0)
                    //                        buttonLogin(title: "N", btncolor: .green, textColor: .white) {
                    //                            viewModel.loginWithNaver()
                    //                        }
                    buttonLogin(image: "logo_kakao", backgroundColor: .yellow) {
                        viewModel.loginWithKakao()
                    }
                    .cornerRadius(5, antialiased: true)
                    GeometryReader { proxy in
                        buttonLoginApple()
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .clipped()
                            .cornerRadius(5, antialiased: true)
                            .shadow(color: .primaryInverted, radius: 0.4, x: 0, y: 0)
                    }
                }
                
            }
            .padding(10)
                .frame(maxWidth: 400, maxHeight: 400)
        }
        
    }
    
    // 3. 메세지뷰
    var messageView: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white.opacity(0.9))
                .frame(height: 100)
            Text(viewModel.message)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 40)
    }
}


// MARK: - [extension] 버튼
extension LoginView {
    func buttonLoginApple() -> some View {
        ZStack {
            Color.black
            SignInWithAppleButton(.continue) { request in
                viewModel.handleRequest(request: request) { _ in
                }
            } onCompletion: { result in
                self.viewModel.loginWithApple(result: result)
            }
            .frame(width: 130)
            .frame(minHeight: 70)
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isShowingProgressView: .constant(false), nameSpace: Namespace.init().wrappedValue)
    }
}
