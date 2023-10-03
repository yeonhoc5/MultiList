//
//  LoginView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/07.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import PhotosUI

struct LoginView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: LoginViewModel
    
    @Binding var isShowingProgressView: Bool
    
    var nameSpace: Namespace.ID
    // sns 연결 alert
    @State var isShowingSNSLinkErrorAlert: Bool = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    // myItems
    @Binding var isShowingMyItemSheet: Bool
    @Binding var myItemNumber: Int
    @Binding var selectedItemType: MyItemType
    @State var myItem: MyItemModel!
    
    init(userData: UserData, isShowingProgressView: Binding<Bool>, isShowingMyItemSheet: Binding<Bool>, myItemNumber: Binding<Int>, selectedItemType: Binding<MyItemType>, nameSpace: Namespace.ID) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: LoginViewModel(userData: userData))
        _isShowingProgressView = isShowingProgressView
        _isShowingMyItemSheet = isShowingMyItemSheet
        _myItemNumber = myItemNumber
        _selectedItemType = selectedItemType
        self.nameSpace = nameSpace
    }
    
    var body: some View {
        Group {
            if userData.user == nil {
                notLoggedInView(nameSpace: nameSpace)
                    .matchedGeometryEffect(id: "loggedOut", in: nameSpace)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .onAppear(perform: {
                        if viewModel.isPreviousUser {
                            isShowingProgressView = true
                        }
                    })
            } else {
                loggedInView(user: userData.user, nameSpace: nameSpace)
                    .matchedGeometryEffect(id: "loggedIn", in: nameSpace)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .fullScreenCover(isPresented: $isShowingMyItemSheet, content: {
            MyItemView(userData: userData,
                       isShowingItemView: $isShowingMyItemSheet,
                       itemType: $selectedItemType,
                       itemNumber: $myItemNumber,
                       myItem: $myItem)
        })
        .alert(alertTitle, isPresented: $isShowingSNSLinkErrorAlert) {
            Button("확인") {
                isShowingSNSLinkErrorAlert = false
            }
        } message: {
            Text(alertMessage)
        }
    }
    
}

// subviews
extension LoginView {
    // 1. not 로그인 뷰
    func notLoggedInView(nameSpace: Namespace.ID) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.primary)
            GeometryReader { geoProxy in
                VStack(spacing: 15) {
                    // 1-1. 익명 로그인 버튼
                    buttonLogin(title: "익명으로 시작하기") {
                        viewModel.loginAnonymously { result in
                            showingLoginResult(result: result)
                        }
                    }
                    .frame(height: screenSize.width < screenSize.height ?
                           geoProxy.size.height / 3 : geoProxy.size.height / 5)
                    // 1-2. sns 로그인 버튼
                    snsLoginButtonView(nameSpace: nameSpace)
                }
            }
            .padding(10)
            .frame(maxWidth: 500, maxHeight: 400)
        }
    }
    // 2. loggedIn View
    func loggedInView(user: UserModel, nameSpace: Namespace.ID) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundStyle(LinearGradient(colors: [.orange, .yellow, .green, .green, .green, .yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
            GeometryReader { geoProxy in
                VStack(spacing: 15) {
                    HStack(alignment: .top) {
                        // 2-1. 유저 닉네임 & 계정 정보
                        accountView(user: user)
                        // 2-2. [네비게이션 뷰] 계정 & 친구 정보
                        NavigationLink {
                            UserSettingView(userData: userData,
                                            isShowingProgressView: $isShowingProgressView)
                        } label: {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
                        }
                        .buttonStyle(ScaleEffect())
                        .frame(height: 35)
                    }
                    .frame(height: screenSize.width < screenSize.height ?
                           geoProxy.size.height / 3 : geoProxy.size.height / 5)
                    // 2-3. 유저 아티템뷰 OR 익명 시 sns연결 버튼 뷰
                    if user.accountType == .anonymousUser {
                        snsLoginButtonView(nameSpace: nameSpace)
                    } else {
                        userItemView
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: 500, maxHeight: 400)
            
        }
    }
}
// subview Items
extension LoginView {
    func accountView(user: UserModel) -> some View {
        VStack {
            HStack {
                Text("Hello, \(viewModel.userData.user.userNickName)")
                if user.accountType == .anonymousUser {
                    Text("[D-\(viewModel.returningDeleteDay(date: user.dateRegistered))]")
                        .foregroundColor(.blue)
                }
                Spacer()
            }
            HStack {
                Text(user.accountType == .anonymousUser ? "(주의 : 익명 계정은 30일 후 삭제됩니다.)" : "(계정 : \(user.userEmail))")
                    .font(.callout).foregroundColor(.secondary)
                Spacer()
            }
        }
    }
    
    func snsLoginButtonView(nameSpace: Namespace.ID) -> some View {
        Group {
            HStack(alignment: .bottom) {
                Text(userData.user == nil
                     ? "sns 계정으로 가입하면 다른 기기에서도 동일하게 이용할 수 있습니다."
                     : "아래 sns ID로 연결하면 기존 데이터를 모두 이전할 수 있습니다.")
                    .font(.footnote)
                    .foregroundColor(.primaryInverted)
                Spacer()
            }
            OStack(alignment: .center, spacing: 10, isVerticalFirst: false) {
                buttonLogin(image: "logo_google") {
                    viewModel.loginWithGoogle { result in
                        showingLoginResult(result: result)
                    }
                }
                .cornerRadius(5, antialiased: true)
                .shadow(color: .black, radius: 0.4, x: 0, y: 0)
                .matchedGeometryEffect(id: "google", in: nameSpace)
//                buttonLogin(title: "N", btncolor: .green, textColor: .white) {
//                    viewModel.loginWithNaver()
//                }
//                .matchedGeometryEffect(id: "naver", in: nameSpace)
                buttonLogin(image: "logo_kakao", backgroundColor: .yellow) {
                    viewModel.loginWithKakao { result in
                        showingLoginResult(result: result)
                    }
                }
                .cornerRadius(5, antialiased: true)
                .matchedGeometryEffect(id: "kako", in: nameSpace)
                GeometryReader { proxy in
                    buttonLoginApple(geoProxy: proxy)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .cornerRadius(5, antialiased: true)
                        .shadow(color: .primaryInverted, radius: 0.4, x: 0, y: 0)
                }
                .matchedGeometryEffect(id: "apple", in: nameSpace)
            }
        }
    }
    
    var userItemView: some View {
        OStack(spacing: 10, isVerticalFirst: false) {
            HStack(spacing: 10) {
                myItemView(number: 0)
                myItemView(number: 1)
            }
            HStack(spacing: 10) {
                myItemView(number: 2)
                myItemView(number: 3)
            }
        }
    }
    
    func myItemView(number: Int) -> some View {
        Group {
            if let myItem = userData.myItems[number] {
                Button(action: {
                    self.myItem = myItem
                    self.selectedItemType = myItem.type
                    self.myItemNumber = myItem.order
                    isShowingMyItemSheet = true
                }, label: {
                    GeometryReader { geoProxy in
                        let size = min(geoProxy.size.width, geoProxy.size.height)
                        RoundedRectangle(cornerRadius: size / 2.5)
                            .fill(Color.orange)
                            .frame(width: size, height: size)
                            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
                            .overlay(alignment: .center) {
                                Text(myItem.title)
                                    .font(.system(.subheadline, 
                                                  design: .rounded,
                                                  weight: .bold))
                                    .multilineTextAlignment(.center)
                                    .padding(5)
                            }
                    }
                })
                .buttonStyle(ScaleEffect())
            } else {
                instantButtonView(number: number)
            }
        }
    }
    
    func instantButtonView(number: Int) -> some View {
        Menu {
            Text("내 아이템 \(number+1)")
            contextMenuItem(title: MyItemType.text.rawValue, image: "text.justify.left") {
                self.selectedItemType = .text
                self.myItemNumber = number
                self.isShowingMyItemSheet = true
            }
            contextMenuItem(title: MyItemType.image.rawValue, image: "photo.fill") {
                self.selectedItemType = .image
                self.myItemNumber = number
                self.isShowingMyItemSheet = true
            }
    
        } label: {
            GeometryReader { geoProxy in
                let size = min(geoProxy.size.width, geoProxy.size.height)
                RoundedRectangle(cornerRadius: size / 2.5)
                    .fill(Color.orange)
                    .frame(width: size, height: size)
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
                    .overlay(alignment: .center) {
                        Image(systemName: "plus.square.dashed")
                            .imageScale(.large)
                            .foregroundColor(.white)
                    }
            }
        }
        .buttonStyle(ScaleEffect())
        .frame(maxWidth: 150, maxHeight: 150)
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
    func buttonLoginApple(geoProxy: GeometryProxy) -> some View {
        ZStack {
            Color.black
            SignInWithAppleButton(.continue) { request in
                viewModel.handleRequest(request: request) { _ in
                }
            } onCompletion: { result in
                self.viewModel.loginWithApple(result: result) { result in
                    showingLoginResult(result: result)
                }
            }
            .frame(width: geoProxy.size.height < 90 ? geoProxy.size.height : geoProxy.size.height / 2)
            .frame(height: geoProxy.size.height < 90 ? geoProxy.size.height * 2 : geoProxy.size.height)
//            .frame(minHeight: 70)
        }
        .buttonStyle(ScaleEffect(scale: 0.9))
    }
    
    func showingLoginResult(result: LoginResult) {
        switch result {
        case .linkFail:
            self.alertTitle = "sns 계정 연결 실패"
            self.alertMessage = "\n연결하려는 sns 계정이 이미 사용중이므로 연결할 수 없습니다.\n다른 계정을 연결해 주세요."
            self.isShowingSNSLinkErrorAlert = true
        case .linkSuccess:
            self.alertTitle = "sns 계정 연결 성공"
            self.alertMessage = "\n현재 데이터가 sns 계정에 연결되었습니다.\n이제 로그인에서 해당 sns 로그인 버튼을 이용해주세요."
            self.isShowingSNSLinkErrorAlert = true
        case .loginSuccess:
            isShowingProgressView = true
        case .loginFail:
            break
        }
    }
}


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(userData: UserData(),
                  isShowingProgressView: .constant(false),
                  isShowingMyItemSheet: .constant(false),
                  myItemNumber: .constant(1),
                  selectedItemType: .constant(.image),
                  nameSpace: Namespace.init().wrappedValue)
    }
}
