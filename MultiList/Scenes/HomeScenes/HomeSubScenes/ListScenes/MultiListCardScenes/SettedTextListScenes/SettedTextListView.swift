//
//  SettedTextListView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/09/30.
//

import SwiftUI

struct SettedTextListView: View {
    @ObservedObject var userData: UserData
    @ObservedObject var textList: TextList
    @StateObject var viewModel: SettedTextListViewModel
    
    let color: Color = .white
    let width: CGFloat
    
    init(userData: UserData, textList: TextList, width: CGFloat) {
        _userData = ObservedObject(wrappedValue: userData)
        _textList = ObservedObject(wrappedValue: textList)
        _viewModel = StateObject(wrappedValue: SettedTextListViewModel(userData: userData, textList: textList))
        self.width = width
    }
    
    var body: some View {
        GeometryReader { proxy in
            backgroundCardView
                .shadow(color: .gray, radius: 1, x: 0, y: 0)
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
                    titleView(title: textList.title)
                }
        }
    }
}


extension SettedTextListView {
    // 1. 배경 카드
    var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
    }
    // 2. 리스트 타입별 Preview
    @ViewBuilder
    func contentTypeView(proxy: GeometryProxy) -> some View {
        HStack(content: {
            HStack(spacing: 1) {
                VStack(alignment: .leading, spacing: -0.9) {
                    Text("T")
                    Text("E")
                    Text("X")
                    Text("T")
                }
                .font(Font.system(size: width * 0.1))
                .fontWeight(.bold)
                Image(systemName: "text.alignleft")
                    .resizable()
                    .fontWeight(.light)
                    .padding(.vertical, 2)
            }
            .frame(width: width * 0.35, height: width * 0.4)
            Text("\(textList.itemList.count)")
        })
        .foregroundColor(.gray)
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

#Preview {
    SettedTextListView(userData: UserData(),
                       textList: TextList(title: "sample TextList"),
                       width: 150)
}
