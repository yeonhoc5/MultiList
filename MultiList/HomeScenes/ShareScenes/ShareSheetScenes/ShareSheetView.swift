//
//  ShareSheetView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/30.
//

import SwiftUI

enum ShareSheet {
    case send, recieve
}

struct ShareSheetView: View {
    @ObservedObject var userData: UserData
    @StateObject var viewModel: ShareSheetViewModel
    @Binding var isShowingSheet: Bool
    @State var selectedTab: ShareSheet = .recieve
    
    init(userData: UserData, isShowingSheet: Binding<Bool>) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: ShareSheetViewModel(userData: userData))
        _isShowingSheet = isShowingSheet
    }
    
    var body: some View {
        NavigationView {
            OStack(spacing: 0) {
                // 탭버튼 && 범례
                VStack(spacing: 15) {
                    OStack(spacing: screenSize.width < screenSize.height ? 15 : 50, isVerticalFirst: false) {
                        tabButton(title: "받은", tab: .recieve)
                        tabButton(title: "보낸", tab: .send)
                    }
                    .padding(.horizontal, 30)
                    legendView
                }
                // 공유 리스트 탭 뷰
                ZStack {
                    cardView(color: .primary)
                        .blur(radius: 1.5)
                    TabView(selection: $selectedTab, content: {
                        eachTabView(tab: .recieve)
                            .tag(ShareSheet.recieve)
                        eachTabView(tab: .send)
                            .tag(ShareSheet.send)
                    })
                    .tabViewStyle(.page)
                    .background(content: {
                        Color.white
                    })
                    .mask {
                        cardView(color: .primary)
                    }
                }
                .padding(20)
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        withAnimation {
                            isShowingSheet = false
                        }
                    }
                }
            }
        }
    }
}

extension ShareSheetView {
    
    func tabButton(title: String, tab: ShareSheet) -> some View {
        Button("공유 \(title) 리스트") {
            withAnimation {
                selectedTab = tab
            }
        }
        .scaleEffect(selectedTab == tab ? 1 : 0.7)
        .font(selectedTab == tab ? .title : .none)
        .fontWeight(.semibold)
        .foregroundColor(selectedTab == tab ? .teal : .gray)
    }
    
    var legendView: some View {
        HStack(spacing: 15) {
            ForEach(ShareType.allCases, id: \.self) { type in
                HStack(spacing: 5) {
                    Image(systemName: ShareType.returnImageName(type: type))
                        .imageScale(.small)
                    Text("\(type.rawValue)")
                        .font(.caption)
                }
            }
        }
    }
    
    @ViewBuilder
    func eachTabView(tab: ShareSheet) -> some View {
        let shareMultiList = userData.user != nil ? (tab == .recieve ?
                                                     userData.sharedMultiList : userData.sharingMultiList) : sampleShareMulti
        
        let text = tab == .recieve ? "받은" : "보낸"
        Group {
            if shareMultiList.count == 0 {
                ListEmptyView(title: "공유 \(text) 리스트가 없습니다.", checkBool: .constant(false))
            } else {
                List {
                    switch tab {
                    case .recieve:
                        shareListView(list: shareMultiList, tab: tab)
                    case .send:
                        let listOnGoing = shareMultiList.filter({ $0.shareResult == .undetermined })
                        let listDone = shareMultiList.filter({ $0.shareResult != .undetermined })
                        Section {
                            shareListView(list: listOnGoing, tab: tab)
                        } header: {
                            HStack {
                                Spacer()
                                Text("요청 중인 목록 (\(listOnGoing.count)개)")
                                    .foregroundColor(.gray)
                                    .fontWeight(.bold)
                            }
                        }
                        Section {
                            shareListView(list: listDone, tab: tab)
                        } header: {
                            HStack {
                                Spacer()
                                Text("요청 완료 목록 (\(listDone.count)개)")
                                    .foregroundColor(.gray)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }
    
    func shareListView(list: [ShareMultiList], tab: ShareSheet) -> some View {
        ForEach(list, id: \.id) { shareInfo in
            GeometryReader { geoProxy in
                HStack(alignment: .center) {
                    // 거부 버튼
                    if tab == .recieve {
                        buttonReject {
                            viewModel.shareResult(friendEmail: shareInfo.userEmail,
                                                  shareID: shareInfo.id,
                                                  multiID: shareInfo.multiID,
                                                  result: .reject)
                        }
                    }
                    HStack {
                        // 공유 리스트 & 시간
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 5) {
                                shareTypeView(type: shareInfo.shareType)
                                    .foregroundColor(.black)
                                labelText(label: shareInfo.title)
                            }
                            secondaryLabelText(label: viewModel.returningDate(date: shareInfo.sharedTime))
                        }
                        .frame(width: tab == .recieve ? geoProxy.size.width * 0.45 : geoProxy.size.width * 0.5, alignment: .leading)
                        // 친구 정보
                        VStack(alignment: .leading, spacing: 5) {
                            labelText(label: shareInfo.userNickName)
                            secondaryLabelText(label: shareInfo.userEmail)
                        }
                    }
                    
                    Spacer()
                    
                    // 승인 버튼
                    if tab == .recieve {
                        buttonAprvORCncl(title: "승인", color: .teal, action: {
                            viewModel.approveShare(friendEmail: shareInfo.userEmail,
                                                   shareID: shareInfo.id,
                                                   multiID: shareInfo.multiID,
                                                   multiType: shareInfo.multiListType,
                                                   shareType: shareInfo.shareType)
                        })
                    } else if tab == .send {
                        if shareInfo.shareResult == .undetermined {
                            buttonAprvORCncl(title: "취소", color: .red, action: {
                                viewModel.cancelShare(friendEmail: shareInfo.userEmail,
                                                      shareID: shareInfo.id)
                            })
                        } else {
                            let result = shareInfo.shareResult
                            VStack(spacing: 5) {
                                Text("승인함")
                                    .foregroundColor(result == .approve ? .colorSet[7] : .gray)
                                Text("거절함")
                                    .foregroundColor(result == .reject ? .colorSet[0] : .gray)
                            }
                            .font(.caption)
                            .background {
                                Color.white
                            }
                        }
                    }
                }
            }
            .listRowBackground(Color.white)
            .frame(height: 40)
        }

    }
}

extension ShareSheetView {
    
    func cardView(color: Color = .teal) -> some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(color)
    }
    
    func labelText(label: String) -> some View {
        Text(label)
            .font(.callout)
            .foregroundColor(.black)
            .lineLimit(1)
    }
    
    func secondaryLabelText(label: String) -> some View {
        Text(label)
            .font(.caption)
            .foregroundColor(.gray)
            .lineLimit(1)
    }
    
    func shareTypeView(type: ShareType) -> some View {
        let image = ShareType.returnImageName(type: type)
        return Image(systemName: image)
            .resizable()
            .scaledToFit()
            .frame(width: 15, height: 15)
    }
    func buttonReject(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: "xmark")
                .imageScale(.large)
                .foregroundColor(.red)
        }
        .buttonStyle(ScaleEffect(scale: 0.7))
    }
    
    func buttonAprvORCncl(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .fill(color)
                Text(title)
                    .font(.callout)
                    .foregroundColor(.white)
            }
            .frame(width: 40)
        }
        .buttonStyle(ScaleEffect())
    }
}

struct ShareSheetView_Previews: PreviewProvider {
    static var previews: some View {
        ShareSheetView(userData: UserData(), isShowingSheet: .constant(true))
    }
}
