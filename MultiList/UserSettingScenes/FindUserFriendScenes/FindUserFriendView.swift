//
//  FindUserFriendView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import SwiftUI

enum FindFriendResult {
    case success
    case fail
    case already
    case myself
    case none
}

struct FindUserFriendView: View {
    @Binding var isShowingSheet: Bool
    @ObservedObject var userData: UserData
    @StateObject var viewModel: FindUserFriendViewModel
    
    @State var friendEmail: String = ""
    @State var isShowingProgressView: Bool = false
    @State var resultViewCase: FindFriendResult = .none
    @FocusState var isFocused: Bool

    init(userData: UserData, isShowingSheet: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: FindUserFriendViewModel(userData: userData))
        _isShowingSheet = isShowingSheet
    }
    
    var body: some View {
        NavigationView {
            OStack(spacing: 20) {
                findResultView(result: resultViewCase)
                    .frame(height: 80)
                    .overlay {
                        if isShowingProgressView {
                            CustomProgressView()
                        }
                    }
                HStack {
                    ZStack {
                        Group {
                            RoundedRectangle(cornerRadius: 5)
                                .blur(radius: 1)
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundColor(.white)
                        }
                        TextField("친구의 이메일 정확히 입력해주세요.",
                                  text: $friendEmail,
                                  prompt: Text("친구의 이메일을 정확히 입력해주세요."))
                            .submitLabel(.done)
                            .onSubmit {
                                viewModel.findFriendInDB(email: friendEmail) { resutl in
                                    withAnimation {
                                        resultViewCase = resutl
                                    }
                                }
                            }
                            .foregroundColor(.black)
                            .focused($isFocused)
                            .padding(.leading, 10)
                            .keyboardType(.emailAddress)
                            
                    }
                    .onAppear {
                        self.isFocused = true
                    }
                    Button {
                        viewModel.findFriendInDB(email: friendEmail) { result in
                            withAnimation {
                                resultViewCase = result
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.teal)
                            Text("검색")
                                .foregroundColor(.white)
                        }
                        .frame(width: 50)
                    }
                    .buttonStyle(ScaleEffect())
                }
                .frame(height: 50)
                .frame(maxWidth: 400)
                .padding(.horizontal, 20)
                Spacer()
                Spacer()
            }
            .frame(height: 200)
            .navigationTitle("친구 찾기")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        withAnimation {
                            self.isShowingSheet = false
                        }
                    }
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

extension FindUserFriendView {
    func findResultView(result: FindFriendResult) -> some View {
        Group {
            switch result {
            case .success, .already:
                if let friend = viewModel.resultFriend {
                    OStack(isVerticalFirst: false) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("닉네임 : \(friend.userNickName)")
                            Text("이메일 : \(friend.userEmail)")
                        }
                        Button {
                            withAnimation {
                                self.isShowingProgressView = true
                            }
                            viewModel.addFriendToMyInfo(friend: friend)
                            self.isShowingSheet = false
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(resultViewCase == .already ? Color.gray : Color.teal)
                                Text(resultViewCase == .already ? "등록된\n친구" : "친구\n추가")
                                    .foregroundColor(.white)
                            }
                            .frame(width: 70)
                        }
                        .buttonStyle(ScaleEffect())
                        .disabled(resultViewCase == .already || resultViewCase == .myself)
                    }
                }
            case .fail:
                VStack(alignment: .leading, spacing: 10) {
                    Text("친구를 찾지 못했습니다.")
                    Text("입력하신 이메일을 확인해주세요.")
                }
            case .myself:
                VStack(alignment: .leading, spacing: 10) {
                    Text("본인의 이메일")
                }
            case .none:
                Rectangle().fill(Color.primaryInverted)
            }
        }
    }
}

struct FindUserFriendView_Previews: PreviewProvider {
    static var previews: some View {
        FindUserFriendView(userData: UserData(), isShowingSheet: .constant(true))
    }
}
