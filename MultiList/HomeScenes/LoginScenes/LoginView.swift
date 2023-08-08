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
    @Binding var isLoggedin: Bool
    @State var isShowingProgressView: Bool = false
    @State var isShowingMessage: Bool = false
    @State var messageHome: String = ""
    var height: CGFloat = 150
    
    var body: some View {
        ZStack {
            if viewModel.isLoggedIn {
                loggedInView(name: viewModel.loggedInName, id: viewModel.loggedInID)
                    .onAppear {
                        isLoggedin = viewModel.isLoggedIn
                        self.isShowingProgressView = false
                    }
            } else {
                notLoggedInView
                    .onAppear {
                        isLoggedin = viewModel.isLoggedIn
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.isShowingMessage = viewModel.isLoggedIn
                            self.messageHome = ""
                        }
                    }
            }
            if isShowingProgressView {
                loginProgressView
            }
            if isShowingMessage {
                messageView
            }
        }
    }
}

extension LoginView {
    // 1. 로그인 완료 뷰
    func loggedInView(name: String, id: String) -> some View {
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
            }
            .frame(height: height)
            buttonLogin(title: "logout") {
                self.isShowingProgressView = true
                print("로그아웃되었습니다.")
                viewModel.logout {
                    
                    self.isShowingProgressView = false
                    self.messageHome = "로그아웃되었습니다."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeInOut) {
                            self.isShowingMessage = true
                        }
                    }
                }
            }
            .frame(height: 50)
        }
    }
    
    // 2. not 로그인 뷰
    var notLoggedInView: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
            VStack(spacing: 20) {
                buttonLogin(title: "익명으로 시작하기") {
                    withAnimation {
                        self.isShowingProgressView = true
                    }
                    viewModel.loginAnonymously()
                }
                HStack {
                    Text("SNS로 로그인하면 다른 기기에서도 볼 수 있어요.")
                        .foregroundColor(.white)
                        .frame(alignment: .leading)
                    Spacer()
                }
                GeometryReader { proxy in
                    HStack(spacing: 20) {
                        buttonLogin(title: "G", btncolor: .white, textColor: .black) {
    //                        DispatchQueue.main.async {
                                self.isShowingProgressView = true
    //                        }
                            viewModel.loginWithGoogle()
                        }
                        buttonLogin(title: "N", btncolor: .green, textColor: .white) {
                            viewModel.loginWithNaver()
                            self.isShowingProgressView = true
                        }
                        buttonLogin(title: "Kakao", btncolor: .yellow, textColor: .black) {
                            viewModel.loginWithKakao()
                            self.isShowingProgressView = true
                        }
                        SigninWithAppleID(viewModel: viewModel)
                            .frame(width: (proxy.size.width - 70) / 4, height: proxy.size.height)
                            .clipped()
                            .cornerRadius(5)
                            .shadow(color: .white, radius: 0.2, x: 0, y: 0)
                    }
                }
            }
            .padding(10)
        }
        .frame(height: height)
    }
    
    // 3. 프로그레스뷰
    var loginProgressView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 100, height: 100)
            ProgressView()
                .tint(.black)
                .progressViewStyle(.circular)
        }
    }
    
    // 4. 메세지뷰
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

extension LoginView {
    func buttonLogin(title: String, btncolor: Color = .teal, textColor: Color = .white, login: @escaping(() -> Void)) -> some View {
        Button {
            login()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(btncolor)
                Text(title)
                    .foregroundColor(textColor)
                    .fontWeight(.black)
            }
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(isLoggedin: .constant(true))
    }
}
