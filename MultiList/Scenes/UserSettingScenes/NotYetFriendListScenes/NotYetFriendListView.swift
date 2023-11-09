//
//  NotYetFriendListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 11/8/23.
//

import SwiftUI

struct NotYetFriendListView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: NotYetFriendListViewModel
    
    @Binding var isShowingSheet: Bool
    
    init(userData: UserData, isShowingSheet: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: NotYetFriendListViewModel(userData: userData))
        _isShowingSheet = isShowingSheet
    }
    
    var body: some View {
        VStack(alignment: .leading, content: {
            Text("나를 친구로 등록한 유저 중에서 아직 내친구로 등록하지 않은 목록입니다.")
                .font(.caption)
                .padding(.horizontal, 17)
                .foregroundStyle(Color.gray)
            ZStack(alignment: .bottomLeading) {
                List {
                    ForEach(userData.notYetFriendList, id: \.userEmail) { friend in
                        HStack(alignment: .center, spacing: 15) {
                            buttonAprvORCncl(title: "친구\n추가", color: .teal) {
                                viewModel.addNotYetFriendToMe(friend: friend)
                            }
                            VStack(alignment: .leading) {
                                Text(friend.userNickName)
                                    .foregroundColor(.black)
                                    .lineLimit(1)
                                Text("(\(friend.userEmail))")
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                                    .font(.caption)
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.white)
                    }
                }
                .padding(.trailing, 10)
                .listStyle(.plain)
                additionalSpace(color: .white)
                    .frame(height: 40)
                
            }
            .background(.white)
            .mask {
                listMaskView(radius: 10)
            }
            .shadow(color: .black, radius: 1, x: 0, y: 0)
            .padding(10)
        })
    }
    
    
    func buttonAprvORCncl(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation {
                action()
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 40, height: 40)
            
        }
        .buttonStyle(ScaleEffect())
    }
    
}

#Preview {
    NotYetFriendListView(userData: UserData(), isShowingSheet: .constant(true))
}
