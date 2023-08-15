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
    @Binding var isLoggedin: Bool
    
    @State var isShowingMessage: Bool = false
    @State var messageHome: String = ""
    var height: CGFloat = 150
    
    var body: some View {
        ZStack {
            if viewModel.isLoggedIn {
//                loggedInView(type: viewModel.loginType,
//                             name: viewModel.loggedInName,
//                             id: viewModel.loggedInID)
                sampleView(user: viewModel.user)
                    .onAppear {
                        isLoggedin = viewModel.isLoggedIn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation {
                                self.isShowingProgressView = false
                            }
                        }
                    }
            } else {
                notLoggedInView
                    .onAppear {
                        isLoggedin = viewModel.isLoggedIn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.isShowingMessage = false
                            self.messageHome = ""
                        }
                    }
            }
            if isShowingMessage {
                messageView
            }
        }
    }
}

extension LoginView {
    // 1. 로그인 완료 뷰
    func loggedInView(type: Int, name: String, id: String) -> some View {
        VStack {
            ZStack {
                Rectangle()
                    .foregroundColor(.orange)
                VStack {
                    Text("안녕하세요, \(name)님")
                        .padding(10)
                    Text(id)
                    Text("현재 익명 사용중입니다.\n 안전한 데이터 관리를 위해 로그인하여 사용하시길 권장합니다.")
                        .padding(10)
                }
                .frame(maxWidth: 500)
            }
            .frame(height: height)
            .cornerRadius(10)
            buttonLogin(title: "로그아웃") {
                viewModel.logout {
                    DispatchQueue.main.async {
                        self.isLoggedin = false
                    }
                }
            }
        }
    }
    
    // 2. sampleView
    func sampleView(user: UserModel) -> some View {
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
        .frame(height: height)
        .cornerRadius(10)
    }
    
    // 2. not 로그인 뷰
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
                GeometryReader { proxy in
                    HStack(spacing: 20) {
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
                        buttonLoginApple()
                            .frame(width: (proxy.size.width - 40) / 3,
                                   height: proxy.size.height)
//                            .clipped()
                            .cornerRadius(5, antialiased: true)
                            .shadow(color: .white, radius: 0.4, x: 0, y: 0)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: 400)
        }
        .frame(height: height)
    }
    
    // 3. 메세지뷰
    var messageView: some View {
        ZStack(alignment: .center) {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white.opacity(0.9))
                .frame(height: 100)
            Text(messageHome)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 40)
    }
}


// MARK: - [extension] 버튼
extension LoginView {
    func buttonLogin(title: String,
                     btncolor: Color = .teal,
                     textColor: Color = .white,
                     login: @escaping(() -> Void)) -> some View {
        Button {
            login()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(btncolor)
                Text(title)
                    .font(.headline)
                    .foregroundColor(textColor)
                    .fontWeight(.black)
            }
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
    
    func buttonLogin(image: String,
                     backgroundColor: Color = .white,
                     login: @escaping(() -> Void)) -> some View {
        Button {
            login()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(backgroundColor)
                Image(image)
                    .resizable()
                    .padding(5)
                    .scaledToFit()
            }
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
    
    func buttonLoginApple() -> some View {
//        ZStack {
//            Color.black
            SignInWithAppleButton(.continue) { request in
                viewModel.handleRequest(request: request) { _ in
                }
            } onCompletion: { result in
                self.viewModel.loginWithApple(result: result)
            }
            .frame(width: 100, height: 70)
//        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isShowingProgressView: .constant(false), isLoggedin: .constant(false))
    }
}
