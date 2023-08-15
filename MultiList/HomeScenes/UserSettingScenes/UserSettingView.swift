//
//  UserSettingView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/11.
//

import SwiftUI

struct UserSettingView: View {

    var screenSize: CGSize {
        get {
            guard let size = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.screen.bounds.size
            else {
                return CGSize(width: 200, height: 300)
            }
            return size
        }
    }
    
    let viewModel: UserSettingViewModel
    let widthRate = 0.7
    @State var isShowingAlert: Bool = false {
        didSet {
            if !isShowingAlert {
                anonymousMessage = ""
            }
        }
    }
    @Environment(\.dismiss) var isUserNil
    @State var anonymousMessage: String = ""
    
    var body: some View {
        let isVertical = screenSize.width < screenSize.height
        accountAndFriendListView(isVertical: isVertical, screenSize: screenSize)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("탈퇴하기") {
                        isShowingAlert = true
                    }
                    .tint(.primary)
                }
            }
            .alert("계정 & 데이터 삭제 경고", isPresented: $isShowingAlert, actions: {
                Button(role: .destructive) {
                    viewModel.deleteAccount {
                        self.isUserNil.callAsFunction()
                        self.anonymousMessage = ""
                    }
                } label: { Text("탈퇴하기") }
                Button(role: .cancel) {
                    anonymousMessage = ""
                } label: {
                    Text("취소")
                }

            }, message: {
                Text("\n\(anonymousMessage)탈퇴 시 계정과 데이터가 모두 삭제되며,\n복구할 수 없습니다.")
            })
    }
    
    @ViewBuilder
    func accountAndFriendListView(isVertical: Bool, screenSize: CGSize) -> some View {
        if isVertical {
            VStack(spacing: 10) {
                accountView(isVertical: isVertical, screenSize: screenSize)
                friendsListView(isVertical: isVertical, screenSize: screenSize)
            }
        } else {
            HStack(spacing: 10) {
                accountView(isVertical: isVertical, screenSize: screenSize)
                friendsListView(isVertical: isVertical, screenSize: screenSize)
            }
        }
    }
    
}

extension UserSettingView {
    
    func accountView(isVertical: Bool, screenSize: CGSize) -> some View {
        VStack(alignment: .leading) {
            Text("계정 정보")
                .foregroundColor(.primary)
            cardView()
                .overlay {
                    VStack(spacing: 0) {
                        Spacer()
                        VStack(alignment: .leading, spacing: 20) {
                            labelText(label: "닉네임", content: viewModel.user.userNickName)
                            labelText(label: "계정", content: viewModel.user.userEmail ?? "익명 계정")
                            labelText(label: "가입일", content: viewModel.returningDate(date: viewModel.user.dateRegistered))
                        }
                        Spacer()
                        HStack {
                            btnAccount(title: "닉네임 수정") {
                                
                            }
                            btnAccount(title: "로그 아웃") {
                                if viewModel.user.accountType == 0 {
                                    self.anonymousMessage = "익명 계정은 로그아웃 시 탈퇴 처리됩니다.\n"
                                    self.isShowingAlert = true
                                } else {
                                    viewModel.signOut {
                                        isUserNil.callAsFunction()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
        }
        .frame(width: isVertical ? screenSize.width : screenSize.width / 2,
               height: isVertical ? screenSize.height / 2 : screenSize.height)
    }
    
    func friendsListView(isVertical: Bool, screenSize: CGSize) -> some View {
        VStack(alignment: .leading) {
            Text("친구 리스트")
                .foregroundColor(.primary)
            List {
                Text("1")
                    .padding(.horizontal, screenSize.width * (1 - widthRate))
                Text("2")
                    .padding(.horizontal, screenSize.width * (1 - widthRate))
                Text("3")
                    .padding(.horizontal, screenSize.width * (1 - widthRate))
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
        .frame(width: isVertical ? screenSize.width : screenSize.width / 2,
               height: isVertical ? screenSize.height / 2 : screenSize.height)
    }
    
}

extension UserSettingView {
    
    func labelText(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
                Spacer()
            }
            HStack {
                Text(content)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
    }
    
    
    func btnAccount(title: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .foregroundColor(.white)
                Text(title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.teal)
            }
        }
        .frame(width: screenSize.width * 0.7 / 2.5, height: screenSize.height * 0.05)
        .buttonStyle(ScaleEffect())
    }
    
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
