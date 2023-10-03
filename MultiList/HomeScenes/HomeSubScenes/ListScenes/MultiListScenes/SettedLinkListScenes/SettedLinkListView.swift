//
//  SettedLinkListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/11.
//

import SwiftUI

struct SettedLinkListView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var linkList: LinkList
    @StateObject var viewModel: SettedLinkListViewModel
    
    let color: Color
    let width: CGFloat
    
    init(userData: UserData, linkList: LinkList, color: Color, width: CGFloat) {
        _userData = ObservedObject(wrappedValue: userData)
        _linkList = ObservedObject(wrappedValue: linkList)
        _viewModel = StateObject(wrappedValue: SettedLinkListViewModel(userData: userData,
                                                                        linkList: linkList))
        self.color = .colorSet[2]
        self.width = width
    }

    
    var body: some View {
        GeometryReader { proxy in
            backgroundCardView
                .overlay(alignment: .bottom) {
                    contentTypeView(proxy: proxy)
                }
                .overlay(alignment: .bottomTrailing) {
                    if viewModel.returningSharingcount() >= 2 {
                        shareMark(width: width * 0.35)
                            .offset(x: width * 0.07, y: width * 0.1)
                    }
                }
                .overlay(alignment: .topLeading) {
                    titleView(title: linkList.title)
                }
        }
    }
}


extension SettedLinkListView {
    // 1. 배경 카드
    var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
    }
    // 2. 리스트 타입별 Preview
    @ViewBuilder
    func contentTypeView(proxy: GeometryProxy) -> some View {
        HStack {
            Image(systemName: "link")
                .imageScale(.large)
            Text("\(linkList.itemList.count)")
        }
        .foregroundColor(.white)
        .frame(height: width)
    }
    
    // 2-1. 로딩 뷰
    var loadingView: some View {
        Text("Loading...")
            .foregroundColor(.white.opacity(0.5))
            .font(.caption)
            .padding(.bottom, 10)
    }
    
    
    // 3. 타이틀뷰
    func titleView(isDone: Bool! = false, title: String, total: Int = 0, doneCount: Int = 0) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(.black)
                .padding([.leading, .top], 5)
        }
    }
}

struct SettedLinkListView_Previews: PreviewProvider {
    static var previews: some View {
        SettedLinkListView(userData: UserData(),
                           linkList: sampleLinkList,
                           color: .teal,
                           width: min(screenSize.width, screenSize.height) / 5)
    }
}
