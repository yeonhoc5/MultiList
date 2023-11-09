//
//  FindUserFriendView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import SwiftUI

struct FindUserFriendView: View {
    @Binding var isShowingSheet: Bool
    @ObservedObject var userData: UserData
    @StateObject var viewModel: FindUserFriendViewModel
    
    @State var friendID: String = ""
    @State var friendEmail: String = ""
    @State var isShowingProgressView: Bool = false
    @State var resultViewCase: FindFriendResult = .none
    @State var resultFriend: Friend!
    @FocusState var isFocused1: Bool
    @FocusState var isFocused2: Bool

    init(userData: UserData, isShowingSheet: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: FindUserFriendViewModel(userData: userData))
        _isShowingSheet = isShowingSheet
    }
    
    var body: some View {
        NavigationView {
            OStack(spacing: 20) {
                findResultView(result: resultViewCase)
                inputTextFieldView
                    .frame(height: 50)
                    .onAppear {
                        self.isFocused1 = true
                    }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 20)
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
        }
    }
}

extension FindUserFriendView {
    func findResultView(result: FindFriendResult) -> some View {
        Rectangle().fill(Color.clear)
            .overlay {
                Group {
                    switch result {
                    case .success, .already:
                        if let friend = resultFriend {
                            HStack {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("닉네임 : \(friend.userNickName)")
                                    Text("이메일 : \(friend.userEmail)")
                                }
                                Button {
                                    withAnimation {
                                        self.isShowingProgressView = true
                                        self.userData.addFriendToMyInfo(friend: friend,
                                                                        addMeToFriend: true)
                                    }
                                    self.isShowingSheet = false
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(resultViewCase == .already ? Color.gray : Color.teal)
                                        Text(resultViewCase == .already ? "등록된\n친구" : "친구\n추가")
                                            .foregroundColor(.white)
                                    }
                                    .frame(width: 50, height: 50)
                                }
                                .buttonStyle(ScaleEffect())
                                .disabled(resultViewCase == .already || resultViewCase == .myself)
                            }
                        }
                    case .fail:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("친구(\(resultFriend.userEmail))를 찾지 못했습니다.")
                            Text("입력하신 이메일을 확인해주세요.")
                        }
                    case .myself:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("현재 사용자의 계정(\(resultFriend.userEmail))입니다.")
                        }
                    default:
                        VStack(alignment: .leading, spacing: 10) {
                            Text("e-mail로 친구를 검색해주세요.")
                        }
                    }
                }
                if isShowingProgressView {
                    CustomProgressView()
                }
            }
    }
    
    var inputTextFieldView: some View {
        HStack(alignment: .bottom) {
            emailTextfield(binding: $friendID, placeHolder: "이메일 ID", focused: $isFocused1)
            HStack(alignment: .center) {
                Text("@")
                emailTextfield(binding: $friendEmail, placeHolder: "직접 입력", focused: $isFocused2, keyboardTyep: .URL)
                    .overlay(alignment: .topTrailing, content: {
                        HStack {
                            buttonEmailProvider(provider: .google)
                            buttonEmailProvider(provider: .kakao)
                            buttonEmailProvider(provider: .others)
                        }
                        .offset(y: -35)
                    })
            }
            Button {
                withAnimation {
                    isShowingProgressView = true
                }
                viewModel.findFriendInDB(email: friendID+"@"+friendEmail) { result, email in
                    withAnimation {
                        resultViewCase = result
                        resultFriend = email
                        isShowingProgressView = false
                    }
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(friendEmail == "" ? Color.gray : Color.teal)
                    Text("검색")
                        .foregroundColor(.white)
                }
                .frame(width: 50)
            }
            .buttonStyle(ScaleEffect())
            .disabled(friendID.count * friendEmail.count == 0)
        }
    }
}

enum EmailProviders: String {
    case google = "gmail.com"
    case kakao = "kakao.com"
    case others = ""
    
    static func returnIamge(provider: EmailProviders) -> String {
        switch provider {
        case .google: return "logo_google"
        case .kakao: return "logo_kakao"
        case .others: return "xmark"
        }
    }
}

extension FindUserFriendView {
    
    func emailTextfield(binding: Binding<String>, placeHolder: String, focused: FocusState<Bool>.Binding,
                        keyboardTyep: UIKeyboardType! = .default, submit: SubmitLabel! = .done) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .foregroundColor(.white)
                .shadow(color: .black, radius: 1, x: 0, y: 0)
            TextField("", text: binding)
                .placeholder(when: binding.wrappedValue.isEmpty, alignment: .leading, placeholder: {
                    Text(placeHolder)
                        .foregroundColor(.gray)
                })
                .onSubmit {
                    if friendID.count * friendEmail.count > 0 {
                        viewModel.findFriendInDB(email: friendID+"@"+friendEmail) { result, friend in
                            withAnimation {
                                resultViewCase = result
                                resultFriend = friend
                            }
                        }
                    }
                }
                .foregroundColor(.black)
                .focused(focused)
                .keyboardType(keyboardTyep)
                .submitLabel(submit)
                .padding(.leading, 10)
        }
    }
    
    func buttonEmailProvider(provider: EmailProviders) -> some View {
        Button {
            self.friendEmail = provider.rawValue
        } label: {
            ZStack {
                Circle()
                    .foregroundStyle(provider == .kakao ? Color.yellow : Color.white)
                    .shadow(color: .black, radius: 0.1, x: 0, y: 0)
                Group {
                    if provider != .others {
                        Image(EmailProviders.returnIamge(provider: provider))
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(systemName: EmailProviders.returnIamge(provider: provider))
                            .foregroundStyle(Color.black)
                    }
                }
                .padding(5)
            }
        }
        .buttonStyle(ScaleEffect())
        .frame(width: 30)
    }
}

struct FindUserFriendView_Previews: PreviewProvider {
    static var previews: some View {
        FindUserFriendView(userData: UserData(), isShowingSheet: .constant(true))
    }
}
