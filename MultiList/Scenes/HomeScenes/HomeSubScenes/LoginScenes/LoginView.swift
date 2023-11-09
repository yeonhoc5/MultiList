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
import Lottie

struct LoginView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: LoginViewModel
    @Binding var isShowingProgressView: Bool
    var nameSpace: Namespace.ID
    
    // sns 연결 alert
    @State var isShowingSNSLinkErrorAlert: Bool = false
    @State var alertTitle = ""
    @State var alertMessage = ""
    
    // myItems 프라퍼티
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
                // 1. nill 유저 View
                notLoggedInView(nameSpace: nameSpace)
                    .matchedGeometryEffect(id: "logView", in: nameSpace)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .onAppear(perform: {
                        if viewModel.isPreviousUser {
                            isShowingProgressView = true
                        }
                    })
            } else {
                // 2. 유저 로그인 뷰
                loggedInView(user: userData.user, nameSpace: nameSpace)
                    .matchedGeometryEffect(id: "logView", in: nameSpace)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .fullScreenCover(isPresented: $isShowingMyItemSheet, content: {
            // 3. myItems 디테일 뷰
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

// MARK: - Main subviews
extension LoginView {
    // 1. not 로그인 뷰
    func notLoggedInView(nameSpace: Namespace.ID) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.primary)
            GeometryReader { geoProxy in
                VStack(spacing: 0) {
                    // 1-1. 익명 로그인 버튼
                    buttonLogin(title: "익명으로 시작하기") {
                        viewModel.loginAnonymously { result in
                            showingLoginResult(result: result)
                        }
                    }
                    .frame(height: geoProxy.size.height / (screenSize.width < screenSize.height ? 3 : 5))
                    Spacer()
                    // 1-2. sns 로그인 버튼
                    snsLoginButtonView(nameSpace: nameSpace, geoProxy: geoProxy)
                        .matchedGeometryEffect(id: "snsLoginButton", in: nameSpace)
                }
            }
            .padding(10)
            .frame(maxWidth: 500, maxHeight: 500)
        }
    }
    // 2. loggedIn View
    func loggedInView(user: UserModel, nameSpace: Namespace.ID) -> some View {
            ZStack {
                lottieView()
                    .cornerRadius(10)
                    .clipped()
                GeometryReader { geoProxy in
                    VStack(spacing: 0) {
                        HStack(alignment: .top) {
                            // 2-1. 유저 닉네임 & 계정 정보
                            accountView(user: user)
                            // 2-2. [네비게이션 뷰] 계정 & 친구 정보
                            NavigationLink {
                                UserSettingView(userData: userData,
                                                isShowingProgressView: $isShowingProgressView)
                            } label: {
                                imageScaleToFit(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
                            }
                            .buttonStyle(ScaleEffect())
                            .frame(height: 35)
                        }
                        .frame(height: geoProxy.size.height / (screenSize.width < screenSize.height ? 3 : 5))
                        Spacer()
                        // 2-3. 유저 아티템뷰 OR 익명 시 sns연결 버튼 뷰
                        Group {
                            if user.accountType == .anonymousUser {
                                snsLoginButtonView(nameSpace: nameSpace, geoProxy: geoProxy)
                                    .matchedGeometryEffect(id: "snsLoginButton", in: nameSpace)
                            } else {
                                userItemView
                            }
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: 500, maxHeight: 500)
        }
    }
}

// MARK: - subview Items
extension LoginView {
    
    func lottieView(degree: Double = 0) -> some View {
        LottieView(animation: .named(userData.cardBackground[userData.randomNum]))
            .playing(loopMode: .loop)
            .scaleEffect(x: screenSize.width < screenSize.height ? 2.3 : 1,
                         y: screenSize.width < screenSize.height ? 1 : 3.6)
            .rotationEffect(.degrees(degree))
    }
    
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
    
    func snsLoginButtonView(nameSpace: Namespace.ID, geoProxy: GeometryProxy) -> some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom) {
                Text(userData.user == nil
                     ? "sns 계정으로 다른 기기에서도 동일하게 이용할 수 있습니다."
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
            .frame(height: geoProxy.size.height * (screenSize.width < screenSize.height ? (1/3) : (3/5)))
        }
    }
    
    var userItemView: some View {
        OStack(isVerticalFirst: false) {
            HStack {
                myItemView(number: 0)
                myItemView(number: 1)
            }
            HStack {
                myItemView(number: 2)
                myItemView(number: 3)
            }
        }
//        let columns = Array(repeating: GridItem(.flexible(minimum: 80, maximum: 150), spacing: 10, alignment: .center),
//                                                     count: screenSize.width < screenSize.height ? 4 : 2)
//        return LazyVGrid(columns: columns) {
//            ForEach(0..<4) { int in
//                myItemView(number: int)
//            }
//        }
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
                    myItemLabel(myItem: myItem)
                })
            } else {
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
                    myItemLabel()
                }
            }
        }
        .buttonStyle(ScaleEffect())
        .frame(maxWidth: 150, maxHeight: 150)
    }
    
    
    // 2-1. 마이아이템 라벨뷰
    func myItemLabel(myItem: MyItemModel? = nil) -> some View {
        GeometryReader { geoProxy in
            let size = max(geoProxy.size.width, geoProxy.size.height)
            ZStack {
                BlurView(style: .light)
                if let myItem = myItem {
                    Text(myItem.title)
                        .font(.system(.subheadline, design: .rounded, weight: .bold))
                        .lineLimit(3, reservesSpace: false)
                        .multilineTextAlignment(.center)
                        .padding(5)
                } else {
                    Image(systemName: "plus.square.dashed")
                        .imageScale(.large)
                        .foregroundColor(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: size / 2.6))
            .padding(5)
            .frame(width: size, height: size)
            .position(x: geoProxy.frame(in: .local).midX, y: geoProxy.frame(in: .local).midY)
            .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 0)
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
    func shuffleColorSet(colorSet: [Color] = [Color.colorSet[0], Color.colorSet[1], Color.colorSet[2]]) -> Gradient {
        var colorSet = colorSet
        let firstColor = colorSet.removeFirst()
        colorSet.append(firstColor)
        return Gradient(colors: colorSet)
    }
    
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
                  myItemNumber: .constant(0),
                  selectedItemType: .constant(.text),
                  nameSpace: Namespace().wrappedValue)
    }
}

