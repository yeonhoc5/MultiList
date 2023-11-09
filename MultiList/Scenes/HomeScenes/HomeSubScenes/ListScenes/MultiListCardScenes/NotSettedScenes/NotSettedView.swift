//
//  NotSettedView.swift
//  MultiList
//
//  Created by yeonhoc5 on 2023/08/18.
//

import SwiftUI
import PieChart

struct NotSettedView: View {
    @StateObject var viewModel: NotSettedViewModel
    @ObservedObject var userData: UserData
    
    let color: Color = .gray.opacity(0.3)
    
    init(userData: UserData, multiList: MultiList) {
        _userData = ObservedObject(wrappedValue: userData)
        _viewModel = StateObject(wrappedValue: NotSettedViewModel(userData: userData,
                                                                  multiList: multiList))
    }
    
    var body: some View {
        GeometryReader(content: { geometry in
            backgroundCardView
                .overlay(alignment: .topLeading) {
                    titleView(title: "New\n멀티리스트")
                }
                .overlay(alignment: .bottom) {
                    HStack(content: {
                        Image(systemName: "questionmark")
                            .imageScale(.large)
                            .fontWeight(.black)
                            .foregroundColor(.white.opacity(0.5))
                    })
                    .frame(height: geometry.size.width)
                }
        })
    }
}


extension NotSettedView {
    // 1. 배경 카드
    var backgroundCardView: some View {
        RoundedRectangle(cornerRadius: 5)
            .foregroundColor(color)
    }
    
    // 3. 타이틀뷰
    func titleView(title: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .lineLimit(5, reservesSpace: true)
                .multilineTextAlignment(.leading)
                .bold()
                .foregroundColor(.white.opacity(0.5))
                .padding([.leading, .top], 5)
        }
    }
}


struct MultiListView_Previews: PreviewProvider {
    static var previews: some View {
        NotSettedView(userData: UserData(), multiList: sampleMultiList1)
    }
}
