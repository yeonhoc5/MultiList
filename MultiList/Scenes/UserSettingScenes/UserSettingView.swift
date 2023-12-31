//
//  UserSettingView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import SwiftUI
import Lottie

struct UserSettingView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: UserSettingViewModel
    @Environment(\.dismiss) var dismissThisView
    @Binding var isShowingProgressView: Bool
    
    init(userData: UserData, isShowingProgressView: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: UserSettingViewModel(userData: userData))
        _isShowingProgressView = isShowingProgressView
    }
    
    let widthRate = 0.7
    
    @State var editMode: EditMode = .inactive
    @State var isShowingSheet: Bool = false
    @State var isShowingAlertDelete: Bool = false
    @State var isShowingAlertRename: Bool = false
    @State var reName: String = ""
    @State var friendUID: String!
    @Namespace var settingView
    
    @State var isShowingNotYetFriendSheet: Bool = false
    
    var body: some View {
        let isVertical = screenSize.width < screenSize.height
        GeometryReader { proxy in
            OStack(alignment: .center, verticalSpacing: 20, horizontalSpacing: 20) {
                accountView(user: viewModel.userData.user ?? sampleUser,
                            isVertical: isVertical, geoProxy: proxy)
                    .matchedGeometryEffect(id: "accountView", in: settingView)
                    .frame(maxHeight: screenSize.width < screenSize.height ? proxy.size.height * 0.4 : .infinity)
                    .frame(maxWidth: screenSize.width < screenSize.height ? .infinity : proxy.size.width * 0.3)
                    .zIndex(0)
                friendsListView(user: viewModel.userData.user ?? sampleUser,
                                isVertical: isVertical, geoProxy: proxy)
                    .matchedGeometryEffect(id: "friendView", in: settingView)
                    .zIndex(1)
            }
            .padding(10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("탈퇴하기") {
                    isShowingAlertDelete = true
                }
                .tint(.colorSet[0].opacity(0.5))
            }
        }
        .alert("계정 & 데이터 삭제 경고", isPresented: $isShowingAlertDelete, actions: {
            Button(role: .cancel) {
                self.reName = ""
            } label: { Text("취소")}
            Button(role: .destructive) {
                self.isShowingProgressView = true
                self.dismissThisView.callAsFunction()
                viewModel.deleteAccount {
                    self.reName = ""
                }
            } label: { Text("탈퇴하기") }
        }, message: {
            Text("\(reName)\n탈퇴 시 계정과 데이터가 모두 삭제되며,\n복구할 수 없습니다.")
        })
        .alert("\n\(friendUID == nil ? "나" : "친구")의 닉네임을 변경합니다.",
               isPresented: $isShowingAlertRename,
               actions: {
            TextField(reName, text: $reName)
                .submitLabel(.done)
                .onSubmit {
                    viewModel.changeNickName(newName: reName, uid: friendUID)
                    isShowingAlertRename = false
                }
            Button("취소") {
                isShowingAlertRename = false
            }
            Button("수정하기") {
                viewModel.changeNickName(newName: reName, uid: friendUID)
                isShowingAlertRename = false
            }
        }, message: {
            Text("새로운 닉네임을 입력해주세요.")
                .padding(.vertical, 10)
        })
        .sheet(isPresented: $isShowingSheet, content: {
            FindUserFriendView(userData: viewModel.userData, isShowingSheet: $isShowingSheet)
        })
    }
}

extension UserSettingView {
    
    func accountView(user: UserModel, isVertical: Bool, geoProxy: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            Text("계정 정보")
                .foregroundColor(.primary)
            ZStack {
                lottieView(geoProxy: geoProxy)
                    .cornerRadius(10)
                    .clipped()
                VStack(alignment: .leading) {
                        labelText(label: "닉네임", content: user.userNickName)
                    Spacer(minLength: 5)
                    labelText(label: "계정", content: user.accountType != .anonymousUser ? user.userEmail : "(계정 없음)")
                    Spacer(minLength: 5)
                        labelText(label: "가입일", content: viewModel.returningDate(date: user.dateRegistered))
                    Spacer()
                    Spacer()
                    HStack {
                        btnAccount(title: "닉네임 수정") {
                            self.friendUID = nil
                            self.reName = user.userNickName
                            self.isShowingAlertRename = true
                        }
                        .disabled(user.accountType == .anonymousUser)
                        .overlay {
                            if user.accountType == .anonymousUser {
                                RoundedRectangle(cornerRadius: 5)
                                    .foregroundStyle(Color.gray.opacity(0.7))
                            }
                        }
                        btnAccount(title: "로그 아웃") {
                            if viewModel.userData.user != nil {
                                if user.accountType == .anonymousUser {
                                    self.reName = "\n익명 계정은 로그아웃 시 탈퇴 처리됩니다."
                                    self.isShowingAlertDelete = true
                                } else {
                                    viewModel.signOut {
                                        isShowingProgressView = true
                                        dismissThisView.callAsFunction()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .overlay {
                    if editMode == .active {
                        blurViewWithTapAction {
                            withAnimation {
                                editMode = .inactive
                            }
                        }
                    }
                }
            }
        }
    }
    
    func friendsListView(user: UserModel, isVertical: Bool, geoProxy: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            // 2-1. [친구리스트] - 타이틀
            HStack(alignment: .bottom) {
                Text("친구 리스트 (\(userData.friendList.count)명)")
                    .foregroundColor(.primary)
                if user.accountType != .anonymousUser {
                    Button {
                        withAnimation {
                            self.editMode = editMode == .inactive ? .active : .inactive
                        }
                    } label: {
                        Image(systemName: editMode == .inactive ? "gearshape.fill" : "gearshape")
                            .frame(width: 30)
                    }
                    .buttonStyle(ScaleEffect(scale: 0.7))
                    .foregroundColor(.teal)
                    .padding(.trailing, 5)
                }
                Spacer()
                if userData.notYetFriendList.count > 0 {
                    NavigationLink {
                        NotYetFriendListView(userData: userData, isShowingSheet: $isShowingNotYetFriendSheet)
                            .navigationTitle("알 수도 있는 친구 (\(userData.notYetFriendList.count)명)")
                            .navigationBarTitleDisplayMode(.large)
                    } label: {
                        HStack(spacing: 5, content: {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .imageScale(.small)
                                .rotation3DEffect(
                                    .degrees(180), axis: (x: 0.0, y: 1.0, z: 0.0)
                                )
                            Text("알 수도 있는 친구")
                                .font(.caption)
                        })
                    }
                    .buttonStyle(ScaleEffect(scale: 0.9))
                    .foregroundColor(.teal)
                    .padding(.trailing, 5)
                }
            }
            // 2-2. [친구리스트] - 리스트목록
            ZStack(alignment: .bottomLeading) {
                if user.accountType != .anonymousUser {
                    Button {
                        self.isShowingSheet = true
                    } label: {
                        ZStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.teal)
                        }
                    }
                    .buttonStyle(ScaleEffect(scale: 0.8))
                    .zIndex(1)
                    .padding([.bottom, .leading], 20)
                    .offset(x: editMode == .active ? -100 : 0)
                    .animation(.interactiveSpring(response: 0.3,
                                                  dampingFraction: 0.5,
                                                  blendDuration: 0.5),
                               value: editMode)

                }
                
                if userData.friendList.count == 0 {
                    Rectangle()
                        .fill(Color.white)
                        .overlay {
                            if user.accountType == .anonymousUser {
                                Text("sns 계정으로 로그인해 주세요.")
                                    .foregroundColor(.gray)
                            } else {
                                Text("등록된 친구가 없습니다.")
                                    .foregroundColor(.gray)
                            }
                        }
                } else {
                    List {
                        ForEach(userData.friendList, id: \.userEmail) { friend in
                            HStack(alignment: .center) {
                                Circle().fill(Color(uiColor: UIColor.systemGray5))
                                    .overlay {
                                        Text("\(friend.order + 1)")
                                            .foregroundColor(.white)
                                            .font(Font.system(size: 10, design: .rounded))
                                    }
                                    .frame(height: 20)
                                Text(friend.userNickName)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                if editMode != .active {
                                    Spacer()
                                }
                                Text("(\(friend.userEmail))")
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                if editMode == .active {
                                    Spacer()
                                    Image(systemName: "pencil.circle.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.teal)
                                }
                            }
                            .overlay(alignment: .trailing) {
                                if editMode == .active {
                                    Image(systemName: "line.3.horizontal")
                                        .imageScale(.large)
                                        .foregroundStyle(Color.black)
                                        .offset(x: 33)
                                }
                            }
                            .listRowBackground(Color.white)
                            .onTapGesture {
                                if editMode == .active {
                                    self.reName = friend.userNickName
                                    self.friendUID = friend.id
                                    self.isShowingAlertRename = true
                                }
                            }
                        }
                        .onMove { indexSet, int in
                            viewModel.reOrdering(onIndex: int, indexSet: indexSet)
                        }
                        .onDelete { indexSet in
                            viewModel.deleteFriend(indexSet: indexSet)
                        }
                    }
                    .padding(.trailing, 10)
                    .listStyle(.plain)
                    .environment(\.editMode, $editMode)
                    additionalSpace(color: .white)
                        .frame(height: 40)
                }
                
            }
            .background(.white)
            .mask {
                listMaskView(radius: 10)
            }
            .shadow(color: .black, radius: 1, x: 0, y: 0)
        }
        .frame(minWidth: geoProxy.size.width * 0.6, minHeight: geoProxy.size.height * 0.55)
    }
    
}

extension UserSettingView {
    func lottieView(geoProxy: GeometryProxy, degree: Double = 0) -> some View {
        let isVertical = screenSize.width < screenSize.height
        return GeometryReader { proxy in
            LottieView(animation: .named(userData.cardBackground[userData.randomNum]))
                .playing(loopMode: .loop)
                .scaleEffect(x: isVertical ? 1.25 : 1,
                             y: isVertical ? 1.25 : 3.5)
                .rotationEffect(.degrees(degree))
        }
    }
}

struct UserSettingView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingView(userData: UserData(), isShowingProgressView: .constant(false))
    }
}
