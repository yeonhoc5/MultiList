//
//  SendShareView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/01.
//

import SwiftUI

struct SendShareView: View {
    @ObservedObject var userData: UserData
    @Binding var multiList: MultiList!
    @StateObject var viewModel: SendShareViewModel
    @Binding var isShowingSheet: Bool
    @State var indexSetToShare: [Int] = []
    @State var selectedShareType: ShareType = .copy
    
    @State var sharePeple: [String] = []
    
    let color: Color
    let width = min(screenSize.width, screenSize.height) / 5 > 100 ? 100 : min(screenSize.width, screenSize.height) / 5
    
    init(userData: UserData, multiList: Binding<MultiList?>, isShowingSheet: Binding<Bool>, color: Color) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: SendShareViewModel(userData: userData))
        _multiList = multiList
        _isShowingSheet = isShowingSheet
        self.color = color
    }
    
    var body: some View {
        NavigationView {
            OStack(verticalSpacing: 30, horizontalSpacing: 0) {
                // 1. 공유할 항목 View
                multiListToShareView(multiList: self.multiList)
                    .frame(width: width * 1.3, height: width * 1.3 * 1.2)
                    .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
                    .padding(.horizontal, 20)
                Divider()
                // 2. 공유 방식 선택 View
                shareTypeSelectView
                    .frame(maxWidth: screenSize.width < screenSize.height ? screenSize.width : max(screenSize.width, screenSize.height) * 0.27)
                Divider()
                VStack(content: {
                // 3. 공유할 친구 선택 View
                    friendListCheckView
                // 4. 공유 버튼
                    shareButton
                })
            }
            .padding(.bottom, 30)
            .navigationTitle("멀티리스트 공유하기")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        withAnimation {
                            indexSetToShare = []
                            isShowingSheet = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - 1. 공유할 항목 View
extension SendShareView {
    @ViewBuilder
    func multiListToShareView(multiList: MultiList) -> some View {
        Group {
            switch multiList.listType {
            case .textList:
                if let content = userData.textList.first(where: { $0.id == multiList.multiID }) {
                    SettedTextListView(userData: userData,
                                        textList: content,
                                        width: width * 1.5)
                    .onAppear {
                        sharePeple = content.sharedPeople.compactMap({ $0.userEmail })
                    }
                } else {
                    NotSettedView(userData: self.userData, multiList: multiList)
                }
            case .checkList:
                if let content = userData.checkList.first(where: { $0.id == multiList.multiID }) {
                    SettedCheckListView(userData: userData,
                                        checkList: content,
                                        width: width * 1.5)
                    .onAppear {
                        sharePeple = content.sharedPeople.compactMap({ $0.userEmail })
                    }
                } else {
                    NotSettedView(userData: self.userData, multiList: multiList)
                }
            case .linkList:
                if let content = userData.linkList.first(where: { $0.id == multiList.multiID }) {
                    SettedLinkListView(userData: userData,
                                       linkList: content,
                                       width: width * 1.5)
                    .onAppear {
                        sharePeple = content.sharedPeople.compactMap({ $0.userEmail })
                    }
                } else {
                    NotSettedView(userData: self.userData, multiList: multiList)
                }
            default:
                NotSettedView(userData: self.userData, multiList: multiList)
            }
        }
        .clipped()
    }
}

// MARK: - 2. 공유 방식 선택 View
extension SendShareView {
    var shareTypeSelectView: some View {
        Rectangle()
            .foregroundStyle(Color.primaryInverted)
            .frame(maxHeight: screenSize.width < screenSize.height ? 60 : .infinity)
            .overlay(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("1. 공유 방식을 선택해주세요.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    OStack(spacing: 10, isVerticalFirst: false) {
                        ForEach(ShareType.allCases, id: \.self) { type in
                            let isSelected = selectedShareType == type
                            Button {
                                selectedShareType = type
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .foregroundColor(isSelected ? .teal : .white)
                                        .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
                                    HStack(spacing: 15) {
                                        Image(systemName: ShareType.returnImageName(type: type))
                                            .foregroundColor(isSelected ? .white : .gray)
                                            .frame(width: 10)
                                        Text("\(type.rawValue)")
                                    }
                                    .foregroundColor(.black)
                                }
                            }
                            .buttonStyle(ScaleEffect())
                            .frame(height: 50)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 30)
    }
}

// MARK: - 3. 공유할 친구 리스트
extension SendShareView {
    var friendListCheckView: some View {
        Rectangle()
            .foregroundStyle(Color.primaryInverted)
            .overlay {
                VStack(alignment: .leading, spacing: 5) {
                    Text("2. 공유할 친구들을 선택해주세요.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)
                    if userData.friendList.count > 0 {
                        ScrollView {
                            GeometryReader { geoProxy in
                                let item = Array(repeating: GridItem(.flexible(),
                                                                     spacing: 0,
                                                                     alignment: .bottom),
                                                 count: screenSize.width > 400 ? (Int(geoProxy.size.width) - 50) / 150 : 2)
                                LazyVGrid(columns: item, spacing: 0) {
                                    ForEach(userData.friendList, id: \.userEmail) { friend in
                                        let aleadyShared = sharePeple.contains(friend.userEmail)
                                        Button {
                                            if let index = indexSetToShare.firstIndex(of: friend.order) {
                                                self.indexSetToShare.remove(at: index)
                                            } else {
                                                withAnimation(.easeOut(duration: 0.2)) {
                                                    self.indexSetToShare.append(friend.order)
                                                }
                                            }
                                        } label: {
                                            personCardView(isSelected: indexSetToShare.contains(friend.order),
                                                           friend: friend,
                                                           alreadyShared: aleadyShared)
                                        }
                                        .buttonStyle(ScaleEffect())
                                        .opacity(aleadyShared ? 0.5 : 1)
                                        .disabled(aleadyShared)
                                        .padding(5)
                                    }
                                }
                            }
                        }
                        .scrollIndicators(.visible)
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(Color.primaryInverted)
                            VStack {
                                Text("등록된 친구가 없습니다.")
                                Text("사용자 설정에서 친구를 등록해주세요.")
                            }
                            .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 15)
            }
    }
    
    func personCardView(isSelected: Bool, friend: Friend, alreadyShared: Bool) -> some View {
        let state = alreadyShared && selectedShareType == .groupShare
        return RoundedRectangle(cornerRadius: 10)
            .fill(state ? .gray : (isSelected ? .teal : .white))
            .frame(height: 70)
            .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
            .overlay {
                VStack(alignment: .leading, spacing: 8) {
                    Text(friend.userNickName)
                        .font(.callout)
                        .foregroundColor(state ? .white : .black)
                    Text(friend.userEmail)
                        .font(.caption)
                        .foregroundColor(state ? .white : (isSelected ? .white : .gray))
                }
            }
            .overlay(alignment: .topTrailing) {
                if alreadyShared {
                    Text("참여 중")
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(content: {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(.teal)
                        })
                        .padding(5)
                }
            }
    }
}

// MARK: - 4. share button
extension SendShareView {
    var shareButton: some View {
        let readyToShare = arrayToShare(type: selectedShareType).count != 0
        return Button {
            viewModel.sendShareMultilist(indexSet: arrayToShare(type: selectedShareType),
                                         multiList: multiList,
                                         shareType: selectedShareType)
            self.isShowingSheet = false
            self.indexSetToShare = []
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .foregroundColor(readyToShare ? .blue : .white)
                HStack(spacing: 0) {
                    Text("\(readyToShare ? "\(arrayToShare(type: selectedShareType).count)명의 친구에게" : "선택한 친구가" )")
                    Text(" ")
                    Text("\(readyToShare ? "공유하기" : "없습니다.")")
                }
                .foregroundColor(readyToShare ? .white : .gray)
            }
        }
        .buttonStyle(ScaleEffect())
        .disabled(!readyToShare)
        .padding(.horizontal, 20)
        .frame(height: 50)
        .clipped()
        .shadow(color: .black, radius: 1.5, x: 0, y: 1.3)
    }
    
    func arrayToShare(type: ShareType) -> Array<Int> {
        if type == .copy {
            return self.indexSetToShare
        } else {
            let set = Set(self.indexSetToShare).symmetricDifference(Set((userData.friendList.filter({sharePeple.contains($0.userEmail)}).compactMap({$0.order}))))
            let reArray = Array(set)
            return reArray
        }
    }
}

struct SendShareView_Previews: PreviewProvider {
    static var previews: some View {
        SendShareView(userData: UserData(),
                      multiList: .constant(sampleMultiList3),
                      isShowingSheet: .constant(true),
                      color: .teal)
    }
}
