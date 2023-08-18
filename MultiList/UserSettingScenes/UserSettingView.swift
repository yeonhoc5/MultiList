//
//  UserSettingView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import SwiftUI

struct UserSettingView: View {
    
    @Environment(\.dismiss) var dismissThisView
    @ObservedObject var viewModel: UserSettingViewModel
    
    let widthRate = 0.7
    @State var isShowingAlert: Bool = false
    @Namespace var settingView
    
    var body: some View {
        let isVertical = screenSize.width < screenSize.height
        GeometryReader { proxy in
            OStack(alignment: .center, spacing: 10) {
                accountView(user: viewModel.user ?? sampleUser, isVertical: isVertical, geoProxy: proxy)
                    .matchedGeometryEffect(id: "accountView", in: settingView)
                friendsListView(user: viewModel.user ?? sampleUser, isVertical: isVertical, geoProxy: proxy)
                    .matchedGeometryEffect(id: "friendView", in: settingView)
            }
            .padding(10)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("탈퇴하기") {
                    isShowingAlert = true
                }
                .tint(.primary)
                .disabled(viewModel.user == nil)
            }
        }
        .alert("계정 & 데이터 삭제 경고", isPresented: $isShowingAlert, actions: {
            Button(role: .destructive) {
                viewModel.deleteAccount {
                    self.dismissThisView.callAsFunction()
                }
            } label: { Text("탈퇴하기") }
        }, message: {
            if viewModel.user?.accountType == 0 {
                Text("\n익명 계정은 로그아웃 시 탈퇴 처리됩니다.\n탈퇴 시 계정과 데이터가 모두 삭제되며,\n복구할 수 없습니다.")
            } else {
                Text("\n탈퇴 시 계정과 데이터가 모두 삭제되며,\n복구할 수 없습니다.")
            }
        })
    }
    
//    @ViewBuilder
//    func accountAndFriendListView(screenSize: CGSize, nameSpace: Namespace.ID) -> some View {
//
//    }
}

extension UserSettingView {
    
    func accountView(user: UserModel, isVertical: Bool, geoProxy: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            Text("계정 정보")
                .foregroundColor(.primary)
            cardView()
                .overlay {
                    VStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 10) {
                            labelText(label: "닉네임", content: user.userNickName)
                            labelText(label: "계정", content: user.userEmail ?? "익명 계정")
                            labelText(label: "가입일", content: viewModel.returningDate(date: user.dateRegistered))
                        }
                        Spacer()
                        HStack {
                            btnAccount(title: "닉네임 수정") {
                                
                            }
                            btnAccount(title: "로그 아웃") {
                                if viewModel.user != nil {
                                    if user.accountType == 0 {
                                        self.isShowingAlert = true
                                    } else {
                                        viewModel.signOut {
                                            dismissThisView.callAsFunction()
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
        }
//        .frame(width: isVertical ? screenSize.width - 60 : (screenSize.width * 0.4) - 60,
//               height: isVertical ? (screenSize.height * 0.4) - 60 : screenSize.height - 60)
    }
    
    func friendsListView(user: UserModel, isVertical: Bool, geoProxy: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            Text("친구 리스트")
                .foregroundColor(.primary)
            List(user.friendList, id: \.userUID) { friend in
                Text(friend.userNickName)
            }
            .foregroundColor(.primary)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .colorInvert()
            .background(.primary)
            .mask {
                cardView()
            }
        }
        .frame(minWidth: geoProxy.size.width * 0.6, minHeight: geoProxy.size.height * 0.55)
//        .frame(width: isVertical ? screenSize.width - 60 : (screenSize.width * 0.6) - 60,
//               height: isVertical ? (screenSize.height * 0.6) - 60 : screenSize.height - 60)
    }
    
}

extension UserSettingView {
    func cardView(color: Color = .teal) -> some View {
        return RoundedRectangle(cornerRadius: 20)
            .foregroundColor(color)
    }
}

struct UserSettingView_Previews: PreviewProvider {
    static var previews: some View {
        UserSettingView(viewModel: UserSettingViewModel(user: sampleUser))
    }
}
