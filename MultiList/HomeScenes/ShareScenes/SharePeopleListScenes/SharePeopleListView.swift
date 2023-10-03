//
//  SharePeopleListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/01.
//

import SwiftUI

struct SharePeopleListView: View {
    @ObservedObject var userData: UserData
    @Binding var multiList: MultiList!
    @StateObject var viewModel: SharePeopleListViewModel
    @Binding var isShowingSheet: Bool
    @State var indexSetToShare: [Int] = []
    @State var selectedShareType: ShareType = .copy
    
    @State var sharePeple: [String] = []
    
    let color: Color
    let width = min(screenSize.width, screenSize.height) / 5 > 100 ? 100 : min(screenSize.width, screenSize.height) / 5
    
    init(userData: UserData, multiList: Binding<MultiList?>, isShowingSheet: Binding<Bool>, color: Color) {
        _userData = ObservedObject(wrappedValue: userData)
        
        _viewModel = StateObject(wrappedValue: SharePeopleListViewModel(userData: userData))
        _multiList = multiList
        _isShowingSheet = isShowingSheet
        self.color = color
    }
    
    var body: some View {
        NavigationView {
            OStack(spacing: 30) {
                multiListToShareView(multiList: self.multiList)
                    .frame(width: width * 1.5, height: width * 1.5 * 1.2)
                VStack {
                    friendListCheckView
                    shareTypeSelectView
                }
                .frame(minWidth: min(screenSize.width, screenSize.height))
                shareButton
//                    .frame(minWidth: min(screenSize.width, screenSize.height) * 0.5)
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

extension SharePeopleListView {
    // 1. 공유할 항목
    @ViewBuilder
    func multiListToShareView(multiList: MultiList) -> some View {
        switch multiList.listType {
        case .checkList:
            if let content = userData.checkList.first(where: { $0.id == multiList.multiID }) {
                SettedCheckListView(userData: userData,
                                    checkList: content,
                                    color: color,
                                    width: width * 1.5)
                .onAppear {
                    sharePeple = content.sharedPeople.compactMap({ $0.userEmail })
                }
            } else {
                NotSettedView(userData: self.userData, color: color, multiList: multiList)
                    
            }
        case .linkList:
            if let content = userData.linkList.first(where: { $0.id == multiList.multiID }) {
                SettedLinkListView(userData: userData,
                                   linkList: content,
                                   color: color,
                                   width: width * 1.5)
                .onAppear {
                    sharePeple = content.sharedPeople.compactMap({ $0.userEmail })
                }
            } else {
                NotSettedView(userData: self.userData, color: color, multiList: multiList)
            }
        default:
            NotSettedView(userData: self.userData, color: color, multiList: multiList)
        }
    }
    
    // 2. 공유할 친구 리스트
    var friendListCheckView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("1. 공유할 친구들을 선택해주세요.")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            if userData.friendList.count > 0 {
                GeometryReader { geoProxy in
                    let item = Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .bottom), count: (Int(geoProxy.size.width) - 50) / 150)
                    LazyVGrid(columns: item, spacing: 10) {
                        ForEach(userData.friendList, id: \.userEmail) { friend in
                            let aleadyShared = sharePeple.contains(friend.userEmail)
                            Button {
                                if let index = indexSetToShare.firstIndex(of: friend.order) {
                                    withAnimation(.easeOut(duration: 0.2)) {
//                                        self.indexSetToShare.remove(at: index)
                                    }
                                } else {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        indexSetToShare.append(friend.order)
                                    }
                                }
                            } label: {
                                personCardView(isSelected: indexSetToShare.contains(friend.order),
                                               friend: friend,
                                               alreadyShared: aleadyShared)
                            }
                            .buttonStyle(ScaleEffect())
                            .opacity(aleadyShared && selectedShareType == .groupShare ? 0.5 : 1)
                            .disabled(aleadyShared && selectedShareType == .groupShare)
                        }
                    }
                }
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
        .padding(.horizontal, 20)
    }
    
    // 3. 공유 방식
    var shareTypeSelectView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2. 공유 방식을 선택해주세요.")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            HStack(spacing: 10) {
                ForEach(ShareType.allCases, id: \.self) { type in
                    let isSelected = selectedShareType == type
                    Button {
                        selectedShareType = type
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(isSelected ? .teal : .white)
                                .shadow(color: .black, radius: 1.5, x: 0, y: 0)
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
        .padding(.bottom, 30)
    }

    // 4. share button
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
                OStack(spacing: 0, isVerticalFirst: false) {
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
        .frame(height: screenSize.width < screenSize.height ? 50 : 150)

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


struct SharePeopleListScenes_Previews: PreviewProvider {
    static var previews: some View {
        SharePeopleListView(userData: UserData(),
                            multiList: .constant(sampleMultiList1),
                            isShowingSheet: .constant(true),
                            color: .teal)
    }
}
